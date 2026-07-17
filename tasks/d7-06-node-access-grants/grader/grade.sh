#!/usr/bin/env bash
# Grader for d7-06-node-access-grants. Arg: agent workspace (recordaccess/).
# Probe: seed two centers, rebuild grants, run node_access-tagged listing
# queries as two users — each must see only their own center's records.
set -uo pipefail
WS="$(cd "$1" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
FIXTURE="$(cd "$HERE/../fixture" && pwd)"
MOD="$SITE/sites/all/modules/custom/recordaccess"

lint=true; enable=false; alice_scoped=false; bob_scoped=false
for f in "$WS"/recordaccess/*.module "$WS"/recordaccess/*.install "$WS"/recordaccess/*.inc; do
  [ -e "$f" ] || continue
  php -l "$f" >/dev/null 2>&1 || lint=false
done

if [ -d "$SITE" ] && [ -f "$SITE/index.php" ] && $lint; then
  cd "$SITE" || exit 1
  cp "$HERE/assets/reset.php" "$HERE/assets/probe.php" "$SITE/"

  ddev drush -y pm-disable recordaccess >/dev/null 2>&1 || true
  ddev drush php-script reset.php >/dev/null 2>&1
  rm -rf "$MOD"

  # Pristine install creates the fields; then deploy the agent's code.
  mkdir -p "$MOD"; cp -r "$FIXTURE/recordaccess/." "$MOD/"
  ddev drush cc all >/dev/null 2>&1
  if ddev drush -y pm-enable recordaccess >/dev/null 2>&1; then
    rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/recordaccess/." "$MOD/"
    ddev drush cc all >/dev/null 2>&1
    enable=true

    out=$(ddev drush php-script probe.php 2>/dev/null)
    printf '%s' "$out" > "$WS/probe.json"
    if echo "$out" | jq -e '.alice == .c7' >/dev/null 2>&1; then alice_scoped=true; fi
    if echo "$out" | jq -e '.bob == .c9' >/dev/null 2>&1; then bob_scoped=true; fi
  fi
  ddev drush -y pm-disable recordaccess >/dev/null 2>&1 || true
  ddev drush php-script reset.php >/dev/null 2>&1
  rm -f "$SITE/reset.php" "$SITE/probe.php"
  rm -rf "$MOD"
fi

pass=false; $lint && $enable && $alice_scoped && $bob_scoped && pass=true
jq -n --argjson lint $lint --argjson enable $enable --argjson a $alice_scoped \
      --argjson b $bob_scoped --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, enable:$enable, alice_scoped:$a, bob_scoped:$b}}' \
      > "$WS/grade.json"
$pass
