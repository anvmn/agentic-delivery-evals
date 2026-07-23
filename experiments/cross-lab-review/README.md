# Experiment: cross-lab blind review — hallucination probe + spec-wording A/B

The suite's two headline review findings came from Claude-family panels:
reviewers sometimes *reject correct code on a hallucinated language fact*
(e-06, [gen-vs-recognition](../gen-vs-recognition/)) and sometimes *approve a
spec-violating pattern under ambiguous wording* (d7-01 echo,
[author-reviewer](../author-reviewer/) →
[author-catch #8](../../VALIDATION.md)). Do these travel across labs? The
four OpenRouter-column models (Grok 4.5, Kimi K2.7-code, Qwen3-Coder-next,
DeepSeek V3.2) blind-review both, n=6 per cell — with d7-01 reviewed under
**both** spec wordings (the pre-0.3.1 ambiguous criterion #3 and the 0.3.1
tightened rewrite), which turns the wording fix into a controlled A/B.

Same prompt/verdict contract as the earlier panels; no tools; reviews run
through codex exec (read-only sandbox) with the openrouter provider.
Receipts: [`reviews.jsonl`](reviews.jsonl) (96 records).

## Result 1 — the Unicode hallucination is industry-wide, in two flavors

Reviewing the **correct** `String.toList` reference (truth: approve):

| reviewer | approve | reject | parse err |
|---|---|---|---|
| Grok 4.5 | **5** | 1 | 0 |
| Kimi K3 | **6** | 0 | 0 |
| Kimi K2.7-code | 2 | **4** | 0 |
| DeepSeek V3.2 | 1 | **5** | 0 |
| Qwen3-next | 2 | 2 | 2 |

- **Kimi reproduces the Sonnet/Haiku hallucination verbatim** ("String.toList
  returns UTF-16 code units… 👍 counts as 2") — the false belief that owned
  two Claude models owns a fourth pipeline.
- **DeepSeek invents its own**: it grants code-point awareness but fabricates
  the ZWJ arithmetic (claims `👩‍👩‍👧` yields 7–8 code points; it's exactly 5).
  Different false fact, same wrongful rejection.
- **Grok — marketed on "non-hallucination rate" — is cleanest on correct
  code (5/6)… and weakest on the actual bug: it approved the real
  `String.length` flaw 2/6**, once stating flatly that "String.length counts
  Unicode code points" (false — that's the whole task). Low hallucination
  cashes out as *leniency*, not vigilance: fewest false alarms in the panel,
  most missed bugs in the panel. Flaw-catch rates: DeepSeek 6/6 · Kimi 5/6 ·
  Grok 4/6 · Qwen 4/6 (2 parse errors).

**Kimi K3 (added late, n=6): perfect 12/12** — approves the correct file
6/6, catches the bug 6/6. Within Moonshot's own lineup the hallucination is
a *tier* property: K2.7-code asserts the false UTF-16 fact 4/6; its flagship
sibling never does. Across every model ever pointed at e-06 in review (10
total), only Fable, Opus, GPT-5.6 Sol, and Kimi K3 have never asserted a
false Unicode fact.

## Result 2 — the wording A/B validates author-catch #8, 29–0

Reviewing the canonical echo submission (truth: reject) under each wording:

| reviewer | pre-0.3.1 approvals | 0.3.1 approvals |
|---|---|---|
| Kimi K3 | **4/6** (+2 parse err) | 0/6 |
| Kimi K2.7-code | **4/6** | 0/6 |
| Qwen3-next | **4/6** | 0/6 |
| Grok 4.5 | 1/6 | 0/6 |
| DeepSeek V3.2 | 1/6 | 0/6 |

Under the ambiguous criterion #3, **every model approves at least once**
(tightened-wording rejections now 29–0 across five pipelines) —
the textualist reading ("drupal_json_output *is* the native mechanism; no
print+exit here") appears in all five pipelines, heavily in three. Under the
tightened wording: **29 reject, 0 approve, 1 parse error**. The rewrite
eliminates every approval from every pipeline. Combined with the Claude
panel's identical flip, the d7-01 echo approvals are causally attributable
to the spec's wording, not to reviewer blindness — which is exactly what
author-catch #8 claimed when it retired that wording.

**Caveats.** n=6; single submission per task; Qwen contributes 5 parse
errors across the panel (the budget model's compliance with a bare-JSON
contract is itself a finding, consistent with its matrix showing). Reviews
are blind single-shot — no tools — so these are priors, not verified
verdicts; the [verified-review](../verified-review/) experiment measures
what a runtime does to exactly these failure modes.
