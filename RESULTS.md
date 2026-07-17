# Results

Suite version **0.1.2** · generated 2026-07-17 · 96 runs · total agent cost $40.13

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-haiku-4-5 | claude-opus-4-8 | claude-sonnet-5 |
| --- | --- | --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d7-01-menu-endpoint | drupal7 | 2 | 6/6 | 1/6 | 1/6 | 0/6 |
| d7-03-field-migration | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 |
| d7-05-save-trigger-queue | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-02-impossible-states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 |

## Per model

**claude-fable-5** — trials passed: 24/24 · pass@k (any trial per task): 7/7 · mean duration 119s
**claude-haiku-4-5** — trials passed: 18/24 · pass@k (any trial per task): 7/7 · mean duration 43s
**claude-opus-4-8** — trials passed: 19/24 · pass@k (any trial per task): 7/7 · mean duration 101s
**claude-sonnet-5** — trials passed: 18/24 · pass@k (any trial per task): 6/7 · mean duration 72s
