#!/usr/bin/env bash
# Grader for d7-01-menu-endpoint. Arg: agent workspace (contains healthstats/).
# Deploys the module into the provisioned D7 eval site and probes it.
# NOT VALIDATED LIVE YET — see VALIDATION.md.
set -uo pipefail
WS="$(cd "$1" && pwd)"   # canonicalize: the grader cd's around; relative paths must not break receipts
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
MOD="$SITE/sites/all/modules/custom/healthstats"

lint=false; enable=false; permission_defined=false; anon_403=false; authorized_json=false

if php -l "$WS/healthstats/healthstats.module" >/dev/null 2>&1 \
   || ( cd "$SITE" && ddev exec php -l /var/www/html/sites/all/modules/custom/healthstats/healthstats.module ) >/dev/null 2>&1; then
  lint=true
fi

if [ -d "$SITE" ] && [ -f "$SITE/index.php" ]; then
  cd "$SITE" || exit 1
  # Reset to a known state first: the eval site is shared and mutable, so a
  # grade must not depend on what the previous grade left behind.
  ddev drush -y pm-disable healthstats >/dev/null 2>&1 || true
  rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/healthstats/." "$MOD/"
  ddev drush cc all >/dev/null 2>&1
  if ddev drush -y pm-enable healthstats >/dev/null 2>&1 && ddev drush cc all >/dev/null 2>&1; then
    enable=true

    perm=$(ddev drush php-eval 'print (int) array_key_exists("view healthstats", (array) module_invoke("healthstats", "permission"));' 2>/dev/null)
    [ "$perm" = "1" ] && permission_defined=true

    url=$(ddev describe -j | jq -r '.raw.primary_url')
    for _ in 1 2; do
      code=$(curl -sk -o /dev/null -w '%{http_code}' "$url/api/healthstats")
      [ "$code" = "403" ] && { anon_403=true; break; }
      sleep 2
    done

    # Call whatever page callback the module actually registered — the task
    # contract fixes the path and payload shape, not the function name.
    payload=$(ddev drush php-eval '
      global $user; $user = user_load(1);
      menu_rebuild();
      $item = menu_get_item("api/healthstats");
      $cb = $item ? $item["page_callback"] : NULL;
      $args = ($item && !empty($item["page_arguments"])) ? $item["page_arguments"] : array();
      $out = ($cb && function_exists($cb)) ? call_user_func_array($cb, $args) : NULL;
      print drupal_json_encode($out);' 2>"$WS/payload-stderr.log")
    printf '%s' "$payload" > "$WS/payload.log"
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
