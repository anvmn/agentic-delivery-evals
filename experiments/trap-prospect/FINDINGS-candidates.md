# Trap discovery round 1 — candidate shortlist (2026-08-17)

Full 60-probe × 4-model sweep complete (240/240, 0 failures). Consensus probing
across the warning-poor D7 corpus. Below: what survived triage + reading.
(Adjudication note: reads below are preliminary — the reference solutions for
any task build are authored/verified by Fable 5 against D7 core source, per the
plan's Model-roles bias guard.)

## Lead candidate — BUILD IT

### C1 · Field output: `['value']` vs `['safe_value']` (XSS)  [from tp-51]

Prompt: output a `text_long` field the editor entered, on a node page.

- **haiku** → `print $field[0]['value'];`  (raw → XSS)
- **sonnet** → `print $node->field_body[LANGUAGE_NONE][0]['value'];`  (raw → XSS)
- **opus5** → `check_markup($items[0]['value'], $items[0]['format'])`  (safe)
- **sol** → `render(field_view_field(...))`  (safe)

Why it qualifies: the popular pattern (`['value']`) emits **unfiltered** stored
HTML — a real stored-XSS — while the safe path (`['safe_value']` / check_markup /
field_view_field) is a distinct, less-documented idiom. Produces a d7-01-style
**capability staircase** (weaker models fail, stronger clear it). Security-
flavored, high severity, genuinely warning-poor in the corpus.

Caveat vs the d10-05 bar: consensus here is **lineage-concentrated** (both
failures are Anthropic-lower-tier; Sol cleared it). d7-01's echo instinct is
also lineage-concentrated, so this doesn't disqualify — but the real test is
running the built task against the open-weight fleet (Grok/DeepSeek/Kimi/Qwen).
If they also emit raw `['value']`, it's a strong cross-lineage discriminator.

## Secondary — watch / re-probe tighter

- **C2 · Autocomplete node_access leak** [tp-53] — haiku+sonnet omit the
  `node_access` tag on an any-authenticated-user title autocomplete (unpublished
  titles leak); opus5+sol tag it. 2/4, worth a tighter re-probe.
- **C3 · JSON list delivery + access** [tp-55] — 3/4 reach for
  `drupal_json_output` and skip the access tag — but this largely **re-treads
  d7-01's delivery trap**; the fresh angle is the missing node_access on a
  public list. Interesting but overlapping.

## Method lesson (drives round 2)

Loosely-specified probes yield **defensible near-misses, not traps** (tp-12,
tp-13). The observable constraint must be IN the prompt. Round-2 probes: bake
the requirement in (e.g. "public profile, PUBLISHED, newest-first") and lean
hard into the security veins, where the corpus is genuinely warning-poor.

## Verdict

1 solid lead (C1), 2 secondaries. Round 1's loose probes limited the yield, as
predicted — but the tight security-flavored probes delivered exactly one
d7-01-shaped candidate worth building into task **d7-09** (Fable authors the
reference + grader; validate blind against the full fleet).
