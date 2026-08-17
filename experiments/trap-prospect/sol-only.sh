#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; cd "$HERE"
eval "$(grep -E '^export (OPENAI|CODEX)' "$HOME/.bashrc" 2>/dev/null | tail -5)" 2>/dev/null || true
SUFFIX=' Output only the code (or, for a how-to question, a terse numbered list). No prose, no explanation. Answer directly from your knowledge; do not use tools.'
n=0
while IFS= read -r line; do
  id=$(jq -r '.id' <<<"$line"); prompt=$(jq -r '.prompt' <<<"$line")
  f="answers/${id}__sol.txt"; [ -s "$f" ] && continue
  ans=$(timeout 150 codex exec "$prompt$SUFFIX" --model gpt-5.6-sol --dangerously-bypass-approvals-and-sandbox </dev/null 2>/dev/null)
  [ -n "$ans" ] && printf '%s\n' "$ans" > "$f" && n=$((n+1)) && echo "$(date +%H:%M:%S) $id sol ok ($n)" >> sol.log
done < prompts.jsonl
echo "$(date +%H:%M:%S) SOL DONE new=$n total=$(ls answers/*__sol.txt 2>/dev/null | wc -l)/60" | tee -a sol.log
