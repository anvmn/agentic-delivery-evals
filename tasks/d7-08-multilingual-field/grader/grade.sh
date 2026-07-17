#!/usr/bin/env bash
# Grader for d7-08-multilingual-field. Arg: agent workspace (langfield/).
# Seeds a node with per-language bodies and probes language resolution:
# the LANGUAGE_NONE-hardcode trap returns '' for the translated case.
set -uo pipefail
WS="$(cd "$1" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
FIXTURE="$(cd "$HERE/../fixture" && pwd)"
MOD="$SITE/sites/all/modules/custom/langfield"

lint=true; enable=false; translated=false; fallback=false; empty=false
for f in "$WS"/langfield/*.module "$WS"/langfield/*.install "$WS"/langfield/*.inc; do
  [ -e "$f" ] || continue
  php -l "$f" >/dev/null 2>&1 || lint=false
done

if [ -d "$SITE" ] && [ -f "$SITE/index.php" ] && $lint; then
  cd "$SITE" || exit 1
  cp "$HERE/assets/reset.php" "$HERE/assets/probe.php" "$SITE/"

  ddev drush -y pm-disable langfield >/dev/null 2>&1 || true
  ddev drush php-script reset.php >/dev/null 2>&1
  rm -rf "$MOD"

  mkdir -p "$MOD"; cp -r "$FIXTURE/langfield/." "$MOD/"
  ddev drush cc all >/dev/null 2>&1
  if ddev drush -y pm-enable langfield >/dev/null 2>&1; then
    rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/langfield/." "$MOD/"
    ddev drush cc all >/dev/null 2>&1
    enable=true

    out=$(ddev drush php-script probe.php 2>/dev/null)
    printf '%s' "$out" > "$WS/probe.json"
    if echo "$out" | jq -e '.rw == "Kinyarwanda body" and .en == "English body"' >/dev/null 2>&1; then translated=true; fi
    if echo "$out" | jq -e '.fallback == "Undefined body"' >/dev/null 2>&1; then fallback=true; fi
    if echo "$out" | jq -e '.empty == ""' >/dev/null 2>&1; then empty=true; fi
  fi
  ddev drush -y pm-disable langfield >/dev/null 2>&1 || true
  ddev drush php-script reset.php >/dev/null 2>&1
  rm -f "$SITE/reset.php" "$SITE/probe.php"
  rm -rf "$MOD"
fi

pass=false; $lint && $enable && $translated && $fallback && $empty && pass=true
jq -n --argjson lint $lint --argjson enable $enable --argjson t $translated \
      --argjson fb $fallback --argjson e $empty --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, enable:$enable, translated:$t, fallback:$fb, empty:$e}}' \
      > "$WS/grade.json"
$pass
