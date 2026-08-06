# Narration — one paragraph per scene (single source for TTS and subtitles)

## Scene 0 — motivation

I run a production health platform — legacy Drupal plus Elm — and AI agents now do real work on it. So the practical question: which model can I trust with this codebase? Who writes quality code here, and who can review it — catching the bug instead of waving it through? Public benchmarks rank models on fresh mainstream code, not on stacks like mine. So I measured it myself. Fourteen models, one question: can I trust you here?

## Scene 1 — hook

We gave fifteen real coding tasks to fourteen AI models from seven vendors. Five hundred and forty-five graded runs, about one hundred and thirty dollars of agent time. Almost every model passed almost everything. The story is the one task that didn't.

## Scene 2 — the suite

The tasks come from two under-measured territories: Drupal, the CMS behind a large share of institutional websites, in both its modern and its legacy versions — and Elm, a typed functional language for web apps. Every task is graded mechanically: compilers, tests, and live behavior probes. No AI judges, and every number regenerates from machine-readable receipts. Here is the scoreboard. A wall of green — with one exception.

---

## Appendix — full motivation text (for written posts; not parsed for narration)

I work on a production digital-health platform — legacy Drupal on the backend, Elm on the frontend — and AI coding agents have become part of how work gets done on it. Which raises a very practical question: out of all these models, which one can I actually trust with *this* codebase? Who writes quality code here, who just writes plausible code? And when a model reviews a change — will it catch the bug that matters, or wave it through?

The public benchmarks can't answer that. They rank models on fresh Python and JavaScript in greenfield repos — not on a fifteen-year-old CMS with its own way of doing things, not on a typed functional frontend, not on the kind of code my platform is actually made of.

So I measured it myself: fifteen tasks distilled from my real production patterns, graded by compilers, tests, and live probes — never by another AI's opinion — with a receipt behind every number. Fourteen models, seven vendors, every one asked the same question: can I trust you here?
