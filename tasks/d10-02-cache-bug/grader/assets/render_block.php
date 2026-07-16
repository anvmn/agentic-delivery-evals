<?php

/**
 * @file
 * Renders latest_notice_block the way core's block rendering does
 * (drush php:script). A wrapper with #cache keys stands in for
 * BlockViewBuilder: the plugin build's cacheability bubbles up into the
 * wrapper's render-cache entry, so missing tags reproduce as staleness
 * across separate drush invocations — exactly like a real placed block.
 */

use Drupal\Core\Render\RenderContext;

$renderer = \Drupal::service('renderer');
$block = \Drupal::service('plugin.manager.block')->createInstance('latest_notice_block', []);

$context = new RenderContext();
$html = $renderer->executeInRenderContext($context, function () use ($renderer, $block) {
  $wrapped = [
    '#cache' => [
      'keys' => ['eval', 'latest_notice_block'],
    ],
    'content' => $block->build(),
  ];
  return $renderer->render($wrapped);
});
print (string) $html;
