<?php

/**
 * @file
 * Renders the latest_notice_block through the render pipeline (drush php:script).
 * Render cache applies, so staleness reproduces across separate drush calls.
 */

use Drupal\Core\Render\RenderContext;

$renderer = \Drupal::service('renderer');
$block = \Drupal::service('plugin.manager.block')->createInstance('latest_notice_block', []);
$context = new RenderContext();
$html = $renderer->executeInRenderContext($context, function () use ($renderer, $block) {
  $build = $block->build();
  return $renderer->render($build);
});
print (string) $html;
