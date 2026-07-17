<?php

namespace Drupal\notice_api\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;

/**
 * Lists the newest notices as JSON — reference solution (self-tests only).
 *
 * Two load-bearing lines, not one: accessCheck(TRUE) alone does NOT filter
 * unpublished nodes on sites without node-access modules (it checks the
 * 'access content' permission, not per-node status) — the status condition
 * is also required. The grader caught the suite author on this.
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
