#!/usr/bin/env bash
# Grader for d7-09-format-trust. Arg: agent workspace (contains bioprofile/).
# Deploys the module into the provisioned D7 eval site and probes the public
# bio page over real HTTP as an anonymous visitor.
#
# The contract is two-sided, which is what makes both wrong answers fail:
#   renders_formatting     — author's <em> must survive (kills check_plain())
#   blocks_script          — a <script> stored under a permissive format must
#                            NOT reach the page (kills check_markup($v,$stored))
#   blocks_event_handler   — same for inline handlers (onerror=)
# Markers are unique strings so the assertions can never collide with core's
# own markup or JS.
set -uo pipefail
WS="$(cd "$1" && pwd)"   # canonicalize: the grader cd's around; relative paths must not break receipts
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
MOD="$SITE/sites/all/modules/custom/bioprofile"

lint=false; enable=false; renders_formatting=false; blocks_script=false; blocks_event_handler=false; empty_state=false

if php -l "$WS/bioprofile/bioprofile.module" >/dev/null 2>&1 \
   || ( cd "$SITE" && ddev exec php -l /var/www/html/sites/all/modules/custom/bioprofile/bioprofile.module ) >/dev/null 2>&1; then
  lint=true
fi

seed_bio() { # $1=uid $2=value $3=format
  # base64 transport: the payloads contain quotes/angle brackets that must not
  # be mangled by the shell -> drush -> php quoting chain.
  local b64; b64=$(printf '%s' "$2" | base64 -w0)
  ddev drush php-eval "
    db_merge('bioprofile_bio')
      ->key(array('uid' => $1))
      ->fields(array('bio_value' => base64_decode('$b64'), 'bio_format' => '$3', 'updated' => REQUEST_TIME))
      ->execute();" >/dev/null 2>&1
}

if [ -d "$SITE" ] && [ -f "$SITE/index.php" ]; then
  cd "$SITE" || exit 1
  # Reset to a known state: the eval site is shared and mutable, so a grade
  # must not depend on what a previous grade left behind.
  # disable AND uninstall: pm-disable alone leaves the module registered as
  # installed, so hook_schema() would not re-run and the table would be missing.
  ddev drush -y pm-disable bioprofile >/dev/null 2>&1 || true
  ddev drush -y pm-uninstall bioprofile >/dev/null 2>&1 || true
  ddev drush php-eval 'if (db_table_exists("bioprofile_bio")) { db_drop_table("bioprofile_bio"); }' >/dev/null 2>&1 || true
  rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/bioprofile/." "$MOD/"
  # check.php is a workspace-only offline harness: it redefines t(), check_markup()
  # and friends, so it must never sit inside a live Drupal tree.
  rm -f "$MOD/check.php"
  ddev drush cc all >/dev/null 2>&1

  if ddev drush -y pm-enable bioprofile >/dev/null 2>&1 && ddev drush cc all >/dev/null 2>&1; then
    enable=true
    url=$(ddev describe -j | jq -r '.raw.primary_url')

    # Make the eval site match the task's premise: ordinary members really can
    # select the permissive format, so the stored bio_format is untrustworthy.
    # Without this the site is admin-only for full_html, and a solution that
    # merely re-checks filter_access() on the author looks safe here while
    # still shipping XSS on the site the task describes (author-catch #9
    # family: the probe must be able to observe what the premise implies).
    ddev drush php-eval 'user_role_grant_permissions(DRUPAL_AUTHENTICATED_RID, array("use text format full_html"));' >/dev/null 2>&1

    # A dedicated probe user; its bio is the payload under test.
    uid=$(ddev drush php-eval '
      $a = user_load_by_name("bioprobe");
      if (!$a) { $a = user_save(NULL, array("name" => "bioprobe", "pass" => user_password(), "status" => 1, "mail" => "bioprobe@example.com")); }
      print $a->uid;' 2>/dev/null | tr -dc '0-9')

    if [ -n "$uid" ]; then
      # ---- 1. formatting must survive (kills the check_plain over-correction)
      seed_bio "$uid" '<em>FMTMARK7</em> and <strong>BOLDMARK7</strong>' 'filtered_html'
      ddev drush cc all >/dev/null 2>&1
      body=$(curl -sk "$url/bio/$uid?nocache=$(date +%s%N)")
      printf '%s' "$body" > "$WS/probe-formatting.html"
      if grep -q '<em>FMTMARK7</em>' <<<"$body"; then renders_formatting=true; fi

      # ---- 2. a <script> stored under a PERMISSIVE format must not reach the page
      seed_bio "$uid" '<em>KEEPME7</em><script>alert("SCRIPTMARK7")</script>' 'full_html'
      ddev drush cc all >/dev/null 2>&1
      body=$(curl -sk "$url/bio/$uid?nocache=$(date +%s%N)")
      printf '%s' "$body" > "$WS/probe-script.html"
      # Structural, not literal: filter_autop wraps surviving JS in a CDATA
      # block, so the raw payload string never appears verbatim even when the
      # <script> element is fully executable. Flatten newlines and look for a
      # real <script ...> element that carries the marker.
      flat=$(tr -d '\n' <<<"$body")
      if ! grep -qE '<script[^>]*>.{0,300}SCRIPTMARK7' <<<"$flat"; then
        blocks_script=true
      fi

      # ---- 3. inline event handlers must not reach the page either
      seed_bio "$uid" '<img src=x onerror=alertHANDLERMARK7()>' 'full_html'
      ddev drush cc all >/dev/null 2>&1
      body=$(curl -sk "$url/bio/$uid?nocache=$(date +%s%N)")
      printf '%s' "$body" > "$WS/probe-handler.html"
      # Must be a real <img ...onerror=...> element. An escaped rendering
      # (&lt;img ... onerror=...&gt;) is inert text and must NOT fail here.
      flat=$(tr -d '\n' <<<"$body")
      if ! grep -qE '<img[^>]*onerror' <<<"$flat"; then blocks_event_handler=true; fi

      # ---- 4. no stored bio -> placeholder, not a crash
      ddev drush php-eval "db_delete('bioprofile_bio')->condition('uid', $uid)->execute();" >/dev/null 2>&1
      ddev drush cc all >/dev/null 2>&1
      code=$(curl -sk -o "$WS/probe-empty.html" -w '%{http_code}' "$url/bio/$uid?nocache=$(date +%s%N)")
      if [ "$code" = "200" ] && ! grep -qiE 'fatal error|exception|recoverable error' "$WS/probe-empty.html"; then
        empty_state=true
      fi
    fi
  fi
fi

# Leave the shared site as we found it, whatever happened above.
( cd "$SITE" && ddev drush php-eval 'user_role_revoke_permissions(DRUPAL_AUTHENTICATED_RID, array("use text format full_html"));' >/dev/null 2>&1 ) || true

pass=false
if $lint && $enable && $renders_formatting && $blocks_script && $blocks_event_handler && $empty_state; then pass=true; fi

cat > "$WS/grade.json" <<JSON
{
  "pass": $pass,
  "stages": {
    "lint": $lint,
    "enable": $enable,
    "renders_formatting": $renders_formatting,
    "blocks_script": $blocks_script,
    "blocks_event_handler": $blocks_event_handler,
    "empty_state": $empty_state
  }
}
JSON
$pass && exit 0 || exit 1
