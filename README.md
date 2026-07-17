# agentic-delivery-evals

Coding evals for agentic work on **Drupal (7 and 10)** and **Elm** — the measurement layer of the [agentic-delivery-harness](https://github.com/anvmn/agentic-delivery-harness). Realistic tasks, mechanical grading, hidden holdouts, and a runner that executes coding agents headlessly and reports pass rates per model. Built and validated on the workflow behind a production digital-health platform.

## v0.1 results (suite 0.1.2 · 96 runs · 4 models · 2026-07-17)

| task | lane | tier | fable-5 | opus-4-8 | sonnet-5 | haiku-4-5 |
| --- | --- | --- | --- | --- | --- | --- |
| e-01 decoder round-trip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-02 impossible states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| b-01 write-the-E2E | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d10-02 cache invalidation | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| **d7-01 menu endpoint** (two independent runs) | **drupal7** | **2** | **6/6** | **1/6** | **0/6** | **1/6** |
| d7-03 field migration | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 2/3 |
| d7-05 save-trigger queue | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 |

**The finding, twice refined by replication — and now test-retested:** on d7-01, four models spanning the capability range separate in a clean staircase — Fable 5 6/6, Opus 4.8 1/6, Sonnet 5 0/6, Haiku 4.5 1/6 over two independent runs a day apart — while every modern-stack task is 12/12 across all four. Two more Drupal 7 tasks then tested whether "legacy is hard" explains it. It doesn't: d7-03 (a harder-tier dual-table data migration) came back 11/12, and d7-05 — which deliberately stacks *four* legacy-API axes (DrupalQueue vs QueueWorker instincts, variables vs State API, EntityFieldQuery vs entityQuery, plus an idempotency requirement) and is modeled on the most common pattern in a real production D7 backend — came back **12/12**. Old and obscure APIs alone don't separate models. What separated them, in the one task that did, is sharper: **d7-01 is the only task where the canonical-*looking* solution is wrong** (`drupal_json_output` as a delivery callback reads like textbook D7 and silently breaks access control). The working hypothesis after three legacy tasks: models fail not where code is old, but where **plausible looks-right patterns are subtly incorrect** — and that is also precisely where unaided human reviewers fail. v0.2's task design targets exactly such looks-right-is-wrong spots, in both eras.

The failure modes are distinct, and all three are real Drupal 7 production hazards:

- **The delivery trap** (all 5 Opus failures, 3 of 5 Haiku failures): `'delivery callback' => 'drupal_json_output'` looks canonical but delivers access-denied as HTTP 200 with body `3` (the JSON-encoded `MENU_ACCESS_DENIED` constant). The same trap caught the suite's author writing the reference solution.
- **The echo instinct** (all 6 Sonnet failures, 2 of 5 Haiku failures): calling `drupal_json_output()` *inside* the page callback and returning nothing — through D7's real delivery pipeline that yields JSON followed by a 404 page (a NULL callback return means "not found"), violating the task's explicit return-array contract.
- Only Fable consistently wrote what D7 actually requires: a custom delivery callback routing integer menu-status results through standard delivery.
- **Failure modes are model-stable:** across two runs a day apart, Sonnet *always* fails by echoing, Opus *always* by the delivery trap. These read as stable per-model instincts, not coin flips — only Haiku, the smallest, mixes modes.

Models are trained overwhelmingly on modern-framework idioms; the **paradigm-bleed hypothesis** — that agents underperform where legacy conventions predate their training distribution's center of mass — now has a four-model data point *and* a boundary condition from its first replication attempt. No other public eval measures agents on legacy stacks at all.

A practical corollary from the cost column of the receipts: Haiku passed every modern-stack task at $0.06–$0.11 per run — 4–8× cheaper than the frontier models on the same green results. In this suite's domains, capability spend only pays off where the training distribution runs thin.

Honest caveats: n=3 trials per cell — error bars are wide, and differences under ~2 tasks are noise. Six of seven tasks are (nearly) saturated across the whole capability band, so they demonstrate competence, not separation; v0.2 targets looks-right-is-wrong spots. Every number above is regenerable from `results/runs.jsonl` (receipts: stages, duration, cost, transcript per run; six d7 records are marked `regraded` after grader-fairness fixes — see [`VALIDATION.md`](VALIDATION.md)).

## How it works

```text
tasks/<id>/         task.md (agent-visible spec) · fixture/ (starting state)
                    grader/ (answer key — never enters the agent workspace)
                    meta.json (lane, tier, timeout, required stages)
runner/run.sh       task × model × trial matrix over headless Claude Code
runner/report.sh    results/runs.jsonl -> RESULTS.md scoreboard
```

Design rules (full reasoning in [`SPEC.md`](SPEC.md)):

- **Mechanical grading only** — compiler, tests, linters, browser; no LLM judge in the headline score.
- **Hidden holdouts** — task.md states criteria in prose; the grader's assertions stay outside the agent workspace.
- **Pristine tests re-imposed** — "agent edits the test until green" is structurally impossible.
- **The double-fixture rule** (b-01): the agent's test must pass on the healthy app *and fail* on a seeded-broken variant. A test that can't fail is not a test — the repo includes a deliberately lazy spec that the grader correctly rejects.
- **Compile-failure as a grade** (e-02): correctness of an opaque type is proven by injected invalid code *failing* to compile.
- **Graders are self-tested both directions** — every task ships a reference solution that must pass and a flawed baseline that must fail on the intended stage ([`VALIDATION.md`](VALIDATION.md) logs what this caught, including in the suite's own reference solutions).

## Run it

```bash
# one-time fixture provisioning (Drupal cores via ddev, Playwright chromium)
tasks/d7-01-menu-endpoint/provision.sh
tasks/d10-02-cache-bug/provision.sh
tasks/b-01-write-e2e/provision.sh

runner/run.sh --models "claude-opus-4-8,claude-fable-5" --trials 3 --max-cost-usd 15
runner/report.sh
```

Requirements: ddev, node ≥ 20, elm 0.19, jq, and the Claude Code CLI authenticated. The runner's `--max-cost-usd` is a hard cap checked before every session.

## Roadmap

- **v0.2:** 15 tasks (more tier-3; the Features-module task D7-02 has no modern analogue and no public eval anywhere), 4-model matrix, and the **author × reviewer experiment**: score each model as a reviewer of the accumulated pass/fail-labeled solutions — precision/recall of rejecting broken code, self-pairs vs cross-pairs.
- Judge lane for code-quality dimensions (reported separately, never mixed into pass rates).

## License

[MIT](LICENSE) — © Anatoly Vaitsman
