# agentic-delivery-evals — coding evals for agentic Drupal & Elm work (SPEC)

**Status:** shipped — kept as the original pre-build design, unedited below this note. Current truth: [README](README.md) (results + roadmap), [RESULTS.md](RESULTS.md) (generated from receipts), [VALIDATION.md](VALIDATION.md) (grader log).

> **As built vs. planned (delta note, 2026-07-18):**
>
> - v0.1 shipped exactly the five planned seeds (D7-01, D10-02, E-01, E-02, B-01). After that, task selection stopped following §4's list and switched to **discriminator-hunting**: v0.2/v0.3 tasks (d7-03, d7-05…d7-08, d10-04, d10-05, e-06…e-08) were engineered to d7-01's anatomy. Planned D7-02, D10-01, D10-03, E-03…E-05 and B-02 were never built; D7-02 remains on the roadmap.
> - The difficulty ladder (§2, principle 4) did not survive contact with data: tier is a design label, not an observed difficulty — frontier models went 45/45 on the tier-3 traps, and the suite's only discriminator is a tier-2 task.
> - The runner outgrew §5: multi-lab adapter routing (Gemini CLI), effort passthrough, session-limit and provider-quota aborts with run voiding, and the `--max-cost-usd` cap (§10 Q5: yes).
> - §7 actuals: 264 default-effort runs, $90.60 total agent cost, 8 models across 3 labs (Anthropic, Google, OpenAI).
> - §8 ran, corpus-narrowed to d7-01 solutions (the only cell with meaningful fails): 95 blind reviews; results in the README.
> - §10: all six questions decided — name kept, separate repo, published after v0.1 results, 4 Claude + 2 Gemini models, 3 trials with the small-n caveat printed on every table, clean-room D7 fixture.

**Author:** Anatoly Vaitsman (drafted 2026-07-15)
**Working name:** `agentic-delivery-evals` (alternatives: `drupal-elm-agent-evals`, `harness-evals`)
**Sibling:** [agentic-delivery-harness](https://github.com/anvmn/agentic-delivery-harness) — the harness is the *process*, this is the *measurement*. Graders implement the harness's verify contract; task specs use its spec template.

## 1. Problem

Everyone running agents on production code answers "how do you know the output is good?" with adjectives. This suite answers with numbers: a versioned set of realistic coding tasks from two under-measured domains — Drupal (config-heavy CMS work) and Elm (typed functional UI with offline-first constraints) — plus a runner that executes coding agents against them and reports pass rates per model.

Three consumers, in priority order:

1. **Daily engineering:** which model to author with, which to review with, in *this* stack — decided by data, not vibes.
2. **The author × reviewer experiment (§8):** does cross-model review catch more than self-review? Nobody has published this for agentic CMS/FP work.
3. **Public artifact:** reproducible, inspectable, growing — the "how do you measure?" answer, on GitHub.

**Prior art check:** SWE-bench & derivatives (Python/JS repos), Aider/polyglot benchmarks (small algorithmic tasks), HumanEval-family (function completion). Nothing agentic for Drupal; nothing for Elm; nothing for *legacy* stacks at all — every public suite measures greenfield-modern code, while a large share of real agentic work happens on systems past their framework's fashion window. Empty shelf confirmed 2026-07-15.

## 2. Design principles

1. **Mechanical grading only (v1).** Compile, tests, conventions, behavior. No LLM-judge in the headline score — objective, cheap to rerun, immune to judge drift. (Optional judge lane for code-quality *dimensions* is v2+, reported separately, never mixed into pass rates.)
2. **Hidden holdouts.** The task states acceptance criteria in prose; the grader's exact assertions live outside the agent's workspace. An eval the agent can read is a to-do list, not an eval.
3. **Grader outside the sandbox.** Grading runs on a fresh copy with pristine test files re-imposed — "agent edits the test until green" is structurally impossible, not merely discouraged.
4. **A difficulty ladder.** Tasks are tiered 1–3 and the suite must *separate* models. If every model passes everything, the suite failed, not succeeded. Target spread at seed time: tier-1 ≈ pass for all, tier-3 ≈ pass for none reliably.
5. **Synthetic tasks, real patterns.** Zero client code. Task shapes distilled from a decade of production Drupal/Elm (multi-site syndication, offline sync, translation fallbacks, impossible-states modeling) — the *patterns* are the value, the code is fresh.
6. **Receipts everywhere.** Every run appends a JSONL record (task, model, trial, stages, duration, cost, transcript path). Published tables must be regenerable from the JSONL.
7. **Versioned suite.** Results are comparable only within a suite version; adding/changing tasks bumps it. Tables carry the version.

## 3. Task format

```text
tasks/<lane>-<nn>-<slug>/
├── task.md          # the spec (harness template: goal, context, acceptance
│                    #   criteria in prose, out of scope) — agent-visible
├── fixture/         # starting project state — copied to the agent workspace
├── grader/          # NOT copied to workspace; runs from outside
│   ├── grade.sh     # exit 0/1 + writes grade.json {pass, stages, notes}
│   └── assets/      # pristine tests, holdout assertions, expected artifacts
└── meta.json        # lane, tier (1-3), timeout_s, required stages
```

Grading stages (each pass/fail, task passes only if all *required* stages pass):
`compile` → `unit` (pristine tests re-imposed over agent's copies) → `conventions` (elm-format / elm-review / phpcs; includes codebase-specific rules, e.g. alphabetical union-variant ordering as a custom check) → `behavior` (Playwright journey against the fixture, where applicable — the all-artifacts rule: every record/side effect the task creates gets asserted).

## 4. Lanes and seed tasks

### Drupal lane — two sub-lanes, one per era

**`drupal7/`** (fixtures: Drupal 7 + ddev, minimal custom profile — the author's actual daily production stack) and **`drupal10/`** (fixtures: Drupal 10 + ddev — where the market is). The legacy sub-lane is a feature, not a compromise: no public eval measures agents on legacy code, enterprises run mountains of it, and the D7-vs-D10 score gap tests a concrete hypothesis — **paradigm bleed**: models trained overwhelmingly on D8+ (OOP, services, plugins, YAML config) inject those APIs into D7's procedural hook-and-Features world. If that shows up in the numbers, it's the most interesting finding in the suite — and it's the failure mode a D7 maintainer actually lives with.

| ID | Ver | Tier | Task | Grade focus |
| --- | --- | --- | --- | --- |
| D7-01 | 7 | 1 | `hook_menu` endpoint with an access callback | unit + holdout "anonymous must get 403" probe |
| D7-02 | 7 | 2 | Change exported config via the Features module and re-export cleanly | grader diffs the feature export against holdout |
| D7-03 | 7 | 3 | Update hook migrating a field's stored shape (Field API), data preserved | row-count/content holdout |
| D10-01 | 10 | 1 | REST endpoint exposing a content type, correct access checks | unit + 403 probe |
| D10-02 | 10 | 2 | Fix a seeded cache-invalidation bug (stale render after entity update) | behavior: update visible without manual cache clear |
| D10-03 | 10 | 3 | Config drift: reconcile live config vs exported YAML without losing intent | grader diffs final config against holdout |

### Elm lane (fixtures: Elm 0.19 app skeleton)

| ID | Tier | Task | Grade focus |
| --- | --- | --- | --- |
| E-01 | 1 | JSON decoder/encoder round-trip for a nested type | property test: `decode ∘ encode ≡ identity` |
| E-02 | 2 | Remodel a form so invalid states don't compile ("make impossible states impossible") | grader injects invalid-state constructor usage → MUST fail to compile |
| E-03 | 2 | Translation record with runtime English fallback; identical translations stay `Nothing` | unit + convention check |
| E-04 | 3 | Offline-first sync conflict: local edit vs server edit on the same entity | unit over conflict matrix (holdout cases) |
| E-05 | 3 | Extend a union type + all its handlers across decoder/encoder/update/view | compile + exhaustiveness + ordering convention |

E-02's grader is the signature move: correctness proven by a *compile failure* on purpose-built bad code — very Elm, very hard to game.

### Behavioral lane (fixtures: small Elm+API app with Playwright configured)

| ID | Tier | Task | Grade focus |
| --- | --- | --- | --- |
| B-01 | 2 | Write a Playwright E2E for a described feature, covering **all** artifacts it creates | grader runs the agent's test against two fixture variants: healthy (must pass) and seeded-broken (must fail) — tests that can't fail don't count |
| B-02 | 3 | Given a failing E2E, find and fix the app bug (not the test) | pristine test re-imposed, must pass; diff must not touch test files |

v0.1 ships **five**: D7-01, D10-02, E-01, E-02, B-01 — both Drupal eras represented from day one. Target 15 by v0.2 (including at least D7-02 for the Features workflow, which has no D10 analogue and no public eval anywhere).

## 5. Runner

Bash + jq (no framework; the repo should be readable in ten minutes):

```bash
runner/run.sh --tasks tasks/ --models "claude-opus-4-8,claude-fable-5" --trials 3
```

Per (task × model × trial): create throwaway workspace (git worktree or plain copy of `fixture/`) → invoke headless Claude Code (`claude -p` with the task.md as prompt, `--model`, auto-accept edits, per-task timeout; exact flags pinned at build time) → run `grader/grade.sh` from outside → append `results/runs.jsonl`.

`runner/report.sh` regenerates `RESULTS.md` from JSONL: pass@1 and pass@k per model per lane, per tier, suite version, total cost. The README embeds the latest table — the money screenshot.

Agent-runner abstraction kept thin (one `agents/claude-code.sh` adapter) so other CLI agents can be added later without touching graders.

## 6. Anti-gaming rules (the part interviewers actually probe)

- Workspace gets `fixture/` + `task.md` only; graders and holdouts never enter it.
- Pristine tests overwrite agent-modified test files before grading; B-02 additionally fails on any diff touching test paths.
- B-01 double-fixture rule (must pass on healthy, must fail on broken) kills assertion-free "tests".
- Network: package installs allowed (composer/npm/elm), nothing else assumed; graders run offline.
- Per-task wall-clock cap (meta.json); a timeout is a fail, recorded as such.
- Trials are independent fresh workspaces; no cross-trial memory.

## 7. Cost & cadence (honest math)

Seed matrix: 5 tasks × 2 models × 3 trials = 30 agent sessions ≈ single-digit dollars and an evening of wall-clock. Full matrix: 15 × 4 × 3 = 180 sessions — batched overnight, run *per suite version*, not per whim; results committed with receipts so nobody reruns to browse. CI runs grader unit tests only (graders are pure scripts + fixtures) — no agent calls in CI.

## 8. The author × reviewer experiment (v0.2 headline)

Corpus: all solutions from the matrix runs, labeled pass/fail by graders. Each (author-model, reviewer-model) pair: reviewer gets the task.md + solution diff, must output a structured verdict (approve/reject + findings). Score reviewers as classifiers against ground truth: **precision/recall of rejecting failing solutions**, self-pairs vs cross-pairs. Deliverables: one table, one short write-up — "Does cross-model review beat self-review? Data from a Drupal/Elm agentic eval suite." (Post #2, and the empirical answer to the self-review question.)

## 9. Milestones

- **v0.1 (one weekend):** runner + 5 seed tasks + graders + 2-model table in README. Suite version `0.1.0`.
- **v0.2 (following weeks):** 15 tasks, 4-model matrix, author×reviewer experiment + write-up draft.
- **v1.0:** difficulty recalibration from data, optional judge lane (separate report), optional integration with the (parked) MCP server — graders exposed as tools.

## 10. Open questions (decide before weekend 1)

1. Name: `agentic-delivery-evals` ok? Separate repo (recommended — different cadence than the harness) or monorepo?
2. Publish timing: repo public from day one with a status banner (harness precedent) or only after v0.1 results exist? (Recommended: after v0.1 results — an eval repo without numbers is scaffolding.)
3. Model set for the seed table: Opus 4.8 + Fable 5? Add Sonnet 5/Haiku 4.5 at seed or at v0.2?
4. Trials: 3 enough for seed honesty? (pass@1 with n=3 has wide error bars — the README must say so.)
5. Cost guardrail: hard per-run budget cap in the runner (recommended: yes, `--max-cost-usd`).
6. D7 fixture base: bare `ddev config --project-type=drupal7` plus a tiny synthetic custom module/Features skeleton (recommended — clean-room, no client code), or a distilled hedley-like profile (riskier: must be provably free of client IP).
