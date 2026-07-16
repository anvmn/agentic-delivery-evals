# agentic-delivery-evals

> **Status: pre-results.** This repo stays private until the v0.1 scoreboard exists — an eval suite without numbers is scaffolding. See [`SPEC.md`](SPEC.md) for the full design.

Coding evals for agentic work on **Drupal (7 and 10)** and **Elm** — the measurement layer of the [agentic-delivery-harness](https://github.com/anvmn/agentic-delivery-harness). Realistic tasks, mechanical grading, hidden holdouts, and a runner that executes coding agents headlessly and reports pass rates per model.

## Layout

```
tasks/<id>/         task.md (agent-visible spec) · fixture/ (starting state)
                    grader/ (answer key — never enters the agent workspace)
                    meta.json (lane, tier, timeout, required stages)
runner/run.sh       task × model × trial matrix over headless Claude Code
runner/report.sh    results/runs.jsonl -> RESULTS.md scoreboard
```

## Run

```bash
# one-time per machine: provision heavy fixtures (Drupal cores, Playwright browsers)
tasks/d7-01-menu-endpoint/provision.sh
tasks/d10-02-cache-bug/provision.sh
tasks/b-01-write-e2e/provision.sh

# seed matrix
runner/run.sh --models "claude-opus-4-8,claude-fable-5" --trials 3 --max-cost-usd 15
runner/report.sh
```

## Honesty notes

- 3 trials per cell → wide error bars; the scoreboard must say so.
- Results are comparable only within a suite version (see `SUITE_VERSION` in run.sh).
- Every published number is regenerable from `results/runs.jsonl` — receipts or it didn't happen.

MIT — © Anatoly Vaitsman
