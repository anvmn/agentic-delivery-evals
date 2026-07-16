# Task: make invalid verification states impossible

## Goal

`src/Verification.elm` currently allows nonsense: a record can claim
`verified = True` while carrying no timestamp and no verifier. Remodel the
module so that **invalid states cannot be constructed at all** — not guarded
against at runtime; unrepresentable at compile time.

## Context

The current model is a transparent record:

```elm
type alias Verification =
    { verified : Bool, verifiedAt : Maybe Int, verifier : Maybe String }
```

Callers throughout a real codebase would construct and pattern-match this
freely, so the fix is a proper opaque type with a small API.

## Required API (exact names and signatures — callers depend on them)

```elm
module Verification exposing (Verification, init, isVerified, markVerified, verificationInfo)

init : Verification                                  -- unverified
markVerified : Int -> String -> Verification -> Verification
isVerified : Verification -> Bool
verificationInfo : Verification -> Maybe { at : Int, by : String }
```

## Acceptance criteria

- [ ] It is impossible to construct (or transition into) a value where
      `isVerified` is `True` but `verificationInfo` is `Nothing`, or vice
      versa. External code must not be able to build `Verification` values
      except through this API.
- [ ] `isVerified init == False`; after `markVerified t by`, `isVerified`
      is `True` and `verificationInfo` returns `Just { at = t, by = by }`.
- [ ] `elm make src/Verification.elm` succeeds; code is `elm-format` clean.

## Out of scope

- Persistence, JSON, UI. Model and API only.
- Adding dependencies.

## Commands

```bash
npm install
npx elm make src/Verification.elm --output=/dev/null
npx elm-format --validate src/
```
