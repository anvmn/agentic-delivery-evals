#!/usr/bin/env bash
# Grader for d7-03-field-migration. Arg: agent workspace (contains phonebook/).
# Flow mirrors a real D7 deployment: install pristine module -> seed data ->
# swap in the agent's code -> drush updb -> assert on both field tables.
set -uo pipefail
WS="$(cd "$1" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
FIXTURE="$(cd "$HERE/../fixture" && pwd)"
MOD="$SITE/sites/all/modules/custom/phonebook"

lint=true; update_ran=false; data_normalized=false; no_data_loss=false
for f in "$WS"/phonebook/*.install "$WS"/phonebook/*.module "$WS"/phonebook/*.inc "$WS"/phonebook/*.php; do
  [ -e "$f" ] || continue
  php -l "$f" >/dev/null 2>&1 || lint=false
done

if [ -d "$SITE" ] && [ -f "$SITE/index.php" ] && $lint; then
  cd "$SITE" || exit 1
  cp "$HERE/assets/reset.php" "$HERE/assets/seed.php" "$HERE/assets/check.php" "$SITE/"

  # Known state: disable, purge remnants, remove files.
  ddev drush -y pm-disable phonebook >/dev/null 2>&1 || true
  ddev drush php-script reset.php >/dev/null 2>&1
  rm -rf "$MOD"

  # Pristine install (no update hooks known at install time) + hidden seed.
  mkdir -p "$MOD"; cp -r "$FIXTURE/phonebook/." "$MOD/"
  ddev drush cc all >/dev/null 2>&1
  if ddev drush -y pm-enable phonebook >/dev/null 2>&1; then
    before=$(ddev drush php-script seed.php 2>/dev/null)
    printf '%s' "$before" > "$WS/seed.log"

    # Deploy the agent's code, then run updates — the real-world sequence.
    rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/phonebook/." "$MOD/"
    ddev drush cc all >/dev/null 2>&1
    ddev drush -y updb > "$WS/updb.log" 2>&1

    after=$(ddev drush php-script check.php 2>/dev/null)
    printf '%s' "$after" > "$WS/check.log"

    if echo "$after" | jq -e '.schema >= 7100' >/dev/null 2>&1; then update_ran=true; fi
    if echo "$after" | jq -e '
        .data_values == ["+972523334444","+972541234567","+972541234567",
                         "+972541234567","+972541234567","+972541234567","+972541234567"]
        and .rev_values == ["+972521112222","+972523334444"]' >/dev/null 2>&1; then
      data_normalized=true
    fi
    if jq -e -n --argjson b "${before:-null}" --argjson a "${after:-null}" \
        '$b != null and $a != null and $a.counts == $b' >/dev/null 2>&1; then
      no_data_loss=true
    fi
  fi
  ddev drush -y pm-disable phonebook >/dev/null 2>&1 || true
  rm -f "$SITE/reset.php" "$SITE/seed.php" "$SITE/check.php"
fi

pass=false; $lint && $update_ran && $data_normalized && $no_data_loss && pass=true
jq -n --argjson lint $lint --argjson ran $update_ran --argjson norm $data_normalized \
      --argjson loss $no_data_loss --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, update_ran:$ran, data_normalized:$norm,
        no_data_loss:$loss}}' > "$WS/grade.json"
$pass
