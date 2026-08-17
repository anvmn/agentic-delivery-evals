# Trap discovery round 1 — resume state

**Method:** one-shot D7 consensus probes; ≥3/4 models converging on the same
*spec-violating* answer = trap candidate. Full plan:
`~/.claude/plans/lets-leave-the-rerun-quiet-pebble.md`.

## State (as of 2026-08-17 ~19:52)

- `prompts.jsonl` — 60 probes, each with an observable `check`. Committed.
- `answers/<id>__<model>.txt` — raw one-shot answers (gitignored, durable path).
  - **Sol: 60/60 complete.** Claude fleet (haiku/sonnet/opus5): partial, sweep running.
- `.backups/answers-*.tgz` — periodic snapshots (belt-and-suspenders).
- First 6 probes verified corpus-healthy (well-warned areas → correct consensus).

## Resume the sweep (one command, resume-safe)

```bash
cd ~/projects/agentic-delivery-evals/experiments/trap-prospect && nohup ./sweep.sh > sweep.stdout 2>&1 &
```

Skips every existing non-empty answer; only fills gaps. The Claude lane runs
**lean** (empty cwd, `--setting-sources ""`, empty `--mcp-config`, no repo
context) so it won't exhaust the Max quota the way the first heavy run did.
A stale `LIMIT on ... at tp-07` line from the first (heavy) run sits in
`sweep.log` — ignore it; watch for `DONE cells=` or a fresh `LIMIT`.

## Next steps after the fleet completes (all 60 × 4)

1. Cluster the 4-model matrix; flag ≥3/4 consensus on a spec-violating pattern.
   Highest-potential veins are the access-leak / value-vs-safe_value probes in
   the tp-40s/50s (untested by the fleet until this run finishes).
2. **Fable 5 adjudicates** each candidate vs D7 core source (NOT main-loop
   recollection — bias guard): `claude -p --model claude-fable-5`.
3. Shortlist → `FINDINGS-candidates.md`; build top 3 into tasks (Fable authors
   the reference solutions + graders), suite → 0.4.0 on first validated task.
