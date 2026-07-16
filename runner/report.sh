#!/usr/bin/env bash
# report.sh — regenerate RESULTS.md from results/runs.jsonl (receipts -> table).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUNS="$ROOT/results/runs.jsonl"
OUT="$ROOT/RESULTS.md"
[ -f "$RUNS" ] || { echo "no runs.jsonl yet" >&2; exit 1; }

{
  echo "# Results"
  echo
  suite=$(jq -r '.suite' "$RUNS" | tail -1)
  gen=$(date -u +%Y-%m-%d)
  total_cost=$(jq -s '[.[] | .agent.cost_usd // 0] | add | .*100 | round / 100' "$RUNS")
  n_runs=$(wc -l < "$RUNS")
  echo "Suite version **$suite** · generated $gen · $n_runs runs · total agent cost \$$total_cost"
  echo
  echo "> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal."
  echo
  echo "## Pass per task (passes/trials)"
  echo
  jq -rs '
    (map(.model) | unique) as $models |
    (map({task,lane,tier}) | unique | sort_by(.task)) as $tasks |
    (["task","lane","tier"] + $models) as $hdr |
    ( "| " + ($hdr | join(" | ")) + " |" ),
    ( "| " + ($hdr | map("---") | join(" | ")) + " |" ),
    ( $tasks[] as $t |
      . as $all |
      "| \($t.task) | \($t.lane) | \($t.tier) | " +
      ( [ $models[] as $m |
          ( [ $all[] | select(.task==$t.task and .model==$m) ] |
            "\(map(select(.pass)) | length)/\(length)" ) ] | join(" | ") ) + " |" )
  ' "$RUNS"
  echo
  echo "## Per model"
  echo
  jq -rs '
    (map(.model) | unique)[] as $m |
    ([ .[] | select(.model==$m) ]) as $R |
    ($R | map(.task) | unique | length) as $ntasks |
    ($R | group_by(.task) | map(any(.pass)) | map(select(.)) | length) as $passk |
    "**\($m)** — trials passed: \($R | map(select(.pass)) | length)/\($R | length)" +
    " · pass@k (any trial per task): \($passk)/\($ntasks)" +
    " · mean duration \(($R | map(.agent.duration_s // 0) | add / length) | round)s"
  ' "$RUNS"
} > "$OUT"
echo "wrote $OUT"
