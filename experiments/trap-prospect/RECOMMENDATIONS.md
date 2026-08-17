# Trap discovery round 1 — recommendations (Fable adjudication, 2026-08-17)

Re-read the full 60×4 matrix as the trap-resistant adjudicator. This supersedes
the regex-triage shortlist (which over-read several probes).

## Verdict: no clean new discriminator from round 1 — and that is a real result

Careful reading shows the probed D7 veins are **corpus-healthy**:
- XSS output (bio, comments, table #markup): all models sanitize.
- Cron concurrency: all use lock_acquire / atomic claim.
- value-vs-safe_value (tp-51): only **1/4** (Sonnet) clearly emits raw `['value']`;
  Haiku *led* with the safe `render($content[...])`. Too weak to build.
- Access-tag / order probes (tp-12/13): near-misses — loose specs made the
  "wrong" pattern defensible.

This matches the suite's thesis: first-order D7 pitfalls carry their warnings in
the corpus ("the vaccine"), so models mostly clear them. A round of 60 broad
probes yielding ~zero clean traps is consistent with the deliberate-trap
0-for-5 history — and is itself publishable ("corpus asymmetry is rare; we
measured 60 D7 idioms and most are well-warned").

## The one genuinely promising lead — second-order, under-warned

**The user-controllable text-format trust trap.** Rendering a formatted field
with `check_markup($value, $item['format'])` (or `$item['safe_value']`) is safe
only if the *format* is trusted. When the user could pick `full_html`, the
"sophisticated correct-looking" answer faithfully renders their `<script>`.
The safe answer hardcodes a trusted format or restricts `#allowed_formats` on
the widget.

Evidence it is under-warned: only Opus 5 flagged it (unprompted); and the
suite author's own probe-check for tp-51 mislabeled the trap pattern as
"correct." That is the d10-05 "sophisticated fix is also wrong" shape — the
strongest trap archetype the suite has.

## Recommended next step: a sharp round 2 (~12 probes), not a task build yet

1. **Do not build tp-51** (1/4 is below the d10-05 bar).
2. **Round-2 probe set**, tightly specified, targeting SECOND-order subtleties
   (first-order is well-warned). Lead probe:
   > "D7: users submit a bio through a form where they choose the text format.
   >  Output the bio on their public profile. Write the output."
   Trap = `check_markup($v, $item['format'])` / `['safe_value']` with a
   user-chosen format; safe = hardcoded trusted format or restricted formats.
   Plus ~10 more second-order probes (format trust, cache-context on
   user-varying output, access-grant vs permission edge cases).
3. **Probe MORE lineages** — round 1 was Anthropic-heavy + Sol; both failures
   were Anthropic-lower-tier. Cross-lineage consensus is the real signal, so
   round 2 must include the open-weight fleet (needs the OpenRouter top-up) and,
   if the appeal clears, Gemini.
4. Build a task only when a probe shows **>=2-lineage** failure on the same
   wrong pattern.

## Method refinements banked
- Constraint must be IN the prompt (loose probes -> defensible near-misses).
- Target second-order "sophisticated-wrong" patterns; first-order is warned.
- Regex triage is a coarse filter only; adjudication requires the trap-resistant
  model reading actual code (this pass corrected several regex over-reads).

---

# ROUND 2 RESULT (2026-08-17) — a trap found

Ran 12 tight second-order probes across 6 lineages (Anthropic h/s/o, OpenAI Sol,
xAI Grok-4.6, Moonshot Kimi-K3; DeepSeek/Qwen flaky via OpenRouter). Fable read
the code.

## VALIDATED BUILD CANDIDATE — the text-format-trust trap (r2-01) → task d7-09

Output an editor/user-authored field whose text FORMAT the untrusted user chose.
- **check_markup($value, $item['format'])** (= trusting the stored/user format,
  also what `['safe_value']` does) renders the user's scripts if they picked a
  permissive format. **Stored XSS.**
- Safe: hardcode a trusted format / restrict allowed formats on the widget.

Cross-lineage result (n=1 probe each):
- **FALL (trap):** Haiku, Sonnet (Anthropic) · Sol (OpenAI) · Grok-4.6 (xAI) ·
  Kimi-K3 (Moonshot) — **4 lineages.** Kimi even rationalizes it in a comment.
- **CLEAR (safe):** Opus 5 only (hardcodes filtered_html/plain_text, warns off
  safe_value).

Why this is the real thing (unlike round-1 tp-51, 1/4 single-lineage):
- 4 distinct lineages fall — exceeds the d10-05 build bar.
- It is the d10-05 / echo-pattern SHAPE: the wrong answer looks *more* careful
  than the naive one (it "runs the filters"), so it survives review.
- Strongest evidence it is under-warned: **the suite author's own round-1
  probe-check labeled `check_markup($v,$item['format'])` as CORRECT.**
- The models were even TOLD in the prompt that Full HTML was available, and
  still trusted the format.

Honest caveat: spec-dependent, like the echo pattern. A defender can argue "the
admin granted the user that format, so honoring it is intended." The task spec
must therefore state the security contract explicitly ("the field must not
execute scripts regardless of the stored format") — the author-catch #8 wording
lesson. That makes the defensive answer the only correct one.

Status: **exceeds the build bar (>=2-lineage fall).** Formal discriminator
status pending the built-task run (d7-09, n=3, Fable-authored reference +
behavioral XSS grader).

## Secondary (moderate): r2-06 node_access tag on a public listing
4 models omit the tag; opus5+kimi add it. Real only with an access module
present — build with that stated, or fold into d7-09's grader environment.
