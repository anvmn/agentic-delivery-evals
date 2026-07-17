# Task: public notices API (Drupal 10)

## Goal

Implement the `notice_api` module's controller: `GET /api/notices` returns a
JSON array of the **5 newest notice titles the requesting user is allowed to
view**.

## Context

Drupal 10. The route is already defined in `notice_api.routing.yml` (public
route, controller method `NoticeListController::list()`) — implement the
controller method. The *notice* content type exists on the target site.

## Acceptance criteria

- [ ] Returns HTTP 200 with a JSON array of up to 5 title strings, newest
      first.
- [ ] **Respects access control**: the response must never include content
      the requesting user cannot view — an anonymous visitor must not see
      unpublished notices, no matter what else changes on the site.
- [ ] `php -l` passes; Drupal coding standards style.

## Out of scope

- Response caching (return a plain `JsonResponse`).
- Pagination, filtering, other entity types, new routes.

## Commands

There is no site in this workspace — implement against documented Drupal 10
entity APIs.

```bash
php -l src/Controller/NoticeListController.php
```
