<?php

namespace Drupal\notice_api\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;

/**
 * @file
 * Controller for the newest-notices JSON endpoint.
 */
class NoticeListController extends ControllerBase {

  /**
   * GET /api/notices.
   */
  public function list(): JsonResponse {
    $nids = $this->entityTypeManager()->getStorage('node')->getQuery()
      ->condition('type', 'notice')
      ->condition('status', 1)
      ->accessCheck(TRUE)
      ->sort('created', 'DESC')
      ->range(0, 5)
      ->execute();

    $titles = [];
    foreach ($this->entityTypeManager()->getStorage('node')->loadMultiple($nids) as $node) {
      $titles[] = $node->label();
    }
    return new JsonResponse($titles);
  }

}
