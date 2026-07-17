#!/usr/bin/env bash
# fill.sh — run an explicit list of review cells (ws<TAB>reviewer per line).
# Used for the stratified fill of the author×reviewer experiment.
# Usage: fill.sh cells.txt [max_cost_usd]
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/reviews.jsonl"
CELLS="${1:-$HERE/cells.txt}"
MAX_COST="${2:-27}"
TASKMD="$(cat "$ROOT/tasks/d7-01-menu-endpoint/task.md")"

spent() { jq -s '[.[] | .cost // 0] | add // 0' "$OUT" 2>/dev/null || echo 0; }

while IFS=$'\t' read -r ws reviewer; do
  [ -n "$ws" ] || continue
  sid=$(basename "$ws")
  if jq -e --arg s "$sid" --arg r "$reviewer" \
       'select(.solution == $s and .reviewer == $r)' "$OUT" >/dev/null 2>&1; then
    continue
  fi
  s_now=$(spent); [ -n "$s_now" ] || s_now=0
  if jq -n --argjson s "$s_now" --argjson m "$MAX_COST" '$s >= $m' | grep -q true; then
    echo "BUDGET CAP reached — stopping." >&2; exit 2
  fi

  rec=$(jq -c --arg w "$ws" 'select(.workspace == $w)' "$ROOT/results/runs.jsonl" | head -1)
  author=$(jq -r '.model // "unknown"' <<<"$rec")
  truth=$(jq -r '.pass // false' <<<"$rec")
  code="$(cat "$ws/healthstats/healthstats.module")"

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

  dur=$((end - start))
  [ -n "$cost" ] || cost=0
  [ -n "$reasons" ] || reasons='[]'
  [ -n "$verdict" ] || verdict=parse_error
  if ! jq -cn --arg s "$sid" --arg author "$author" --argjson truth "$truth" \
    --arg reviewer "$reviewer" --arg verdict "$verdict" --argjson reasons "$reasons" \
    --argjson correct "$correct" --argjson cost "$cost" --argjson dur "$dur" \
    '{solution: $s, author: $author, truth_pass: $truth, reviewer: $reviewer,
      verdict: $verdict, reasons: $reasons, correct: $correct,
      cost: $cost, duration_s: $dur}' >> "$OUT" 2>>"$HERE/jq-fail.log"; then
    { echo "=== $(date -u '+%FT%TZ') cell: $sid / $reviewer"
      printf 'cost=[%s] truth=[%s] verdict=[%s] reasons=[%s]\n' "$cost" "$truth" "$verdict" "$reasons"
    } >> "$HERE/jq-fail.log"
    echo "RECORD-WRITE FAILED for $sid / $reviewer — dumped, continuing." >&2
  fi
  echo "$sid | $reviewer -> $verdict"
done < "$CELLS"
echo "fill done. total records: $(wc -l < "$OUT")"
