# Validation status

Graders are tested against their own reference solutions (must PASS) and
against raw/insufficient submissions (must FAIL on the intended stage) —
the suite applies its own "test the smoke detector" rule to itself.

All 15 tasks are validated; details for each addition are in the dated
sections below.

| Task | Grader self-test | Validated |
| --- | --- | --- |
| e-01-decoder-roundtrip | reference PASS · fixture FAIL (unit) | ✅ 2026-07-16 |
| e-02-impossible-states | reference PASS · fixture FAIL (impossible_states) | ✅ 2026-07-16 |
| b-01-write-e2e | reference PASS · lazy-test FAIL (broken_detected) · empty FAIL (has_tests) | ✅ 2026-07-16 |
| d7-01-menu-endpoint | reference PASS · fixture FAIL (permission/403/json) | ✅ 2026-07-16 |
| d10-02-cache-bug | reference PASS · seeded-bug fixture FAIL (behavior) | ✅ 2026-07-16 |
| d7-03-field-migration | reference PASS · no-revisions variant FAIL (data_normalized) · fixture FAIL (update_ran) | ✅ 2026-07-16 |
| d7-05-save-trigger-queue | reference PASS · no-dedup variant FAIL (queueing/dedup) · fixture FAIL (behavioral) | ✅ 2026-07-16 |
| e-06-unicode-length | reference PASS · String.length variant FAIL (unit) · fixture FAIL | ✅ 2026-07-17 |
| d10-04-cache-context-leak | reference PASS · no-user-context variant FAIL (per_user) · fixture FAIL | ✅ 2026-07-17 |
| d10-05-query-access-leak | reference PASS · accessCheck(FALSE) variant FAIL (no_leak) · fixture FAIL | ✅ 2026-07-17 |
| e-07-tagged-union-decode | reference PASS · oneOf variant FAIL (unit) · fixture FAIL | ✅ 2026-07-17 |
| e-08-muac-classify | reference PASS · <= variant FAIL (boundary unit) · fixture FAIL | ✅ 2026-07-17 |
| d7-06-node-access-grants | reference PASS · hook_node_access variant FAIL (both scoped stages) · fixture FAIL | ✅ 2026-07-17 |
| d7-07-batched-update | reference PASS · one-pass variant FAIL (batched) · fixture FAIL | ✅ 2026-07-17 |
| d7-08-multilingual-field | reference PASS · LANGUAGE_NONE variant FAIL (translated) · fixture FAIL | ✅ 2026-07-17 |

## Grader-development findings (kept because they're the point)

- **d7-01:** the first reference solution used `'delivery callback' => 'drupal_json_output'`
  directly — anonymous users got HTTP 200 with body `3` (MENU_ACCESS_DENIED json-encoded)
  instead of a 403. The anon_403 probe caught the suite author in the exact D7 paradigm
  trap the lane measures. Fixed with a delivery callback that routes integer menu-status
  results through standard delivery. Task retiered 1 → 2.
- **d10-02:** the render harness originally rendered the bare plugin build; without
  `#cache keys` Drupal never creates a render-cache entry, so the seeded staleness was
  invisible and the buggy fixture passed. The harness now wraps the build with keys the
  way core's BlockViewBuilder does; cacheability bubbles up and both directions grade
  correctly.

## Matrix-day grader fixes (2026-07-16, all re-graded from preserved workspaces)

- **Contract-only grading:** the authorized_json probe hardcoded the page-callback
  *function name*; both models legitimately chose another name and were failed
  unfairly. The probe now resolves whatever callback the module registered via
  `menu_get_item()`. Rule: grade only what task.md contracts.
- **Canonicalized workspace paths:** grade.sh cd's into the eval site mid-run;
  called with a relative workspace path it wrote grade.json/receipts into the
  site tree while stale originals were being read. Workspace arg is now
  canonicalized on entry. (Cost: ~an hour of chasing phantom flakiness.)
- **Shared-fixture state reset:** each grade now disables the module, replaces
  files, clears caches, then enables — grades are order-independent; the anon
  HTTP probe retries once to ride out router rebuilds.
- **Outcome:** d7-01 final: fable-5 3/3 (correct custom delivery callback each
  time), opus-4-8 1/3 (2 trials hit the drupal_json_output/403 trap — the same
  one that caught the suite author).

## d7-03-field-migration (added 2026-07-16 → suite 0.1.1)

Three-way self-test: reference PASS · forgot-the-revisions variant FAIL on
exactly data_normalized · raw fixture FAIL on update_ran. One grader fix
during validation: `drupal_get_installed_schema_version()` needs
`includes/install.inc` loaded explicitly in a php-script bootstrap.
Run result: 11/12 across four models (haiku 2/3; its failing run errored
during updb and left data unnormalized) — the d7-01 staircase did NOT
reproduce, refining the finding from "legacy is hard" to the trap-density
hypothesis. Records before d7-03 carry suite 0.1.0; the table is regenerated
over both — treated as one suite since no earlier task changed.

## d7-05-save-trigger-queue (added 2026-07-16 → suite 0.1.1)

Modeled on the most common backend pattern in a real production D7 health
platform: node-save → deduplicated DrupalQueue item → hook_cron worker
recomputing per-clinic totals via EntityFieldQuery into variables. Four
paradigm-trap axes stacked (QueueWorker/State API/entityQuery instincts,
plus idempotency). Three-way self-test: reference PASS with exact state
transitions · no-dedup variant FAIL on queueing/dedup · fixture FAIL on all
behavioral stages. Logged here retroactively 2026-07-18 — the self-test ran
before the matrix (recorded in commit df2421d) but this file wasn't updated.
Run result: 12/12 across four models.

## v0.2 trap tasks (added 2026-07-17 → suite 0.2.0)

Design rule extracted from d7-01's anatomy: a discriminating task needs a
popular-but-wrong consensus pattern, a bug living in framework interaction,
happy-path camouflage, and a spec written at the observable layer.

- **e-06-unicode-length**: reference PASS · String.length variant FAIL (unit)
  · fixture FAIL. The holdout's astral/ZWJ/niqqud cases catch the UTF-16 trap.
- **d10-04-cache-context-leak**: reference PASS · tags-but-no-user-context
  variant FAIL on exactly per_user (cross-process cache poisoning reproduces
  through the keyed-wrapper harness with account switching) · fixture FAIL.
- **d10-05-query-access-leak**: reference PASS · accessCheck(FALSE) variant
  FAIL on exactly no_leak · fixture FAIL. **Author-catch #3:** the first
  reference used accessCheck(TRUE) alone and still leaked — on sites without
  node-access modules it checks the permission, not per-node published
  status; the correct solution needs the status condition too. The task
  therefore has two camouflage layers: the naive pattern AND the
  sophisticated-looking fix are both wrong.

## v0.2 matrix-day notes (2026-07-17)

- **Author-catch #4 (harness):** Fable's d10-04 solutions declared cacheability
  via the canonical plugin methods (getCacheContexts()/getCacheTags()); the
  render harness only merged inline #cache and wrongly failed them. Fixed to
  merge plugin-level metadata like core's BlockViewBuilder; all 12 workspaces
  re-graded (records marked "regraded"). Post-fix: fable/opus/sonnet 3/3.
- haiku d10-04 t3 classified: not a cache failure — build() crashes on a
  D10 entityQuery missing accessCheck() (empty render receipts). Genuine fail.
- e-06 12/12: the String.length trap is too well-documented to discriminate.

## v0.3 complex trap tasks (added 2026-07-17 → suite 0.3.0)

Five tasks engineered to the d7-01 recipe (canonical-looking-but-wrong),
weighted toward warning-poor D7. All self-tested three ways.

- **e-07 tagged-union-decode**: reference PASS · oneOf variant FAIL (unit, the
  "gotcha" case: malformed visit silently becomes a Note) · fixture FAIL.
- **e-08 muac-classify**: reference PASS · <= variant FAIL (boundary unit) ·
  fixture FAIL. Author-error caught: miscounted the summarize holdout.
- **d7-06 node-access-grants** (flagship): reference PASS · runtime-hook_node_access
  variant FAIL (both scoped stages — it leaks every center's records to every
  user through listing queries, the exact production footgun) · fixture FAIL.
  First try, no author-catch.
- **d7-07 batched-update**: reference PASS (3 passes, maxdelta 50) · one-pass
  variant FAIL on exactly `batched` (maxdelta 120) · fixture FAIL. Grader
  detects batching mechanically via per-pass progress deltas.
- **d7-08 multilingual-field**: reference PASS · LANGUAGE_NONE-hardcode variant
  FAIL on exactly `translated` · fixture FAIL. **Author-catch #5:** the first
  contract demanded '' for an unavailable language, but field_get_items()
  resolves through Field API language fallback and returns an available value
  — the API fought the naive contract. Fixed to test a truly-empty node.

## v0.3 matrix results (2026-07-17)

Frontier models 45/45 across all five engineered traps; haiku 13/15 (one
grants leak, one batched-correctness miss). No second discriminator found —
the deliberately-hunted traps are all well-warned in the corpus. d7-01
remains unique. Infra audit of the resumed d7-08 cells: clean (normal
durations/costs/exit codes).

## Receipt-hygiene events (voided runs)

Two batches of receipts were voided — kept out of runs.jsonl and every table:

- **Claude session-limit poisoning:** nine runs during a session-limit window
  were instant refusals recorded as fails. Voided; the runner now greps the
  transcript for the limit banner and aborts the whole matrix (exit 3).
- **Gemini daily-quota poisoning:** nine zero-second runs after the paid-tier
  250 req/day cap. The adapter flagged them (exit 99) but the runner ignored
  it; voided, and the runner now treats exit 99 as a matrix abort.

Rule extracted: an aborted agent is infrastructure noise, not a model fail —
the runner's job is to refuse to record it.
