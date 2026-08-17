#!/usr/bin/env bash
# sweep.sh — consensus-probe sweep. Each prompt in prompts.jsonl is answered
# one-shot by the prospector fleet (3 Claude tiers via the Max CLI + Sol via
# Codex). Raw answers land in answers/<id>__<label>.txt. Resume-safe: an
# existing non-empty answer file is skipped; failures/limits leave no file so a
# rerun retries. Fable is NOT a prospector (it doesn't fall for traps — it is
# the adjudicator in a later stage).
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
mkdir -p answers
LOG="$HERE/sweep.log"
SUFFIX=' Output only the code (or, for a how-to question, a terse numbered list). No prose, no explanation. Answer directly from your knowledge; do not use tools.'

# Claude lane: model-id -> label
declare -A CLAUDE=( [claude-haiku-4-5]=haiku [claude-sonnet-5]=sonnet [claude-opus-5]=opus5 )

eval "$(grep -E '^export (OPENAI|CODEX)' "$HOME/.bashrc" 2>/dev/null | tail -5)" 2>/dev/null || true

run_claude() { # $1=model $2=prompt  -> stdout=answer
  local out d="$HERE/.lean"; mkdir -p "$d"; echo '{"mcpServers":{}}' > "$d/mcp.json"
  # run lean: empty cwd, no project/user settings, no MCP — a bare knowledge probe,
  # ~30x lighter per call than loading the repo context (which exhausted the quota)
  out=$(cd "$d" && timeout 150 claude -p "$2$SUFFIX" --model "$1" \
        --setting-sources "" --mcp-config "$d/mcp.json" --strict-mcp-config \
        --output-format json </dev/null 2>/dev/null) || return 1
  # bail on limit signals so we don't write junk
  grep -qiE 'hit your session limit|usage limit|reached your .* limit|api_error_status.*(429|401|403)' <<<"$out" && return 2
  jq -r 'select(.is_error==false) | .result // empty' <<<"$out" 2>/dev/null
}

run_sol() { # $1=prompt -> stdout=answer
  timeout 150 codex exec "$1$SUFFIX" --model gpt-5.6-sol \
    --dangerously-bypass-approvals-and-sandbox </dev/null 2>/dev/null
}

total=0; done_n=0; skip=0; fail=0
while IFS= read -r line; do
  id=$(jq -r '.id' <<<"$line"); prompt=$(jq -r '.prompt' <<<"$line")
  # Claude tiers
  for model in "${!CLAUDE[@]}"; do
    label=${CLAUDE[$model]}; f="answers/${id}__${label}.txt"; total=$((total+1))
    if [ -s "$f" ]; then skip=$((skip+1)); continue; fi
    tries=0
    while :; do
      ans=$(run_claude "$model" "$prompt"); rc=$?
      if [ $rc -eq 2 ]; then
        tries=$((tries+1))
        if [ $tries -gt 30 ]; then echo "$(date +%H:%M:%S) LIMIT persistent on $model at $id — giving up cell (resume later)" >>"$LOG"; break; fi
        echo "$(date +%H:%M:%S) LIMIT on $model at $id — waiting 120s (retry $tries)" >>"$LOG"; sleep 120; continue
      fi
      break
    done
    if [ -n "$ans" ]; then printf '%s\n' "$ans" > "$f"; done_n=$((done_n+1)); echo "$(date +%H:%M:%S) $id $label ok" >>"$LOG"
    else fail=$((fail+1)); echo "$(date +%H:%M:%S) $id $label FAIL(rc=$rc)" >>"$LOG"; fi
  done
  # Sol
  f="answers/${id}__sol.txt"; total=$((total+1))
  if [ -s "$f" ]; then skip=$((skip+1)); else
    ans=$(run_sol "$prompt")
    if [ -n "$ans" ]; then printf '%s\n' "$ans" > "$f"; done_n=$((done_n+1)); echo "$(date +%H:%M:%S) $id sol ok" >>"$LOG"
    else fail=$((fail+1)); echo "$(date +%H:%M:%S) $id sol FAIL" >>"$LOG"; fi
  fi
done < prompts.jsonl
echo "$(date +%H:%M:%S) DONE cells=$total new=$done_n skipped=$skip failed=$fail" | tee -a "$LOG"
