# Task: batched update hook (Drupal 7)

## Goal

The `bulknorm` module stores *item* nodes whose `field_code` values are
lowercase. Write **`hook_update_7100`** in `bulknorm.install` that uppercases
every stored `field_code` value — **batched**, processing **at most 50 items
per invocation**, using the `$sandbox` mechanism so it survives large data.

## Context

Drupal **7**. `drush updb` (and update.php) calls an update hook repeatedly,
passing a `&$sandbox` array, until the hook sets `$sandbox['#finished'] >= 1`.
The hook must:

- On the first call, initialise progress tracking in `$sandbox` (total count,
  progress, a cursor).
- On each call, process **no more than 50** items, advance the cursor, and
  set `$sandbox['#finished']` to `progress / total` (and `1` when done).

A one-shot update that transforms everything in a single call "works" on a
handful of rows but violates the batching contract that exists precisely so
the update does not exhaust memory/time on a real dataset. That is the error
this task checks for.

## Acceptance criteria

- [ ] After the update completes, every `field_code` value is uppercased.
- [ ] No item is processed more than once; the count is preserved.
- [ ] **At most 50 items are transformed per invocation** of the hook.
- [ ] `$sandbox['#finished']` progresses below 1 until done, then reaches 1.
- [ ] `php -l` passes; do not modify `hook_install()`.

## Out of scope

- Node revisions handling beyond current values, UI, other fields.

## Commands

There is no site in this workspace — write to documented Drupal 7 update-hook
/ `$sandbox` APIs.

```bash
php -l bulknorm/bulknorm.install
```
