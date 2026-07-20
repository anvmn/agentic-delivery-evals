#!/usr/bin/env bash
# claude-code.sh — adapter: run headless Claude Code on a workspace.
# Args: <workspace> <model> <timeout_s> <transcript_out>
# Stdout: one JSON object {cost_usd, duration_s, turns, agent_exit, timed_out}
#
# Notes:
# - --dangerously-skip-permissions is deliberate: the workspace is a throwaway
#   sandbox copy; the agent must be able to edit/run without prompts.
#   NEVER point this adapter at a directory you care about.
# - Flags pinned against Claude Code CLI as of 2026-07; revalidate on upgrade.
set -uo pipefail

WS="$1"; MODEL="$2"; TIMEOUT_S="$3"; TRANSCRIPT="$4"

EFFORT_FLAG=()
[ -n "${CLAUDE_EFFORT:-}" ] && EFFORT_FLAG=(--effort "$CLAUDE_EFFORT")

# Clean-room: exclude the "user" setting source so the agent does NOT inherit
# the operator's global ~/.claude/CLAUDE.md or auto-memory. Auth still applies.
# (Headless runs never load auto-memory, but they DO load user CLAUDE.md; this
# makes runs reproducible across machines/operators.)
CLEAN_FLAG=()
[ -n "${CLAUDE_CLEAN_ROOM:-}" ] && CLEAN_FLAG=(--setting-sources "project,local")

start=$(date +%s)
out=$(cd "$WS" && timeout "${TIMEOUT_S}s" \
  claude -p "$(cat task.md)

Work only inside the current directory. Implement the task per the acceptance criteria. When done, ensure the project builds/tests cleanly with the commands named in the task." \
  --model "$MODEL" \
  "${EFFORT_FLAG[@]}" \
  "${CLEAN_FLAG[@]}" \
  --output-format json \
  --dangerously-skip-permissions 2>"$WS/agent-stderr.log")
agent_exit=$?
end=$(date +%s)

timed_out=false; [ $agent_exit -eq 124 ] && timed_out=true
printf '%s' "$out" > "$TRANSCRIPT" 2>/dev/null || true

cost=$(printf '%s' "$out" | jq -r '.total_cost_usd // .cost_usd // 0' 2>/dev/null || echo 0)
turns=$(printf '%s' "$out" | jq -r '.num_turns // 0' 2>/dev/null || echo 0)

jq -cn \
  --argjson cost "${cost:-0}" --argjson turns "${turns:-0}" \
  --argjson dur "$((end - start))" --argjson ec "$agent_exit" \
  --argjson to "$timed_out" --arg eff "${CLAUDE_EFFORT:-default}" \
  --arg clean "${CLAUDE_CLEAN_ROOM:+true}" \
  '{cost_usd:$cost, duration_s:$dur, turns:$turns, agent_exit:$ec, timed_out:$to,
    effort:$eff, clean_room:($clean == "true")}'
