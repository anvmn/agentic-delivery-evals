#!/usr/bin/env bash
# Grader for d10-02-cache-bug. Arg: agent workspace (contains notice_board/).
# Behavior probe: render block, create a new notice, render again in a fresh
# process — the new title must appear without any cache rebuild.
# NOT VALIDATED LIVE YET — see VALIDATION.md.
set -uo pipefail
WS="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d10site"
MOD="$SITE/web/modules/custom/notice_board"
BLOCK_FILE="$WS/notice_board/src/Plugin/Block/LatestNoticeBlock.php"

lint=false; enable=false; no_cache_optout=false; behavior=false

if php -l "$BLOCK_FILE" >/dev/null 2>&1; then lint=true
elif [ -d "$SITE" ]; then
  cp "$BLOCK_FILE" "$SITE/.lintcheck.php" 2>/dev/null &&
    ( cd "$SITE" && ddev exec php -l /var/www/html/.lintcheck.php ) >/dev/null 2>&1 && lint=true
  rm -f "$SITE/.lintcheck.php"
fi

# Cheap opt-out ban: max-age zero / killSwitch / cache clears in module code.
if ! grep -REn "max-age.{0,4}=>.{0,4}0[^0-9]|maxAge\(0\)|killSwitch|invalidateAll\(\)|cache.*->deleteAll|drupal_flush" \
     "$WS/notice_board" >/dev/null 2>&1; then
  no_cache_optout=true
fi

if [ -d "$SITE" ] && [ -f "$SITE/web/index.php" ]; then
  rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/notice_board/." "$MOD/"
  cp "$HERE/assets/render_block.php" "$SITE/render_block.php"
  cd "$SITE"
  if ddev drush -y pm:install notice_board >/dev/null 2>&1 && ddev drush cr >/dev/null 2>&1; then
    enable=true
    marker="Notice-$(date +%s%N)"
    ddev drush php:script render_block.php >/dev/null 2>&1   # warm the render cache
    ddev drush php:eval "\Drupal\node\Entity\Node::create(['type'=>'notice','title'=>'$marker','status'=>1])->save();" >/dev/null 2>&1
    out=$(ddev drush php:script render_block.php 2>/dev/null)
    case "$out" in *"$marker"*) behavior=true ;; esac
  fi
  ddev drush -y pm:uninstall notice_board >/dev/null 2>&1
  rm -rf "$MOD" "$SITE/render_block.php"
fi

pass=false; $lint && $enable && $no_cache_optout && $behavior && pass=true
jq -n --argjson lint $lint --argjson enable $enable --argjson opt $no_cache_optout \
      --argjson behavior $behavior --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, enable:$enable, no_cache_optout:$opt, behavior:$behavior}}' \
      > "$WS/grade.json"
$pass
