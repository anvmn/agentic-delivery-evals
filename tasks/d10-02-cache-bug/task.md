# Task: fix the stale notice block (Drupal 10)

## Goal

The `notice_board` module's block shows the latest published *notice* node's
title — but it shows a **stale** title after a new notice is created, until
caches are rebuilt. Fix the caching metadata so the block updates when
notices change, **without turning caching off**.

## Context

Drupal 10 module, one block plugin:
`src/Plugin/Block/LatestNoticeBlock.php`. The render array is cached
permanently with no invalidation information — that's the bug. The fix is
proper cacheability metadata, the way Drupal's render cache is designed to
be used.

## Acceptance criteria

- [ ] After a new *notice* node is published, the block shows its title on
      the next render **without** any cache rebuild (`drush cr`) or cache
      clears in module code.
- [ ] The block remains cacheable: solutions that set `max-age = 0`, disable
      caching, or clear caches programmatically are explicitly failing
      solutions.
- [ ] `php -l` passes on all module files; Drupal coding standards style.

## Out of scope

- Changing what the block displays or how the query works.
- Config, theming, new dependencies, other cache layers (page_cache module
  etc. stay as they are).

## Commands

There is no site in this workspace — implement against documented Drupal 10
render-cache APIs.

```bash
php -l src/Plugin/Block/LatestNoticeBlock.php
```
