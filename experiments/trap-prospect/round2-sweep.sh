#!/usr/bin/env bash
# round2-sweep.sh — tight second-order D7 probes across 6 lineages:
# Anthropic (haiku/sonnet/opus5), OpenAI (Sol via codex), and the open-weight
# fleet via OpenRouter (grok-4.6, deepseek-v4-pro, qwen3.8-max, kimi-k3).
# Resume-safe; Claude lane self-heals through transient rolling limits.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; cd "$HERE"
mkdir -p answers2; LOG="$HERE/round2.log"
SUFFIX=' Output only the code. No prose, no explanation. Answer directly from your knowledge; do not use tools.'
declare -A CLAUDE=( [claude-haiku-4-5]=haiku [claude-sonnet-5]=sonnet [claude-opus-5]=opus5 )
declare -A OR=( [x-ai/grok-4.6]=grok46 [deepseek/deepseek-v4-pro-0813]=dsv4pro [qwen/qwen3.8-max]=qwen38max [moonshotai/kimi-k3]=kimik3 )
eval "$(grep -E '^export (OPENAI|CODEX|OPENROUTER)' "$HOME/.bashrc" 2>/dev/null | tail -6)" 2>/dev/null || true

run_claude() { local d="$HERE/.lean"; mkdir -p "$d"; echo '{"mcpServers":{}}' > "$d/mcp.json"
  local out; out=$(cd "$d" && timeout 150 claude -p "$2$SUFFIX" --model "$1" --setting-sources "" --mcp-config "$d/mcp.json" --strict-mcp-config --output-format json </dev/null 2>/dev/null) || return 1
  grep -qiE 'hit your session limit|usage limit|reached your .* limit|api_error_status.*(429|401|403)' <<<"$out" && return 2
  jq -r 'select(.is_error==false) | .result // empty' <<<"$out" 2>/dev/null; }
run_sol() { timeout 150 codex exec "$1$SUFFIX" --model gpt-5.6-sol --dangerously-bypass-approvals-and-sandbox </dev/null 2>/dev/null; }
run_or() { # $1=model $2=prompt
  local body; body=$(jq -n --arg m "$1" --arg c "$2$SUFFIX" '{model:$m,messages:[{role:"user",content:$c}],max_tokens:1200}')
  curl -s --max-time 180 -X POST https://openrouter.ai/api/v1/chat/completions -H "Authorization: Bearer $OPENROUTER_API_KEY" -H 'Content-Type: application/json' -d "$body" | jq -r '.choices[0].message.content // empty' 2>/dev/null; }

while IFS= read -r line; do
  id=$(jq -r '.id' <<<"$line"); prompt=$(jq -r '.prompt' <<<"$line")
  for model in "${!CLAUDE[@]}"; do label=${CLAUDE[$model]}; f="answers2/${id}__${label}.txt"; [ -s "$f" ] && continue
    tries=0; while :; do ans=$(run_claude "$model" "$prompt"); rc=$?
      if [ $rc -eq 2 ]; then tries=$((tries+1)); [ $tries -gt 30 ] && { echo "$(date +%H:%M:%S) $id $label give-up" >>"$LOG"; break; }
        echo "$(date +%H:%M:%S) LIMIT $model $id wait120 ($tries)" >>"$LOG"; sleep 120; continue; fi; break; done
    [ -n "$ans" ] && printf '%s\n' "$ans" > "$f" && echo "$(date +%H:%M:%S) $id $label ok" >>"$LOG" || echo "$(date +%H:%M:%S) $id $label FAIL" >>"$LOG"
  done
  f="answers2/${id}__sol.txt"; [ -s "$f" ] || { ans=$(run_sol "$prompt"); [ -n "$ans" ] && printf '%s\n' "$ans">"$f" && echo "$(date +%H:%M:%S) $id sol ok">>"$LOG" || echo "$(date +%H:%M:%S) $id sol FAIL">>"$LOG"; }
  for model in "${!OR[@]}"; do label=${OR[$model]}; f="answers2/${id}__${label}.txt"; [ -s "$f" ] && continue
    ans=$(run_or "$model" "$prompt"); [ -n "$ans" ] && printf '%s\n' "$ans">"$f" && echo "$(date +%H:%M:%S) $id $label ok">>"$LOG" || echo "$(date +%H:%M:%S) $id $label FAIL">>"$LOG"
  done
done < round2-prompts.jsonl
echo "$(date +%H:%M:%S) ROUND2 DONE cells=$(ls answers2|wc -l)/96" | tee -a "$LOG"
