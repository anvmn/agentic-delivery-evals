<?php

namespace Drupal\notice_board\Plugin\Block;

use Drupal\Core\Block\BlockBase;
use Drupal\Core\Cache\Cache;

/**
 * Shows the title of the latest published notice.
 *
 * Reference solution for grader self-tests: the render array carries the
 * node_list cache tag, so creating/updating notices invalidates it.
 *
 * @Block(
 *   id = "latest_notice_block",
 *   admin_label = @Translation("Latest notice")
 * )
 */
class LatestNoticeBlock extends BlockBase {

  /**
   * {@inheritdoc}
   */
  public function build() {
    $nids = \Drupal::entityQuery('node')
      ->condition('type', 'notice')
      ->condition('status', 1)
      ->sort('created', 'DESC')
      ->range(0, 1)
      ->accessCheck(FALSE)
      ->execute();

    $title = '(no notices yet)';
    $tags = ['node_list:notice'];
    if ($nids) {
      $node = \Drupal::entityTypeManager()->getStorage('node')->load(reset($nids));
      if ($node) {
        $title = $node->label();
        $tags = Cache::mergeTags($tags, $node->getCacheTags());
      }
    }

    return [
      '#markup' => $this->t('Latest notice: @title', ['@title' => $title]),
      '#cache' => [
        'max-age' => Cache::PERMANENT,
        'tags' => $tags,
      ],
    ];
  }

}
