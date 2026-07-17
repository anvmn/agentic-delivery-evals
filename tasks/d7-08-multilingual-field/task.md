# Task: language-correct field access (Drupal 7)

## Goal

Implement `langfield_body_value($node, $langcode)` in `langfield.module`,
returning an `article` node's body text **in the requested language**, with a
defined fallback.

## Context

Drupal **7**. The fixture's `hook_install()` (do not modify) creates content
type `article` with a **translatable** text field `field_body`. A node can
therefore hold different `field_body` values per language (stored under the
language code, e.g. `en`, `rw`), plus possibly a language-neutral value under
`LANGUAGE_NONE` (`'und'`).

## The contract

`langfield_body_value($node, $langcode)` returns:

1. the `field_body` value for `$langcode` (resolved through the Field API's
   language handling), if present; else
2. the value for `LANGUAGE_NONE` (`'und'`), if present; else
3. the empty string `''` when the node has no body value at all.

The trap: the ubiquitous pattern
`$node->field_body[LANGUAGE_NONE][0]['value']` (or `field_get_items()` with
no/`'und'` language) ignores `$langcode` and returns the wrong value — or
nothing — for translated content. Resolve the requested language.

## Acceptance criteria

- [ ] For a node with `en` and `rw` bodies (no `und`), the function returns
      the `rw` text for `'rw'` and the `en` text for `'en'`.
- [ ] For a node with only an `und` body, any `$langcode` returns that value
      (fallback rule 2).
- [ ] For a language with no value and no `und`, returns `''`.
- [ ] `php -l` passes.

## Out of scope

- Writing translations, the translation UI, entity_translation contrib.

## Commands

There is no site in this workspace — write to documented Drupal 7 Field API
language handling (`field_get_items`, `field_language`, `LANGUAGE_NONE`).

```bash
php -l langfield/langfield.module
```
