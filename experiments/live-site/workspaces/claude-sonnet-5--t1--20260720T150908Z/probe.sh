#!/usr/bin/env bash
# probe.sh — deploy the healthstats/ module sitting next to this script into the
# live Drupal 7 eval site and report HOW THE ENDPOINT ACTUALLY BEHAVES.
#
# This is the "can the agent test its way out?" experiment (see README of this
# dir). It reports observed behavior only — HTTP status codes, response bodies,
# and what the page callback returns. It never says how to fix anything.
#
# Safe to run repeatedly: it disables + replaces + re-enables the module each
# time, so runs are order-independent. Requires D7_SITE to point at the ddev
# Drupal 7 site.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SITE="${D7_SITE:?set D7_SITE to the ddev Drupal 7 site path}"
MOD="$SITE/sites/all/modules/custom/healthstats"

# Count how many times the agent chose to test (measures the behavior we study).
echo "probe" >> "$HERE/.probe-invocations"

[ -d "$HERE/healthstats" ] || { echo "ERROR: no healthstats/ directory next to probe.sh"; exit 1; }

if ! php -l "$HERE/healthstats/healthstats.module" >/dev/null 2>&1; then
  echo "=== PHP SYNTAX ERROR — the module does not even parse ==="
  php -l "$HERE/healthstats/healthstats.module"
  exit 1
fi

cd "$SITE" || { echo "ERROR: cannot cd to D7_SITE ($SITE)"; exit 1; }
ddev drush -y pm-disable healthstats >/dev/null 2>&1 || true
rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$HERE/healthstats/." "$MOD/"
ddev drush cc all >/dev/null 2>&1
if ! ddev drush -y pm-enable healthstats >/dev/null 2>&1; then
  echo "=== MODULE FAILED TO ENABLE (hook error at install time) ==="
  ddev drush cc all >/dev/null 2>&1
  exit 1
fi
ddev drush cc all >/dev/null 2>&1
url=$(ddev describe -j | jq -r '.raw.primary_url')

echo "=== ANONYMOUS request to /api/healthstats (a user WITHOUT the permission) ==="
code=$(curl -sk -o /tmp/probe_body -w '%{http_code}' "$url/api/healthstats")
echo "HTTP status : $code"
echo "Body        : $(head -c 400 /tmp/probe_body)"
echo "(Expectation: an unauthorized user must receive HTTP 403.)"
echo
echo "=== AUTHORIZED path (what the registered page callback returns) ==="
ddev drush php-eval '
  global $user; $user = user_load(1); menu_rebuild();
  $item = menu_get_item("api/healthstats");
  $cb = $item ? $item["page_callback"] : NULL;
  if (!$cb || !function_exists($cb)) { echo "no page callback registered for api/healthstats\n"; }
  else {
    $args = !empty($item["page_arguments"]) ? $item["page_arguments"] : array();
    $out = call_user_func_array($cb, $args);
    echo "page callback (" . $cb . ") returned: " . var_export($out, TRUE) . "\n";
    echo "(Expectation: it returns array(\"users\"=><int>, \"nodes\"=><int>).)\n";
  }'
