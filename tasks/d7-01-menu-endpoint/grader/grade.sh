#!/usr/bin/env bash
# Grader for d7-01-menu-endpoint. Arg: agent workspace (contains healthstats/).
# Deploys the module into the provisioned D7 eval site and probes it.
# NOT VALIDATED LIVE YET — see VALIDATION.md.
set -uo pipefail
WS="$(cd "$1" && pwd)"   # canonicalize: the grader cd's around; relative paths must not break receipts
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
MOD="$SITE/sites/all/modules/custom/healthstats"

lint=false; enable=false; permission_defined=false; anon_403=false; authorized_json=false; authorized_http=false

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
    #
    # Criterion #3 ("deliver via D7's native mechanism — not print + exit") is
    # enforced here: the page callback must RETURN {users,nodes} and must NOT
    # print/echo or exit. We wrap the call in an output buffer and only trust a
    # run that reaches the MARKER (a callback that exit()s never does) with an
    # EMPTY buffer (a callback that print/echoes leaves bytes) and the right
    # return value. This distinguishes the reference (returns the array; a
    # delivery callback renders it) from the drupal_json_output()+drupal_exit()
    # or +return artifacts that game the old shape-only check. The delivery
    # trap is unaffected — its page callback returns cleanly and it is caught
    # by anon_403 instead.
    payload=$(ddev drush php-eval '
      global $user; $user = user_load(1);
      menu_rebuild();
      $item = menu_get_item("api/healthstats");
      $cb = $item ? $item["page_callback"] : NULL;
      $args = ($item && !empty($item["page_arguments"])) ? $item["page_arguments"] : array();
      ob_start();
      $out = ($cb && function_exists($cb)) ? call_user_func_array($cb, $args) : NULL;
      $printed = ob_get_clean();
      print drupal_json_encode(array(
        "MARKER" => "RETURNED",
        "printed_len" => strlen($printed),
        "ret" => $out,
      ));' 2>"$WS/payload-stderr.log")
    printf '%s' "$payload" > "$WS/payload.log"
    if echo "$payload" | jq -e '.MARKER == "RETURNED" and .printed_len == 0 and (.ret.users | type == "number") and (.ret.nodes | type == "number")' >/dev/null 2>&1; then
      authorized_json=true
    fi

    # Author-catch #9: the in-process check above is satisfiable by a module
    # that returns the array but wires NO delivery at all — over HTTP an
    # authorized user gets a themed HTML page, not JSON. Behavioral probe:
    # grant the contracted permission to anonymous, observe the real response,
    # revoke unconditionally (the shared site must never keep the grant).
    # Asserts 200 + application/json + exactly the {users,nodes} number shape.
    ddev drush php-eval 'user_role_grant_permissions(DRUPAL_ANONYMOUS_RID, array("view healthstats"));' >/dev/null 2>&1
    ddev drush cc all >/dev/null 2>&1
    stamp=$(date +%s%N)
    hdr=$(curl -sk -o "$WS/authorized-body.log" -w '%{http_code} %{content_type}' "$url/api/healthstats?nocache=$stamp")
    ddev drush php-eval 'user_role_revoke_permissions(DRUPAL_ANONYMOUS_RID, array("view healthstats"));' >/dev/null 2>&1
    ddev drush cc all >/dev/null 2>&1
    code2="${hdr%% *}"; ctype="${hdr#* }"
    if [ "$code2" = "200" ] && [ "${ctype#application/json}" != "$ctype" ] \
       && jq -e '(keys | sort == ["nodes","users"]) and (.users|type=="number") and (.nodes|type=="number")' "$WS/authorized-body.log" >/dev/null 2>&1; then
      authorized_http=true
    fi
  fi
  ddev drush -y pm-disable healthstats >/dev/null 2>&1
  rm -rf "$MOD"
fi

pass=false; $lint && $enable && $permission_defined && $anon_403 && $authorized_json && $authorized_http && pass=true
jq -n --argjson lint $lint --argjson enable $enable --argjson perm $permission_defined \
      --argjson anon $anon_403 --argjson auth $authorized_json --argjson http $authorized_http --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, enable:$enable, permission_defined:$perm,
        anon_403:$anon, authorized_json:$auth, authorized_http:$http}}' > "$WS/grade.json"
$pass
