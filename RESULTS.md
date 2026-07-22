# Results

Suite version **0.3.1** · generated 2026-07-22 · 370 runs · total agent cost $96.44

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-haiku-4-5 | claude-opus-4-8 | claude-sonnet-5 | gemini:gemini-3-flash | gemini:gemini-3.1-pro-preview | openai:gpt-5.6-luna | openai:gpt-5.6-sol | openrouter:deepseek/deepseek-v3.2 | openrouter:moonshotai/kimi-k2.7-code | openrouter:moonshotai/kimi-k3 | openrouter:qwen/qwen3-coder-next | openrouter:x-ai/grok-4.5 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 0/0 | 3/3 | 3/3 | 3/3 | 2/3 | 2/3 | 3/3 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 1/3 | 3/3 |
| d10-04-cache-context-leak | drupal10 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 3/3 | 0/0 | 3/3 | 3/3 | 3/3 | 2/3 | 0/3 | 3/3 |
| d10-05-query-access-leak | drupal10 | 3 | 3/3 | 0/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-01-menu-endpoint | drupal7 | 2 | 6/6 | 0/6 | 1/6 | 0/6 | 0/3 | 1/3 | 0/3 | 0/3 | 0/3 | 0/3 | 0/3 | 0/3 | 0/3 |
| d7-03-field-migration | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-05-save-trigger-queue | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-06-node-access-grants | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-07-batched-update | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-08-multilingual-field | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 2/3 | 4/4 |
| e-02-impossible-states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-06-unicode-length | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| e-07-tagged-union-decode | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 0/0 | 3/3 | 3/3 | 3/3 | 3/3 | 1/3 | 3/3 |
| e-08-muac-classify | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |

## Per model

**claude-fable-5** — trials passed: 48/48 · pass@k (any trial per task): 15/15 · mean duration 105s
**claude-haiku-4-5** — trials passed: 35/48 · pass@k (any trial per task): 13/15 · mean duration 46s
**claude-opus-4-8** — trials passed: 43/48 · pass@k (any trial per task): 15/15 · mean duration 106s
**claude-sonnet-5** — trials passed: 42/48 · pass@k (any trial per task): 14/15 · mean duration 76s
**gemini:gemini-3-flash** — trials passed: 6/9 · pass@k (any trial per task): 2/3 · mean duration 382s
**gemini:gemini-3.1-pro-preview** — trials passed: 19/21 · pass@k (any trial per task): 7/7 · mean duration 112s
**openai:gpt-5.6-luna** — trials passed: 9/12 · pass@k (any trial per task): 3/4 · mean duration 30s
**openai:gpt-5.6-sol** — trials passed: 24/30 · pass@k (any trial per task): 8/10 · mean duration 43s
**openrouter:deepseek/deepseek-v3.2** — trials passed: 18/21 · pass@k (any trial per task): 6/7 · mean duration 255s
**openrouter:moonshotai/kimi-k2.7-code** — trials passed: 18/21 · pass@k (any trial per task): 6/7 · mean duration 128s
**openrouter:moonshotai/kimi-k3** — trials passed: 16/21 · pass@k (any trial per task): 6/7 · mean duration 86s
**openrouter:qwen/qwen3-coder-next** — trials passed: 9/21 · pass@k (any trial per task): 5/7 · mean duration 166s
**openrouter:x-ai/grok-4.5** — trials passed: 19/22 · pass@k (any trial per task): 6/7 · mean duration 31s
