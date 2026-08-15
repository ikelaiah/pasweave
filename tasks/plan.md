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
- Persist a header **Symbols A–Z** destination and theme control on every page.
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
- [x] Task 3: Add the header **Symbols A–Z** destination and category filter
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
