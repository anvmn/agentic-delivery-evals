#!/usr/bin/env bash
# run.sh — cross-lab blind-review panel: the four OpenRouter-column models
# (Grok 4.5, Kimi K2.7-code, Qwen3-Coder-next, DeepSeek V3.2) blind-review the
# suite's two headline review probes:
#
#   e-06:  correct String.toList reference + String.length flaw. Does a fresh
#          pipeline hallucinate the UTF-16 bug (Sonnet/Haiku did) or judge it
#          correctly (Fable/Opus/Sol did)? Grok 4.5 is explicitly marketed on
#          "non-hallucination rate" — this is that claim, measured.
#   d7-01: the canonical echo submission, against BOTH spec wordings — the
#          pre-0.3.1 ambiguous criterion #3 (what the Claude panel saw) and
#          the 0.3.1 tightened wording. If tightening flips approvals to
#          rejections, author-catch #8's diagnosis (wording, not blindness)
#          is validated on independent pipelines.
#
# Blind = no tools; prompt/verdict contract identical to gen-vs-recognition.
# Reviews run through codex exec with the openrouter provider (read-only
# sandbox), stdin pinned. Cost metered like runner/agents/openrouter.sh
# (cache-aware token pricing from the live catalog).
# Usage: run.sh [trials] [max_cost] [reviewers-csv]
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$HERE/reviews.jsonl"
TRIALS="${1:-3}"; MAX_COST="${2:-6}"
REVIEWERS="${3:-x-ai/grok-4.5,moonshotai/kimi-k2.7-code,qwen/qwen3-coder-next,deepseek/deepseek-v3.2}"

# Key + catalog prices (cache-aware), fetched once.
if [ -z "${OPENROUTER_API_KEY:-}" ] && [ -f "$HOME/.bashrc" ]; then
  eval "$(grep -E '^export OPENROUTER_API_KEY=' "$HOME/.bashrc" | tail -1)" || true
fi
CATALOG="$HERE/.catalog.json"
curl -s --max-time 30 https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" -o "$CATALOG" 2>/dev/null
price_of() { # $1=model -> "pi po pc"
  jq -r --arg m "$1" '.data[] | select(.id==$m) |
    "\(.pricing.prompt) \(.pricing.completion) \(.pricing.input_cache_read // .pricing.prompt)"' \
    "$CATALOG" 2>/dev/null | head -n1
}

spent() { local v; v=$(jq -s '[.[] | .cost // 0] | add // 0' "$OUT" 2>/dev/null); [[ "$v" =~ ^[0-9] ]] && printf '%s' "$v" || echo 0; }

# --- the d7-01 spec variants -------------------------------------------------
SPEC_NEW="$ROOT/tasks/d7-01-menu-endpoint/task.md"          # 0.3.1 tightened
SPEC_OLD="$HERE/.task-d7-01-pre031.md"                       # reconstructed pre-0.3.1
python3 - "$SPEC_NEW" "$SPEC_OLD" <<'EOF'
import sys
s = open(sys.argv[1]).read()
new = """- [ ] JSON is delivered as JSON (correct Content-Type) through D7's
      delivery architecture: the page callback **returns** the data array and
      emits no output itself — no `print`/`echo`, no output-emitting helpers
      called inside the callback, no `exit`. (Conversion to JSON belongs to
      the menu item's delivery layer, not the page callback.)"""
old = """- [ ] JSON is delivered as JSON (correct Content-Type), using D7's native
      delivery mechanism — not `print` + `exit`."""
assert new in s, "0.3.1 wording not found in task.md"
open(sys.argv[2], 'w').write(s.replace(new, old))
EOF

files_inline() { # $1=dir $2..=relative paths
  local d="$1"; shift; local body="" f
  for f in "$@"; do body+=$'\n\n--- FILE: '"$f"$' ---\n'"$(cat "$d/$f")"; done
  printf '%s' "$body"
}

build_prompt() {  # $1=domain $2=spec-file $3=code-body
  printf 'You are a strict senior %s code reviewer. Review the submission below against its task specification. Judge ONLY whether the code fully satisfies every acceptance criterion; assume it will be deployed to production as-is.\n\n=== TASK SPECIFICATION ===\n%s\n\n=== SUBMITTED CODE ===%s\n\n=== INSTRUCTIONS ===\nDo not use any tools. Respond with ONLY a JSON object, no other text:\n{"verdict": "approve" or "reject", "reasons": ["short reason", ...]}\nReject if any acceptance criterion is violated, including edge-case behavior.' \
    "$1" "$(cat "$2")" "$3"
}

run_review() {  # $1=model $2=prompt -> "<verdict>\t<cost>\t<reasons>"
  local model="$1" prompt="$2" resp text usage pr cost blob verdict reasons
  resp=$(timeout 300 codex exec -c model_provider=openrouter -m "$model" --json \
           --skip-git-repo-check --sandbox read-only -C /tmp "$prompt" \
           </dev/null 2>/dev/null || true)
  text=$(printf '%s' "$resp" | jq -rs 'map(select(.type=="item.completed") | .item.text // empty) | last // ""' 2>/dev/null | head -c 20000)
  usage=$(printf '%s' "$resp" | jq -s '
    [ .[] | (.usage? // .msg?.usage? // .payload?.usage?) | select(. != null) ] |
    { in:  ([.[] | .input_tokens       // 0] | add // 0),
      cin: ([.[] | .cached_input_tokens // 0] | add // 0),
      out: ([.[] | (.output_tokens // 0) + (.reasoning_output_tokens // 0)] | add // 0) }' 2>/dev/null)
  printf '%s' "$usage" | jq -e . >/dev/null 2>&1 || usage='{"in":0,"cin":0,"out":0}'
  pr=$(price_of "$model"); [ -n "$pr" ] || pr="0 0 0"
  read -r pi po pc <<<"$pr"
  cost=$(jq -n --argjson u "$usage" --argjson pi "$pi" --argjson po "$po" --argjson pc "$pc" \
    '((($u.in - $u.cin) * $pi) + ($u.cin * $pc) + ($u.out * $po)) | if . < 0 then 0 else . end' 2>/dev/null | head -n1)
  # Extraction ladder (verified-review lesson: no `jq || echo` doubling).
  if printf '%s' "$text" | jq -e '.verdict' >/dev/null 2>&1; then
    blob="$text"
  else
    blob=$(printf '%s' "$text" | tr '\n' ' ' | grep -o '{"verdict".*}' | tail -1 || true)
    printf '%s' "$blob" | jq -e '.verdict' >/dev/null 2>&1 || \
      blob=$(printf '%s' "$text" | tr '\n' ' ' | grep -o '{[^{}]*"verdict"[^{}]*}' | tail -1 || true)
  fi
  verdict=$(printf '%s' "$blob" | jq -r '.verdict // "parse_error"' 2>/dev/null | head -n1)
  reasons=$(printf '%s' "$blob" | jq -c '.reasons // []' 2>/dev/null | head -n1)
  [ -n "$verdict" ] || verdict=parse_error
  printf '%s' "$reasons" | jq -e . >/dev/null 2>&1 || reasons='[]'
  [[ "$cost" =~ ^[0-9.]+([eE][-+][0-9]+)?$ ]] || cost=0
  printf '%s\t%s\t%s' "$verdict" "$cost" "$reasons"
}

do_cell() {  # $1=reviewer $2=task $3=solution $4=spec_version $5=truth $6=trial $7=prompt
  local reviewer="$1" task="$2" sol="$3" specv="$4" truth="$5" trial="$6" prompt="$7"
  jq -e --arg r "$reviewer" --arg t "$task" --arg s "$sol" --arg v "$specv" --argjson tr "$trial" \
     'select(.reviewer==$r and .task==$t and .solution==$s and .spec_version==$v and .trial==$tr)' \
     "$OUT" 2>/dev/null | grep -q . && return 0   # resume
  local s; s=$(spent)
  jq -n --argjson s "$s" --argjson m "$MAX_COST" '$s >= $m' | grep -q true \
    && { echo "BUDGET CAP (\$$s) — stopping." >&2; exit 2; }
  local ts verdict cost reasons correct=false
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  IFS=$'\t' read -r verdict cost reasons < <(run_review "$reviewer" "$prompt")
  { [ "$verdict" = "reject" ] && [ "$truth" = "reject" ]; } && correct=true
  { [ "$verdict" = "approve" ] && [ "$truth" = "approve" ]; } && correct=true
  jq -cn --arg ts "$ts" --arg reviewer "$reviewer" --arg task "$task" --arg sol "$sol" \
     --arg specv "$specv" --arg truth "$truth" --argjson trial "$trial" --arg verdict "$verdict" \
     --argjson correct "$correct" --argjson cost "${cost:-0}" --argjson reasons "$reasons" \
     '{experiment:"cross-lab-review", ts:$ts, reviewer:$reviewer, task:$task, solution:$sol,
       spec_version:$specv, truth:$truth, trial:$trial, verdict:$verdict, correct:$correct,
       cost:$cost, reasons:$reasons}' >> "$OUT" \
    || echo "  !! record write failed: $reviewer $task/$sol/$specv t$trial" >&2
  echo "  $reviewer | $task/$sol${specv:+/$specv} t$trial -> $verdict $([ "$correct" = true ] && echo OK || echo MISS)"
}

E06="$HERE/../gen-vs-recognition/solutions/e-06-unicode-length"
D701="$HERE/../verified-review/solutions/d7-01-echo"
E06_SPEC="$ROOT/tasks/e-06-unicode-length/task.md"

IFS=',' read -ra RVW <<< "$REVIEWERS"
for reviewer in "${RVW[@]}"; do
  for solkind in reference flawed; do
    truth="approve"; [ "$solkind" = "flawed" ] && truth="reject"
    body=$(files_inline "$E06/$solkind" TextStats.elm TextStatsTest.elm)
    prompt=$(build_prompt "Elm" "$E06_SPEC" "$body")
    for trial in $(seq 1 "$TRIALS"); do
      do_cell "$reviewer" "e-06" "$solkind" "current" "$truth" "$trial" "$prompt"
    done
  done
  body=$(files_inline "$D701" healthstats/healthstats.info healthstats/healthstats.module)
  for specv in pre-0.3.1 0.3.1; do
    spec="$SPEC_OLD"; [ "$specv" = "0.3.1" ] && spec="$SPEC_NEW"
    prompt=$(build_prompt "Drupal" "$spec" "$body")
    for trial in $(seq 1 "$TRIALS"); do
      do_cell "$reviewer" "d7-01" "echo" "$specv" "reject" "$trial" "$prompt"
    done
  done
done
echo "done. reviews: $OUT ($(wc -l < "$OUT" 2>/dev/null || echo 0) records)"
