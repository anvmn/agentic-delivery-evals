# Results

Suite version **0.3.0** · generated 2026-07-17 · 192 runs · total agent cost $78.44

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-haiku-4-5 | claude-opus-4-8 | claude-sonnet-5 |
| --- | --- | --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| d10-04-cache-context-leak | drupal10 | 3 | 3/3 | 2/3 | 3/3 | 3/3 |
| d10-05-query-access-leak | drupal10 | 3 | 3/3 | 2/3 | 3/3 | 3/3 |
| d7-01-menu-endpoint | drupal7 | 2 | 6/6 | 1/6 | 1/6 | 0/6 |
| d7-03-field-migration | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 |
| d7-05-save-trigger-queue | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 |
| d7-06-node-access-grants | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 |
| d7-07-batched-update | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 |
| d7-08-multilingual-field | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-02-impossible-states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-06-unicode-length | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-07-tagged-union-decode | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-08-muac-classify | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 |

## Per model

**claude-fable-5** — trials passed: 48/48 · pass@k (any trial per task): 15/15 · mean duration 105s
**claude-haiku-4-5** — trials passed: 38/48 · pass@k (any trial per task): 15/15 · mean duration 46s
**claude-opus-4-8** — trials passed: 43/48 · pass@k (any trial per task): 15/15 · mean duration 106s
**claude-sonnet-5** — trials passed: 42/48 · pass@k (any trial per task): 14/15 · mean duration 76s
