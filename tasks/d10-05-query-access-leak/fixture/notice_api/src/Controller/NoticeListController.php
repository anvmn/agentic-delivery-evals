<?php

namespace Drupal\notice_api\Controller;

use Drupal\Core\Controller\ControllerBase;
use Symfony\Component\HttpFoundation\JsonResponse;

/**
 * Lists the newest notices as JSON.
 */
class NoticeListController extends ControllerBase {

  /**
   * GET /api/notices — implement per task.md.
   */
  public function list(): JsonResponse {
    // TODO: implement per task.md.
    return new JsonResponse([]);
  }

}
