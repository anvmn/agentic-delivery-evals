#!/usr/bin/env bash
# gemini.sh — adapter: run headless Gemini CLI on a workspace.
# Args: <workspace> <model> <timeout_s> <transcript_out>
#   <model> "default" uses the CLI's default model; anything else -> -m <model>.
# Stdout: one JSON object {cost_usd, duration_s, turns, agent_exit, timed_out, model_used}
#
# Notes:
# - --yolo auto-approves tool calls: the workspace is a throwaway sandbox copy.
#   NEVER point this adapter at a directory you care about.
# - cost_usd is estimated from the CLI's token stats and a pinned price table
#   (see below) so the runner's --max-cost-usd cap applies to paid Gemini keys.
# - Flags pinned against gemini-cli 0.51.x; revalidate on upgrade.
set -uo pipefail
# The user's ~/.bashrc guards against non-interactive sourcing; pull just the key.
eval "$(grep '^export GEMINI_API_KEY=' ~/.bashrc 2>/dev/null)" || true

WS="$1"; MODEL="$2"; TIMEOUT_S="$3"; TRANSCRIPT="$4"

MFLAG=()
[ "$MODEL" != "default" ] && MFLAG=(-m "$MODEL")

start=$(date +%s)
out=$(cd "$WS" && timeout "${TIMEOUT_S}s" \
  gemini -p "$(cat task.md)

Work only inside the current directory. Implement the task per the acceptance criteria. When done, ensure the project builds/tests cleanly with the commands named in the task." \
  "${MFLAG[@]}" \
  --yolo \
  --output-format json 2>"$WS/agent-stderr.log")
agent_exit=$?
end=$(date +%s)

timed_out=false; [ $agent_exit -eq 124 ] && timed_out=true
# gemini-cli 0.51 writes its JSON (including terminal errors) to stderr when
# stdout is empty; prefer stdout, fall back to captured stderr.
[ -z "$out" ] && out="$(cat "$WS/agent-stderr.log" 2>/dev/null || true)"
printf '%s' "$out" > "$TRANSCRIPT" 2>/dev/null || true

if printf '%s' "$out" | grep -qi "exhausted your daily quota"; then
  echo "GEMINI QUOTA exhausted — void this cell and stop the matrix." >&2
  jq -cn '{cost_usd:0, duration_s:0, turns:0, agent_exit:99, timed_out:false, model_used:"quota-exhausted"}'
  exit 99
fi

turns=$(printf '%s' "$out" | jq '[.stats.models // {} | to_entries[] | .value.api.totalRequests // 0] | add // 0' 2>/dev/null || echo 0)
model_used=$(printf '%s' "$out" | jq -r '.stats.models // {} | keys | first // "gemini-cli-default"' 2>/dev/null || echo "gemini-cli-default")
# Estimated dollars from token stats (per-1M prices, 2026-07; cache reads at 10%;
# thinking tokens bill as output). Keeps the runner budget cap real for Gemini.
cost=$(printf '%s' "$out" | jq '[.stats.models // {} | to_entries[] |
  (.value.tokens // {}) as $t |
  (if (.key | startswith("gemini-3.1-pro")) then {i: 2.0, o: 12.0}
   elif (.key | startswith("gemini-3.5-flash")) then {i: 1.5, o: 9.0}
   elif (.key | startswith("gemini-3-flash")) then {i: 0.5, o: 3.0}
   else {i: 2.0, o: 12.0} end) as $p |
  ((($t.prompt // 0) - ($t.cached // 0)) * $p.i
   + ($t.cached // 0) * $p.i * 0.1
   + ((($t.candidates // 0) + ($t.thoughts // 0)) * $p.o)) / 1000000
] | add // 0 | .*10000 | round / 10000' 2>/dev/null || echo 0)

jq -cn \
  --argjson cost "${cost:-0}" --argjson turns "${turns:-0}" \
  --argjson dur "$((end - start))" --argjson ec "$agent_exit" \
  --argjson to "$timed_out" --arg mu "${model_used:-unknown}" \
  '{cost_usd:$cost, duration_s:$dur, turns:$turns, agent_exit:$ec, timed_out:$to, model_used:$mu}'
