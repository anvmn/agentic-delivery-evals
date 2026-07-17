<?php

namespace Drupal\notice_api\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;

/**
 * Lists the newest notices as JSON — FLAWED self-test variant: accessCheck(FALSE), the pattern pasted
 * from a thousand examples — leaks unpublished content to anonymous.
 */
class NoticeListController extends ControllerBase {

  /**
   * GET /api/notices.
   */
  public function list(): JsonResponse {
    $nids = $this->entityTypeManager()->getStorage('node')->getQuery()
      ->condition('type', 'notice')
      ->accessCheck(FALSE)
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
