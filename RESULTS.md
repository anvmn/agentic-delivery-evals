# Results

Suite version **0.3.2** · generated 2026-08-06 · 512 runs · total agent cost $127.16

> n=trials per cell is small — treat differences under ~2 tasks as noise, not signal.

## Pass per task (passes/trials)

| task | lane | tier | claude-fable-5 | claude-haiku-4-5 | claude-opus-4-8 | claude-opus-5 | claude-sonnet-5 | gemini:gemini-3-flash | gemini:gemini-3.1-pro-preview | openai:gpt-5.6-luna | openai:gpt-5.6-sol | openrouter:deepseek/deepseek-v3.2 | openrouter:moonshotai/kimi-k2.7-code | openrouter:moonshotai/kimi-k3 | openrouter:qwen/qwen3-coder-next | openrouter:x-ai/grok-4.5 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| b-01-write-e2e | behavioral | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 2/3 | 3/3 |
| d10-02-cache-bug | drupal10 | 2 | 3/3 | 3/3 | 3/3 | 2/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 1/3 | 3/3 |
| d10-04-cache-context-leak | drupal10 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 1/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/3 | 3/3 |
| d10-05-query-access-leak | drupal10 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 3/3 | 2/3 | 2/3 | 2/3 | 0/2 | 1/3 | 3/3 |
| d7-01-menu-endpoint | drupal7 | 2 | 6/6 | 0/6 | 1/6 | 5/6 | 0/6 | 0/3 | 1/3 | 0/3 | 0/3 | 0/6 | 0/6 | 0/6 | 0/6 | 0/6 |
| d7-03-field-migration | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 3/3 | 3/3 | 3/3 | 1/3 | 3/3 | 0/3 | 3/3 |
| d7-05-save-trigger-queue | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| d7-06-node-access-grants | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 3/3 | 3/3 | 3/3 | 2/3 | 2/2 | 1/3 | 3/3 |
| d7-07-batched-update | drupal7 | 3 | 3/3 | 2/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 3/3 | 3/3 | 3/3 | 2/3 | 0/0 | 2/3 | 3/3 |
| d7-08-multilingual-field | drupal7 | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| e-01-decoder-roundtrip | elm | 1 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 2/3 | 4/4 |
| e-02-impossible-states | elm | 2 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 |
| e-06-unicode-length | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |
| e-07-tagged-union-decode | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 1/3 | 3/3 |
| e-08-muac-classify | elm | 3 | 3/3 | 3/3 | 3/3 | 3/3 | 3/3 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 | 0/0 |

## Per model

**claude-fable-5** — trials passed: 48/48 · pass@k (any trial per task): 15/15 · mean duration 105s
**claude-haiku-4-5** — trials passed: 37/48 · pass@k (any trial per task): 14/15 · mean duration 46s
**claude-opus-4-8** — trials passed: 43/48 · pass@k (any trial per task): 15/15 · mean duration 106s
**claude-opus-5** — trials passed: 46/48 · pass@k (any trial per task): 15/15 · mean duration 128s
**claude-sonnet-5** — trials passed: 42/48 · pass@k (any trial per task): 14/15 · mean duration 76s
**gemini:gemini-3-flash** — trials passed: 6/9 · pass@k (any trial per task): 2/3 · mean duration 382s
**gemini:gemini-3.1-pro-preview** — trials passed: 19/21 · pass@k (any trial per task): 7/7 · mean duration 112s
**openai:gpt-5.6-luna** — trials passed: 28/33 · pass@k (any trial per task): 10/11 · mean duration 29s
**openai:gpt-5.6-sol** — trials passed: 29/33 · pass@k (any trial per task): 10/11 · mean duration 45s
**openrouter:deepseek/deepseek-v3.2** — trials passed: 29/36 · pass@k (any trial per task): 10/11 · mean duration 265s
**openrouter:moonshotai/kimi-k2.7-code** — trials passed: 25/36 · pass@k (any trial per task): 10/11 · mean duration 115s
**openrouter:moonshotai/kimi-k3** — trials passed: 23/31 · pass@k (any trial per task): 8/10 · mean duration 110s
**openrouter:qwen/qwen3-coder-next** — trials passed: 13/36 · pass@k (any trial per task): 8/11 · mean duration 150s
**openrouter:x-ai/grok-4.5** — trials passed: 31/37 · pass@k (any trial per task): 10/11 · mean duration 36s

## Raised-effort and clean-room arms (excluded from the scoreboard above)

| model | task | arm | passes/trials |
| --- | --- | --- | --- |
| claude-fable-5 | d7-01-menu-endpoint | effort=max · clean-room | 3/3 |
| claude-haiku-4-5 | d7-01-menu-endpoint | effort=max | 0/3 |
| claude-opus-4-8 | d7-01-menu-endpoint | effort=max | 2/3 |
| claude-opus-5 | d7-01-menu-endpoint | effort=max | 3/3 |
| claude-sonnet-5 | d7-01-menu-endpoint | effort=max | 0/3 |
| openai:gpt-5.6-sol | d10-05-query-access-leak | effort=xhigh | 2/3 |
| openai:gpt-5.6-sol | d7-01-menu-endpoint | effort=xhigh | 0/3 |
| openrouter:deepseek/deepseek-v3.2 | d7-01-menu-endpoint | effort=high | 0/3 |
| openrouter:moonshotai/kimi-k2.7-code | d7-01-menu-endpoint | effort=high | 0/3 |
| openrouter:moonshotai/kimi-k3 | d7-01-menu-endpoint | effort=high | 0/3 |
| openrouter:x-ai/grok-4.5 | d7-01-menu-endpoint | effort=high | 0/3 |

## Live-site arm (d7-01 on a running site, with a behavior probe)

| model | passes/trials | mean probe invocations |
| --- | --- | --- |
| claude-haiku-4-5 | 1/3 | 7 |
| claude-opus-4-8 | 6/6 | 1.7 |
| claude-opus-5 | 7/7 | 1.6 |
| claude-sonnet-5 | 2/3 | 2 |
| openai:gpt-5.6-sol | 3/3 | 2.7 |
| openrouter:deepseek/deepseek-v3.2 | 3/6 | 13.7 |
| openrouter:moonshotai/kimi-k2.7-code | 4/6 | 2.8 |
| openrouter:moonshotai/kimi-k3 | 3/4 | 2.5 |
| openrouter:qwen/qwen3-coder-next | 1/6 | 5.5 |
| openrouter:x-ai/grok-4.5 | 6/6 | 2 |

## Review panel — blind reviews of graded d7-01 solutions vs grader ground truth (parse-error reviews excluded)

| reviewer | failing solutions caught | passing solutions approved |
| --- | --- | --- |
| claude-fable-5 | 12/18 | 7/7 |
| claude-haiku-4-5 | 3/17 | 6/7 |
| claude-opus-4-8 | 6/9 | 2/2 |
| claude-sonnet-5 | 8/17 | 6/7 |

## Cross-lab review panel (correct verdicts per cell; echo = the d7-01 echo solution under two spec wordings)

| reviewer | e-06 reference | e-06 flawed | echo @pre-0.3.1 | echo @0.3.1 |
| --- | --- | --- | --- | --- |
| claude-opus-5 | 6/6 | 6/6 | 4/6 | 6/6 |
| deepseek/deepseek-v3.2 | 1/6 | 6/6 | 5/6 | 6/6 |
| moonshotai/kimi-k2.7-code | 2/6 | 5/6 | 0/6 | 5/6 |
| moonshotai/kimi-k3 | 6/6 | 6/6 | 0/6 | 6/6 |
| qwen/qwen3-coder-next | 2/6 | 4/6 | 1/6 | 6/6 |
| x-ai/grok-4.5 | 5/6 | 4/6 | 5/6 | 6/6 |
