#!/usr/bin/env bash
# run.sh — the "can the agent test its way out?" experiment.
#
# Same d7-01 spec, but the agent gets a LIVE Drupal 7 site and a probe.sh that
# reports the endpoint's real behavior. Question: do models that fail d7-01
# blind catch and fix their own bug once they can observe it?
#
# Routes each model through the SAME adapters as the main runner
# (claude-code.sh / codex.sh), so it is multi-lab and inherits their cost
# metering + refusal guards. Claude agents run clean-room. Runs SERIALLY (the
# probe and grader share one D7 site).
#
# Usage: experiments/live-site/run.sh "<model1,model2,...>" [trials] [max_cost]
#   models: claude-*  or  openai:<codex-model>
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
TASK="$ROOT/tasks/d7-01-menu-endpoint"
OUT="$HERE/runs.jsonl"
WSROOT="$HERE/workspaces"; mkdir -p "$WSROOT"

MODELS="${1:?models required, e.g. claude-haiku-4-5,openai:gpt-5.6-sol}"
TRIALS="${2:-3}"; MAX_COST="${3:-30}"
export D7_SITE="$SITE"
timeout_s=$(jq -r .timeout_s "$TASK/meta.json")

spent() { jq -s '[.[] | .cost // 0] | add // 0' "$OUT" 2>/dev/null || echo 0; }

IFS=',' read -ra MODEL_ARR <<< "$MODELS"
for model in "${MODEL_ARR[@]}"; do
  adapter="$ROOT/runner/agents/claude-code.sh"; agent_model="$model"
  case "$model" in
    openai:*) adapter="$ROOT/runner/agents/codex.sh"; agent_model="${model#openai:}" ;;
  esac

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
    # Clean-room only applies to the Claude adapter; the codex adapter ignores it.
    agent_json=$(CLAUDE_CLEAN_ROOM=1 "$adapter" "$ws" "$agent_model" "$timeout_s" "$ws/transcript.json" || true)
    [ -n "$agent_json" ] || agent_json='{"error":"adapter produced no output"}'

    # Void infra failures (usage limits, provider quota, adapter errors) — never
    # record them as model failures.
    if grep -qiE "reached your [a-z0-9. ]*limit|\"api_error_status\": ?(429|401|403)" \
         "$ws/transcript.json" 2>/dev/null \
       || jq -e '(.agent_exit == 99) or (.error != null)' <<<"$agent_json" >/dev/null 2>&1; then
      echo "    !! infra failure (limit/quota/adapter) — voiding this trial" >&2
      rm -rf "$ws"; continue
    fi

    cost=$(jq -r '.cost_usd // 0' <<<"$agent_json" 2>/dev/null || echo 0)
    turns=$(jq -r '.turns // 0' <<<"$agent_json" 2>/dev/null || echo 0)
    probes=$( [ -f "$ws/.probe-invocations" ] && wc -l < "$ws/.probe-invocations" || echo 0 )

    pass=false; grade='{}'
    if "$TASK/grader/grade.sh" "$ws" >"$ws/grade-stdout.log" 2>&1; then pass=true; fi
    [ -f "$ws/grade.json" ] && grade=$(cat "$ws/grade.json")

    # Empty-guard every argjson input (the fill.sh footgun).
    printf '%s' "$grade" | jq -e . >/dev/null 2>&1 || grade='{}'
    [ -n "$cost" ] || cost=0; [ -n "$turns" ] || turns=0; [ -n "$probes" ] || probes=0

    if ! jq -cn --arg model "$model" --argjson trial "$trial" --argjson pass "$pass" \
        --argjson probes "$probes" --argjson grade "$grade" \
        --argjson cost "$cost" --argjson turns "$turns" --arg ts "$ts" \
        '{experiment:"live-site", ts:$ts, model:$model, trial:$trial, pass:$pass,
          probe_invocations:$probes, grade:$grade, cost:$cost, turns:$turns}' >> "$OUT"; then
      echo "    !! receipt write failed for $model t$trial — skipping record" >&2
    fi
    echo "    -> pass=$pass · probed ${probes}x · \$$cost"
  done
done
echo "done. receipts: $OUT"
