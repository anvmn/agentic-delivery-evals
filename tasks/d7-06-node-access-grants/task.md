# Task: per-center record access (Drupal 7)

## Goal

Records belong to a health center; a user may only see records from **their
own** center — and this restriction must hold for **listings and queries**,
not only when viewing a single node.

## Context

Drupal **7**. The fixture's `hook_install()` (do not modify) creates:

- content type `record`, with integer field `field_center_id`
- integer field `field_user_center` on the **user** entity

Implement the access logic in `recordaccess.module`. A user with
`field_user_center = N` may view a `record` node iff its
`field_center_id = N`.

## The critical requirement

The restriction must apply to **database listing queries** — e.g. a
`db_select('node', 'n')->addTag('node_access')` that powers any list of
records — so that a user's listing never includes another center's records.

In Drupal 7, `hook_node_access()` alone does **not** do this: it gates
`node_access()` checks (single-node view/edit) but leaves listing queries
untouched, so lists still leak every center's records. Node **access
grants** (`hook_node_grants()` + `hook_node_access_records()`) are what
filter queries. Implement those.

## Acceptance criteria

- [ ] A `node_access`-tagged query, run as a user, returns exactly the
      `record` nodes of that user's center — no others.
- [ ] Two users in different centers each see only their own center's
      records; neither sees the other's.
- [ ] Grants are written for records (via `hook_node_access_records`) and
      resolved for accounts (via `hook_node_grants`) under the `view` op.
- [ ] `php -l` passes on module files.

## Out of scope

- Edit/delete grants (view only), the admin/bypass user, UI, unpublished
  records.

## Commands

There is no site in this workspace — implement against documented Drupal 7
node access APIs.

```bash
php -l recordaccess/recordaccess.module
```
