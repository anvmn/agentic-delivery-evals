<?php

namespace Drupal\greeting_board\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Cache\Cache;

/**
 * Greets the current user and counts notices — FLAWED self-test variant: tags but no user context — cache poisoning.
 *
 * @Block(
 *   id = "greeting_block",
 *   admin_label = @Translation("Greeting")
 * )
 */
class GreetingBlock extends BlockBase {

  /**
   * {@inheritdoc}
   */
  public function build() {
    $account = \Drupal::currentUser();

    $count = \Drupal::entityQuery('node')
      ->condition('type', 'notice')
      ->condition('status', 1)
      ->accessCheck(TRUE)
      ->count()
      ->execute();

    return [
      '#markup' => $this->t('Hello @name — @count notices', [
        '@name' => $account->getDisplayName(),
        '@count' => $count,
      ]),
      '#cache' => [
        'tags' => ['node_list:notice'],
        'max-age' => Cache::PERMANENT,
      ],
    ];
  }

}
