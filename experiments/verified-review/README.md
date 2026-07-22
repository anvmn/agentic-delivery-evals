# Experiment: does a runtime fix blind review?

The blind review panels erred in **both directions**:

- **d7-01** ([author × reviewer](../author-reviewer/)): reviewers *endorsed a
  spec violation*. Fable approved all 6 echo-pattern solutions it reviewed
  (0/6 catch); Haiku and Sonnet approved most of them too. (The echoed
  endpoint *functions* over HTTP — the violation is criterion #3's mandated
  delivery architecture — which makes this arm a test of enforcing an
  explicit spec clause, not of spotting breakage.)
- **e-06** ([gen-vs-recognition](../gen-vs-recognition/)): reviewers *rejected
  correct code on a hallucinated bug*. Haiku 3/3 and Sonnet 2/3 rejected the
  spotless `String.toList` reference, claiming it miscounts astral characters
  (false — it's code-point-aware), even predicting the submission's own
  passing test "will fail".

Separately, [live-site](../live-site/) showed *authors* escape the blind trap
when they can test. This experiment asks the same question for *reviewers*:
**same reviewers, same submissions, but now with a verification harness — does
empirical access fix both failure modes?**

**Design.** Each reviewer gets the submission checked out in its working
directory plus a one-command harness — e-06: `./check.sh` (runs the
submission's own `elm-test` suite); d7-01: `./probe.sh` (deploys the module to
a live Drupal 7 site, reports the anonymous HTTP status/body and what the page
callback returns). The prompt permits and points at the harness ("trust
observed behavior over recollection") but does **not** mandate running it —
whether a reviewer chooses to verify is measured (`verified_runs`). Reviewers
are told not to modify files; an md5 manifest over the reviewed files flags
tampering. Verdict contract and ground truth are identical to the blind runs.

- **e-06 arm** — panel: Fable, Sonnet, Haiku × {reference, flawed} × 3.
  (Fable's blind e-06 baseline was filled first — it wasn't in the blind
  panel.) The flawed variant's own test suite genuinely fails under
  `String.length`, and the reference's genuinely passes — so one `./check.sh`
  run directly confronts the hallucination.
- **d7-01 arm** — panel: Fable, Opus, Sonnet, Haiku × 3, reviewing the
  canonical echo-bug submission (a real Sonnet matrix solution: clean lint,
  permission, 403; page callback calls `drupal_json_output()` and returns
  NULL). One `./probe.sh` run shows the authorized path's real behavior.
  Blind, Fable/Haiku/Sonnet all approved this exact file.

Runs serially against the shared ddev D7 site for the d7-01 arm. Receipts:
[`reviews.jsonl`](reviews.jsonl); Claude reviewers run clean-room
(`--setting-sources project,local`).

## Result — verification cures what behavior can falsify, and only that

**Every reviewer chose to verify.** 30/30 recorded reviews ran the harness at
least once (one Haiku flawed-e-06 trial skipped it and still rejected
correctly); no reviewer modified a reviewed file (`tampered:false`
throughout).

**e-06 (behavioral question — does the code miscount?):**

| reviewer | reference, blind | reference, verified | flawed, verified |
|---|---|---|---|
| Fable 5 | 3/3 approve | **3/3 approve** | 3/3 reject |
| Sonnet 5 | 1/3 approve | **3/3 approve** | 3/3 reject |
| Haiku 4.5 | 0/3 approve | 1/3 approve | 3/3 reject |

The `String.toList` hallucination **did not survive contact with the
runtime**: zero verified reviews repeat the UTF-16 miscount claim. Sonnet is
fully cured — and actively so, running `elm repl` probes beyond the given
suite ("verified 👍→1, 🇮🇱→2, 👩‍👩‍👧→5") and concluding "this naive-looking
implementation is actually correct." Haiku shows the darker pattern:
**the evidence killed its reason but not its verdict** — after watching the
tests pass, the UTF-16 claim vanishes and a fresh objection appears (the
suite lacks the spec's ZWJ case — arguable spec-lawyering the rest of the
panel doesn't share). Motivated reasoning with a rotating rationale.

**d7-01 (architectural question — is echoing JSON "the native delivery
mechanism"?):**

| reviewer | echo solutions, blind (catch/seen) | echo submission, verified |
|---|---|---|
| Fable 5 | 0/6 | **2/3 catch** |
| Opus 4.8 | 0/5 (3 parse errors) | 0/3 |
| Sonnet 5 | 1/5 | 0/3 |
| Haiku 4.5 | 2/5 | 0/3 |

All twelve probed; nine still approve. And here's the honest part: **they are
not being sloppy.** Investigating the two earliest approvals, we falsified our
own prose — the echo pattern *works* over real HTTP (verified live: authorized
`200` + `application/json` + exact JSON; and `drupal_deliver_html_page()`
treats a NULL return as "callback already printed", the same pattern as core's
`user_autocomplete`). Opus's approvals state exactly that, correctly. The
probe settles every *behavioral* criterion (403 ✓, shape ✓, header ✓) — the
verdict then turns entirely on reading criterion #3's wording ("native
delivery mechanism — not print+exit"): textualists approve, intent-readers
(Fable, 2/3 — the only model that *authors* the delivery-callback
architecture unprompted) reject. A runtime cannot arbitrate a wording
dispute. That wording became **author-catch #8**
([VALIDATION.md](../../VALIDATION.md)): criterion #3 is rewritten for suite
0.3.1 to state the enforceable contract — the page callback returns the data
and emits nothing. This experiment ran against the pre-0.3.1 wording, which
is exactly what it measured.

## Reading

Blind review failed in two directions; a runtime fixed exactly one of them.
The e-06 hallucination was a **behavioral claim**, so one test run falsifies
it — approvals recover, and even the stubborn holdout has to abandon the
false fact. The d7-01 echo violation is **architectural**: the behavior is
fine, the spec's *text* is the only witness, and reviewers split on
interpretation exactly as senior humans would. Corollary for agentic review
pipelines: give reviewers a runtime and they will use it (30/30 uptake here),
but expect it to converge *behavioral* disagreements only — spec-conformance
disputes need a tighter spec, not a better sandbox.

**Caveats.** n=3 per cell; single submission per task; Claude-only panel (Sol
was right blind on e-06, so no cure to measure; codex tooling differs enough
that its absence keeps arms comparable). Two harness incidents, both logged
and neutralized: a concurrent-arm usage-limit burst voided 8 reviews
(re-run after reset; limit guard + resume added), and one verdict was
initially lost to an extraction bug (recovered from its saved transcript,
marked `backfilled_from`). Receipts: [`reviews.jsonl`](reviews.jsonl).
