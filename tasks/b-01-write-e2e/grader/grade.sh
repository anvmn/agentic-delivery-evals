#!/usr/bin/env bash
# Grader for b-01-write-e2e. Arg: agent workspace.
# The double-fixture rule: the agent's tests must PASS on the healthy app and
# FAIL on a seeded-broken variant (persistence silently dropped). Tests that
# cannot fail do not count. The agent must not touch the app itself.
set -uo pipefail
WS="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"
FIXTURE="$HERE/../fixture"

has_tests=false; app_untouched=false; healthy=false; broken_detected=false

find "$WS/e2e" -name '*.spec.*' 2>/dev/null | grep -q . && has_tests=true

app_untouched=true
for f in src/Main.elm index.html build.sh playwright.config.js elm.json; do
  cmp -s "$WS/$f" "$FIXTURE/$f" || app_untouched=false
done

run_suite() {  # $1 = main-file to use; returns playwright exit code
  local main_src="$1" G rc
  G="$(mktemp -d)"
  cp -r "$WS/." "$G/"
  cp "$main_src" "$G/src/Main.elm"
  ( cd "$G" &&
    { [ -d node_modules ] || npm install --silent --no-audit --no-fund; } >/dev/null 2>&1 &&
    ./build.sh >/dev/null 2>&1 &&
    npx playwright test > pw.log 2>&1 )
  rc=$?
  rm -rf "$G"
  return $rc
}

if $has_tests && $app_untouched; then
  if run_suite "$FIXTURE/src/Main.elm"; then healthy=true; fi
  if ! run_suite "$HERE/assets/broken/Main.elm"; then broken_detected=true; fi
fi

pass=false; $has_tests && $app_untouched && $healthy && $broken_detected && pass=true
jq -n --argjson has_tests $has_tests --argjson app_untouched $app_untouched \
      --argjson healthy $healthy --argjson broken $broken_detected --argjson pass $pass \
      '{pass:$pass, stages:{has_tests:$has_tests, app_untouched:$app_untouched,
        healthy_passes:$healthy, broken_detected:$broken}}' > "$WS/grade.json"
$pass
