# Implementation Plan: PasWeave v0.5.2 API discovery and reader themes

## Overview

Add model-derived API discovery (an A–Z symbol index and a reordered project
index) and a System/Light/Dark reader theme system with offline persistence,
alongside restrained build-time project branding. All new markup degrades to
useful no-JavaScript HTML and keeps the dependency-free offline contract.

This plan is strictly limited to the `v0.5.2` roadmap. Incremental builds,
project configuration, portability expansion, contract freezing, and all
`v0.6.0+` work are out of scope.

## Architecture decisions

- Render `symbols.html` as a complete, sorted, letter-grouped list of every
  renderable non-unit symbol with stable links. JavaScript only hides
  non-matching native entries and empty sections.
- Exclude the unit symbol itself so the five filters (types, routines,
  members, constants, variables) match the roadmap wording exactly.
- Reorder the project index to summary, Browse API, units, architecture
  diagrams, diagnostics; keep the units table canonical and diagrams unchanged.
- Persist a header **Symbols Index** destination and theme control on every page.
- Apply the reader scheme through a tiny inline `data-theme` bootstrap before
  the stylesheet; drive all colors/typography through CSS custom properties so
  native controls, KaTeX, Mermaid, focus, and contrast stay synchronized.
- Derive dark-mode accent variants deterministically from the configured
  tokens and keep the default colors identical.
- Keep branding to a validated `--project-mark`, `--theme-accent`,
  `--theme-accent-2`, and `--theme-font` surface recorded additively in
  `api-model.json`.

## Task list

### Phase 1: A–Z symbol index and index reorder

- [x] Task 1: Add failing renderer tests for the symbol index, its counts,
  filters, letter sections, stable links, and the reordered project index.
- [x] Task 2: Render `symbols.html` and the **Browse API** section; reorder the
  project index; write the new page from `WriteHTMLDocumentation`.
- [x] Task 3: Add the header **Symbols Index** destination and category filter
  JavaScript with a live count and deep links.

### Checkpoint: Static discovery

- [x] The A–Z index is complete, deterministic, and derives only from the model.
- [x] No-JavaScript browsing of the A–Z index works and unit symbols are absent.
- [x] Existing unit routes, anchors, and search schema are unchanged.

### Phase 2: Reader themes and persistence

- [x] Task 4: Add failing asset-contract tests for the bootstrap, control,
  persistence fallback, and tokenized stylesheet.
- [x] Task 5: Implement the theme bootstrap, control, and tokenized light/dark
  CSS; wire Mermaid theme selection and diagram re-render on theme change.
- [x] Task 6: Verify generated pages in a real browser with clean consoles and
  an applied scheme.

### Checkpoint: Reader themes

- [x] System/Light/Dark choices apply before visible rendering and persist when
  storage is available.
- [x] Rejected storage and `file://` fall back to the System scheme.
- [x] No-JavaScript pages follow the system color scheme.

### Phase 3: Branding and examples

- [x] Task 7: Add validated branding CLI options, JSON fields, and a custom
  project mark in the header.
- [x] Task 8: Regenerate and verify the documented and scientific sample
  output, including `symbols.html` goldens, and add Pages workflow assertions.

### Checkpoint: Validation corpora

- [x] Examples and the latest `mathlib-fp` corpus satisfy the v0.5.2 contract.
- [x] Unrelated generated output remains deterministic.
- [x] The Pages workflow is ready to validate the deployed showcase after merge.

### Phase 4: Release contract

- [x] Task 9: Update README and detailed renderer/navigation documentation,
  including no-JavaScript behavior and limitations.
- [x] Task 10: Update changelog, roadmap status, release note, version
  metadata, portable-build default, and version regression test to `0.5.2`.
- [x] Task 11: Run the complete suite, production build, headless browser
  checks, deterministic sample checks, `mathlib-fp` determinism, and final
  five-axis review.

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| JavaScript becomes required for the symbol index | Violates offline/no-JS contract | Render the complete native list first; JavaScript only hides non-matches. |
| Filter markup and script selectors drift apart | Broken filtering | Tag entries with both `data-symbol-entry` and `data-symbol-kind` and assert both in fixtures. |
| Large projects create an unwieldy symbol page | Poor keyboard and responsive usability | Letter bar, height-bounded sections, live filtered count, and responsive single-column layout. |
| Theme choices break offline/`file://` behavior | Persistence failures | Inline bootstrap with `try/catch`; always fall back to the System scheme. |
| Branding tokens allow CSS injection | Security regression | Strict validation of marks, colors, and font names before output. |
| Mermaid ignores the chosen theme | Diagram/theme mismatch | Read `data-theme`, re-render on `pasweave:themechange`, bind interaction once. |

## Definition of done

- [x] Every `v0.5.2` exit criterion has code, focused tests, documentation, or
  explicit post-merge deployed-site evidence.
- [x] No `v0.6.0+` capability or preparatory contract is introduced.
- [x] Existing unit URLs, symbol anchors, API-index role, and diagram scope are
  unchanged.
- [x] Full tests and production build pass; direct-file and default-`///`
  workflows still work end to end.

## `v0.5.3` label polish

A follow-up release renames the visible symbol-browser label from
**Symbols A–Z** to **Symbols Index** in the header, page heading/breadcrumb,
and Browse API card. "A–Z" remains only in descriptive copy. Routes, anchors,
filters, deep links, themes, and branding tokens are unchanged; both examples'
HTML goldens and the version metadata are regenerated to v0.5.3.

## `v0.5.4` index-total alignment

A follow-up release aligns the project index totals with the A–Z symbol index
population. **Parsed symbols** becomes **Parsed declarations** (still counts
every model declaration), **Public API symbols** equals the index population
(units excluded), and coverage plus the per-unit API-symbol rows use the same
indexed population in both HTML and Markdown. The CI coverage metric behind
`--min-documentation-coverage` (`PW411`) is intentionally unchanged. Routes,
anchors, filters, themes, and branding are unchanged; example goldens and
version metadata are regenerated to v0.5.4.

## `v0.5.5` hero-copy polish

A follow-up release rephrases the project-index hero paragraph to "Browse the
API using the A–Z symbol index, explore individual units, or search the
complete public API reference.", preserving the `&#8211;` en-dash entity.
A focused test pins the new copy and both examples' HTML goldens are
regenerated to v0.5.5. No routes, anchors, schema, themes, or branding change.

## `v0.5.6` symbol-index terminology correction

A follow-up release removes the A–Z-only implication from symbol-index copy.
The hero, Browse API description, and Symbols Index card say "symbol index";
the symbols page introduction says "Public API symbols indexed by name and
grouped into navigable sections"; the meta description is "Symbol index for
{project}"; and the section-navigation label is "Symbol index sections".
Symbols beginning with `_`, digits, or other non-letter characters remain valid
and group under the `#` section. Routes, anchors, filters, sorting, and
grouping are unchanged; living docs are corrected while historical records are
preserved. Example goldens and version metadata are regenerated to v0.5.6.

## `v0.6.0` safe incremental builds

A follow-up release adds safe incremental builds. A content-addressed input
fingerprint (PasWeave version, every build-affecting option, every reached
source/include/project/package file, and the vendored assets) is computed
before parsing; an unchanged run prints `[up-to-date]` and exits with parity.
A deterministic `manifest.json` records every generated page and asset with a
SHA-256 and size and serves as the ownership proof for stale-output removal,
which deletes only previously manifest-owned files. Output writes are atomic
(temp plus rename) with the manifest written last, so interrupted builds are
never published as successful and are repaired on the next run. `--clean`
forces a full rebuild, and clean and incremental results are byte-for-byte
identical. A corrupted or schema-incompatible manifest is a recoverable
warning that triggers a clean rebuild. `--verbose` reports elapsed time and
peak heap; baselines are recorded in the incremental-builds guide.


