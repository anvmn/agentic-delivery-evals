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
agent to test and iterate. The final grade is still the blind 5-stage grader.
Agents run clean-room (`--setting-sources project,local`). `probe.sh` was
self-tested first: correct module → anon **403**; delivery-trap module → anon
**200, body `3`**.

## Result — Sonnet 5 (2026-07-20)

Sonnet is **0/6 on d7-01 blind**. With a live site to test against: **2/3.**

| trial | result | probes | turns | note |
| --- | --- | --- | --- | --- |
| 1 | **PASS** | 2 | 22 | tested, saw the failure, fixed it |
| 2 | **PASS** | 3 | 33 | tested, iterated to green |
| 3 | FAIL | 1 | 8 | probed once, quit early — shipped the echo-mode bug (`drupal_json_output()` inside the page callback, no return) → fails `authorized_json` |

The mechanism is visible in the receipts: the two rescues are the trials where
Sonnet actually *used* the loop (2–3 probes, 20–33 turns); the one failure is
the trial where it barely tested (1 probe, 8 turns) and stopped before the
probe's "page callback returned: NULL" signal could bite.

**Reading.** A behavioral feedback loop rescues a model that fails blind —
*conditional on the model engaging it*. The knowledge gap is real (blind: 0/6)
but bridgeable by observation, not only by knowing the trap a priori. This is
the constructive half of the suite's "below the threshold, only behavioral
gates help": the gate doesn't just *catch* the bug, a visible gate lets the
model *fix* it. The residual failure mode shifts from "doesn't know" to
"didn't test enough."

**Caveats.** n=3, one model — preliminary. Different protocol from the blind
benchmark; not comparable to the headline scoreboard and kept out of it.
GPT-5.6 Sol and Gemini Flash (the other blind-failers) are the natural next
subjects, pending provider quota/suspension. Fable isn't a useful subject — it
already passes blind.

Receipts: [`runs.jsonl`](runs.jsonl) (`probe_invocations` = how many times the
agent chose to test).
