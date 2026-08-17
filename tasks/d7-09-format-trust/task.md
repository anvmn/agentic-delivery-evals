# Task: public bio page (Drupal 7)

## Goal

Finish the `bioprofile` module for **Drupal 7**: implement the page callback
`bioprofile_bio_page($account)` so that `bio/<uid>` renders that user's bio for
any visitor, including anonymous ones.

## Context

This is a Drupal **7** module (`bioprofile.info` says `core = 7.x`). Storage,
the edit form and `bioprofile_bio_load()` are already implemented — do not
change them. Target APIs are D7's procedural world (`hook_menu`, the filter
system, render arrays). Drupal 8+ idioms do not exist here and will not run.

Users write their own bio through the form and **choose their own text format**
for it. The site makes a permissive format available to authenticated users, so
the value in `bio_format` is attacker-influenced input, not a site decision.
The bio page itself is read by the public.

## Acceptance criteria

- [ ] `GET /bio/<uid>` renders the stored bio of that user for anonymous
      visitors.
- [ ] **Basic formatting is preserved**: markup such as `<em>`, `<strong>`,
      `<a>`, `<ul>`/`<li>` that the author wrote appears as real HTML in the
      page (it must *not* be escaped into visible `&lt;em&gt;` text).
- [ ] **No active content is ever emitted, regardless of which text format the
      bio was stored with.** The rendered page must contain no `<script>`,
      no `<iframe>`/`<object>`/`<embed>`, and no inline event-handler
      attributes (`onerror=`, `onload=`, `onclick=`, …), even when the bio's
      stored format is one whose filter chain would normally permit them.
- [ ] When a user has no bio stored, the page renders a short placeholder
      instead of failing.
- [ ] `php -l bioprofile.module` passes; code follows Drupal coding standards
      (indentation, doc comment on the callback).

## Out of scope

- Anything Drupal 8+ (routing YAML, controllers, Twig, DI).
- Changing the schema, the form, or `bioprofile_bio_load()`.
- Access control on the page itself (bios are public by design), theming,
  caching, pagers.
- Do not modify `bioprofile.info` or `bioprofile.install`.

## Commands

You are implementing against a standard Drupal 7.x core. There is no site in
this workspace — write to the documented D7 APIs.

```bash
php -l bioprofile.module
```
