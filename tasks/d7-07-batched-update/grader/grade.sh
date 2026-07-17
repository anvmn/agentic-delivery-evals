#!/usr/bin/env bash
# Grader for d7-07-batched-update. Arg: agent workspace (bulknorm/).
# Drives hook_update_7100 in a controlled loop, measuring per-pass progress:
# correctness (all uppercased), batched (<=50 transformed per invocation),
# and the #finished protocol (progresses to 1).
set -uo pipefail
WS="$(cd "$1" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
FIXTURE="$(cd "$HERE/../fixture" && pwd)"
MOD="$SITE/sites/all/modules/custom/bulknorm"

lint=true; correctness=false; batched=false; completed=false
for f in "$WS"/bulknorm/*.install "$WS"/bulknorm/*.module "$WS"/bulknorm/*.inc; do
  [ -e "$f" ] || continue
  php -l "$f" >/dev/null 2>&1 || lint=false
done

if [ -d "$SITE" ] && [ -f "$SITE/index.php" ] && $lint; then
  cd "$SITE" || exit 1
  cp "$HERE/assets/reset.php" "$HERE/assets/seed_and_probe.php" "$SITE/"

  ddev drush -y pm-disable bulknorm >/dev/null 2>&1 || true
  ddev drush php-script reset.php >/dev/null 2>&1
  rm -rf "$MOD"

  # Pristine install creates type+field; then deploy the agent's code.
  mkdir -p "$MOD"; cp -r "$FIXTURE/bulknorm/." "$MOD/"
  ddev drush cc all >/dev/null 2>&1
  if ddev drush -y pm-enable bulknorm >/dev/null 2>&1; then
    rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/bulknorm/." "$MOD/"
    ddev drush cc all >/dev/null 2>&1

    out=$(ddev drush php-script seed_and_probe.php 2>/dev/null)
    printf '%s' "$out" > "$WS/probe.json"
    if echo "$out" | jq -e '.total == 120 and .upper == 120' >/dev/null 2>&1; then correctness=true; fi
    if echo "$out" | jq -e '.maxdelta <= 50 and .passes >= 2' >/dev/null 2>&1; then batched=true; fi
    if echo "$out" | jq -e '(.finished | tonumber) >= 1 and .passes < 200' >/dev/null 2>&1; then completed=true; fi
  fi
  ddev drush -y pm-disable bulknorm >/dev/null 2>&1 || true
  ddev drush php-script reset.php >/dev/null 2>&1
  rm -f "$SITE/reset.php" "$SITE/seed_and_probe.php"
  rm -rf "$MOD"
fi

pass=false; $lint && $correctness && $batched && $completed && pass=true
jq -n --argjson lint $lint --argjson c $correctness --argjson b $batched \
      --argjson comp $completed --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, correctness:$c, batched:$b, completed:$comp}}' \
      > "$WS/grade.json"
$pass
