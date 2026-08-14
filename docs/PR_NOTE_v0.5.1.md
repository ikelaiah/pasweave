# feat(navigation): add direct unit and section navigation for v0.5.1

## Summary

This PR completes the implementation and local-validation work for the
`v0.5.1` roadmap milestone. Readers can now move directly between generated
unit pages and jump to the symbol groups present on the current page without
returning to the API index or using global symbol search.

The existing unit routes, overload-aware symbol anchors, API-index role,
diagram scope, dependency-free offline output, direct-file input, and default
`///` workflow remain intact. No `v0.6.0` incremental-build work or later
roadmap scope is included.

## What changed

- Added a native **Switch unit** disclosure to every generated HTML unit page.
- Included a deterministic alphabetical link to every parsed unit, with the
  current page identified by `aria-current="page"`.
- Added a labelled local filter, polite match count, ArrowUp/ArrowDown link
  movement, Escape focus restoration, and visible open/closed state.
- Added an **On this page** navigator containing only the non-empty symbol
  groups rendered for the current unit: Types, Routines, Members, and
  Constants and variables.
- Added height-bounded scrolling for large unit sets and responsive stacking
  at tablet and phone widths.
- Added focused renderer, interaction, accessibility, responsive-layout,
  stable-route, and present-only-category regression coverage.
- Regenerated the documented and scientific HTML examples and application
  assets.
- Extended the GitHub Pages workflow to check the switcher, direct cross-unit
  link, category navigator, and enhancement script before upload and after
  deployment.
- Updated version metadata, portable-build defaults, README, roadmap,
  changelog, renderer and navigation guides, release guidance, example notes,
  `mathlib-fp` evidence, and the v0.5.1 release note.

## Design and safety notes

- The complete unit link list is server-rendered inside a native `<details>`
  element. JavaScript progressively filters that list; it does not create or
  replace navigation.
- Any unit is reachable from another by opening the disclosure and following
  one direct link, including when JavaScript is disabled.
- Unit links reuse `HTMLUnitFilename`; category links reuse the established
  `#types`, `#routines`, `#members`, and `#values` group IDs.
- Category visibility is derived from the same effective-renderability rules
  used to render the symbol groups, preventing links to absent sections.
- Filter text is compared against existing link `textContent`; user input is
  never interpreted as HTML.
- The implementation uses only existing Pascal, CSS, and local JavaScript
  facilities and introduces no dependency or remote runtime.
- The API index remains the canonical browse-all and architectural view.
  Dependency and type-relationship diagrams remain unchanged, and individual
  declarations were not added to the project graphs.

See [the HTML renderer guide](html-renderer.md),
[navigation and source traceability](navigation-and-source-traceability.md),
and the [v0.5.1 release note](../RELEASE_NOTE_v0.5.1.md) for the detailed
behavior, fallback, and rationale.

## Compatibility

- Generated unit routes remain `units/<UnitName>.html` and
  `units/<UnitName>.md`.
- Stable overload-aware symbol fragments and existing symbol-card permalinks
  are unchanged.
- Existing project-index search, diagrams, coverage, source links, and
  renderer output contracts remain intact.
- The search-index schema and parser-independent JSON model are unchanged.
- Direct file and directory inputs and default `///` documentation mode pass
  end to end.
- HTML remains self-contained and usable through `file://`, with no server,
  network connection, or runtime installation required.
- With JavaScript disabled, the native unit disclosure, every direct unit
  link, breadcrumbs, category links, and diagram text fallbacks remain usable.

## Validation

- [x] Complete automated suite passes with Free Pascal 3.2.2.
- [x] Production CLI builds and reports `PasWeave 0.5.1`.
- [x] Portable Windows build, embedded-asset packaging, isolated scientific-
      example smoke test, and checksum generation pass.
- [x] Direct-file input with the default `///` mode produces JSON, Markdown,
      HTML, diagnostics, search assets, and a unit page with zero errors.
- [x] Checked-in HTML, stylesheet, and application-script golden output
      matches the current renderer; unrelated Markdown and model goldens are
      unchanged.
- [x] Focused fixtures prove every unit directly links every other unit,
      current-page state is unique, empty categories are omitted, and stable
      unit filenames are preserved.
- [x] Isolated Chrome checks pass at 1280 and 390 CSS pixels, including local
      filtering, live status, ArrowDown, Escape, visible disclosure state,
      category fragments, viewport fit, and a clean console.
- [x] A JavaScript-disabled Chrome run opens the native disclosure and follows
      its direct unit link successfully.
- [x] Two builds of latest `mathlib-fp` commit
      `b5aea1c2d841fd82f9e98cb770c00fc04c2d9b17` parse 50 of 50 units into
      2,978 symbols and 2,707 search entries with zero errors.
- [x] All 50 `mathlib-fp` unit pages contain all 50 direct unit links, one
      current-page state, valid category targets, and retained project
      diagrams, with zero navigation audit failures.
- [x] Both `mathlib-fp` runs produce the same 174 files with audit digest
      `EE702B7A8727050A786AA4DF329F6B34EC8DFF7E7ECAFA508ED014C123C75952`.
- [x] A real-browser `mathlib-fp` check passes bounded 50-unit scrolling,
      filtering, keyboard focus, desktop layout, and 390-pixel phone layout.
- [x] Final five-axis review covers correctness, readability, architecture,
      security, and performance; its disclosure-state finding is fixed and
      regression-tested.

## Known limits

- Local unit filtering, enhanced Arrow-key movement, and global symbol search
  require the generated application script. The complete native unit list and
  category links remain available without it.
- The on-page navigator intentionally links symbol groups, not every
  declaration; global symbol search remains the detailed symbol finder.
- The unit list is rendered in full on every unit page to guarantee the
  two-action no-JavaScript path. Large lists are filtered and height-bounded,
  but are not virtualized.
- The public GitHub Pages site cannot validate this branch before merge. The
  workflow performs the same navigation assertions against the deployed site
  after `main` is published.

## Merge and release checklist

- [x] `PasWeaveVersion`, its regression assertion, portable-build default, and
      README badge are set to `0.5.1`.
- [x] `CHANGELOG.md`, `RELEASE_NOTE_v0.5.1.md`, roadmap status, detailed docs,
      examples, validation evidence, and golden output are updated.
- [x] Local tests, production build, portable release build, browser checks,
      direct-input validation, and `mathlib-fp` determinism checks pass.
- [x] The branch contains no `v0.6.0+` implementation or preparatory contract.
- [ ] Push `feature/v0.5.1-navigation-polish` and open the pull request against
      `main`.
- [ ] Confirm PR checks, including the Pages generated-site build gate, pass.
- [ ] Merge the reviewed PR into `main`.
- [ ] Confirm the Pages deployment and deployed-site smoke test pass at
      `https://ikelaiah.github.io/pasweave/`.
- [ ] Confirm the post-merge Windows build on `main` passes.
- [ ] Tag the verified merge commit as `v0.5.1` and push the tag.
- [ ] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` with the v0.5.1 release note.
