#!/usr/bin/env bash
# run.sh — generation-vs-recognition experiment (blind review edition).
#
# The reviewer models AUTHOR these tasks correctly (matrix pass-rates are high).
# Question: do they still MISS the task's silent idiom bug when reviewing it?
# For each (reviewer, task, {reference | flawed}, trial): blind-review the
# submission, approve/reject, scored vs ground truth (reference => approve,
# flawed => reject). Compare flaw-catch rate (recognition) to authoring rate.
#
# v2: reviews COMMENT-NEUTRALIZED submissions from solutions/ — the grader's
# own assets leaked provenance ("reference solution" / "FLAWED variant: the
# trap"), which the first run judged instead of the code. Reference & flawed
# now share an identical neutral header; only the code differs.
#
# Panel excludes Fable (usage-limited) and Gemini (suspended).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
cd "$ROOT" || exit 1
OUT="$HERE/reviews.jsonl"
SOL="$HERE/solutions"
TRIALS="${1:-3}"; MAX_COST="${2:-30}"
REVIEWERS="${3:-claude-opus-4-8,claude-sonnet-5,claude-haiku-4-5,openai:gpt-5.6-sol}"

# task<TAB>domain<TAB>kind<TAB>task.md
TASKS=$(cat <<TSV
d10-05	Drupal 10	treatment	tasks/d10-05-query-access-leak/task.md
e-06	Elm	treatment	tasks/e-06-unicode-length/task.md
d7-06	Drupal 7	treatment	tasks/d7-06-node-access-grants/task.md
d7-07	Drupal 7	control	tasks/d7-07-batched-update/task.md
TSV
)
# map short task id -> solutions subdir
declare -A DIRMAP=( [d10-05]=d10-05-query-access-leak [e-06]=e-06-unicode-length
                    [d7-06]=d7-06-node-access-grants [d7-07]=d7-07-batched-update )

spent() { local v; v=$(jq -s '[.[] | .cost // 0] | add // 0' "$OUT" 2>/dev/null); [[ "$v" =~ ^[0-9] ]] && printf '%s' "$v" || echo 0; }

build_prompt() {  # $1=domain $2=task.md $3=solution-dir
  local body="" f
  while IFS= read -r f; do
    body+=$'\n\n--- FILE: '"$(basename "$f")"$' ---\n'"$(cat "$f")"
  done < <(find "$3" -type f | sort)
  printf 'You are a strict senior %s code reviewer. Review the submission below against its task specification. Judge ONLY whether the code fully satisfies every acceptance criterion; assume it will be deployed to production as-is.\n\n=== TASK SPECIFICATION ===\n%s\n\n=== SUBMITTED CODE ===%s\n\n=== INSTRUCTIONS ===\nDo not use any tools. Respond with ONLY a JSON object, no other text:\n{"verdict": "approve" or "reject", "reasons": ["short reason", ...]}\nReject if any acceptance criterion is violated, including edge-case behavior.' \
    "$1" "$(cat "$2")" "$body"
}

run_review() {  # $1=reviewer $2=prompt -> "<verdict>\t<cost>\t<reasons-json>"
  local model="$1" prompt="$2" resp text cost blob verdict reasons
  if [[ "$model" == openai:* ]]; then
    local m="${model#openai:}" tok
    resp=$(timeout 240 codex exec -m "$m" --json --skip-git-repo-check \
             --sandbox read-only -C /tmp "$prompt" </dev/null 2>/dev/null || true)
    text=$(printf '%s' "$resp" | jq -rs 'map(select(.type=="item.completed") | .item.text // empty) | last // ""' 2>/dev/null || echo "")
    tok=$(printf '%s' "$resp" | jq -s '[.[]|.usage?//.msg?.usage?//empty]|{i:([.[].input_tokens//0]|add),o:([.[]|(.output_tokens//0)+(.reasoning_output_tokens//0)]|add)}' 2>/dev/null || echo '{"i":0,"o":0}')
    cost=$(jq -n --argjson t "$tok" '($t.i*5 + $t.o*30)/1000000' 2>/dev/null || echo 0)  # gpt-5.6-sol $5/$30 per M
  else
    resp=$(timeout 240 claude -p "$prompt" --model "$model" --setting-sources "project,local" --output-format json </dev/null 2>/dev/null || true)
    text=$(jq -r '.result // ""' <<<"$resp" 2>/dev/null || echo "")
    cost=$(jq -r '.total_cost_usd // .cost_usd // 0' <<<"$resp" 2>/dev/null || echo 0)
  fi
  blob=$(printf '%s' "$text" | tr '\n' ' ' | grep -o '{.*}' | head -1 || true)
  verdict=$(jq -r '.verdict // "parse_error"' <<<"$blob" 2>/dev/null || echo parse_error)
  reasons=$(jq -c '.reasons // []' <<<"$blob" 2>/dev/null || echo '[]')
  [ -n "$cost" ] || cost=0; [ -n "$reasons" ] || reasons='[]'; [ -n "$verdict" ] || verdict=parse_error
  printf '%s\t%s\t%s' "$verdict" "$cost" "$reasons"
}

IFS=',' read -ra RVW <<< "$REVIEWERS"
mapfile -t TASK_LINES <<< "$TASKS"
for line in "${TASK_LINES[@]}"; do
  IFS=$'\t' read -r task domain kind md <<< "$line"
  [ -n "$task" ] || continue
  base="$SOL/${DIRMAP[$task]}"
  for reviewer in "${RVW[@]}"; do
    for solkind in reference flawed; do
      dir="$base/$solkind"; truth="approve"; [ "$solkind" = "flawed" ] && truth="reject"
      [ -d "$dir" ] || { echo "MISSING $dir" >&2; continue; }
      for trial in $(seq 1 "$TRIALS"); do
        s=$(spent); [ -n "$s" ] || s=0
        if jq -n --argjson s "$s" --argjson m "$MAX_COST" '$s >= $m' | grep -q true; then
          echo "BUDGET CAP (\$$s) — stopping." >&2; exit 2
        fi
        prompt="$(build_prompt "$domain" "$md" "$dir")"
        IFS=$'\t' read -r verdict cost reasons < <(run_review "$reviewer" "$prompt")
        printf '%s' "$reasons" | jq -e . >/dev/null 2>&1 || reasons='[]'
        [[ "$cost" =~ ^[0-9]+(\.[0-9]+)?$ ]] || cost=0
        [ -n "$verdict" ] || verdict=parse_error
        correct=false
        { [ "$verdict" = "reject" ] && [ "$truth" = "reject" ]; } && correct=true
        { [ "$verdict" = "approve" ] && [ "$truth" = "approve" ]; } && correct=true
        ts="$(date -u +%Y%m%dT%H%M%SZ)"
        if ! jq -cn --arg ts "$ts" --arg reviewer "$reviewer" --arg task "$task" \
             --arg domain "$domain" --arg kind "$kind" --arg sol "$solkind" \
             --arg truth "$truth" --argjson trial "$trial" --arg verdict "$verdict" \
             --argjson correct "$correct" --argjson cost "${cost:-0}" --argjson reasons "$reasons" \
             '{experiment:"gen-vs-recognition", ts:$ts, reviewer:$reviewer, task:$task,
               domain:$domain, kind:$kind, solution:$sol, truth:$truth, trial:$trial,
               verdict:$verdict, correct:$correct, cost:$cost, reasons:$reasons}' >> "$OUT"; then
          echo "  !! record write failed: $reviewer $task $solkind t$trial" >&2
        fi
        echo "  $reviewer | $task/$solkind t$trial -> $verdict $([ "$correct" = true ] && echo OK || echo MISS)"
      done
    done
  done
done
echo "done. reviews: $OUT ($(wc -l < "$OUT") records)"
