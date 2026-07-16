# Validation status

Graders are tested against their own reference solutions (must PASS) and
against raw/insufficient submissions (must FAIL on the intended stage) —
the suite applies its own "test the smoke detector" rule to itself.

| Task | Grader self-test | Status (2026-07-16) |
| --- | --- | --- |
| e-01-decoder-roundtrip | reference PASS · fixture FAIL (unit) | ✅ validated |
| e-02-impossible-states | reference PASS · fixture FAIL (impossible_states) | ✅ validated |
| b-01-write-e2e | reference PASS · lazy-test FAIL (broken_detected) · empty FAIL (has_tests) | ✅ validated |
| d7-01-menu-endpoint | pending — needs provisioned D7 site | ⚠️ written, not validated live |
| d10-02-cache-bug | pending — needs provisioned D10 site | ⚠️ written, not validated live |

## Next sitting checklist

1. `tasks/d7-01-menu-endpoint/provision.sh` (network: D7 core tarball; ddev site install)
2. `tasks/d10-02-cache-bug/provision.sh` (network: composer create-project; ddev site install)
3. Self-test both Drupal graders: reference solution → PASS, raw fixture → FAIL;
   for d10-02 additionally verify the render-cache staleness actually reproduces
   across separate drush invocations (the behavior stage depends on it).
4. One end-to-end `runner/run.sh --only e-01-decoder-roundtrip --models <one> --trials 1`
   to validate the adapter (headless flags, cost extraction) before the seed matrix.
5. Seed matrix: `runner/run.sh --models "claude-opus-4-8,claude-fable-5" --trials 3 --max-cost-usd 15`
6. `runner/report.sh` → review RESULTS.md → recalibrate any task that reads
   trivially-easy or brittle → then (and only then) discuss publishing.
