# Task: classify and summarize MUAC measurements

## Goal

Implement MUAC (mid-upper-arm-circumference) nutrition classification and a
summary over a batch of measurements. Exposed API (do not rename):

```elm
module Nutrition exposing (Status(..), classifyMuac, summarize)

type Status
    = Normal
    | Moderate
    | Severe

classifyMuac : Float -> Status
summarize : List Float -> { normal : Int, moderate : Int, severe : Int, anySevere : Bool }
```

## The classification rule (millimetres — read the boundaries exactly)

- `muac < 115` → `Severe`
- `115 <= muac < 125` → `Moderate`
- `muac >= 125` → `Normal`

These cutoffs are clinical definitions: the boundary values **115.0** and
**125.0** matter. `115.0` is `Moderate` (not Severe). `125.0` is `Normal`
(not Moderate). Getting `<` vs `<=` wrong at the cutoff is the classic error.

## summarize

Count each status across the list, and set `anySevere = True` iff at least
one measurement classifies as `Severe`. An empty list gives all-zero counts
and `anySevere = False`.

## Acceptance criteria

- [ ] `classifyMuac` correct across the ranges, exact at 115.0 and 125.0.
- [ ] `summarize` counts correctly and sets `anySevere` correctly, including
      the empty list.
- [ ] `npx elm-test` passes (write at least one of your own).
- [ ] `elm-format` clean; no dependencies added.

## Commands

```bash
npm install
npx elm-test
npx elm-format --validate src/
```
