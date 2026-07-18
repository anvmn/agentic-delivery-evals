# agentic-delivery-evals

Coding evals for agentic work on **Drupal (7 and 10)** and **Elm** — the measurement layer of the [agentic-delivery-harness](https://github.com/anvmn/agentic-delivery-harness). Realistic tasks, mechanical grading, hidden holdouts, and a runner that executes coding agents headlessly and reports pass rates per model. Built and validated on the workflow behind a production digital-health platform.

## Results (suites 0.1–0.3 · 226 runs · 8 models, 3 labs · 2026-07-18)

| task | lane | tier | fable-5 | opus-4-8 | sonnet-5 | haiku-4-5 | g3.1-pro | g3-flash | 5.6-sol | 5.6-luna |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| e-01 decoder round-trip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | — |
| e-02 impossible states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 |
| b-01 write-the-E2E | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | — |
| d10-02 cache invalidation | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 |
| **d7-01 menu endpoint** (two independent runs) | **drupal7** | **2** | **6/6** | **1/6** | **0/6** | **1/6** | 1/3 | 0/3 |
| d7-03 field migration | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 2/3 | — | — |
| d7-05 save-trigger queue | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 | — | — |
| e-06 unicode length | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | — | — |
| d10-04 cache context (poisoning) | drupal10 | 3 | 3/3 | 3/3 | 3/3 | 2/3 | 3/3 | — |
| d10-05 query access leak | drupal10 | 3 | 3/3 | 3/3 | 3/3 | 2/3 | ※ | — |
| e-07 tagged-union decode (oneOf) | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | — |
| e-08 MUAC boundary classify | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | — | — |
| d7-06 node-access grants | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 2/3 | ※ | — |
| d7-07 batched $sandbox update | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 2/3 | ※ | — |
| d7-08 multilingual field access | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 | — | — |

*Gemini and OpenAI columns: subset by design (— = not run); ※ = pending the provider's suspension appeal. Gemini/OpenAI d7-01 cells are single-run (n=3); OpenAI stage 2 (the six-task subset) is planned.*

**The finding, twice refined by replication — and now test-retested:** on d7-01, four models spanning the capability range separate in a clean staircase — Fable 5 6/6, Opus 4.8 1/6, Sonnet 5 0/6, Haiku 4.5 1/6 over two independent runs a day apart — while every modern-stack task is 12/12 across all four. Two more Drupal 7 tasks then tested whether "legacy is hard" explains it. It doesn't: d7-03 (a harder-tier dual-table data migration) came back 11/12, and d7-05 — which deliberately stacks *four* legacy-API axes (DrupalQueue vs QueueWorker instincts, variables vs State API, EntityFieldQuery vs entityQuery, plus an idempotency requirement) and is modeled on the most common pattern in a real production D7 backend — came back **12/12**. Old and obscure APIs alone don't separate models. What separated them, in the one task that did, is sharper: **d7-01 is the only task where the canonical-*looking* solution is wrong** (`drupal_json_output` as a delivery callback reads like textbook D7 and silently breaks access control). The working hypothesis after three legacy tasks: models fail not where code is old, but where **plausible looks-right patterns are subtly incorrect** — and that is also precisely where unaided human reviewers fail. v0.2's task design targeted exactly such looks-right-is-wrong spots, in both eras.

The failure modes are distinct, and all three are real Drupal 7 production hazards:

- **The delivery trap** (all 5 Opus failures, 3 of 5 Haiku failures): `'delivery callback' => 'drupal_json_output'` looks canonical but delivers access-denied as HTTP 200 with body `3` (the JSON-encoded `MENU_ACCESS_DENIED` constant). The same trap caught the suite's author writing the reference solution.
- **The echo instinct** (all 6 Sonnet failures, 2 of 5 Haiku failures): calling `drupal_json_output()` *inside* the page callback and returning nothing — through D7's real delivery pipeline that yields JSON followed by a 404 page (a NULL callback return means "not found"), violating the task's explicit return-array contract.
- Only Fable consistently wrote what D7 actually requires: a custom delivery callback routing integer menu-status results through standard delivery.
- **Failure modes are model-stable:** across two runs a day apart, Sonnet *always* fails by echoing, Opus *always* by the delivery trap. These read as stable per-model instincts, not coin flips — only Haiku, the smallest, mixes modes.

Models are trained overwhelmingly on modern-framework idioms; the **paradigm-bleed hypothesis** — that agents underperform where legacy conventions predate their training distribution's center of mass — now has a four-model data point *and* a boundary condition from its first replication attempt. No other public eval measures agents on legacy stacks at all.

A practical corollary from the cost column of the receipts: Haiku cleared 25 of 27 modern-stack trials at $0.05–$0.16 per run, against a frontier mean of $0.60 on the same lanes — and its only two modern-stack drops are the two engineered Drupal 10 traps. In this suite's domains, capability spend only pays off where the traps are.

**The v0.2 counter-result — traps with published warnings don't trap.** We built three tasks deliberately engineered to d7-01's recipe (popular-wrong pattern, framework-interaction bug, happy-path camouflage) in *modern* territory: Elm's UTF-16 length trap, Drupal 10 cache-context poisoning, and the entityQuery access leak. The frontier models dodged all three, 27/27; only Haiku dropped points (a runtime crash from a missing `accessCheck()`, and one genuine access leak). The distinction this forces is the sharpest yet: modern traps are *loudly documented as traps* — change records, security advisories, a decade of blog posts — so the warnings live in the training corpus alongside the bugs. d7-01's delivery-callback trap predates that discourse: the corpus carries the disease without the vaccine. Working formulation after ten tasks: **models fail where the training corpus contains the wrong pattern but not its warning.** Corollary, measured on ourselves: these traps caught the suite's human author four times during development — more often than they caught any frontier model.

**The v0.3 negative result — an expert hunting traps went 0-for-5.** Five more tasks were engineered *deliberately* to the looks-right-is-wrong recipe, harder than anything before them and weighted to Drupal 7: node-access grants vs the runtime-hook leak, the `$sandbox` batching contract, multilingual field access, `Decode.oneOf` silent mis-decoding, clinical boundary conditions. Frontier models: **45/45.** Only Haiku dropped two trials. Every one of these traps turns out to be *well-warned* in the corpus — node access grants and `$sandbox` batching are among the most-documented D7 topics precisely because they burned so many humans. The task-author (20 years in these stacks, actively hunting) could not construct a second d7-01 on purpose. Which sharpens the finding to its final v0.x form: frontier models are robust to *famous* traps regardless of era or complexity; what still catches them is the rare spot where the wrong pattern is popular **and its warning never made it into the corpus** — d7-01's delivery-callback interaction remains, after 15 tasks and 192 Claude runs, the only such spot found. Corollary: those spots are exactly as hard for humans to enumerate — the suite's development caught its own author five times.

**Cross-lab replication (2026-07-18): the trap belongs to the internet, not to a lab.** Google's models, run through the identical pipeline (a thin Gemini-CLI adapter; same tasks, same graders, same blind protocol) on d7-01:

| model | d7-01 | failure stage | failing line |
| --- | --- | --- | --- |
| gemini-3.1-pro-preview | 1/3 | anon_403 | `'delivery callback' => 'drupal_json_output'` |
| gemini-3-flash | 0/3 | anon_403 | `'delivery callback' => 'drupal_json_output'` |

Frontier-for-frontier the pattern mirrors Claude: Google's top model escapes the trap at the same ~1-in-3 rate as Opus 4.8, its smaller model never does, and every failure is the *same mode, same line* — the canonical-looking delivery callback that serves access-denied as HTTP 200. Two labs, one shared training distribution, one shared blind spot. (Caveat: different CLI scaffolding — these are model+harness systems, stated as such.)

Beyond the trap, the symmetry held everywhere it was tested: gemini-3.1-pro went **18/18** on a stratified six-task subset (e-01, e-02, e-07, b-01, d10-02, and notably d10-04 — the cache-poisoning trap), and gemini-3-flash passed both floor-calibration tasks 6/6, placing it inside the Claude band on famous-trap work. Three subset cells (d10-05, d7-06, d7-07) are **not run**: the provider first exhausted its 250-requests/day tier cap (nine poisoned records voided; the runner now honors the adapter's quota signal), and the project's API access was subsequently suspended pending an Acceptable Use appeal — plausibly triggered by this suite's own overnight quota-retry loop, a bot-shaped mistake we've documented and stopped. Benchmarking across vendors means inheriting every vendor's failure modes; the receipts include theirs and ours.

**Third lab (2026-07-18): OpenAI, same trap — and now both failure modes replicate.** GPT-5.6 Sol (OpenAI's flagship, via a thin Codex-CLI adapter) went **0/3 on d7-01**, and its three failures land exactly in the two known grooves: one trial wrote the delivery trap — `'delivery callback' => 'drupal_json_output'`, the same line as Opus and both Geminis — and two trials wrote the echo mode (JSON emitted inside the page callback, nothing returned), previously Sonnet's signature. At n=3, 0/3 is statistically indistinguishable from the Opus/Gemini-Pro ~1-in-3 band, so no ranking claim; what is *not* noise is that a third lab's flagship produced no novel failure — every wrong answer across nine frontier-model failures on this task is one of the same two canonical-looking patterns. System caveat, stated plainly: Codex-CLI runs were single-shot (~35 s, a few commands, no live-site testing), a different agent style than the Claude runs — these are model+harness systems. GPT-5.6 Luna passed the e-01 smoke test 1/1; the OpenAI subset run mirroring Gemini's stage 2 is planned.

Honest caveats: n=3 trials per cell — error bars are wide, and differences under ~2 tasks are noise. Fourteen of fifteen tasks are (nearly) saturated for frontier models; d7-01 remains the sole strong discriminator. Every number above is regenerable from `results/runs.jsonl` (receipts: stages, duration, cost, transcript per run; six d7 records are marked `regraded` after grader-fairness fixes — see [`VALIDATION.md`](VALIDATION.md)).

## Beyond authoring: two experiments on the same receipts

**Does thinking budget rescue models from the trap?** Rerunning d7-01 at `--effort max` for the models that fail at default effort: Opus 4.8 jumped from 1/6 to **2/3** — its max-effort passes ran ~2× longer and found the trap. Sonnet 5 (0/3) and Haiku 4.5 (0/3) stayed trapped, merely shuffling *which* wrong pattern they chose. Gemini's receipts show the observational twin: with dynamic thinking, its Pro's one passing trial spontaneously spent 9.8k thinking tokens vs 4–5.6k in its failing trials. The verdict is tiered: **effort rescues a model that is one step below the trap; it cannot substitute for knowledge that isn't there.** Below the threshold, only behavioral gates help.

**Can models review their way out?** All four Claude models blindly reviewed 24 graded d7-01 solutions (plus Gemini's), 95 reviews against grader ground truth ([`experiments/author-reviewer/`](experiments/author-reviewer/)):

| reviewer | delivery-trap catches | echo catches | good code approved |
| --- | --- | --- | --- |
| fable-5 | 12/12 | 0/6 | 7/7 |
| opus-4-8 | 6/7 | 0/2 | 2/2 |
| sonnet-5 | 7/12 | 1/5 | 6/7 |
| haiku-4-5 | 1/12 | 2/5 | 6/7 |

Three results: review capability is the **same staircase as authoring capability** (and it transfers cross-lab — Fable rejects Gemini's trap failures 4/4, Haiku 1/4); the echo failure mode is **near-invisible to every reviewer** — 3/18 caught, pooled — with reviewers routinely praising the bug as a virtue; and false alarms stay low (21/23 good solutions approved). Model review is a filter that inherits the reviewer's blind spots; the grader — the behavioral gate — was the floor.

## How it works

```text
tasks/<id>/         task.md (agent-visible spec) · fixture/ (starting state)
                    grader/ (answer key — never enters the agent workspace)
                    meta.json (lane, tier, timeout, required stages)
runner/run.sh       task × model × trial matrix over headless agents
                    (Claude Code; `gemini:`-prefixed models route to the
                    Gemini CLI adapter in runner/agents/)
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

# cross-lab column (routes to the Gemini CLI adapter; needs GEMINI_API_KEY)
runner/run.sh --models "gemini:gemini-3.1-pro-preview" --only d7-01-menu-endpoint
```

Requirements: ddev, node ≥ 20, elm 0.19, jq, and the Claude Code CLI authenticated (plus the Gemini CLI for `gemini:` models). The runner's `--max-cost-usd` is a hard cap checked before every session.

## Roadmap

Shipped so far: 15 tasks across four lanes; a 4-model Claude matrix with a test-retest replication; cross-lab columns (Gemini Pro/Flash); the effort experiment; and the author × reviewer experiment (95 blind reviews). What's genuinely next:

- **More labs:** OpenAI is in progress — the Codex-CLI adapter landed and GPT-5.6 Sol has its d7-01 cell (0/3, both known failure modes; subset run pending). Next: open-weights models (DeepSeek, Qwen, Kimi) via a single Aider/OpenRouter adapter — the corpus-trap prediction stays on record for them.
- **Complete the Gemini column:** three subset cells (d10-05, d7-06, d7-07) pending the provider's suspension appeal.
- **Hunt more discriminators:** the recipe is documented (popular wrong pattern + absent corpus warning) and hard to satisfy on purpose — the author went 0-for-5. Candidate contributions welcome as issues; the D7-02 Features-module task remains unbuilt and unmeasured anywhere.
- **Tighter intervals where it matters:** raise trial counts on discriminating cells (d7-01 sits at n=6; saturated cells don't need more).
- **Effort curve:** the max-effort experiment rescued exactly one model; a low→max sweep would map the full budget-capability trade.
- **Judge lane** for code-quality dimensions — still future, still reported separately, never mixed into pass rates.

## License

[MIT](LICENSE) — © Anatoly Vaitsman
