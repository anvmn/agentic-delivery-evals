#!/usr/bin/env bash
# Grader for d10-05-query-access-leak. Arg: agent workspace (notice_api/).
# The leak probe: seed published + unpublished markers, curl as anonymous —
# published must appear, unpublished must not. Cache-buster per request.
set -uo pipefail
WS="$(cd "$1" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d10site"
MOD="$SITE/web/modules/custom/notice_api"

lint=false; route_ok=false; lists_published=false; no_leak=false; correct_order=false
php -l "$WS/notice_api/src/Controller/NoticeListController.php" >/dev/null 2>&1 && lint=true

if [ -d "$SITE" ] && [ -f "$SITE/web/index.php" ] && $lint; then
  cd "$SITE" || exit 1
  rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/notice_api/." "$MOD/"
  if ddev drush -y pm:install notice_api >/dev/null 2>&1 && ddev drush cr >/dev/null 2>&1; then
    stamp=$(date +%s%N)
    # Reset first: remove any leftover notice nodes so the top-5 is exactly our
    # seed (grades must be order-independent and immune to accumulated content).
    ddev drush php:eval "
      \$old = \Drupal::entityQuery('node')->condition('type','notice')->accessCheck(FALSE)->execute();
      foreach (\Drupal\node\Entity\Node::loadMultiple(\$old) as \$n) { \$n->delete(); }" >/dev/null 2>&1
    # pub1 (Pub-A) is the OLDER published notice, pub2 (Pub-B) the NEWER — set
    # distinct future-relative created times so "newest-first" is unambiguous
    # and the seed always outranks anything else.
    pub1="Pub-A-$stamp"; pub2="Pub-B-$stamp"; unpub="Secret-$stamp"
    ddev drush php:eval "
      \$t = \Drupal::time()->getRequestTime();
      foreach ([['$pub1',1,\$t+10],['$pub2',1,\$t+20],['$unpub',0,\$t+30]] as \$n) {
        \Drupal\node\Entity\Node::create(['type'=>'notice','title'=>\$n[0],'status'=>\$n[1],'created'=>\$n[2]])->save();
      }" >/dev/null 2>&1

    url=$(ddev describe -j | jq -r '.raw.primary_url')
    # Precondition: a dead site must abort loudly, never grade as failure.
    # (2026-07-23: a site outage during the #7 re-grade sweep recorded 9
    # cascade-failures as ground truth — caught by operator question.)
    if ! curl -sk -o /dev/null --max-time 20 "$url"; then
      echo "SITE DOWN — refusing to grade" >&2; exit 3
    fi
    body=$(curl -sk "$url/api/notices?nocache=$stamp")
    printf '%s' "$body" > "$WS/response.log"
    code=$(curl -sk -o /dev/null -w '%{http_code}' "$url/api/notices?nocache=${stamp}b")

    if [ "$code" = "200" ] && echo "$body" | jq -e 'type == "array"' >/dev/null 2>&1; then
      route_ok=true
    fi
    if echo "$body" | jq -e --arg a "$pub1" --arg b "$pub2" 'index($a) != null and index($b) != null' >/dev/null 2>&1; then
      lists_published=true
    fi
    if ! echo "$body" | grep -q "$unpub"; then
      no_leak=true
    fi
    # Order: the task returns the NEWEST titles first. Pub-B is newer than
    # Pub-A, so it must appear at an earlier index. Catches solutions that sort
    # the query but then iterate loadMultiple() (storage order, not query order).
    if echo "$body" | jq -e --arg a "$pub1" --arg b "$pub2" \
         '(index($b) != null) and (index($a) != null) and (index($b) < index($a))' >/dev/null 2>&1; then
      correct_order=true
    fi

    ddev drush php:eval "
      \$ids = \Drupal::entityQuery('node')->condition('title','%-$stamp','LIKE')->accessCheck(FALSE)->execute();
      foreach (\Drupal\node\Entity\Node::loadMultiple(\$ids) as \$n) { \$n->delete(); }" >/dev/null 2>&1
  fi
  ddev drush -y pm:uninstall notice_api >/dev/null 2>&1
  rm -rf "$MOD"
fi

pass=false; $lint && $route_ok && $lists_published && $no_leak && $correct_order && pass=true
jq -n --argjson lint $lint --argjson route $route_ok --argjson lp $lists_published \
      --argjson nl $no_leak --argjson co $correct_order --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, route_ok:$route, lists_published:$lp, no_leak:$nl,
        correct_order:$co}}' \
      > "$WS/grade.json"
$pass
