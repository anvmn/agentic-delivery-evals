#!/usr/bin/env bash
# Author × Reviewer experiment, phase 1: every model blindly reviews all 24
# d7-01 solutions (8 pass / 16 fail per grader ground truth). Reviewers see
# the task spec and the code — never the author, never the grader.
# Usage: review.sh [--max-cost-usd 20]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/reviews.jsonl"
REVIEWERS=(claude-fable-5 claude-opus-4-8 claude-sonnet-5 claude-haiku-4-5)
MAX_COST="${2:-35}"

TASKMD="$(cat "$ROOT/tasks/d7-01-menu-endpoint/task.md")"

spent() {
  [ -f "$OUT" ] || { echo 0; return; }
  jq -s '[.[] | .cost // 0] | add // 0' "$OUT"
}

jq -c 'select(.task == "d7-01-menu-endpoint") | {ws: .workspace, author: .model, truth: .pass}' \
  "$ROOT/results/runs.jsonl" > "$HERE/corpus.tmp"

total=$(wc -l < "$HERE/corpus.tmp")
echo "corpus: $total solutions"

while IFS= read -r sol; do
  ws=$(jq -r .ws <<<"$sol")
  author=$(jq -r .author <<<"$sol")
  truth=$(jq -r .truth <<<"$sol")
  sid=$(basename "$ws")
  code="$(cat "$ws/healthstats/healthstats.module")"

  for reviewer in "${REVIEWERS[@]}"; do
    if [ -f "$OUT" ] && jq -e --arg s "$sid" --arg r "$reviewer" \
         'select(.solution == $s and .reviewer == $r)' "$OUT" >/dev/null 2>&1; then
      continue  # resume support
    fi
    if jq -n --argjson s "$(spent)" --argjson m "$MAX_COST" '$s >= $m' | grep -q true; then
      echo "BUDGET CAP reached — stopping." >&2; exit 2
    fi

    prompt="You are a strict senior Drupal code reviewer. Review the submission below against its task specification. Judge ONLY whether the code fully satisfies every acceptance criterion; assume it will be deployed to production as-is.

=== TASK SPECIFICATION ===
$TASKMD

=== SUBMITTED CODE (healthstats/healthstats.module) ===
$code

=== INSTRUCTIONS ===
Do not use any tools. Respond with ONLY a JSON object, no other text:
{\"verdict\": \"approve\" or \"reject\", \"reasons\": [\"short reason\", ...]}
Reject if any acceptance criterion is violated, including edge-case behavior."

    start=$(date +%s)
    resp=$(timeout 300 claude -p "$prompt" --model "$reviewer" --output-format json 2>/dev/null || true)
    end=$(date +%s)
    text=$(jq -r '.result // ""' <<<"$resp" 2>/dev/null || echo "")
    cost=$(jq -r '.total_cost_usd // .cost_usd // 0' <<<"$resp" 2>/dev/null || echo 0)
    blob=$(printf '%s' "$text" | tr '\n' ' ' | grep -o '{.*}' | head -1 || true)
    verdict=$(jq -r '.verdict // "parse_error"' <<<"$blob" 2>/dev/null || echo parse_error)
    reasons=$(jq -c '.reasons // []' <<<"$blob" 2>/dev/null || echo '[]')

    correct=false
    if [ "$verdict" = "reject" ] && [ "$truth" = "false" ]; then
      correct=true
    elif [ "$verdict" = "approve" ] && [ "$truth" = "true" ]; then
      correct=true
    fi

    jq -cn --arg s "$sid" --arg author "$author" --argjson truth "$truth" \
      --arg reviewer "$reviewer" --arg verdict "$verdict" --argjson reasons "$reasons" \
      --argjson correct "$correct" --argjson cost "${cost:-0}" \
      --argjson dur "$((end - start))" \
      '{solution: $s, author: $author, truth_pass: $truth, reviewer: $reviewer,
        verdict: $verdict, reasons: $reasons, correct: $correct,
        cost: $cost, duration_s: $dur}' >> "$OUT"
    echo "$sid | $reviewer -> $verdict ($correct)"
  done
done < "$HERE/corpus.tmp"
rm -f "$HERE/corpus.tmp"
echo "done. $(wc -l < "$OUT") reviews recorded."
