<?php

/**
 * @file
 * Renders greeting_block as a given user, through a keyed cache wrapper
 * (drush php:script render_as.php -- <username>).
 * Mirrors core block rendering: child cacheability (contexts, tags) bubbles
 * into the wrapper's render-cache entry, so missing contexts reproduce as
 * cross-user cache poisoning across separate drush invocations.
 */

use Drupal\Core\Render\RenderContext;
use Drupal\user\Entity\User;

foreach (array('grader_alice', 'grader_bob') as $name) {
  if (!user_load_by_name($name)) {
    User::create(array(
      'name' => $name,
      'mail' => $name . '@example.test',
      'status' => 1,
    ))->save();
  }
}

$target = isset($extra[0]) ? $extra[0] : 'grader_alice';
$account = user_load_by_name($target);

$switcher = \Drupal::service('account_switcher');
$switcher->switchTo($account);

$renderer = \Drupal::service('renderer');
$block = \Drupal::service('plugin.manager.block')->createInstance('greeting_block', []);
$context = new RenderContext();
$html = $renderer->executeInRenderContext($context, function () use ($renderer, $block) {
  $wrapped = [
    '#cache' => [
      'keys' => ['eval', 'greeting_block'],
    ],
    'content' => $block->build(),
  ];
  return $renderer->render($wrapped);
});

$switcher->switchBack();
print (string) $html;
