# Task: JSON decoder & encoder for the Patient type

## Goal

Implement `Codec.decoder` and `Codec.encode` in `src/Codec.elm` so that Patient
values survive a JSON round-trip unchanged.

## Context

`src/Patient.elm` defines the types (do not modify it):

- `Patient` — id, name, contact, tags
- `Contact` — optional email, list of phones
- `Phone` — label, number

`src/Codec.elm` contains the two stubs to implement. The JSON shape mirrors the
field names exactly (camelCase, arrays for lists; a missing or null `email`
maps to `Nothing` and encodes back as `null`).

## Acceptance criteria

- [ ] `Json.Decode.decodeValue Codec.decoder (Codec.encode p) == Ok p` for any
      Patient value — including: `email = Nothing`, empty `phones`, empty
      `tags`, unicode in any string field, and negative/zero ids.
- [ ] `elm make src/Codec.elm` succeeds with no warnings-as-errors tricks.
- [ ] `npx elm-test` passes (write at least one round-trip test of your own).
- [ ] Code is `elm-format` clean.

## Out of scope

- Changing `src/Patient.elm` or `elm.json`.
- Any UI. This is a codec task only.

## Commands

```bash
npm install          # once — brings elm-test
npx elm-test         # run tests
npx elm-format --validate src/
```
