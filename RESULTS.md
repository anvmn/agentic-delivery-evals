# Results

Suite version **0.1.1** · generated 2026-07-16 · 84 runs · total agent cost $35.87

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-haiku-4-5 | claude-opus-4-8 | claude-sonnet-5 |
| --- | --- | --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d7-01-menu-endpoint | drupal7 | 2 | 3/3 | 0/3 | 1/3 | 0/3 |
| d7-03-field-migration | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 |
| d7-05-save-trigger-queue | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-02-impossible-states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 |

## Per model

**claude-fable-5** — trials passed: 21/21 · pass@k (any trial per task): 7/7 · mean duration 120s
**claude-haiku-4-5** — trials passed: 17/21 · pass@k (any trial per task): 6/7 · mean duration 46s
**claude-opus-4-8** — trials passed: 19/21 · pass@k (any trial per task): 7/7 · mean duration 106s
**claude-sonnet-5** — trials passed: 18/21 · pass@k (any trial per task): 6/7 · mean duration 76s
