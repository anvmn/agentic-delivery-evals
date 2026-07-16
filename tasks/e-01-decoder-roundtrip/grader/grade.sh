#!/usr/bin/env bash
# Grader for e-01-decoder-roundtrip. Arg: agent workspace.
# Runs on a fresh copy; pristine holdout tests replace anything agent-authored.
set -uo pipefail
WS="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"
G="$(mktemp -d)"
trap 'rm -rf "$G"' EXIT

cp -r "$WS/." "$G/"
rm -rf "$G/tests"; mkdir -p "$G/tests"
cp "$HERE/assets/RoundTripHoldout.elm" "$G/tests/"

compile=false; unit=false; conventions=false
cd "$G" || exit 1
( [ -d node_modules ] || npm install --silent --no-audit --no-fund ) >/dev/null 2>&1

if npx elm make src/Codec.elm --output=/dev/null > compile.log 2>&1; then compile=true; fi
if $compile && npx elm-test > unit.log 2>&1; then unit=true; fi
if npx elm-format --validate src/Codec.elm > fmt.log 2>&1; then conventions=true; fi

pass=false; $compile && $unit && $conventions && pass=true
jq -n --argjson compile $compile --argjson unit $unit --argjson conventions $conventions \
      --argjson pass $pass \
      '{pass:$pass, stages:{compile:$compile, unit:$unit, conventions:$conventions}}' \
      > "$WS/grade.json"
$pass
