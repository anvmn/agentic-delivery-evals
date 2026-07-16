# Results

Suite version **0.1.0** · generated 2026-07-16 · 72 runs · total agent cost $30.72

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-haiku-4-5 | claude-opus-4-8 | claude-sonnet-5 |
| --- | --- | --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d7-01-menu-endpoint | drupal7 | 2 | 3/3 | 0/3 | 1/3 | 0/3 |
| d7-03-field-migration | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-02-impossible-states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 |

## Per model

**claude-fable-5** — trials passed: 18/18 · pass@k (any trial per task): 6/6 · mean duration 121s
**claude-haiku-4-5** — trials passed: 14/18 · pass@k (any trial per task): 5/6 · mean duration 46s
**claude-opus-4-8** — trials passed: 16/18 · pass@k (any trial per task): 6/6 · mean duration 104s
**claude-sonnet-5** — trials passed: 15/18 · pass@k (any trial per task): 5/6 · mean duration 75s
