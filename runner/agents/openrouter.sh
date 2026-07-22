#!/usr/bin/env bash
# openrouter.sh — adapter: run headless codex CLI against OpenRouter models
# (open-weights + xAI cross-lab column). Args: <workspace> <model> <timeout_s> <transcript_out>
# Stdout: one JSON object {cost_usd, duration_s, turns, agent_exit, timed_out, effort, provider}
#
# Notes:
# - Reuses the codex CLI as the agent harness (-c model_provider=openrouter,
#   defined in ~/.codex/config.toml with wire_api="chat") so the OpenAI-lane
#   tooling stays constant and only the model varies. Model arg is the full
#   OpenRouter id, e.g. x-ai/grok-4.5.
# - Cost is metered from transcript token counts x the model's live catalog
#   price (OpenRouter /api/v1/models). The server-side spend counter
#   (/api/v1/key) lags ~2 min, so per-run deltas under-report; use /credits
#   at end of matrix to reconcile receipts against real dollars. Cached input
#   is charged at the catalog's input_cache_read rate (agent loops resend the
#   conversation each turn — ~90% of input is cache reads, so this is the
#   difference between the meter and reality; caught by UI reconciliation
#   2026-07-21). Known gap: Grok's >200k-prompt price override isn't modeled.
# - CODEX_EFFORT (e.g. "high") flows through codex's model_reasoning_effort
#   into the Responses payload; grok-4.5/kimi/deepseek accept it (catalog
#   supported_parameters), qwen3-coder-next does not — leave unset for it.
# - Exit 99 = provider-side refusal (quota/billing/auth): the run must be
#   voided by the runner, not recorded as a model fail.
# - Flags pinned against codex-cli 0.144.5 (2026-07); revalidate on upgrade.
set -uo pipefail

WS="$1"; MODEL="$2"; TIMEOUT_S="$3"; TRANSCRIPT="$4"

# Non-interactive shells skip ~/.bashrc; pull only the key export from it.
if [ -z "${OPENROUTER_API_KEY:-}" ] && [ -f "$HOME/.bashrc" ]; then
  eval "$(grep -E '^export OPENROUTER_API_KEY=' "$HOME/.bashrc" | tail -1)" || true
fi
export OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}"

EFFORT_FLAG=()
[ -n "${CODEX_EFFORT:-}" ] && EFFORT_FLAG=(-c "model_reasoning_effort=${CODEX_EFFORT}")

start=$(date +%s)

(cd "$WS" && timeout "${TIMEOUT_S}s" \
  codex exec \
    -c model_provider=openrouter \
    "${EFFORT_FLAG[@]}" \
    -m "$MODEL" \
    --json \
    --ephemeral \
    --skip-git-repo-check \
    --dangerously-bypass-approvals-and-sandbox \
    -C "$WS" \
    --output-last-message "$WS/agent-last-message.txt" \
    "$(cat task.md)

Work only inside the current directory. Implement the task per the acceptance criteria. When done, ensure the project builds/tests cleanly with the commands named in the task." \
  </dev/null > "$TRANSCRIPT" 2>"$WS/agent-stderr.log")
agent_exit=$?
end=$(date +%s)
timed_out=false; [ "$agent_exit" -eq 124 ] && timed_out=true

# Provider-side refusal guard: quota, billing, or auth trouble must abort the
# matrix (exit 99), never be recorded as a model fail. Checked in stderr and
# the final message only — not the full transcript, where task content could
# false-positive.
refusal='insufficient credits|402|payment required|invalid_api_key|401 Unauthorized|User not found|Missing OPENROUTER_API_KEY|key limit exceeded|account.*(deactivated|suspended)|exceeded retry limit, last status: 429'
err_events=$(jq -r 'select(.type=="error") | .message // empty' "$TRANSCRIPT" 2>/dev/null || true)
if { cat "$WS/agent-stderr.log" "$WS/agent-last-message.txt" 2>/dev/null; printf '%s' "$err_events"; } \
   | grep -qiE "$refusal"; then
  jq -cn --argjson dur "$((end - start))" \
    --arg eff "${CODEX_EFFORT:-default}" \
    '{cost_usd:0, duration_s:$dur, turns:0, agent_exit:99, timed_out:false, effort:$eff}'
  exit 99
fi

# Token usage: sum across all JSONL events, tolerating either a top-level
# .usage or one nested under .msg/.payload (schema differs across versions).
usage=$(jq -s '
  [ .[] | (.usage? // .msg?.usage? // .payload?.usage?) | select(. != null) ] |
  { in:  ([.[] | .input_tokens        // 0] | add // 0),
    cin: ([.[] | .cached_input_tokens  // 0] | add // 0),
    out: ([.[] | (.output_tokens // 0) + (.reasoning_output_tokens // 0)] | add // 0) }' \
  "$TRANSCRIPT" 2>/dev/null || echo '{"in":0,"cin":0,"out":0}')
printf '%s' "$usage" | jq -e . >/dev/null 2>&1 || usage='{"in":0,"cin":0,"out":0}'

# Live catalog prices for this model ($/token strings).
prices=$(curl -s --max-time 30 https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" 2>/dev/null \
  | jq --arg m "$MODEL" '.data[] | select(.id==$m) | {pi: (.pricing.prompt|tonumber), po: (.pricing.completion|tonumber), pc: ((.pricing.input_cache_read // .pricing.prompt)|tonumber)}' 2>/dev/null)
printf '%s' "$prices" | jq -e '.pi' >/dev/null 2>&1 \
  || { prices='{"pi":0,"po":0}'; echo "WARN: no catalog price for $MODEL — cost recorded as 0" >&2; }
cost=$(jq -n --argjson u "$usage" --argjson p "$prices" \
  '((($u.in - $u.cin) * $p.pi) + ($u.cin * $p.pc) + ($u.out * $p.po)) | if . < 0 then 0 else . end' 2>/dev/null || echo 0)

turns=$(grep -c '"type":"turn.completed"' "$TRANSCRIPT" 2>/dev/null)
[ -n "$turns" ] || turns=0
[ -n "${cost:-}" ] || cost=0
if [ "$agent_exit" -eq 0 ] && [ "$turns" -eq 0 ]; then
  echo "codex exited 0 with zero completed turns — treating as provider refusal" >&2
  jq -cn --argjson dur "$((end - start))" \
    --arg eff "${CODEX_EFFORT:-default}" \
    '{cost_usd:0, duration_s:$dur, turns:0, agent_exit:99, timed_out:false, effort:$eff}'
  exit 99
fi

jq -cn \
  --argjson cost "${cost:-0}" --argjson turns "${turns:-0}" \
  --argjson dur "$((end - start))" --argjson ec "$agent_exit" \
  --argjson to "$timed_out" --arg eff "${CODEX_EFFORT:-default}" \
  '{cost_usd:$cost, duration_s:$dur, turns:$turns, agent_exit:$ec, timed_out:$to, effort:$eff}'
