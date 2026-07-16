# Results

Suite version **0.1.0** · generated 2026-07-16 · 30 runs · total agent cost $17.56

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-opus-4-8 |
| --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 |
| d7-01-menu-endpoint | drupal7 | 2 | 3/3 | 1/3 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 |
| e-02-impossible-states | elm | 2 | 3/3 | 3/3 |

## Per model

**claude-fable-5** — trials passed: 15/15 · pass@k (any trial per task): 5/5 · mean duration 112s
**claude-opus-4-8** — trials passed: 13/15 · pass@k (any trial per task): 5/5 · mean duration 84s
