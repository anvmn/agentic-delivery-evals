#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")" || exit 1
mkdir -p dist
elm make src/Main.elm --optimize --output=dist/app.js
cp index.html dist/
echo "built -> dist/"
