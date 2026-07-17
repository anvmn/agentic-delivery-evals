# Task: per-user greeting block, correctly cached (Drupal 10)

## Goal

Implement the `greeting_board` module's block: it greets the **current
user** by name and shows how many published *notice* nodes exist. It must be
correct for every user, always — and it must stay cacheable.

## Context

Drupal 10. The block plugin skeleton is in
`src/Plugin/Block/GreetingBlock.php` — implement `build()`. The *notice*
content type exists on the target site.

## Required output

The block's rendered text: `Hello {username} — {count} notices`
(username = the display name of the user viewing the block; count = number
of **published** notice nodes).

## Acceptance criteria

- [ ] Every user sees **their own** name — under all circumstances,
      including render caching. A user must never be served another user's
      greeting.
- [ ] The count updates when a notice is created/published — without any
      manual cache clearing.
- [ ] The block remains cacheable: `max-age = 0`, disabling caching, or
      clearing caches in module code are failing solutions.
- [ ] `php -l` passes; Drupal coding standards style.

## Out of scope

- Configuration, theming, permissions beyond the default.
- Anonymous users (the block is used on authenticated pages).

## Commands

There is no site in this workspace — implement against documented Drupal 10
render/cache APIs.

```bash
php -l src/Plugin/Block/GreetingBlock.php
```
