# Task: decode a list of tagged events

## Goal

Implement `Events.decoder : Decoder (List Event)` that decodes a JSON array
of tagged event objects into Elm values — and **fails informatively** when
an event is malformed, rather than silently mis-decoding it.

## The type (exposed as given — do not rename)

```elm
module Events exposing (Event(..), decoder)

type Event
    = Visit Int        -- {"type":"visit","clinic":<int>}
    | Note String      -- {"type":"note","text":<string>}
    | Measurement Float -- {"type":"measurement","value":<number>}
```

## The contract

Each array element is an object with a `"type"` discriminator:

- A well-formed object decodes to its variant.
- An object whose `"type"` is **known but whose payload is malformed** (wrong
  or missing fields) must make the **whole decode fail** — it must NOT fall
  through and be decoded as a different variant.
- An unknown `"type"` must fail.

The subtlety this tests: `Decode.oneOf [visit, note, measurement]` satisfies
the happy path but violates the contract — a malformed `visit` that happens
to carry a `text` field will be silently accepted as a `Note`. Dispatch on
the `"type"` field first.

## Acceptance criteria

- [ ] Valid arrays decode to the right variants, in order.
- [ ] A malformed known-type element yields `Err` (not a wrong variant).
- [ ] An unknown-type element yields `Err`.
- [ ] `npx elm-test` passes (write at least one of your own).
- [ ] `elm-format` clean; no dependencies added.

## Commands

```bash
npm install
npx elm-test
npx elm-format --validate src/
```
