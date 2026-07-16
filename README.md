# agentic-delivery-evals

Coding evals for agentic work on **Drupal (7 and 10)** and **Elm** — the measurement layer of the [agentic-delivery-harness](https://github.com/anvmn/agentic-delivery-harness). Realistic tasks, mechanical grading, hidden holdouts, and a runner that executes coding agents headlessly and reports pass rates per model. Built and validated on the workflow behind a production digital-health platform.

## v0.1 results (suite 0.1.0 · 30 runs · 2026-07-16)

| task | lane | tier | claude-fable-5 | claude-opus-4-8 |
| --- | --- | --- | --- | --- |
| e-01 decoder round-trip | elm | 1 | 3/3 | 3/3 |
| e-02 impossible states | elm | 2 | 3/3 | 3/3 |
| b-01 write-the-E2E | behavioral | 2 | 3/3 | 3/3 |
| d10-02 cache invalidation | drupal10 | 2 | 3/3 | 3/3 |
| **d7-01 menu endpoint** | **drupal7** | **2** | **3/3** | **1/3** |

**The finding:** the only task that separated frontier models is the **legacy** one. Opus 4.8 fell into Drupal 7's `drupal_json_output` access-denied trap (anonymous users get HTTP 200 with body `3` — the JSON-encoded MENU_ACCESS_DENIED constant) in two of three trials; Fable 5 wrote a correct custom delivery callback in all three. The same trap caught the suite's author when writing the reference solution. Models are trained overwhelmingly on modern-framework idioms; the **paradigm-bleed hypothesis** — that agents underperform on legacy codebases whose conventions predate their training distribution's center of mass — now has its first data point. No other public eval measures agents on legacy stacks at all.

Honest caveats: n=3 trials per cell — error bars are wide, and differences under ~2 tasks are noise. Four of five tasks came back saturated (6/6), so they demonstrate competence, not separation; v0.2 grows the tier-3 end. Every number above is regenerable from `results/runs.jsonl` (receipts: stages, duration, cost, transcript per run; six d7 records are marked `regraded` after grader-fairness fixes — see [`VALIDATION.md`](VALIDATION.md)).

## How it works

```
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
