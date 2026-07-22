# Experiment: can the agent test its way out?

**Question.** d7-01 is run *blind* in the main suite — the agent has no site,
only `php -l`, so it must reason to the access-control trap from knowledge
alone. Models that lack that knowledge fail. But in a real workflow you'd
*test*: deploy, hit the endpoint, see the wrong status, fix it. So: does giving
a model that fails blind a live site to test against let it catch and fix its
own bug?

**Setup.** Same d7-01 spec, but the workspace ships a `probe.sh` that deploys
the agent's current module to the live Drupal 7 site and prints the real
behavior — the HTTP status and body an anonymous request gets, and what the
page callback returns for an authorized user. The task explicitly tells the
agent to test and iterate. The final grade is the standard blind grader —
including the hardened criterion-#3 check (deliver via the return value, not
print+exit), so a pass here means a genuinely-working solution, not one that
games the grader. Agents run clean-room. `probe.sh` was self-tested first:
correct module → anon **403**; delivery-trap module → anon **200, body `3`**.

## Results (2026-07-20)

Each model is a blind-failer on d7-01. Blind rates are the main-suite numbers.

| model | blind | live-site | probe pattern |
| --- | --- | --- | --- |
| Sonnet 5 | 0/6 | **2/3** | passes probed 2–3× (22–33 turns); the fail probed 1× |
| GPT-5.6 Sol | 0/3 | **3/3** | every pass probed 2–3× |
| Haiku 4.5 | 0/6 | **1/3** | the pass probed 13× (74 turns); the two fails probed 1× and 7× |

**Correctness, not just grader-pass.** After the criterion-#3 hardening (see
the main [`VALIDATION.md`](../../VALIDATION.md), author-catch #6) each pass was
read by hand:

- **Sonnet — 2/3, both genuinely correct.** Custom delivery callback with the
  `is_int()` routing (status codes → `drupal_deliver_html_page`, payload →
  `drupal_json_output`). The reference pattern, reached by iteration.
- **Sol — 3/3, all genuinely correct.** Same reference-quality pattern all
  three times. It wrote the trap blind and the textbook solution once it could
  test — the cleanest rescue of the three.
- **Haiku — 1/3.** t1 works (returns the payload through its own delivery
  callback; non-idiomatic — it disables declarative access and checks the
  permission by hand — but it delivers correctly and returns a real 403). t2
  was a print-and-return artifact (`drupal_json_output(); return $data;`) that
  passed the *old* grader; the hardened grader now fails it. t3 failed.

**Reading.** A behavioral feedback loop rescues models that fail blind —
*conditional on the model engaging it*. Every fail across all three models is a
trial that barely tested; every genuine pass came from real iteration. The
knowledge gap is real (blind: 0/6, 0/3, 0/6) but bridgeable by observation, not
only by knowing the trap a priori — and the two stronger models (Sonnet, Sol)
iterate all the way to the reference pattern. This is the constructive half of
the suite's "below the threshold, only behavioral gates help": a *visible* gate
doesn't just catch the bug, it lets a model that lacks the knowledge fix it.

**Caveats.** n=3 per model — preliminary. A different protocol from the blind
benchmark; kept out of the headline scoreboard. Fable isn't a useful subject —
it already passes blind. Gemini Flash (the remaining blind-failer) is pending
provider access.

Receipts: [`runs.jsonl`](runs.jsonl) — `probe_invocations` = how many times the
agent chose to test; `grade.regraded_c3` marks records re-scored under the
hardened grader.

## OpenRouter column (2026-07-22)

Same experiment, four new pipelines (0.3.1 task wording), thickened to
n=6 per model. Post author-catch-#9 re-grade (the probe shares the old
grader's blind spot — see below): **grok-4.5 6/6** · **kimi-k2.7-code
4/6** · **deepseek-v3.2 3/6** · **qwen3-coder-next 1/6** (plus a voided
first batch — tool-protocol collapse at 0 turns). Blind, these models go
0/15 on d7-01; with a live probe: **14/24**. Grok is the only clean
sweep — it probes exactly twice per trial and stops; DeepSeek probes
8–17× per trial and still loses half, mostly to the #9 blind spot and to
timeouts spent mid-iteration. Verification diligence has diminishing
returns when the probe can't show the failure. (Metering note:
timeout-truncated runs report $0 — codex emits usage on turn completion,
which a timeout prevents; those runs' true cost is uncounted.)

**The probe has a blind spot, and three "passes" fell into it.** probe.sh
shows the anonymous status (403 ✓) and the page callback's return value
("returns array" ✓) — both look perfect for a solution that returns the
array but wires no JSON delivery at all, which serves authorized users a
themed HTML page. The behavioral authorized-HTTP stage added by
author-catch #9 failed exactly those three runs (deepseek t3 probed **13
times** and still shipped the hole; both surviving qwen retry passes died
the same way). The dose-response among *visible* failures still holds
(passes probed ≥2×, the trap-miss probed once), but the sharper lesson
supersedes it: **testing rescues agents only from failures the harness can
show them — agents inherit their verifier's blind spots.** The probe is
left unchanged deliberately; the blind spot is part of the record.
