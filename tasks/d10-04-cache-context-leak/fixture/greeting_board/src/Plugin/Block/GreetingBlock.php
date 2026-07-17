<?php

namespace Drupal\greeting_board\Plugin\Block;

use Drupal\Core\Block\BlockBase;

/**
 * Greets the current user and counts notices.
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
    // TODO: implement per task.md.
    return [];
  }

}
