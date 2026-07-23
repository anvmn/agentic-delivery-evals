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

- **Adapter-failure poisoning (OpenAI onboarding):** the codex adapter's first
  invocation failed on a missing execute bit and the runner recorded pass=false.
  Voided; the runner now aborts the matrix on any adapter error object and
  preserves stderr forensics before voiding the workspace.

- **Cost-metering correction (OpenAI):** the Codex event schema reports
  reasoning tokens in a separate `reasoning_output_tokens` field; the first
  four OpenAI receipts under-billed by ~10%. Re-metered from transcripts,
  records marked `remetered`.

- **Per-model usage-limit poisoning (2026-07-20):** a clean-room re-run of
  d7-01 hit a per-model cap and Claude returned `api_error_status: 429`,
  "You've reached your Fable 5 limit" — with `is_error:true`, one turn, $0.
  The session-limit grep only matched "hit your session limit|usage limit",
  so three Fable runs were recorded as false fails. Voided; the abort guard
  now also matches `reached your <Model> limit` and `api_error_status` 429/
  401/403.

Rule extracted: an aborted agent is infrastructure noise, not a model fail —
the runner's job is to refuse to record it. And a receipt is only as honest
as its parser — meter fields are verified against the provider's schema
before a lab's numbers are published.

## Environment-contamination audit (2026-07-20)

Prompted by a spoken-answer TTS footer appearing in a *Fable* d7-01 transcript
— a line that comes from the operator's global `~/.claude/CLAUDE.md`. Probed a
headless `claude -p` with a direct canary:

- It DOES load the operator's user `CLAUDE.md` (the footer instruction).
- It does NOT load auto-memory: asked point-blank, it answered "I have no
  memory files about you or a d7-01 task." So the operator's memory — which by
  then described this exact trap — never reached the eval agents.

Impact on results: none. The grader reads only `healthstats.module`, never the
agent's prose; the only inherited content was the (coding-irrelevant) TTS
footer; and only 1 of 4 Claude models passed d7-01, which is itself proof the
answer didn't leak (a loaded memory would have lifted all four). Added a
reproducible clean-room mode anyway — `CLAUDE_CLEAN_ROOM=1` passes
`--setting-sources project,local`, dropping user `CLAUDE.md`/memory while
keeping auth; receipts carry `clean_room:true` and `report.sh` filters them
out of the headline scoreboard.

**Clean-room confirmation (2026-07-21):** once Fable's usage limit reset, ran
d7-01 × Fable × 3 with `CLAUDE_CLEAN_ROOM=1` — **3/3 pass, every grader stage
green**, matching the original 6/6. Fable's d7-01 result is the model, not the
operator's config.

## Author-catch #6 — the d7-01 grader checked output, not delivery (2026-07-20)

Tracing Haiku's single blind d7-01 "pass" exposed a grader gap, not a real
solution. That run used `drupal_json_output(); drupal_exit();` *inside* the page
callback — the print+exit pattern criterion #3 forbids — and passed only because
`drupal_exit()` terminated the `authorized_json` probe after the JSON printed but
before the probe's own trailing output could invalidate it (captured `{...}` vs
the echo-no-exit variant's `{...}null`). A second variant surfaced in the
live-site experiment (`drupal_json_output(); return $data;`): the return value
satisfied the old shape check while a real authorized request would emit JSON
followed by an HTML render.

Fix: the `authorized_json` stage now wraps the page-callback call in an output
buffer and passes only when (a) a completion MARKER is reached — a callback that
`exit()`s never gets there — AND (b) the buffer is empty (no print/echo) AND (c)
the RETURN value is `{users:int, nodes:int}`. This enforces "deliver via the
return value / a delivery callback, not print+exit."

Self-test: reference **PASS** · print+exit variant **FAIL** (authorized_json) ·
print+return variant **FAIL** (authorized_json) · delivery-trap **FAIL**
(anon_403, unchanged). Re-graded every preserved d7-01 workspace (blind, effort,
live-site): exactly two flips, both Haiku, both the print shortcut — **Haiku
blind 1/6 → 0/6**, **Haiku live-site 2/3 → 1/3**. Fable/Opus/Sonnet/Sol/Gemini-Pro
use the return-array pattern and were unaffected. Flipped/refreshed records carry
`grade.regraded_c3 = true`.

Lesson: a mechanical grader that checks only the observable OUTPUT can pass a
solution that violates a stated criterion about HOW the output is produced. The
suite's own thesis — looks-right-but-isn't — applies to graders too. (Bug hit en
route: `ddev` inside a `while read` loop drained the loop's stdin, so a first
re-grade pass silently processed only one workspace; fixed with `mapfile` + a
`</dev/null` on the grader call.)

## Author-catch #7 — d10-05 never verified "newest first" (2026-07-21)

Found in review, not by the grader: running the gen-vs-recognition experiment,
GPT-5.6 Sol (and independently Opus and Sonnet) flagged that d10-05's endpoint
sorts the query `created DESC` but then iterates `loadMultiple()`, which returns
entities keyed by id in storage order — so the "5 **newest** titles" ordering
can be silently discarded. The old grader only checked *membership* (are the
published titles present), never order.

Honest journey worth recording: I first called this "confirmed real," then the
self-test made me retract it — the *reference* actually preserves order
(loadMultiple happened to keep it for the seed), so the reference isn't buggy.
But adding an order stage and re-grading the matrix flipped **6 real solutions**
(2 Haiku, 4 Sol) that genuinely returned wrong order and had been passing
spuriously — so the grader gap was real even though the reference was fine.
**d10-05 authoring: Haiku 2/3→0/3, Sol 2/3→0/3; Fable/Opus/Sonnet stay 3/3.**

Fixes: grader now (a) resets the notice table before seeding (it had
accumulated `Notice-*` nodes that outranked the seed), (b) seeds with distinct
future-relative created times so newest-first is unambiguous, (c) asserts the
newer Pub-B precedes the older Pub-A (`correct_order`). Reference reindexes by
the sorted ids as a defensive guarantee. Self-test: fixed reference PASS;
delivery-leak variant FAIL (no_leak); wrong-order solutions FAIL (correct_order).
Records carry `grade.regraded_order`. Meta-point: a model *reviewer* caught a
requirement the mechanical grader never checked — the constructive flip side of
"review inherits blind spots."

## Author-corrected claim — the echo pattern works over HTTP (2026-07-21)

The suite's prose described the d7-01 echo pattern (`drupal_json_output()`
inside the page callback, NULL return) as producing "JSON followed by a stray
page-not-found." **False — falsified two ways** while analyzing the
verified-review experiment: (1) reading `drupal_deliver_html_page()` in core —
a NULL result is neither an int (no 404/403 switch) nor `isset` (no HTML
render), so delivery ends cleanly, and core's own comment blesses the pattern
("NULL … likely indicates that it printed something"; `user_autocomplete` works
this way); (2) deploying the canonical echo submission and observing the
authorized path over real HTTP: `200` + `application/json` +
`{"users":1,"nodes":13}`, with anonymous still 403.

Grader ground truth is unaffected — criterion #3 mandates delivery via the
return value and the native delivery architecture, and the hardened
`authorized_json` stage (author-catch #6) enforces exactly that; the six echo
solutions still fail it. What changes is the *framing*: the echo pattern is a
working endpoint that violates an explicit spec clause, not a broken endpoint —
corrected in README.md and the experiment writeups. Blind reviewers who
approved it were extending a genuine core precedent over the spec's text; that
distinction shapes the verified-review experiment's interpretation (a runtime
can only arbitrate what behavior can falsify).

## Author-catch #8 — criterion #3's wording permitted the echo reading (2026-07-21 → suite 0.3.1)

Found BY the verified-review experiment: with a live site in hand, 9 of 12
reviewer sessions approved the echo-pattern submission, and their stated
reasoning was *textually sound* — "JSON is delivered as JSON … using D7's
native delivery mechanism — not `print` + `exit`" is satisfiable by
`drupal_json_output()` inside the page callback (a native function; nothing
prints-and-exits), especially given core's own `user_autocomplete` precedent
and the (verified) fact that the endpoint behaves correctly over HTTP. The
grader has enforced the *intended* architecture since author-catch #6
(return the array, zero printed bytes); only the spec text lagged.

Fix: criterion #3 rewritten in `task.md` (and the live-site variant) to state
the enforceable contract — the page callback **returns** the data array and
emits no output itself; JSON conversion belongs to the delivery layer. Suite
0.3.0 → 0.3.1. No grading logic changed and no records re-graded; all
existing d7-01 runs and all review experiments measured against the pre-0.3.1
wording, which is part of those experiments' findings (reviewers split on an
ambiguity that genuinely existed). Meta-point, twin to author-catch #7: the
verified-review harness surfaced a *spec* defect this time — each layer of
model scrutiny has now caught a different class of author error (grader gap,
missing check, ambiguous wording).

## OpenRouter column: adapter, metering, and two receipt-hygiene events (2026-07-21/22)

Added `runner/agents/openrouter.sh` — codex CLI against OpenRouter's
Responses API (`model_provider=openrouter`; codex 0.144.5 dropped
chat-completions support entirely). Column: x-ai/grok-4.5,
moonshotai/kimi-k2.7-code, qwen/qwen3-coder-next, deepseek/deepseek-v3.2 on
the 7-task Gemini-parity set, n=3.

- **Metering correction (caught by the operator reconciling the provider UI):**
  the first formula priced all input tokens at the full prompt rate; ~90% of
  an agent loop's input is cache reads billed at 8–50% of that. All 34
  affected records re-metered from transcripts with cache-aware pricing
  ($3.63 → $1.76 receipts), marked `cost_remetered:true`; batch totals now
  reconcile with the provider's server-side dollar counter. Known gap:
  Grok's >200k-prompt price override is unmodeled.
- **Write-while-exec abort (self-inflicted):** patching the adapter file
  non-atomically mid-batch let one exec read a half-written file; the runner
  correctly voided the cell and aborted (no bogus records). Rule adopted:
  adapter mutations are atomic (write-temp + mv) or wait for the batch.
- **stdin-drain fix, swept across the class:** codex blocks on a non-tty
  stdin ("Reading additional input from stdin..."); `</dev/null` pinned in
  BOTH codex-based adapters — codex.sh had been surviving on lucky plumbing.

## Author-catch #9 (candidate, pending re-grade approval) — return-without-delivery (2026-07-22)

qwen3-coder-next's lone d7-01 "pass" returns the correct array from the page
callback but registers NO delivery mechanism at all — no delivery callback,
no drupal_json_output anywhere. Over real HTTP an authorized user gets a
themed HTML page, not JSON; criteria #1/#3 are violated but the hardened
authorized_json stage (author-catch #6) passes it, because #6's check is
in-process (return shape + zero printed bytes) and never observes the
authorized path over HTTP. #6 closed print-without-return; this is its exact
mirror. Proposed fix: behavioral authorized-HTTP probe (temporarily grant
the permission to anonymous, curl, assert status/Content-Type/shape, revoke
in a trap) + full d7-01 re-grade sweep. Held for operator approval since it
changes ground truth.

## Effort + live-site arms for the OpenRouter column (2026-07-22)

- **Effort arm:** d7-01 × grok-4.5/kimi-k2.7-code/deepseek-v3.2 × 3 at
  `model_reasoning_effort=high` (recorded `effort:"high"`, filtered from the
  headline table): **0/9 — every run the delivery trap** (anon_403), identical
  to default effort. With Sol's earlier xhigh arm: 12 high-effort runs across
  four labs, 12 trap failures, zero cures.
- **Live-site arm:** same adapters, tightened-0.3.1 task wording (earlier
  cohort saw pre-0.3.1 — noted for comparability): grok 3/3 (2 probes/trial),
  deepseek 3/3 (13–17 probes), kimi 2/3 (its miss probed once and submitted),
  qwen 2/3 on retry (below).
- **Receipt-hygiene: qwen tool-protocol collapse.** First qwen live-site
  batch died at 0 turns — hallucinated tool names (`read_file`) and malformed
  call args; codex's router rejected every call. Voided 3 records as
  infra-class (they answer "can it speak the protocol", not "does testing
  rescue"). Retry: 2/3 pass with residual protocol errors in stderr (flaky,
  not deterministic); the fail is a timeout mid-iteration in the trap after
  10 probes (truncated transcript zeroed its cost meter — known loss).

## Author-catch #9 EXECUTED — behavioral authorized-HTTP probe + full re-sweep (2026-07-22)

Grader change: after the in-process return check, grade.sh now grants the
contracted permission to anonymous, curls the endpoint, asserts
200 + application/json + exactly {"users":<number>,"nodes":<number>}, and
revokes unconditionally. New stage `authorized_http`; pass requires it.

Four-way self-test: reference PASS (all six stages) · return-without-delivery
variant (qwen's matrix module) FAIL on exactly authorized_http · echo variant
FAIL on exactly authorized_json (its authorized_http is TRUE — consistent
with the 2026-07-21 falsification that the echo pattern works over HTTP) ·
delivery-trap variant FAIL on exactly anon_403.

Re-sweep: all 93 preserved d7-01 workspaces (matrix incl. clean-room and
effort arms, both live-site cohorts); records updated with
`grade.regraded_http:true`. **Four flips, all in the OpenRouter column:**

- matrix qwen t1 (the catch's trigger) → fail. New-column blind d7-01 is a
  clean 0/12.
- live-site deepseek t3 and qwen t1/t3 → fail. All three modules have zero
  delivery wiring; all failed exactly authorized_http.

**Probe blind-spot finding:** the live-site probe.sh reports the anonymous
HTTP status and the page callback's return value — both look perfect for a
delivery-less solution — so three agents "tested their way" into the same
hole the old grader had (deepseek probed 13× on its failing trial).
Corrected live-site column: grok 3/3 · kimi 2/3 · deepseek 2/3 · qwen 0/3
(7/12; the earlier Claude/Sol cohort is unchanged). The probe is left as-is
deliberately — the blind spot is now part of what the experiment measures;
future cohorts would need a probe that also exercises the authorized path
over HTTP. Meta-point: verification cures exactly what the verifier can
observe; agents inherit the harness's blind spots.

Historical passes all survived the sweep (Fable's 6/6 + clean-room 3/3,
Opus 1/6, Sonnet/Sol/Gemini live-site passes) — every one wires real
delivery. No pre-column record changed.

- **K3 429-poisoning (2026-07-22):** four kimi-k3 column runs hit codex's
  "exceeded retry limit, last status: 429 Too Many Requests" against the
  five-day-old model's constrained serving, dying mid-run with the turn
  counter at 0 ($0 metered). All four had done partial work before the
  kill (turn.failed voids the turn count, not completed items — an
  author-error nearly voided a passing run on a false "no work" claim,
  caught within minutes by the pass/zero-turn contradiction). Policy
  applied: e-01 t3's PASS stands (the interruption did not prevent
  completion — the artifact passes the grader); the three fail-state
  interrupted runs (b-01 t3, d10-04 t3, d7-01 t3) are voided and re-run —
  a 429 kill is not a fair fail because the turn budget was never
  exhausted (unlike a timeout, which counts). The 429/retry pattern joins
  the openrouter.sh refusal guard once the running batch frees the
  adapter file.

- **Timeout-truncated metering undercount (2026-07-23):** live-site runs
  killed by the task timeout report turns:0/$0 — codex emits usage with
  turn completion, which the SIGTERM prevents. Verified these are true
  timeouts (no 429/error events in transcripts; 7–17 probe invocations of
  real work), so per the standing rule they COUNT as failures (budget
  fairly exhausted) — distinct from the K3 429-kill class, which voids.
  Receipts undercount those runs' dollar cost; provider-counter
  reconciliation covers the gap at program level.

- **Author-corrected over-claim (2026-07-23):** recent doc edits hardened the
  effort finding to "never saves them / 0/21" — falsified by our own
  receipts: pooled d7-01 effort runs are 5/27, the passes being Fable @max
  3/3 (passes blind anyway — not a rescue) and **Opus @max 2/3, a genuine
  partial rescue** (blind 1/6). The original wording ("usually doesn't save
  them") was right; the hardened version was mine and wrong. Corrected
  everywhere to: raised effort has rescued exactly one blind-failer,
  partially (Opus); the other eight blind-failing models are 0/24 at raised
  effort. Also: K3 live-site arm is capacity-blocked (1 recorded timeout
  fail, 5 voided 429 trials) — marked pending, not zero.

## Re-grade-era artifact RETRACTED — the #7 sweep graded against a dead site (2026-07-23)

Operator question ("how come Sol failed all its d10-05 attempts?") exposed
that all six Sol and three Haiku d10-05 records carried the signature of a
grading-time outage: route_ok false (endpoint never responded), no_leak
passing vacuously, everything downstream cascade-failing. Live re-grades of
all nine preserved workspaces: **Sol 4/6, Haiku 2/3** — the three genuine
failures are all no_leak (the sophisticated-looking accessCheck-without-
status-condition pattern; author-catch #3's trap claiming real victims).
Six records corrected (`grade.regraded_audit`).

**Author-catch #7 partial retraction:** the ordering gap was real — the
grader didn't check newest-first, and the flawed-variant self-test proves
the new stage catches violations — but the claim that "6 real solutions
were passing spuriously" is RETRACTED: those six "order failures" were the
outage cascade, and every audited solution passes correct_order live
(they iterate over the sorted ids). The check stays; the victim count was
zero. Origin of the outage window is unrecovered (the d7/d10 sites share
one ddev daemon; the sweep ran amid heavy site churn). Prevention: the
d10-05 grader now refuses to grade when the site is unreachable (exit 3,
no grade.json) instead of recording cascade failures as ground truth.

Scoreboard impact: Sol d10-05 0/3→2/3 ·2 rounds→4/6; Haiku 0/3→2/3. The
"d10-05 authoring: Haiku 2/3→0/3, Sol 2/3→0/3" line in the #7 entry above
is superseded by this section.

## Full-ledger cascade audit — clean (2026-07-23)

Prompted by the d10-05 retraction: swept every FAIL record in both grade
ledgers (matrix + live-site) for the outage fingerprint. Method note: a
naive "all stages false" scan finds nothing — negative checks like no_leak
pass *vacuously* against a dead endpoint (exactly how the d10-05 artifact
hid). The correct signature is **entry-stage false** (enable / route_ok /
compile / first behavioral stage): once the entry observation fails,
every downstream value is unreliable regardless of what was recorded.

Result: two candidates in 385 runs — haiku d7-03 t1 and haiku d7-07 t1.
Both re-graded live against a verified-up site: **both reproduce their
failures exactly** (updb error → update_ran; a real correctness bug).
No further outage victims. The nine d10-05 corrections stand as the full
extent of the artifact.

Scope honestly stated: this audit covers outage-fabricated FAILURES.
Wrong-direction PASSES are covered by the separate self-test + author-catch
regime (that is how #6 and #9 were found); review-experiment verdicts have
no grading-infra dependency (parse errors are recorded, visible, and
excluded from rates); spend is reconciled against provider counters.

- **Opus live-site arm (2026-07-23, operator-prompted):** the original
  cohort omitted Opus with no recorded rationale despite it qualifying
  (1/6 blind). Run at n=6, clean-room: **6/6 pass, 1–3 probes per trial.**
  Completes the within-model comparison — blind 1/6, max effort 2/3, live
  probe 6/6 — the suite's cleanest observation-beats-introspection result.
