#!/usr/bin/env bash
# report.sh — regenerate RESULTS.md from results/runs.jsonl (receipts -> table).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUNS_ALL="$ROOT/results/runs.jsonl"
OUT="$ROOT/RESULTS.md"
[ -f "$RUNS_ALL" ] || { echo "no runs.jsonl yet" >&2; exit 1; }
# The scoreboard covers default-effort runs only; effort experiments are
# analyzed separately from the same receipts.
RUNS=$(mktemp)
jq -c 'select((.agent.effort // "default") == "default" and (.agent.clean_room // false) == false)' "$RUNS_ALL" > "$RUNS"
trap 'rm -f "$RUNS"' EXIT

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

  # ---- experiment arms, from the same receipts ledgers -----------------------
  echo
  echo "## Raised-effort and clean-room arms (excluded from the scoreboard above)"
  echo
  echo "| model | task | arm | passes/trials |"
  echo "| --- | --- | --- | --- |"
  jq -rs '
    map(select((.agent.effort // "default") != "default" or (.agent.clean_room // false))) |
    group_by([.model, .task, (.agent.effort // "default"), ((.agent.clean_room // false)|tostring)])[] |
    "| \(.[0].model) | \(.[0].task) | effort=\(.[0].agent.effort // "default")\(if (.[0].agent.clean_room // false) then " · clean-room" else "" end) | \(map(select(.pass)) | length)/\(length) |"
  ' "$RUNS_ALL"

  LIVE="$ROOT/experiments/live-site/runs.jsonl"
  if [ -f "$LIVE" ]; then
    echo
    echo "## Live-site arm (d7-01 on a running site, with a behavior probe)"
    echo
    echo "| model | passes/trials | mean probe invocations |"
    echo "| --- | --- | --- |"
    jq -rs '
      group_by(.model)[] |
      "| \(.[0].model) | \(map(select(.pass)) | length)/\(length) | \((map(.probe_invocations // 0) | add / length) * 10 | round / 10) |"
    ' "$LIVE"
  fi

  AR="$ROOT/experiments/author-reviewer/reviews.jsonl"
  if [ -f "$AR" ]; then
    echo
    echo "## Review panel — blind reviews of graded d7-01 solutions vs grader ground truth (parse-error reviews excluded)"
    echo
    echo "| reviewer | failing solutions caught | passing solutions approved |"
    echo "| --- | --- | --- |"
    jq -rs '
      map(select(.verdict != "parse_error")) |
      group_by(.reviewer)[] |
      ([ .[] | select(.truth_pass == false) ]) as $bad |
      ([ .[] | select(.truth_pass == true) ]) as $good |
      "| \(.[0].reviewer) | \($bad | map(select(.verdict == "reject")) | length)/\($bad | length) | \($good | map(select(.verdict == "approve")) | length)/\($good | length) |"
    ' "$AR"
  fi

  XR="$ROOT/experiments/cross-lab-review/reviews.jsonl"
  if [ -f "$XR" ]; then
    echo
    echo "## Cross-lab review panel (correct verdicts per cell; echo = the d7-01 echo solution under two spec wordings)"
    echo
    echo "| reviewer | e-06 reference | e-06 flawed | echo @pre-0.3.1 | echo @0.3.1 |"
    echo "| --- | --- | --- | --- | --- |"
    jq -rs '
      def cell($R; $t; $sol; $spec):
        ([ $R[] | select(.task == $t and .solution == $sol and (.spec_version == $spec or $spec == "any")) ]) |
        "\(map(select(.correct)) | length)/\(length)";
      group_by(.reviewer)[] | . as $R |
      "| \(.[0].reviewer) | \(cell($R; "e-06"; "reference"; "any")) | \(cell($R; "e-06"; "flawed"; "any")) | \(cell($R; "d7-01"; "echo"; "pre-0.3.1")) | \(cell($R; "d7-01"; "echo"; "0.3.1")) |"
    ' "$XR"
  fi
} > "$OUT"
echo "wrote $OUT"
