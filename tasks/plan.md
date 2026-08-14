# Implementation Plan: PasWeave v0.5.1 navigation polish

## Overview

Add direct unit-to-unit and in-page category navigation to generated HTML unit
pages. The unit switcher remains a complete native link list without
JavaScript, gains filtering and keyboard support when the local application
script runs, and preserves every existing unit URL and symbol anchor.

This plan is strictly limited to the `v0.5.1` roadmap. Incremental builds,
project configuration, theming, portability expansion, contract freezing, and
all `v0.6.0+` work are out of scope.

## Architecture decisions

- Render the unit switcher as a native `<details>` element containing all
  sorted unit links. This makes every other unit reachable by opening the
  switcher and following one link, even when JavaScript is unavailable.
- Enhance, rather than create, navigation with JavaScript. A local filter,
  live match count, Arrow-key movement, and Escape behavior operate on the
  server-rendered link list.
- Build the on-page navigator from the same renderable symbol groups already
  used by the unit page: Types, Routines, Members, and Constants and variables.
  Omit links for empty groups.
- Reuse `HTMLUnitFilename` and the existing group IDs. Do not change
  `units/<UnitName>.html`, project-index routes, symbol IDs, or diagram scope.
- Keep the API index and global symbol search unchanged as the canonical
  browse-all experience.

## Task list

### Phase 1: Static navigation contract

- [x] Task 1: Add failing renderer tests for the complete sorted unit list,
  current-unit state, two-action no-JavaScript path, present-only category
  links, and unchanged routes/anchors.
- [x] Task 2: Render the unit switcher and on-page category navigator on every
  HTML unit page.

### Checkpoint: Static navigation

- [x] Focused tests prove every fixture unit links directly to every other
  unit through the switcher.
- [x] Empty symbol categories do not produce dead on-page links.
- [x] Existing unit filenames and symbol anchors remain unchanged.

### Phase 2: Search, keyboard access, and responsive layout

- [x] Task 3: Add failing asset-contract tests for filtering, live status,
  ArrowUp/ArrowDown, Escape, visible focus, and phone-width layout.
- [x] Task 4: Implement the dependency-free unit-switcher JavaScript and
  responsive CSS while retaining the unmodified native link fallback.
- [x] Task 5: Verify the generated pages in a real browser with JavaScript
  enabled and disabled at desktop and phone widths.

### Checkpoint: Interaction

- [x] Keyboard users can open, search, traverse, dismiss, and follow unit
  links with visible focus.
- [x] The switcher and category navigator fit without horizontal overflow at
  the repository's phone breakpoint.
- [x] No external runtime dependency is introduced.

### Phase 3: Examples and deployed-showcase gate

- [x] Task 6: Regenerate and verify the documented API sample output.
- [x] Task 7: Regenerate and verify the scientific API sample output and add
  Pages workflow assertions for the switcher and category navigator.
- [x] Task 8: Validate the latest `mathlib-fp` corpus and record unit-count,
  navigation, responsive, keyboard, and determinism evidence.

### Checkpoint: Validation corpora

- [x] Examples and `mathlib-fp` satisfy the v0.5.1 navigation contract.
- [x] Unrelated generated output remains deterministic.
- [x] The Pages workflow is ready to validate the deployed showcase after
  merge.

### Phase 4: Release contract

- [x] Task 9: Update README and detailed renderer/navigation documentation,
  including no-JavaScript behavior and limitations.
- [x] Task 10: Update changelog, roadmap status, release note, version
  metadata, portable-build default, and version regression test to `0.5.1`.
- [ ] Task 11: Run the complete suite, production and portable builds where
  available, deterministic sample checks, and final five-axis review.

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| JavaScript becomes required for unit navigation | Violates offline/no-JS contract | Render the full native link list first; JavaScript only hides non-matches. |
| Large projects create an unwieldy switcher | Poor keyboard and responsive usability | Use a bounded scroll panel, filter, live count, and deterministic alphabetical order. |
| New category links point to absent sections | Broken in-page navigation | Derive links from non-empty renderable groups using the renderer's existing visibility rules. |
| Navigation changes alter stable routes or anchors | Breaks saved links | Reuse existing filename/anchor helpers and add explicit regression assertions. |
| Browser behavior differs from string-level tests | Accessibility or layout regression | Perform real-browser keyboard, no-JS, and narrow-viewport checks on generated examples. |
| Deployed validation cannot complete before merge | External release gate remains open | Make CI assertions part of the branch and report deployed-site validation as the post-merge gate. |

## Definition of done

- [ ] Every `v0.5.1` exit criterion has code, focused tests, documentation, or
  explicit post-merge deployed-site evidence.
- [x] No `v0.6.0+` capability or preparatory contract is introduced.
- [x] Existing unit URLs, symbol anchors, API-index role, and diagram scope are
  unchanged.
- [ ] Full tests and production build pass; direct-file and default-`///`
  workflows still work end to end.
