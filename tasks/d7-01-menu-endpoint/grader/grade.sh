#!/usr/bin/env bash
# Grader for d7-01-menu-endpoint. Arg: agent workspace (contains healthstats/).
# Deploys the module into the provisioned D7 eval site and probes it.
# NOT VALIDATED LIVE YET — see VALIDATION.md.
set -uo pipefail
WS="$1"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
MOD="$SITE/sites/all/modules/custom/healthstats"

lint=false; enable=false; permission_defined=false; anon_403=false; authorized_json=false

if php -l "$WS/healthstats/healthstats.module" >/dev/null 2>&1 \
   || ( cd "$SITE" && ddev exec php -l /var/www/html/sites/all/modules/custom/healthstats/healthstats.module ) >/dev/null 2>&1; then
  lint=true
fi

if [ -d "$SITE" ] && [ -f "$SITE/index.php" ]; then
  rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/healthstats/." "$MOD/"
  cd "$SITE"
  if ddev drush -y pm-enable healthstats >/dev/null 2>&1 && ddev drush cc all >/dev/null 2>&1; then
    enable=true

    perm=$(ddev drush php-eval 'print (int) array_key_exists("view healthstats", (array) module_invoke("healthstats", "permission"));' 2>/dev/null)
    [ "$perm" = "1" ] && permission_defined=true

    url=$(ddev describe -j | jq -r '.raw.primary_url')
    code=$(curl -sk -o /dev/null -w '%{http_code}' "$url/api/healthstats")
    [ "$code" = "403" ] && anon_403=true

    payload=$(ddev drush php-eval '
      global $user; $user = user_load(1);
      menu_rebuild();
      $out = healthstats_page();
      print drupal_json_encode($out);' 2>/dev/null)
    if echo "$payload" | jq -e '(.users | type == "number") and (.nodes | type == "number")' >/dev/null 2>&1; then
      authorized_json=true
    fi
  fi
  ddev drush -y pm-disable healthstats >/dev/null 2>&1
  rm -rf "$MOD"
fi

pass=false; $lint && $enable && $permission_defined && $anon_403 && $authorized_json && pass=true
jq -n --argjson lint $lint --argjson enable $enable --argjson perm $permission_defined \
      --argjson anon $anon_403 --argjson auth $authorized_json --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, enable:$enable, permission_defined:$perm,
        anon_403:$anon, authorized_json:$auth}}' > "$WS/grade.json"
$pass
