# Results

Suite version **0.3.0** · generated 2026-07-18 · 226 runs · total agent cost $85.36

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-haiku-4-5 | claude-opus-4-8 | claude-sonnet-5 | gemini:gemini-3-flash | gemini:gemini-3.1-pro-preview | openai:gpt-5.6-luna | openai:gpt-5.6-sol |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 0/0 | 0/0 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 |
| d10-04-cache-context-leak | drupal10 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 3/3 | 0/0 | 0/0 |
| d10-05-query-access-leak | drupal10 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-01-menu-endpoint | drupal7 | 2 | 6/6 | 1/6 | 1/6 | 0/6 | 0/3 | 1/3 | 0/0 | 0/3 |
| d7-03-field-migration | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-05-save-trigger-queue | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-06-node-access-grants | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-07-batched-update | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-08-multilingual-field | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 1/1 | 0/0 |
| e-02-impossible-states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 |
| e-06-unicode-length | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 |
| e-07-tagged-union-decode | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 0/0 | 0/0 |
| e-08-muac-classify | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 |

## Per model

**claude-fable-5** — trials passed: 48/48 · pass@k (any trial per task): 15/15 · mean duration 105s
**claude-haiku-4-5** — trials passed: 38/48 · pass@k (any trial per task): 15/15 · mean duration 46s
**claude-opus-4-8** — trials passed: 43/48 · pass@k (any trial per task): 15/15 · mean duration 106s
**claude-sonnet-5** — trials passed: 42/48 · pass@k (any trial per task): 14/15 · mean duration 76s
**gemini:gemini-3-flash** — trials passed: 6/9 · pass@k (any trial per task): 2/3 · mean duration 382s
**gemini:gemini-3.1-pro-preview** — trials passed: 19/21 · pass@k (any trial per task): 7/7 · mean duration 112s
**openai:gpt-5.6-luna** — trials passed: 1/1 · pass@k (any trial per task): 1/1 · mean duration 32s
**openai:gpt-5.6-sol** — trials passed: 0/3 · pass@k (any trial per task): 0/1 · mean duration 35s
