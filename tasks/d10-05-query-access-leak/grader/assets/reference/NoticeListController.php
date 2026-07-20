<?php

namespace Drupal\notice_api\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;

/**
 * Lists the newest notices as JSON — reference solution (self-tests only).
 *
 * Three load-bearing details, not one:
 *  - accessCheck(TRUE) alone does NOT filter unpublished nodes on sites without
 *    node-access modules (it checks 'access content', not per-node status) —
 *    the status condition is also required. The grader caught the suite author
 *    on this.
 *  - loadMultiple() returns entities keyed by id in STORAGE order, not query
 *    order, so iterating it loses the created-DESC sort. Re-index by $nids to
 *    keep newest-first. (Author-catch #7: a reviewer flagged this; the grader
 *    missed it.)
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
