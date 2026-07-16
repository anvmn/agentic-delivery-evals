# Results

Suite version **0.1.0** · generated 2026-07-16 · 24 runs · total agent cost $15.43

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-opus-4-8 |
| --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 |
| d7-01-menu-endpoint | drupal7 | 2 | 3/3 | 1/3 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 |

## Per model

**claude-fable-5** — trials passed: 12/12 · pass@k (any trial per task): 4/4 · mean duration 127s
**claude-opus-4-8** — trials passed: 10/12 · pass@k (any trial per task): 4/4 · mean duration 93s
