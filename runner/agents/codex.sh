#!/usr/bin/env bash
# codex.sh — adapter: run headless OpenAI Codex CLI on a workspace.
# Args: <workspace> <model> <timeout_s> <transcript_out>
# Stdout: one JSON object {cost_usd, duration_s, turns, agent_exit, timed_out, effort}
#
# Notes:
# - --dangerously-bypass-approvals-and-sandbox is deliberate: the workspace is
#   a throwaway sandbox copy and tasks need network/ddev. NEVER point this
#   adapter at a directory you care about.
# - Flags pinned against codex-cli 0.144.5 (2026-07); revalidate on upgrade.
# - Cost is metered from token counts in the JSONL event stream against a
#   pinned price table (the CLI reports usage, not dollars). Prices per 1M
#   tokens, 2026-07: sol 5/30, terra 2.5/15, luna 1/6; cache reads 10% of
#   input. Re-pin on price changes.
# - Exit 99 = provider-side refusal (quota/billing/auth): the run must be
#   voided by the runner, not recorded as a model fail.
set -uo pipefail

WS="$1"; MODEL="$2"; TIMEOUT_S="$3"; TRANSCRIPT="$4"

# Non-interactive shells skip ~/.bashrc; pull only the key export from it.
if [ -z "${OPENAI_API_KEY:-}" ] && [ -f "$HOME/.bashrc" ]; then
  eval "$(grep -E '^export OPENAI_API_KEY=' "$HOME/.bashrc" | tail -1)" || true
fi
export OPENAI_API_KEY="${OPENAI_API_KEY:-}"

start=$(date +%s)
(cd "$WS" && timeout "${TIMEOUT_S}s" \
  codex exec \
    -m "$MODEL" \
    --json \
    --ephemeral \
    --skip-git-repo-check \
    --dangerously-bypass-approvals-and-sandbox \
    -C "$WS" \
    --output-last-message "$WS/agent-last-message.txt" \
    "$(cat task.md)

Work only inside the current directory. Implement the task per the acceptance criteria. When done, ensure the project builds/tests cleanly with the commands named in the task." \
  > "$TRANSCRIPT" 2>"$WS/agent-stderr.log")
agent_exit=$?
end=$(date +%s)
timed_out=false; [ "$agent_exit" -eq 124 ] && timed_out=true

# Provider-side refusal guard: quota, billing, or auth trouble must abort the
# matrix (exit 99), never be recorded as a model fail. Patterns are checked in
# stderr and the final message only — not the full transcript, where task
# content could false-positive.
refusal='insufficient_quota|exceeded your current quota|account is not active|invalid_api_key|401 Unauthorized|not logged in|codex login|Missing OPENAI_API_KEY|deactivated|suspended'
# cat-pipe, not multi-file grep: grep exits 2 (no match reported) if any
# listed file is missing — and the last-message file is exactly what's
# missing when the CLI dies early.
if cat "$WS/agent-stderr.log" "$WS/agent-last-message.txt" 2>/dev/null \
   | grep -qiE "$refusal"; then
  jq -cn --argjson dur "$((end - start))" \
    '{cost_usd:0, duration_s:$dur, turns:0, agent_exit:99, timed_out:false, effort:"default"}'
  exit 99
fi

# Token usage: sum across all JSONL events, tolerating either a top-level
# .usage or one nested under .msg/.payload (schema differs across versions).
usage=$(jq -s '
  [ .[] | (.usage? // .msg?.usage? // .payload?.usage?) | select(. != null) ] |
  { in:  ([.[] | .input_tokens        // 0] | add // 0),
    cin: ([.[] | .cached_input_tokens // 0] | add // 0),
    out: ([.[] | .output_tokens       // 0] | add // 0) }' \
  "$TRANSCRIPT" 2>/dev/null || echo '{"in":0,"cin":0,"out":0}')

case "$MODEL" in
  gpt-5.6-sol)          p_in=5.00; p_out=30.00 ;;
  gpt-5.6-terra)        p_in=2.50; p_out=15.00 ;;
  gpt-5.6-luna)         p_in=1.00; p_out=6.00 ;;
  gpt-5.2-codex|gpt-5.3-codex) p_in=1.75; p_out=14.00 ;;
  *) p_in=0; p_out=0; echo "WARN: no pinned price for $MODEL — cost recorded as 0" >&2 ;;
esac
cost=$(jq -n --argjson u "$usage" --argjson pi "$p_in" --argjson po "$p_out" '
  ((($u.in - $u.cin) * $pi) + ($u.cin * $pi * 0.1) + ($u.out * $po)) / 1000000
  | if . < 0 then 0 else . end')

turns=$(grep -c '"type":"turn.completed"' "$TRANSCRIPT" 2>/dev/null || echo 0)

jq -cn \
  --argjson cost "${cost:-0}" --argjson turns "${turns:-0}" \
  --argjson dur "$((end - start))" --argjson ec "$agent_exit" \
  --argjson to "$timed_out" \
  '{cost_usd:$cost, duration_s:$dur, turns:$turns, agent_exit:$ec, timed_out:$to, effort:"default"}'
