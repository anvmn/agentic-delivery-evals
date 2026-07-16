# Task: queued per-clinic statistics (Drupal 7)

## Goal

The `clinicstats` module tracks measurements per clinic. Implement the
save-trigger → queue → cron pipeline: saving a *measurement* node schedules
its clinic for recalculation; cron recomputes that clinic's totals.

## Context

Drupal **7**, core APIs only. The fixture's `hook_install()` (do not modify
it) creates:

- content type `measurement`
- integer field `field_clinic_id` (which clinic the measurement belongs to)
- decimal field `field_value` (the measured value)

Implement the hooks in `clinicstats.module`. This is D7: the queue API is
`DrupalQueue::get()`, cron is `hook_cron`, entity queries are
`EntityFieldQuery`, persistent values are `variable_set()`/`variable_get()`.
(D8+ concepts — QueueWorker plugins, the State API, `entityQuery` — do not
exist here.)

## Required behavior

1. **On saving a measurement** (`hook_node_insert` and `hook_node_update`):
   put one item into the queue named **`clinicstats_recalc`** for that
   node's clinic. **Never queue a duplicate**: if that clinic already has a
   pending item that cron hasn't processed yet, do not add another. Other
   node types must be ignored (and must not cause errors).
2. **Do not compute totals at save time.** Totals change only when cron runs.
3. **On cron** (`hook_cron`): process all queued items. For each queued
   clinic, recompute from scratch — using `EntityFieldQuery` — the totals
   over **published** measurements of that clinic:
   - `count`: number of published measurement nodes
   - `sum`: sum of their `field_value` values (float)

   Store as `variable_set('clinicstats_totals_<clinic_id>',
   array('count' => ..., 'sum' => ...))` and remove the item from the queue.

## Acceptance criteria

- [ ] Saving several measurements for the same clinic before cron leaves
      exactly **one** queue item for that clinic (insert *and* update paths).
- [ ] Totals variables do not exist/change until cron runs.
- [ ] After cron: queue empty; totals exact; **unpublished measurements are
      excluded** from totals (though saving one still schedules its clinic).
- [ ] A later save re-queues the clinic; the next cron updates totals
      correctly again.
- [ ] `php -l` passes on every module file.

## Out of scope

- UI, permissions, performance tuning, contrib modules (core queue only).
- Deleting nodes (no `hook_node_delete` handling required).

## Commands

There is no site in this workspace — write to documented Drupal 7 APIs.

```bash
php -l clinicstats/clinicstats.module
```
