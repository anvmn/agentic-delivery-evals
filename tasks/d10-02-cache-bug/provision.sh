#!/usr/bin/env bash
# One-time: provision a throwaway Drupal 10 eval site under .ddev-cores/d10site.
# Requires network + ddev. NOT VALIDATED LIVE YET — see VALIDATION.md.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SITE="$ROOT/.ddev-cores/d10site"

mkdir -p "$SITE"; cd "$SITE"
[ -f composer.json ] || composer create-project drupal/recommended-project:^10 . --no-interaction
[ -f .ddev/config.yaml ] || ddev config --project-type=drupal10 --project-name=evals-d10 --docroot=web
ddev start -y
ddev composer require drush/drush --no-interaction
ddev drush -y site:install standard --account-pass=admin --site-name="D10 Eval Site" || true
ddev drush php:eval '
  if (!\Drupal\node\Entity\NodeType::load("notice")) {
    \Drupal\node\Entity\NodeType::create(["type" => "notice", "name" => "Notice"])->save();
  }
  \Drupal\node\Entity\Node::create(["type" => "notice", "title" => "Initial notice", "status" => 1])->save();
'
mkdir -p web/modules/custom
echo "d10site provisioned at $SITE"
