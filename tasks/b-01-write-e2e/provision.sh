#!/usr/bin/env bash
# One-time fixture provisioning for b-01: node deps + Playwright chromium.
set -euo pipefail
cd "$(dirname "$0")/fixture" || exit 1
npm install --no-audit --no-fund
npx playwright install chromium
./build.sh && rm -rf dist
echo "b-01 provisioned."
