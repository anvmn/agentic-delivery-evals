# Trap discovery round 1 — interim findings (2026-08-17)

## Method: validated

Consensus probing cleanly separates corpus-healthy areas (all models converge
on the *safe* pattern — e.g. conditional-required fields, email validation,
output sanitization: tp-01..tp-08 mostly healthy) from divergence. The pipeline
works and is cheap (~$0.02–0.06/probe, Max plan).

## Key lesson: probe tightness is the whole game

The first analyzed batch produced **near-misses, not clean traps** — because
several probes are under-specified. The popular "wrong" pattern shows up, but
the loose prompt makes it *defensible*, so there is no violation:

- **tp-12** ("list the current user's articles") — 3/4 omit the node_access
  tag, but for one's *own* content that is defensible; no leak proven.
- **tp-13** ("EFQ then load a field") — the load reorders vs the query, and two
  models even add an ORDER BY the load silently discards — but the prompt never
  *required* ordered output, so nothing is violated.

d7-01 and d10-05 bite precisely because their specs make the corpus pattern
**definitely** wrong (anon MUST get 403; return the **5 newest published**).
The fix for the next probe round: bake the observable constraint INTO the
prompt as a hard requirement, not just record it on the grader side. E.g.
tp-12 → "public profile page listing the user's **published** articles,
**newest first**" turns access-tag + status + order into forced requirements.

## Status

- Sol column 60/60; Claude fleet self-healing toward 60 (transient rolling
  limits, auto-retry). 25 probes fully covered so far.
- Still to do: full-matrix Fable adjudication (against D7 core source), and the
  tighter security-flavored probes (CSRF-delete, value-vs-safe_value field
  output, private-file access — tp-45..tp-60) which are better-specified.
