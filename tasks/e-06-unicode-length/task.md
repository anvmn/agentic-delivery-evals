# Task: count Unicode characters correctly

## Goal

Implement `TextStats.characterCount : String -> Int` returning the number of
**Unicode characters (code points)** in the string — for any string a user
might type, in any language, emoji included.

## Context

`src/TextStats.elm` has the stub. This function will size-limit patient
notes, so correctness matters for non-Latin text.

## Definition (the contract)

The count is of *code points*, exactly:

- `"abc"` → 3
- `"שלום"` → 4
- `"👍"` → 1 (one code point, even though it's outside the Basic
  Multilingual Plane)
- `"🇮🇱"` → 2 (a flag is two regional-indicator code points)
- `"👩‍👩‍👧"` → 5 (three people joined by two zero-width joiners)

Grapheme clusters ("user-perceived characters") are explicitly *not* the
contract — code points are.

## Acceptance criteria

- [ ] Correct counts for all of the above and anything like them (astral
      plane, combining marks, mixed scripts).
- [ ] `npx elm-test` passes (write at least one test of your own).
- [ ] `elm-format` clean; no dependencies added.

## Out of scope

- Grapheme segmentation, normalization, byte counts.

## Commands

```bash
npm install
npx elm-test
npx elm-format --validate src/
```
