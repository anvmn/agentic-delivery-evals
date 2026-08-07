# Narration — one paragraph per scene (single source for TTS and subtitles)

## Scene 0 — motivation

I run a production health platform — legacy Drupal plus Elm — and AI agents now do real work on it. So the practical question: which model can I trust with this codebase? Who writes quality code here, and who can review it — catching the bug instead of waving it through? Public benchmarks rank models on fresh mainstream code, not on stacks like mine. So I measured it myself. Fourteen models, one question: which of these can be trusted in this stack?

## Scene 1 — hook

We gave fifteen real coding tasks to fourteen AI models from seven vendors. Five hundred and forty-five graded runs, about one hundred and thirty dollars of agent time. Almost every model passed almost everything. The story is the one task that didn't.

## Scene 2 — the suite

The tasks come from two under-measured territories: Drupal, the CMS behind a large share of institutional websites, in both its modern and its legacy versions — and Elm, a typed functional language for web apps. Every task is graded mechanically: compilers, tests, and live behavior probes. No AI judges, and every number regenerates from machine-readable receipts. Here is the scoreboard. A wall of green — with one exception.

## Scene 3 — the trap

So what is that one task? A classic Drupal seven job: a small web endpoint that returns JSON, restricted to users with the right permission. There is a one-line way to wire it that looks like textbook code — and the pattern is all over the internet. But it silently breaks the security requirement. Users who should get access denied instead get a friendly two hundred OK — whose entire body is the number three. That is the framework's internal access-denied code, helpfully converted to JSON. One line that looks right, compiles, runs — and quietly fails the one requirement that mattered.

## Scene 4 — the staircase

Blind, with no hints, only two models clear it: Fable five, six out of six — and the brand-new Opus five, five out of six. And Opus five's single miss? The exact same line. Every other model from every vendor sits at or near zero. Ten of the fourteen never passed it once. Model size doesn't explain it. Thinking time doesn't explain it. Something else is going on.

## Scene 5 — two wrong answers

Here is the strangest part. Every failure that actually engages the framework falls into one of just two wrong patterns. Pattern one: the delivery trap — the textbook-looking line we just saw. Grok wrote it, DeepSeek wrote it, Kimi wrote it, Gemini wrote it — and so did the human author of this benchmark. Pattern two: the echo instinct — printing the JSON directly instead of returning it through the framework. That one appears only in the Claude and Gemini lineages. Two patterns, seven vendors, zero exceptions. The corpus carries the disease without the vaccine: the wrong pattern is popular online, and the warning about it is not. Models fail exactly where that is true.

## Scene 6 — can more thinking fix it?

So can more thinking fix it? We reran the trap with every reasoning dial at its maximum. Opus four point eight went from one in six to two in three — a genuine rescue. The new Opus five went three for three. Everyone else: zero. Twenty-four maximum-effort runs across six vendors, twenty-four failures. One model spent ten thousand thinking tokens and still wrote the trap. Thinking harder cannot substitute for knowledge that is not there. But show the model its code failing on a live site — and almost every flagship recovers.

---

## Appendix — full motivation text (for written posts; not parsed for narration)

I work on a production digital-health platform — legacy Drupal on the backend, Elm on the frontend — and AI coding agents have become part of how work gets done on it. Which raises a very practical question: out of all these models, which one can I actually trust with *this* codebase? Who writes quality code here, who just writes plausible code? And when a model reviews a change — will it catch the bug that matters, or wave it through?

The public benchmarks can't answer that. They rank models on fresh Python and JavaScript in greenfield repos — not on a fifteen-year-old CMS with its own way of doing things, not on a typed functional frontend, not on the kind of code my platform is actually made of.

So I measured it myself: fifteen tasks distilled from my real production patterns, graded by compilers, tests, and live probes — never by another AI's opinion — with a receipt behind every number. Fourteen models, seven vendors, every one asked the same question: which of these can be trusted in this stack?
