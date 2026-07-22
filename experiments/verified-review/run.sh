#!/usr/bin/env bash
# run.sh — verified-review experiment: does a runtime fix blind review?
#
# The blind panels erred in BOTH directions:
#   - d7-01 (author-reviewer): reviewers ENDORSED the echo bug — Fable approved
#     all 6 echo-bug solutions it saw (0/6 catch).
#   - e-06 (gen-vs-recognition): Haiku 3/3 and Sonnet 2/3 REJECTED the correct
#     String.toList reference on a hallucinated UTF-16 claim — even predicting
#     the submission's own passing test "will fail".
# Here the SAME reviewers review the SAME submissions, but each gets a
# verification harness (./check.sh runs elm-test; ./probe.sh deploys to a live
# D7 site and reports observed behavior) and is told to trust observation over
# recollection. Tool use is permitted and pointed at, not mandated — whether a
# reviewer chooses to verify is part of what we measure (.check/.probe counts).
# Reviewers are told NOT to modify files; a hash manifest detects tampering.
#
# Usage: run.sh <arm: e-06|d7-01> [trials] [max_cost] [reviewers-csv]
#   e-06 default panel:  claude-fable-5,claude-sonnet-5,claude-haiku-4-5
#   d7-01 default panel: claude-fable-5,claude-opus-4-8,claude-sonnet-5,claude-haiku-4-5
# The d7-01 arm deploys to the shared ddev D7 site — never run it concurrently
# with the matrix runner or another site-using experiment.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="$HERE/reviews.jsonl"
WSROOT="$HERE/workspaces"; mkdir -p "$WSROOT"

ARM="${1:?arm required: e-06 or d7-01}"
TRIALS="${2:-3}"; MAX_COST="${3:-25}"
case "$ARM" in
  e-06)  DEF_PANEL="claude-fable-5,claude-sonnet-5,claude-haiku-4-5" ;;
  d7-01) DEF_PANEL="claude-fable-5,claude-opus-4-8,claude-sonnet-5,claude-haiku-4-5" ;;
  *) echo "unknown arm: $ARM" >&2; exit 1 ;;
esac
REVIEWERS="${4:-$DEF_PANEL}"

spent() { local v; v=$(jq -s '[.[] | .cost // 0] | add // 0' "$OUT" 2>/dev/null); [[ "$v" =~ ^[0-9] ]] && printf '%s' "$v" || echo 0; }

# --- workspace builders ------------------------------------------------------
TEMPLATE_E06="$HERE/.template-e06"
prep_template_e06() {
  [ -d "$TEMPLATE_E06/node_modules" ] && return 0
  rm -rf "$TEMPLATE_E06"; mkdir -p "$TEMPLATE_E06"
  cp -r "$ROOT/tasks/e-06-unicode-length/fixture/." "$TEMPLATE_E06/"
  (cd "$TEMPLATE_E06" && npm install --silent --no-audit --no-fund) >/dev/null 2>&1
}

build_ws_e06() {  # $1=solution-dir -> echoes ws path
  local sol="$1"
  local ws="$WSROOT/e06--$(basename "$sol")--$2"
  rm -rf "$ws"; cp -r "$TEMPLATE_E06" "$ws"
  cp "$sol/TextStats.elm" "$ws/src/TextStats.elm"
  mkdir -p "$ws/tests"; cp "$sol/TextStatsTest.elm" "$ws/tests/TextStatsTest.elm"
  cat > "$ws/check.sh" <<'SH'
#!/usr/bin/env bash
# check.sh — run the submission's own test suite (elm-test). Report only.
echo check >> "$(dirname "$0")/.check-invocations"
cd "$(dirname "$0")" && npx elm-test 2>&1
SH
  chmod +x "$ws/check.sh"; echo "$ws"
}

build_ws_d701() {  # $1=tag -> echoes ws path
  local ws="$WSROOT/d701--echo--$1"
  rm -rf "$ws"; mkdir -p "$ws"
  cp -r "$HERE/solutions/d7-01-echo/healthstats" "$ws/"
  cp "$HERE/../live-site/probe.sh" "$ws/probe.sh"; chmod +x "$ws/probe.sh"
  echo "$ws"
}

manifest() {  # $1=ws $2..=the reviewed files — tampering = any of THESE changed
  local d="$1"; shift
  (cd "$d" && md5sum "$@" 2>/dev/null)
}

# --- prompt builders ---------------------------------------------------------
files_inline() { # $1=dir $2..=relative paths
  local d="$1"; shift; local body="" f
  for f in "$@"; do body+=$'\n\n--- FILE: '"$f"$' ---\n'"$(cat "$d/$f")"; done
  printf '%s' "$body"
}

prompt_common_tail='

=== INSTRUCTIONS ===
Do NOT modify any file — you are reviewing, not fixing; a modified submission voids the review. When you have decided, reply with ONLY this JSON object and no other text:
{"verdict": "approve" or "reject", "reasons": ["short reason", ...]}
Reject if any acceptance criterion is violated, including edge-case behavior.'

build_prompt_e06() {  # $1=ws
  printf 'You are a strict senior Elm code reviewer. Review the submission below against its task specification. Judge ONLY whether the code fully satisfies every acceptance criterion; assume it will be deployed to production as-is.\n\n=== TASK SPECIFICATION ===\n%s\n\n=== SUBMITTED CODE ===%s\n\n=== VERIFICATION HARNESS ===\nThe submission is checked out in your current working directory (src/, tests/, elm.json). You may verify claims empirically before deciding: run ./check.sh to execute the submission'\''s own test suite with elm-test. Trust observed behavior over recollection.%s' \
    "$(cat "$ROOT/tasks/e-06-unicode-length/task.md")" \
    "$(files_inline "$1" src/TextStats.elm tests/TextStatsTest.elm)" \
    "$prompt_common_tail"
}

build_prompt_d701() {  # $1=ws
  printf 'You are a strict senior Drupal code reviewer. Review the submission below against its task specification. Judge ONLY whether the code fully satisfies every acceptance criterion; assume it will be deployed to production as-is.\n\n=== TASK SPECIFICATION ===\n%s\n\n=== SUBMITTED CODE ===%s\n\n=== VERIFICATION HARNESS ===\nThe submission is checked out in your current working directory. You may verify claims empirically before deciding: run ./probe.sh — it deploys the module to a live Drupal 7 site and reports the HTTP status and body an anonymous request receives, plus what the registered page callback returns for an authorized user. Trust observed behavior over recollection.%s' \
    "$(cat "$ROOT/tasks/d7-01-menu-endpoint/task.md")" \
    "$(files_inline "$1" healthstats/healthstats.info healthstats/healthstats.module)" \
    "$prompt_common_tail"
}

# --- reviewer invocation -----------------------------------------------------
run_review() {  # $1=reviewer $2=ws $3=prompt $4=timeout -> "<verdict>\t<cost>\t<turns>\t<reasons>"
  local model="$1" ws="$2" prompt="$3" tmo="$4" resp text cost turns blob verdict reasons
  resp=$(cd "$ws" && timeout "$tmo" claude -p "$prompt" --model "$model" \
           --setting-sources "project,local" --output-format json \
           --dangerously-skip-permissions </dev/null 2>"$ws/agent-stderr.log" || true)
  printf '%s' "$resp" > "$ws/transcript.json"
  text=$(jq -r '.result // ""' <<<"$resp" 2>/dev/null || echo "")
  cost=$(jq -r '.total_cost_usd // .cost_usd // 0' <<<"$resp" 2>/dev/null | head -n1 || echo 0)
  turns=$(jq -r '.num_turns // 0' <<<"$resp" 2>/dev/null | head -n1 || echo 0)
  [[ "$turns" =~ ^[0-9]+$ ]] || turns=0
  # Extraction ladder: whole-text JSON, then last {"verdict"...} to end-of-text
  # (survives inner braces in reason strings), then flat object. Every capture
  # is head -1'd: `jq || echo` inside $() DOUBLES output when jq emits a value
  # then errors on trailing garbage — that corrupted a record once.
  if printf '%s' "$text" | jq -e '.verdict' >/dev/null 2>&1; then
    blob="$text"
  else
    blob=$(printf '%s' "$text" | tr '\n' ' ' | grep -o '{"verdict".*}' | tail -1 || true)
    printf '%s' "$blob" | jq -e '.verdict' >/dev/null 2>&1 || \
      blob=$(printf '%s' "$text" | tr '\n' ' ' | grep -o '{[^{}]*"verdict"[^{}]*}' | tail -1 || true)
  fi
  verdict=$(printf '%s' "$blob" | jq -r '.verdict // "parse_error"' 2>/dev/null | head -n1)
  reasons=$(printf '%s' "$blob" | jq -c '.reasons // []' 2>/dev/null | head -n1)
  [[ "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]] || cost=0
  [ -n "$turns" ] || turns=0; [ -n "$verdict" ] || verdict=parse_error
  printf '%s' "$reasons" | jq -e . >/dev/null 2>&1 || reasons='[]'
  printf '%s\t%s\t%s\t%s' "$verdict" "$cost" "$turns" "$reasons"
}

record() {  # many args via env-ish positional; append one receipt
  local ts="$1" reviewer="$2" task="$3" sol="$4" truth="$5" trial="$6" verdict="$7" \
        cost="$8" turns="$9" checks="${10}" tampered="${11}" reasons="${12}" correct=false
  { [ "$verdict" = "reject" ] && [ "$truth" = "reject" ]; } && correct=true
  { [ "$verdict" = "approve" ] && [ "$truth" = "approve" ]; } && correct=true
  jq -cn --arg ts "$ts" --arg reviewer "$reviewer" --arg task "$task" --arg sol "$sol" \
     --arg truth "$truth" --argjson trial "$trial" --arg verdict "$verdict" \
     --argjson correct "$correct" --argjson cost "$cost" --argjson turns "$turns" \
     --argjson checks "$checks" --argjson tampered "$tampered" --argjson reasons "$reasons" \
     '{experiment:"verified-review", ts:$ts, reviewer:$reviewer, task:$task, solution:$sol,
       truth:$truth, trial:$trial, verdict:$verdict, correct:$correct, verified_runs:$checks,
       tampered:$tampered, cost:$cost, turns:$turns, reasons:$reasons}' >> "$OUT" \
    || echo "  !! record write failed: $reviewer $task $sol t$trial" >&2
}

# --- arms --------------------------------------------------------------------
IFS=',' read -ra RVW <<< "$REVIEWERS"

if [ "$ARM" = "e-06" ]; then
  prep_template_e06
  SOLBASE="$HERE/../gen-vs-recognition/solutions/e-06-unicode-length"
  for reviewer in "${RVW[@]}"; do
    for solkind in reference flawed; do
      truth="approve"; [ "$solkind" = "flawed" ] && truth="reject"
      for trial in $(seq 1 "$TRIALS"); do
        jq -e --arg r "$reviewer" --arg sol "$solkind" --argjson tr "$trial" \
           'select(.task=="e-06" and .reviewer==$r and .solution==$sol and .trial==$tr)' \
           "$OUT" 2>/dev/null | grep -q . && continue  # resume: cell already recorded
        s=$(spent); jq -n --argjson s "$s" --argjson m "$MAX_COST" '$s >= $m' | grep -q true \
          && { echo "BUDGET CAP (\$$s) — stopping." >&2; exit 2; }
        ws=$(build_ws_e06 "$SOLBASE/$solkind" "${reviewer//[^a-zA-Z0-9.-]/_}-t$trial")
        before=$(manifest "$ws" src/TextStats.elm tests/TextStatsTest.elm elm.json check.sh)
        prompt=$(build_prompt_e06 "$ws")
        ts="$(date -u +%Y%m%dT%H%M%SZ)"
        IFS=$'\t' read -r verdict cost turns reasons < <(run_review "$reviewer" "$ws" "$prompt" 420)
        if jq -e '.is_error == true' "$ws/transcript.json" >/dev/null 2>&1 \
           || grep -qiE "hit your session limit|reached your [a-z0-9. ]*limit" "$ws/transcript.json"; then
          echo "  !! $reviewer e-06/$solkind t$trial: usage-limit hit — VOID, not recorded" >&2; continue
        fi
        after=$(manifest "$ws" src/TextStats.elm tests/TextStatsTest.elm elm.json check.sh)
        tampered=false; [ "$before" = "$after" ] || tampered=true
        checks=$( [ -f "$ws/.check-invocations" ] && wc -l < "$ws/.check-invocations" || echo 0 )
        record "$ts" "$reviewer" "e-06" "$solkind" "$truth" "$trial" "$verdict" \
               "$cost" "$turns" "$checks" "$tampered" "$reasons"
        echo "  $reviewer | e-06/$solkind t$trial -> $verdict (checked ${checks}x, tampered=$tampered)"
      done
    done
  done
else
  export D7_SITE="$ROOT/.ddev-cores/d7site"
  for reviewer in "${RVW[@]}"; do
    truth="reject"
    for trial in $(seq 1 "$TRIALS"); do
      jq -e --arg r "$reviewer" --argjson tr "$trial" \
         'select(.task=="d7-01" and .reviewer==$r and .trial==$tr)' \
         "$OUT" 2>/dev/null | grep -q . && continue  # resume: cell already recorded
      s=$(spent); jq -n --argjson s "$s" --argjson m "$MAX_COST" '$s >= $m' | grep -q true \
        && { echo "BUDGET CAP (\$$s) — stopping." >&2; exit 2; }
      ws=$(build_ws_d701 "${reviewer//[^a-zA-Z0-9.-]/_}-t$trial")
      before=$(manifest "$ws" healthstats/healthstats.info healthstats/healthstats.module probe.sh)
      prompt=$(build_prompt_d701 "$ws")
      ts="$(date -u +%Y%m%dT%H%M%SZ)"
      IFS=$'\t' read -r verdict cost turns reasons < <(run_review "$reviewer" "$ws" "$prompt" 600)
      if jq -e '.is_error == true' "$ws/transcript.json" >/dev/null 2>&1 \
         || grep -qiE "hit your session limit|reached your [a-z0-9. ]*limit" "$ws/transcript.json"; then
        echo "  !! $reviewer d7-01 t$trial: usage-limit hit — VOID, not recorded" >&2; continue
      fi
      after=$(manifest "$ws" healthstats/healthstats.info healthstats/healthstats.module probe.sh)
      tampered=false; [ "$before" = "$after" ] || tampered=true
      probes=$( [ -f "$ws/.probe-invocations" ] && wc -l < "$ws/.probe-invocations" || echo 0 )
      record "$ts" "$reviewer" "d7-01" "echo" "$truth" "$trial" "$verdict" \
             "$cost" "$turns" "$probes" "$tampered" "$reasons"
      echo "  $reviewer | d7-01/echo t$trial -> $verdict (probed ${probes}x, tampered=$tampered)"
    done
  done
fi
echo "done. reviews: $OUT ($(wc -l < "$OUT") records)"
