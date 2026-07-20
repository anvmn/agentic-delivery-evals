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

The failure mode inverted instead: on the subtle treatments, reviewers
**over-reject** — they rejected the *correct* reference (d10-05: all 4; e-06:
3 of 4; d7-06: 2 of 4), while the control d7-07 was perfect (all 4 approved the
reference and rejected the flaw).

**And the over-rejection is mostly the reviewers being right, not trigger-happy.**
Reading the reasons: Opus and Sonnet independently flagged that d10-05's
`loadMultiple()` can discard the `created DESC` sort — a real requirement the
grader wasn't checking, now [author-catch #7](../../VALIDATION.md). Others
raised the `empty('0')` center-id edge and the published-vs-viewable access
debate — sophisticated, defensible concerns. One rejection was our artifact
(the neutralizer misplaced d10-05's `@file` docblock; Haiku correctly flagged
the coding-standards violation).

## Reading

Reviewer reliability on subtle code isn't a fixed "recognition is harder than
generation" — it's **domain-dependent vigilance, and it misfires in both
directions.** The echo bug hides in a domain reviewers treat as routine (JSON
output), so they relax and *endorse* it. Security, access, unicode, and
ordering bugs sit in domains reviewers are primed to scrutinize, so they turn
*hyper-critical* — catching real issues (including one the grader missed) but
also rejecting correct code. The single-bug "generation beats recognition"
headline is one pole of that, not the whole shape.

**Caveats.** n=3, four reviewers (no Fable/Gemini). The reference solutions
turned out not to be spotless (real subtleties the grader didn't check), which
complicates the reference/false-alarm arm — but the primary finding (no flaw
ever approved) is robust to that. Receipts: [`reviews.jsonl`](reviews.jsonl).
