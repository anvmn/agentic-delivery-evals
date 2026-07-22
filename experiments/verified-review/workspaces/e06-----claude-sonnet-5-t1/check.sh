#!/usr/bin/env bash
# check.sh — run the submission's own test suite (elm-test). Report only.
echo check >> "$(dirname "$0")/.check-invocations"
cd "$(dirname "$0")" && npx elm-test 2>&1
