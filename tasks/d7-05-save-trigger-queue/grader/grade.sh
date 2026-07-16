#!/usr/bin/env bash
# Grader for d7-05-save-trigger-queue. Arg: agent workspace (contains clinicstats/).
# Behavioral probe on the live d7site: seed saves -> queue depth (dedup) ->
# cron -> exact totals -> second wave -> repeat. All receipts kept in the ws.
set -uo pipefail
WS="$(cd "$1" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
FIXTURE="$(cd "$HERE/../fixture" && pwd)"
MOD="$SITE/sites/all/modules/custom/clinicstats"

lint=true; queueing=false; dedup=false; aggregation=false
for f in "$WS"/clinicstats/*.module "$WS"/clinicstats/*.install "$WS"/clinicstats/*.inc "$WS"/clinicstats/*.php; do
  [ -e "$f" ] || continue
  php -l "$f" >/dev/null 2>&1 || lint=false
done

probe() { ddev drush php-script check.php 2>/dev/null; }

if [ -d "$SITE" ] && [ -f "$SITE/index.php" ] && $lint; then
  cd "$SITE" || exit 1
  cp "$HERE/assets/reset.php" "$HERE/assets/seed1.php" "$HERE/assets/wave2.php" "$HERE/assets/check.php" "$SITE/"

  ddev drush -y pm-disable clinicstats >/dev/null 2>&1 || true
  ddev drush php-script reset.php >/dev/null 2>&1
  rm -rf "$MOD"

  # Pristine install (type + fields), then deploy the agent's code.
  mkdir -p "$MOD"; cp -r "$FIXTURE/clinicstats/." "$MOD/"
  ddev drush cc all >/dev/null 2>&1
  if ddev drush -y pm-enable clinicstats >/dev/null 2>&1; then
    rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/clinicstats/." "$MOD/"
    ddev drush cc all >/dev/null 2>&1

    ddev drush php-script seed1.php > "$WS/seed1.log" 2>&1
    s1=$(probe); printf '%s' "$s1" > "$WS/state-seed1.json"
    if echo "$s1" | jq -e '.queue == 2 and .t7 == null and .t9 == null' >/dev/null 2>&1; then
      queueing=true
    fi

    ddev drush cron > "$WS/cron1.log" 2>&1
    c1=$(probe); printf '%s' "$c1" > "$WS/state-cron1.json"

    ddev drush php-script wave2.php > "$WS/wave2.log" 2>&1
    w2=$(probe); printf '%s' "$w2" > "$WS/state-wave2.json"
    if echo "$w2" | jq -e '
        .queue == 1 and .t7 != null and (.t7.sum | tonumber) == 30.5' >/dev/null 2>&1; then
      dedup=true
    fi

    ddev drush cron > "$WS/cron2.log" 2>&1
    c2=$(probe); printf '%s' "$c2" > "$WS/state-cron2.json"

    if echo "$c1" | jq -e '
        .queue == 0 and .t7 != null and .t9 != null
        and (.t7.count | tonumber) == 2 and (.t7.sum | tonumber) == 30.5
        and (.t9.count | tonumber) == 1 and (.t9.sum | tonumber) == 5.25' >/dev/null 2>&1 \
       && echo "$c2" | jq -e '
        .queue == 0 and .t7 != null and .t9 != null
        and (.t7.count | tonumber) == 3 and (.t7.sum | tonumber) == 35
        and (.t9.count | tonumber) == 1 and (.t9.sum | tonumber) == 5.25' >/dev/null 2>&1; then
      aggregation=true
    fi
  fi
  ddev drush -y pm-disable clinicstats >/dev/null 2>&1 || true
  rm -f "$SITE/reset.php" "$SITE/seed1.php" "$SITE/wave2.php" "$SITE/check.php"
fi

pass=false; $lint && $queueing && $dedup && $aggregation && pass=true
jq -n --argjson lint $lint --argjson q $queueing --argjson d $dedup \
      --argjson agg $aggregation --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, queueing:$q, dedup:$d, aggregation:$agg}}' \
      > "$WS/grade.json"
$pass
