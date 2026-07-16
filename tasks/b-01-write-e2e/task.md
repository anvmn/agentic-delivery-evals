# Task: end-to-end tests for the visit log

## Goal

Write Playwright end-to-end test(s) in `e2e/` proving the visit-log app works.
You are testing the app, not changing it: **do not modify anything outside
`e2e/`**.

## Context

The app (Elm, prebuilt via `./build.sh`) is a clinic visit log:

- a patient name input (`#patient-name`), a visit type select (`#visit-type`),
  an add button (`#add-visit`)
- added visits appear in the list (`#visit-list`, one `.visit-item` each)
- a counter badge (`#visit-count`) shows the number of visits
- visits are persisted in the browser and **must survive a page reload**

## Acceptance criteria

- [ ] Your tests cover **every** user-observable artifact of adding a visit:
      the list entry (with the entered data), the counter value, and
      persistence across reload. A test that only checks one of them is
      insufficient — the suite grades whether your tests would *catch a
      regression in each*.
- [ ] `npx playwright test` passes against the app as shipped.
- [ ] Tests are deterministic: no fixed sleeps; use Playwright's built-in
      waiting/assertions.

## Out of scope

- Modifying the app (`src/`, `index.html`, `build.sh`, configs).
- Visual/screenshot testing.

## Commands

```bash
npm install
npx playwright install chromium   # if not already present
./build.sh
npx playwright test
```
