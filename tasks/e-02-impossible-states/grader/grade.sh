#!/usr/bin/env bash
# Grader for e-02-impossible-states. Arg: agent workspace.
# Stages: compile -> unit (behavioral holdout) -> conventions ->
#         impossible_states (InvalidUsage.elm MUST fail to compile).
set -uo pipefail
WS="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"
G="$(mktemp -d)"
trap 'rm -rf "$G"' EXIT

cp -r "$WS/." "$G/"
rm -rf "$G/tests"; mkdir -p "$G/tests"
cp "$HERE/assets/HoldoutTest.elm" "$G/tests/"

compile=false; unit=false; conventions=false; impossible=false
cd "$G"
( [ -d node_modules ] || npm install --silent --no-audit --no-fund ) >/dev/null 2>&1

if npx elm make src/Verification.elm --output=/dev/null > compile.log 2>&1; then compile=true; fi
if $compile && npx elm-test > unit.log 2>&1; then unit=true; fi
if npx elm-format --validate src/Verification.elm > fmt.log 2>&1; then conventions=true; fi

# The probe: a correct (opaque) model must REJECT this file at compile time.
cp "$HERE/assets/InvalidUsage.elm" "$G/src/"
if $compile && ! npx elm make src/InvalidUsage.elm --output=/dev/null > invalid.log 2>&1; then
  impossible=true
fi

pass=false; $compile && $unit && $conventions && $impossible && pass=true
jq -n --argjson compile $compile --argjson unit $unit --argjson conventions $conventions \
      --argjson impossible $impossible --argjson pass $pass \
      '{pass:$pass, stages:{compile:$compile, unit:$unit, conventions:$conventions,
        impossible_states:$impossible}}' > "$WS/grade.json"
$pass
