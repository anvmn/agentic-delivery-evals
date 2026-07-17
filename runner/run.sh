#!/usr/bin/env bash
# run.sh — execute the task × model × trial matrix.
# Usage: runner/run.sh --models "claude-opus-4-8,claude-fable-5" [--trials 3]
#                      [--only e-01-decoder-roundtrip] [--max-cost-usd 15]
set -euo pipefail

SUITE_VERSION="0.3.0"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TASKS_DIR="$ROOT/tasks"
RESULTS="$ROOT/results"
RUNS="$RESULTS/runs.jsonl"
mkdir -p "$RESULTS/workspaces" "$RESULTS/transcripts"

MODELS="" TRIALS=3 ONLY="" MAX_COST="15"
while [ $# -gt 0 ]; do
  case "$1" in
    --models) MODELS="$2"; shift 2 ;;
    --trials) TRIALS="$2"; shift 2 ;;
    --only) ONLY="$2"; shift 2 ;;
    --max-cost-usd) MAX_COST="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done
[ -n "$MODELS" ] || { echo "--models is required" >&2; exit 1; }

spent() {
  [ -f "$RUNS" ] || { echo 0; return; }
  jq -s '[.[] | .agent.cost_usd // 0] | add // 0' "$RUNS"
}

IFS=',' read -ra MODEL_ARR <<< "$MODELS"
for task_dir in "$TASKS_DIR"/*/; do
  task_id="$(basename "$task_dir")"
  [ -n "$ONLY" ] && [ "$task_id" != "$ONLY" ] && continue
  meta="$task_dir/meta.json"
  [ -f "$meta" ] || { echo "skip $task_id (no meta.json)" >&2; continue; }
  lane=$(jq -r .lane "$meta"); tier=$(jq -r .tier "$meta")
  timeout_s=$(jq -r .timeout_s "$meta")

  for model in "${MODEL_ARR[@]}"; do
    for trial in $(seq 1 "$TRIALS"); do
      total_spent=$(spent)
      if jq -n --argjson s "$total_spent" --argjson m "$MAX_COST" '$s >= $m' | grep -q true; then
        echo "BUDGET CAP reached (\$$total_spent >= \$$MAX_COST) — stopping." >&2
        exit 2
      fi

      ts="$(date -u +%Y%m%dT%H%M%SZ)"
      ws="$RESULTS/workspaces/${task_id}--${model//[^a-zA-Z0-9.-]/_}--t${trial}--${ts}"
      mkdir -p "$ws"
      cp -r "$task_dir/fixture/." "$ws/"
      cp "$task_dir/task.md" "$ws/task.md"

      echo ">>> $task_id | $model | trial $trial"
      # Adapter routing by model-string prefix: "gemini:<model>" -> gemini
      # CLI; anything else -> Claude Code. Graders never see the difference.
      adapter="$ROOT/runner/agents/claude-code.sh"; agent_model="$model"
      case "$model" in
        gemini:*) adapter="$ROOT/runner/agents/gemini.sh"; agent_model="${model#gemini:}" ;;
      esac
      agent_json=$("$adapter" "$ws" "$agent_model" "$timeout_s" \
                   "$RESULTS/transcripts/$(basename "$ws").json" || true)
      [ -n "$agent_json" ] || agent_json='{"error":"adapter produced no output"}'

      if grep -qiE "hit your session limit|usage limit" \
           "$RESULTS/transcripts/$(basename "$ws").json" 2>/dev/null; then
        echo "SESSION LIMIT hit — aborting matrix; voiding this cell." >&2
        rm -rf "$ws"
        exit 3
      fi
      if jq -e '.agent_exit == 99' <<<"$agent_json" >/dev/null 2>&1; then
        echo "PROVIDER QUOTA exhausted (adapter exit 99) — aborting matrix; voiding this cell." >&2
        rm -rf "$ws"
        exit 3
      fi

      grade_json="{}"; pass=false
      if "$task_dir/grader/grade.sh" "$ws" > "$ws/grade-stdout.log" 2>&1; then
        pass=true
      fi
      [ -f "$ws/grade.json" ] && grade_json=$(cat "$ws/grade.json")

      jq -cn \
        --arg suite "$SUITE_VERSION" --arg ts "$ts" --arg task "$task_id" \
        --arg lane "$lane" --argjson tier "$tier" --arg model "$model" \
        --argjson trial "$trial" --argjson pass "$pass" \
        --argjson grade "$grade_json" --argjson agent "$agent_json" \
        --arg workspace "$ws" \
        '{suite:$suite, ts:$ts, task:$task, lane:$lane, tier:$tier,
          model:$model, trial:$trial, pass:$pass, grade:$grade,
          agent:$agent, workspace:$workspace}' >> "$RUNS"
      echo "    -> pass=$pass (total spent: \$$(spent))"
    done
  done
done
echo "done. results: $RUNS"
