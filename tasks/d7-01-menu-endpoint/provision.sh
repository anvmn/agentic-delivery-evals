#!/usr/bin/env bash
# One-time: provision a throwaway Drupal 7 eval site under .ddev-cores/d7site.
# Requires network + ddev. NOT VALIDATED LIVE YET — see VALIDATION.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SITE="$ROOT/.ddev-cores/d7site"
D7_VERSION="7.103"

mkdir -p "$SITE"; cd "$SITE" || exit 1
if [ ! -f index.php ]; then
  curl -fsSL "https://ftp.drupal.org/files/projects/drupal-${D7_VERSION}.tar.gz" | tar xz --strip-components=1
fi
[ -f .ddev/config.yaml ] || ddev config --project-type=drupal7 --project-name=evals-d7 --php-version=7.4
ddev start -y
ddev drush -y site-install standard --account-pass=admin --site-name="D7 Eval Site" || true
mkdir -p sites/all/modules/custom
echo "d7site provisioned at $SITE"
