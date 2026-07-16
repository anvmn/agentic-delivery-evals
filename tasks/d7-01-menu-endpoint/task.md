# Task: JSON stats endpoint (Drupal 7)

## Goal

Implement the `healthstats` module for **Drupal 7**: a JSON endpoint at
`api/healthstats` returning site statistics, protected by a dedicated
permission.

## Context

This is a Drupal **7** module (`healthstats.info` says `core = 7.x`). The
skeleton is in place; implement the hooks in `healthstats.module`. Target
APIs are D7's procedural world: `hook_menu`, `hook_permission`, the D7 Field
API era. Drupal 8+ idioms (routes in YAML, controllers, services,
annotations) do not exist here and will not run.

## Acceptance criteria

- [ ] `GET /api/healthstats` returns JSON exactly of shape
      `{"users": <int>, "nodes": <int>}` — count of **active** users
      (status = 1) and **published** nodes (status = 1).
- [ ] Access requires a new permission `view healthstats` (defined via
      `hook_permission`); anonymous users without it get Drupal's access
      denied (HTTP 403).
- [ ] JSON is delivered as JSON (correct Content-Type), using D7's native
      delivery mechanism — not `print` + `exit`.
- [ ] `php -l healthstats.module` passes; code follows Drupal coding
      standards (indentation, doc comments on hooks).

## Out of scope

- Anything Drupal 8+ (routing YAML, controllers, DI).
- Caching, paging, extra endpoints.
- Do not modify `healthstats.info`.

## Commands

You are implementing against a standard Drupal 7.x core. There is no site in
this workspace — write to the documented D7 APIs.

```bash
php -l healthstats.module
```
