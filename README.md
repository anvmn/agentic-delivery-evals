# agentic-delivery-evals

Coding evals for agentic work on **Drupal (7 and 10)** and **Elm** — the measurement layer of the [agentic-delivery-harness](https://github.com/anvmn/agentic-delivery-harness). Realistic tasks, mechanical grading, hidden holdouts, and a runner that executes coding agents headlessly and reports pass rates per model. Built and validated on the workflow behind a production digital-health platform.

## v0.1 results (suite 0.1.1 · 72 runs · 4 models · 2026-07-16)

| task | lane | tier | fable-5 | opus-4-8 | sonnet-5 | haiku-4-5 |
| --- | --- | --- | --- | --- | --- | --- |
| e-01 decoder round-trip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-02 impossible states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| b-01 write-the-E2E | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d10-02 cache invalidation | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| **d7-01 menu endpoint** | **drupal7** | **2** | **3/3** | **1/3** | **0/3** | **0/3** |
| d7-03 field migration | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 2/3 |

**The finding, refined by its own replication test:** on d7-01, four models spanning the capability range separate in a clean staircase — Fable 5 3/3, Opus 4.8 1/3, Sonnet 5 and Haiku 4.5 0/3 — while every modern-stack task is 12/12 across all four. But a second Drupal 7 task (d7-03, a *harder*-tier data migration through update hooks and revision tables) came back nearly a clean sweep: 11/12. So "legacy code is hard for AI" is the wrong lesson. The evidence so far points somewhere more specific: **what separates models isn't code age — it's idiom traps**, places where the correct legacy pattern *looks wrong* to instincts trained on modern frameworks (d7-01's delivery callback), as opposed to legacy work that is mechanical and well-documented, however fiddly (d7-03's dual-table migration). Two tasks are still two tasks; the trap-density hypothesis is what v0.2 is designed to test.

The failure modes are distinct, and all three are real Drupal 7 production hazards:

- **The delivery trap** (Opus ×2, Haiku ×3): `'delivery callback' => 'drupal_json_output'` looks canonical but delivers access-denied as HTTP 200 with body `3` (the JSON-encoded `MENU_ACCESS_DENIED` constant). The same trap caught the suite's author writing the reference solution.
- **The echo instinct** (Sonnet ×3): calling `drupal_json_output()` *inside* the page callback and returning nothing — through D7's real delivery pipeline that yields JSON followed by a 404 page (a NULL callback return means "not found"), and it violates the task's explicit return-array contract.
- Only Fable consistently wrote what D7 actually requires: a custom delivery callback that routes integer menu-status results through standard delivery.

Models are trained overwhelmingly on modern-framework idioms; the **paradigm-bleed hypothesis** — that agents underperform where legacy conventions predate their training distribution's center of mass — now has a four-model data point *and* a boundary condition from its first replication attempt. No other public eval measures agents on legacy stacks at all.

A practical corollary from the cost column of the receipts: Haiku passed every modern-stack task at $0.06–$0.11 per run — 4–8× cheaper than the frontier models on the same green results. In this suite's domains, capability spend only pays off where the training distribution runs thin.

Honest caveats: n=3 trials per cell — error bars are wide, and differences under ~2 tasks are noise. Five of six tasks are (nearly) saturated across the whole capability band, so they demonstrate competence, not separation; v0.2 grows the trap-density end. Every number above is regenerable from `results/runs.jsonl` (receipts: stages, duration, cost, transcript per run; six d7 records are marked `regraded` after grader-fairness fixes — see [`VALIDATION.md`](VALIDATION.md)).

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
