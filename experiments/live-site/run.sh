#!/usr/bin/env bash
# run.sh — the "can the agent test its way out?" experiment.
#
# Same d7-01 spec, but the agent gets a LIVE Drupal 7 site and a probe.sh that
# reports the endpoint's real behavior. Question: do models that fail d7-01
# blind (no site) catch and fix their own bug once they can observe it?
#
# Usage: experiments/live-site/run.sh "<model1,model2,...>" [trials] [max_cost]
# Writes receipts to experiments/live-site/runs.jsonl. Runs SERIALLY (the probe
# and grader share one D7 site). Clean-room agents (no operator CLAUDE.md).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
TASK="$ROOT/tasks/d7-01-menu-endpoint"
OUT="$HERE/runs.jsonl"
WSROOT="$HERE/workspaces"; mkdir -p "$WSROOT"

MODELS="${1:?models required, e.g. claude-sonnet-5,claude-fable-5}"
TRIALS="${2:-3}"; MAX_COST="${3:-30}"
export D7_SITE="$SITE"
timeout_s=$(jq -r .timeout_s "$TASK/meta.json")

spent() { jq -s '[.[] | .cost // 0] | add // 0' "$OUT" 2>/dev/null || echo 0; }

IFS=',' read -ra MODEL_ARR <<< "$MODELS"
for model in "${MODEL_ARR[@]}"; do
  for trial in $(seq 1 "$TRIALS"); do
    s_now=$(spent); [ -n "$s_now" ] || s_now=0
    if jq -n --argjson s "$s_now" --argjson m "$MAX_COST" '$s >= $m' | grep -q true; then
      echo "BUDGET CAP reached (\$$s_now) — stopping." >&2; exit 2
    fi
    ts="$(date -u +%Y%m%dT%H%M%SZ)"
    ws="$WSROOT/${model//[^a-zA-Z0-9.-]/_}--t${trial}--${ts}"
    mkdir -p "$ws"
    cp -r "$TASK/fixture/." "$ws/"           # healthstats/ skeleton + .info
    cp "$HERE/probe.sh" "$ws/probe.sh"; chmod +x "$ws/probe.sh"
    cp "$HERE/task-live.md" "$ws/task.md"

    echo ">>> live-site | $model | trial $trial"
    start=$(date +%s)
    out=$(cd "$ws" && timeout "${timeout_s}s" \
      claude -p "$(cat task.md)" \
        --model "$model" \
        --setting-sources "project,local" \
        --output-format json \
        --dangerously-skip-permissions 2>"$ws/agent-stderr.log" || true)
    dur=$(( $(date +%s) - start ))
    printf '%s' "$out" > "$ws/transcript.json"
    cost=$(printf '%s' "$out" | jq -r '.total_cost_usd // .cost_usd // 0' 2>/dev/null || echo 0)
    turns=$(printf '%s' "$out" | jq -r '.num_turns // 0' 2>/dev/null || echo 0)
    probes=$( [ -f "$ws/.probe-invocations" ] && wc -l < "$ws/.probe-invocations" || echo 0 )

    # Blind grade with the standard d7-01 grader (resets the site first).
    pass=false; grade='{}'
    if "$TASK/grader/grade.sh" "$ws" >"$ws/grade-stdout.log" 2>&1; then pass=true; fi
    [ -f "$ws/grade.json" ] && grade=$(cat "$ws/grade.json")

    jq -cn --arg model "$model" --argjson trial "$trial" --argjson pass "$pass" \
      --argjson probes "${probes:-0}" --argjson grade "$grade" \
      --argjson cost "${cost:-0}" --argjson turns "${turns:-0}" --argjson dur "$dur" \
      --arg ts "$ts" \
      '{experiment:"live-site", ts:$ts, model:$model, trial:$trial, pass:$pass,
        probe_invocations:$probes, grade:$grade, cost:$cost, turns:$turns, duration_s:$dur}' >> "$OUT"
    echo "    -> pass=$pass · probed ${probes}x · \$$cost"
  done
done
echo "done. receipts: $OUT"
