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

lint=false; route_ok=false; lists_published=false; no_leak=false
php -l "$WS/notice_api/src/Controller/NoticeListController.php" >/dev/null 2>&1 && lint=true

if [ -d "$SITE" ] && [ -f "$SITE/web/index.php" ] && $lint; then
  cd "$SITE" || exit 1
  rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/notice_api/." "$MOD/"
  if ddev drush -y pm:install notice_api >/dev/null 2>&1 && ddev drush cr >/dev/null 2>&1; then
    stamp=$(date +%s%N)
    pub1="Pub-A-$stamp"; pub2="Pub-B-$stamp"; unpub="Secret-$stamp"
    ddev drush php:eval "
      foreach ([['$pub1',1],['$pub2',1],['$unpub',0]] as \$n) {
        \Drupal\node\Entity\Node::create(['type'=>'notice','title'=>\$n[0],'status'=>\$n[1]])->save();
      }" >/dev/null 2>&1

    url=$(ddev describe -j | jq -r '.raw.primary_url')
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

    ddev drush php:eval "
      \$ids = \Drupal::entityQuery('node')->condition('title','%-$stamp','LIKE')->accessCheck(FALSE)->execute();
      foreach (\Drupal\node\Entity\Node::loadMultiple(\$ids) as \$n) { \$n->delete(); }" >/dev/null 2>&1
  fi
  ddev drush -y pm:uninstall notice_api >/dev/null 2>&1
  rm -rf "$MOD"
fi

pass=false; $lint && $route_ok && $lists_published && $no_leak && pass=true
jq -n --argjson lint $lint --argjson route $route_ok --argjson lp $lists_published \
      --argjson nl $no_leak --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, route_ok:$route, lists_published:$lp, no_leak:$nl}}' \
      > "$WS/grade.json"
$pass
