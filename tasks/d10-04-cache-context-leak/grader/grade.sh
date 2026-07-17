#!/usr/bin/env bash
# Grader for d10-04-cache-context-leak. Arg: agent workspace (greeting_board/).
# The poisoning probe: warm the cache as alice, render as bob in a separate
# process — bob must see bob. Then invalidation: new notice, count must move.
set -uo pipefail
WS="$(cd "$1" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
SITE="$ROOT/.ddev-cores/d10site"
MOD="$SITE/web/modules/custom/greeting_board"
BLOCK_FILE="$WS/greeting_board/src/Plugin/Block/GreetingBlock.php"

lint=false; enable=false; no_cache_optout=false; per_user=false; invalidation=false
php -l "$BLOCK_FILE" >/dev/null 2>&1 && lint=true

if ! grep -REn "max-age.{0,4}=>.{0,4}0[^0-9]|maxAge\(0\)|killSwitch|invalidateAll\(\)|cache.*->deleteAll|drupal_flush" \
     "$WS/greeting_board" >/dev/null 2>&1; then
  no_cache_optout=true
fi

render_as() { ddev drush php:script render_as.php -- "$1" 2>/dev/null; }

if [ -d "$SITE" ] && [ -f "$SITE/web/index.php" ] && $lint; then
  cd "$SITE" || exit 1
  rm -rf "$MOD"; mkdir -p "$MOD"; cp -r "$WS/greeting_board/." "$MOD/"
  cp "$HERE/assets/render_as.php" "$SITE/render_as.php"
  if ddev drush -y pm:install greeting_board >/dev/null 2>&1 && ddev drush cr >/dev/null 2>&1; then
    enable=true

    a1=$(render_as grader_alice); printf '%s' "$a1" > "$WS/render-alice1.log"
    b1=$(render_as grader_bob);   printf '%s' "$b1" > "$WS/render-bob1.log"
    a2=$(render_as grader_alice); printf '%s' "$a2" > "$WS/render-alice2.log"
    case "$a1" in *"Hello grader_alice"*) ok_a1=1 ;; *) ok_a1=0 ;; esac
    case "$b1" in *"Hello grader_bob"*)   ok_b1=1 ;; *) ok_b1=0 ;; esac
    case "$b1" in *"grader_alice"*)       ok_b1=0 ;; esac
    case "$a2" in *"Hello grader_alice"*) ok_a2=1 ;; *) ok_a2=0 ;; esac
    [ "$ok_a1$ok_b1$ok_a2" = "111" ] && per_user=true

    count_before=$(printf '%s' "$a2" | grep -oE '[0-9]+ notices' | grep -oE '[0-9]+' | head -1)
    marker="Notice-inv-$(date +%s%N)"
    ddev drush php:eval "\Drupal\node\Entity\Node::create(['type'=>'notice','title'=>'$marker','status'=>1])->save();" >/dev/null 2>&1
    a3=$(render_as grader_alice); printf '%s' "$a3" > "$WS/render-alice3.log"
    count_after=$(printf '%s' "$a3" | grep -oE '[0-9]+ notices' | grep -oE '[0-9]+' | head -1)
    if [ -n "$count_before" ] && [ -n "$count_after" ] && [ "$count_after" -eq $((count_before + 1)) ]; then
      invalidation=true
    fi
  fi
  ddev drush -y pm:uninstall greeting_board >/dev/null 2>&1
  rm -rf "$MOD" "$SITE/render_as.php"
fi

pass=false; $lint && $enable && $no_cache_optout && $per_user && $invalidation && pass=true
jq -n --argjson lint $lint --argjson enable $enable --argjson opt $no_cache_optout \
      --argjson pu $per_user --argjson inv $invalidation --argjson pass $pass \
      '{pass:$pass, stages:{lint:$lint, enable:$enable, no_cache_optout:$opt,
        per_user:$pu, invalidation:$inv}}' > "$WS/grade.json"
$pass
