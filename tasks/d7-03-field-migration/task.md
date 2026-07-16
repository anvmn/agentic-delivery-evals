# Task: normalize stored phone numbers via update hook (Drupal 7)

## Goal

The `phonebook` module's content type *contact* has a text field
`field_phone` holding years of inconsistently formatted Israeli phone
numbers. Write **`hook_update_7100`** in `phonebook.install` that normalizes
every stored value to E.164 — correctly, for all rows, including revisions.

## Context

Drupal **7**, Field API storage. Values currently look like any of:
`054 123 4567`, `054-1234567`, `(054) 123-4567`, `0541234567`,
`+972 54-123-4567`, and some are already normalized (`+972541234567`).
Some contacts have no phone value at all. Some nodes have **multiple
revisions**, with old formats in older revisions.

## Normalization rules

1. Remove all separators (spaces, dashes, parentheses) — keep digits and a
   leading `+`.
2. A national number starting with `0` becomes `+972` + the number without
   the leading `0` (`0541234567` → `+972541234567`).
3. A value already starting with `+972` keeps its digits (separators still
   removed).
4. Empty/absent values stay untouched — do not create rows that don't exist.

## Acceptance criteria

- [ ] After `drush updb`, **every** stored value — current *and* revision
      data — is in E.164 form per the rules above.
- [ ] No rows are added or lost in any field storage table.
- [ ] Already-normalized values pass through unchanged.
- [ ] The update is a proper D7 update hook: `hook_update_7100` in
      `phonebook.install`, safe to run once via `drush updb`, returning a
      message. Do not modify `hook_install()`.
- [ ] `php -l` passes on every file in the module.

## Out of scope

- Validating that numbers are *real* — this is formatting only.
- UI, new fields, D8+ APIs (config, services, post_update files — none of
  these exist in Drupal 7).

## Commands

There is no site in this workspace — write to documented Drupal 7 APIs.

```bash
php -l phonebook/phonebook.install
```
