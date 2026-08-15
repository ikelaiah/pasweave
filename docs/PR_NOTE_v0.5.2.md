# feat(discovery): add A–Z symbol index and reader themes for v0.5.2

## Summary

This PR completes the implementation and local-validation work for the
`v0.5.2` roadmap milestone. Readers can discover an unfamiliar API by browsing
a generated A–Z symbol index as well as by searching, and can choose a
comfortable System, Light, or Dark color scheme that survives offline and
`file://` use. The project index is reordered around discovery, and restrained
build-time branding tokens are added.

The existing unit routes, overload-aware symbol anchors, API-index role,
diagram scope, search-index schema, dependency-free offline output,
direct-file input, and default `///` workflow remain intact. No `v0.6.0`
incremental-build work or later roadmap scope is included.

## What changed

- Added a generated `symbols.html` A–Z symbol index derived entirely from the
  documentation model, with ordinary-HTML letter sections, stable links, and
  category filters for types, routines, members, constants, and variables.
- Added a **Browse API** section on the project index (summary, Browse API,
  units, architecture diagrams, diagnostics) and a persistent **Symbols A–Z**
  header destination on every generated page.
- Added a keyboard-accessible **System / Light / Dark** reader theme control, a
  dependency-free inline bootstrap that publishes `data-theme` before visible
  rendering, and safe persistence/fallback for rejected or unavailable storage.
- Kept KaTeX, Mermaid diagrams, native controls, focus states, and contrast
  synchronized with the active scheme, including diagram re-render on theme
  change.
- Added validated `--project-mark`, `--theme-accent`, `--theme-accent-2`, and
  `--theme-font` branding options feeding shared color, typography, and mark
  tokens recorded additively in `api-model.json`.
- Regenerated the documented and scientific HTML examples and application
  assets.
- Extended the GitHub Pages workflow to check the symbol index, header
  navigation, theme control, and persistence script before upload and after
  deployment.
- Updated version metadata, portable-build defaults, README, roadmap,
  changelog, renderer and navigation guides, release guidance, example notes,
  `mathlib-fp` evidence, and the v0.5.2 release note.

## Design and safety notes

- The complete A–Z symbol list is server-rendered ordinary HTML. JavaScript
  only hides non-matching native list entries and re-hides empty letter
  sections; it never creates or replaces the index.
- Symbol entries carry `data-symbol-entry` and `data-symbol-kind`; the filter
  reads only those generated attributes and never interprets user input as
  markup.
- The unit symbol itself is excluded from the A–Z index so the five category
  filters match the roadmap contract exactly; units remain on the project
  index and unit switcher.
- The theme bootstrap is a small inline script in `<head>`; the interactive
  control is rendered `hidden` and revealed only by the application script, so
  no-JavaScript pages follow the system scheme.
- Reader choices are persisted through `localStorage` inside `try/catch`;
  rejected storage, private mode, and `file://` fall back to `system`.
- Branding values are validated against strict character and color rules before
  output; the stylesheet token set stays small and all dark-mode accent
  variants are derived deterministically. Named-theme galleries, arbitrary
  script injection, and remote theme assets are out of scope.
- Mermaid diagrams resolve their theme from `data-theme` and re-render on a
  `pasweave:themechange` event; interaction listeners are bound once and the
  view state resets per render.
- The implementation uses only existing Pascal, CSS, and local JavaScript
  facilities and introduces no dependency or remote runtime.

See [the HTML renderer guide](html-renderer.md),
[navigation and source traceability](navigation-and-source-traceability.md),
and the [v0.5.2 release note](../RELEASE_NOTE_v0.5.2.md) for the detailed
behavior, fallback, and rationale.

## Compatibility

- Generated unit routes remain `units/<UnitName>.html` and
  `units/<UnitName>.md`; `symbols.html` is a new additive route.
- Stable overload-aware symbol fragments and existing symbol-card permalinks
  are unchanged.
- The search-index schema and parser-independent JSON model stay schema version
  1; branding tokens are additive top-level fields.
- Existing project-index search, diagrams, coverage, source links, and
  renderer output contracts remain intact.
- Direct file and directory inputs and default `///` documentation mode pass
  end to end.
- HTML remains self-contained and usable through `file://`, with no server,
  network connection, or runtime installation required.
- With JavaScript disabled, the A–Z symbol index, unit disclosure, breadcrumbs,
  category links, and diagram text fallbacks remain usable, and the site follows
  the system color scheme.

## Validation

- [x] Complete automated suite passes with Free Pascal 3.2.2.
- [x] Production CLI builds and reports `PasWeave 0.5.2`.
- [x] Invalid branding values fail before output with clear exit-code-2
      messages.
- [x] Direct-file input with the default `///` mode produces JSON, Markdown,
      HTML, `symbols.html`, diagnostics, search assets, and a unit page with
      zero errors.
- [x] Checked-in HTML, stylesheet, and application-script golden output
      matches the current renderer; the symbol-index goldens are pinned for
      both examples.
- [x] Focused fixtures prove the A–Z index counts, filters, letter sections,
      stable links, index ordering, theme markup, bootstrap, persistence
      fallback, and branding validation rules.
- [x] Headless Chrome runs over the generated index, unit page, and a
      2,657-entry `mathlib-fp` symbol index report applied `data-theme`, a
      revealed theme control, and clean consoles.
- [x] Two builds of latest `mathlib-fp` commit
      `b5aea1c2d841fd82f9e98cb770c00fc04c2d9b17` parse 50 of 50 units into
      2,978 symbols and 2,657 A–Z index entries with zero errors.
- [x] Both `mathlib-fp` runs produce the same 175 files with audit digest
      `98B9DAB763AD46D83E71A607E30211F05B7CB1DCDDF1903A9E273809BAD88F9B`.
- [x] All 50 `mathlib-fp` unit pages carry the theme control and bootstrap,
      and the index follows the new discovery-first section order.
- [x] Final five-axis review covers correctness, readability, architecture,
      security, and performance.

## Known limits

- Reader theme persistence depends on browser storage; when storage is
  rejected the site safely follows the system scheme for that page.
- Category filtering and the interactive theme control require the generated
  application script; the full A–Z list and system-scheme rendering remain
  available without it.
- The symbol index renders the complete list and is not virtualized; the
  letter bar and category filters keep large projects navigable.
- The public GitHub Pages site cannot validate this branch before merge. The
  workflow performs the same symbol-index and theme assertions against the
  deployed site after `main` is published.

## Merge and release checklist

- [x] `PasWeaveVersion`, its regression assertion, portable-build default, and
      README badge are set to `0.5.2`.
- [x] `CHANGELOG.md`, `RELEASE_NOTE_v0.5.2.md`, roadmap status, detailed docs,
      examples, validation evidence, and golden output are updated.
- [x] Local tests, production build, portable release build, headless browser
      checks, direct-input validation, and `mathlib-fp` determinism checks
      pass.
- [x] The branch contains no `v0.6.0+` implementation or preparatory contract.
- [ ] Push `feature/v0.5.2-api-discovery-and-reader-themes` and open the pull
      request against `main`.
- [ ] Confirm PR checks, including the Pages generated-site build gate, pass.
- [ ] Merge the reviewed PR into `main`.
- [ ] Confirm the Pages deployment and deployed-site smoke test pass at
      `https://ikelaiah.github.io/pasweave/`.
- [ ] Confirm the post-merge Windows build on `main` passes.
- [ ] Tag the verified merge commit as `v0.5.2` and push the tag.
- [ ] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` with the v0.5.2 release note.
