<?php

namespace Drupal\notice_api\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;

/**
 * Returns the newest notice titles as a JSON array.
 */
class NoticeListController extends ControllerBase {

  /**
   * GET /api/notices.
   */
  public function list(): JsonResponse {
    $storage = $this->entityTypeManager()->getStorage('node');
    $nids = $storage->getQuery()
      ->condition('type', 'notice')
      ->condition('status', 1)
      ->accessCheck(TRUE)
      ->sort('created', 'DESC')
      ->range(0, 5)
      ->execute();

    $nodes = $storage->loadMultiple($nids);
    $titles = [];
    foreach ($nids as $nid) {
      if (isset($nodes[$nid])) {
        $titles[] = $nodes[$nid]->label();
      }
    }
    return new JsonResponse($titles);
  }

}
