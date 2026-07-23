# Experiment: does the generation-vs-recognition gap generalize?

d7-01 produced a striking result in the [author × reviewer](../author-reviewer/)
experiment: Fable **writes** the correct solution 6/6 but, reviewing the echo
bug, **catches** it 0/6 — generation succeeding where recognition fails. Is that
a general law, or special to that one bug?

**Design.** Take three more tasks whose models author correctly but whose flaw
is a silent, idiomatic, corpus-plausible bug — d10-05 (`accessCheck` access
leak), e-06 (`String.length` UTF-16 miscount), d7-06 (runtime `hook_node_access`
that leaks listings) — plus a control whose flaw is a visible omission (d7-07,
missing `$sandbox` batching). Blind-review each task's **reference** and
**flawed** variant; ground truth is approve-reference / reject-flaw. Predicted:
large author-minus-catch gap on the treatments (reviewers approve the flaw),
~zero on the control. Panel: Opus 4.8, Sonnet 5, Haiku 4.5, GPT-5.6 Sol
(Fable usage-limited, Gemini suspended). n=3 per cell.

**Methodology note (important).** A first run was invalid: the grader's own
self-test assets carry provenance labels ("reference solution", "FLAWED
variant: the trap"), so reviewers judged the *comment*, not the code — the
verdicts looked like a clean negative but the *reasons* exposed it. The run
below uses comment-neutralized submissions (identical neutral header on
reference and flawed; only the code differs), with e-06's required test added.

## Result — the gap does NOT generalize

**No reviewer approved a single flaw.** Every reviewer rejected every flawed
variant 3/3 across all four tasks. The echo bug's "endorse the bug" invisibility
did not reproduce on any of three fresh idiom bugs. So the write-it-right /
miss-it-in-review asymmetry is **special to the echo bug**, not a general law.

The failure mode inverted instead: on the subtle treatments, *some* reviewers
**over-reject** — rejecting the *correct* reference — while the control d7-07 is
perfect (all 4 approve the reference and reject the flaw). But this is
**reviewer- and task-specific**, and it comes in two flavors: on d10-05, mostly
the reviewers being right (real subtleties, not trigger-happiness); on e-06, a
genuine *false belief* about the language (both below).

d10-05 makes the point after a polish pass (fixing a `@file`-placement artifact
our neutralizer introduced, and using the order-safe reference): **Sonnet and
Haiku now correctly approve** the clean reference 3/3 — their earlier rejections
were that artifact and a genuine ordering concern. What remains is Opus and Sol
still rejecting it, for sophisticated, defensible reasons — Opus flags that the
query's `accessCheck(TRUE)` doesn't invoke `hook_node_access()` and the loaded
nodes are never re-checked with `->access('view')` (a real Drupal
security-depth point); Sol reads "notices the user is allowed to view" as
including unpublished-viewable content (a spec ambiguity). And the *one* concern
that was an outright bug — Opus and Sonnet independently flagging that
`loadMultiple()` can discard the `created DESC` sort — became
[author-catch #7](../../VALIDATION.md): the grader wasn't checking the
newest-first requirement (the flawed-variant self-test confirms the gap was
exploitable — though a 2026-07-23 audit retracted the initial claim that six
real solutions had exploited it; a site outage during that re-grade had
fabricated the victims, and every audited solution in fact orders correctly).

So d10-05's residual over-rejection is senior-reviewer nuance (security depth,
spec ambiguity), not noise.

**e-06 is the other flavor — and the sharpest result here.** We chased it. After
the same kind of polish (removing an elm-format artifact and a too-thin
ASCII-only test our neutralizer had introduced — exactly the two things Opus,
correctly, was rejecting on), the spotless `String.toList` reference is approved
3/3 by Opus and Sol but **still rejected by Haiku (3/3) and Sonnet (2/3)** —
every time on the same false premise: that Elm 0.19's `String.toList` counts
UTF-16 code units and so miscounts astral characters (`👍` → 2, `🇮🇱` → 4). It
doesn't — `String.toList` is code-point-aware (the grader's hidden holdout
confirms it, Opus states it outright, and these are the very models that *write*
`String.toList` as the fix when they author the task). Two tells mark it as a
knowledge error rather than nuance: Sonnet states the *correct* fact on trial 1
("String.toList combines UTF-16 surrogate pairs into single Char values") and
the false one on trials 2–3 under an identical prompt; and both models cite the
reference's own correct, *passing* astral test as a reason to reject — so certain
the code miscounts that they predict the test fails and hold that against it.
Meanwhile the real flaw (`String.length`) is rejected 12/12. So recognition of
the actual bug is perfect; what breaks is that two reviewers reject the correct
fix on a hallucinated language fact — the inverse of the echo bug, and a cleaner
generation-vs-recognition contradiction, since the model rejects the exact
answer it would itself write.

## Reading

Reviewer reliability on subtle code isn't a fixed "recognition is harder than
generation" — it's **domain-dependent vigilance, and it misfires in both
directions.** The echo bug hides in a domain reviewers treat as routine (JSON
output), so they relax and *endorse* it. Security, access, unicode, and
ordering bugs sit in domains reviewers are primed to scrutinize, so they turn
*hyper-critical* — catching real issues (including one the grader missed) but
also rejecting correct code, and on e-06 hardening into a *stable false belief*:
Haiku and Sonnet reject the correct `String.toList` fix — the one they'd write
themselves — because they misremember its Unicode semantics. The single-bug
"generation beats recognition" headline is one pole of that, not the whole
shape.

**Caveats.** n=3, four reviewers (no Fable/Gemini). Two references (d10-05,
e-06) initially carried neutralizer artifacts; both were polished spotless and
re-run, and the numbers above reflect the clean versions. The primary finding
(no flaw ever approved — 0 across all four tasks) is robust regardless.
Receipts: [`reviews.jsonl`](reviews.jsonl).
