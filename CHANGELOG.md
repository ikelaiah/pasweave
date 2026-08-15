# Changelog

All notable changes to PasWeave are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.3] - 2026-08-15

### Changed

- Renamed the visible symbol-index label from **Symbols A–Z** to the more
  professional **Symbols Index** in the page header, the `symbols.html`
  heading and breadcrumb, and the project-index Browse API card. The "A–Z"
  phrase remains in descriptive copy such as the Browse API card text and the
  page description.
- Version metadata and portable-build defaults now report v0.5.3.

### Compatibility

- The `symbols.html` route, stable symbol anchors, category deep links, and
  the search-index schema are unchanged; only the visible label text changed.
- All other v0.5.2 output contracts remain intact.

### Validation

- The complete FPC 3.2.2 suite, CLI build, deterministic example goldens, and
  direct-file/default-`///` workflows pass.
- Focused tests pin the new **Symbols Index** label in the header and page
  heading, and both examples' golden output was regenerated.

## [0.5.2] - 2026-08-15

### Added

- A generated A–Z symbol index page (`symbols.html`) derived entirely from the
  documentation model, with stable links, letter sections, and keyboard-usable
  category filters for types, routines, members, constants, and variables.
- A persistent **Symbols A–Z** destination in the header of every generated
  page, plus a **Browse API** section on the project index that reports symbol
  totals by category.
- A keyboard-accessible reader theme control with `System`, `Light`, and `Dark`
  choices. `System` remains the default and follows `prefers-color-scheme`;
  an explicit choice is remembered through local storage when available and
  falls back safely when storage is rejected, including under `file://`.
- A dependency-free inline bootstrap that applies the selected scheme before
  visible page rendering, with native controls, KaTeX, Mermaid diagrams, focus
  states, and contrast synchronized through shared CSS tokens.
- Build-time project branding through validated `--project-mark`,
  `--theme-accent`, `--theme-accent-2`, and `--theme-font` options that feed a
  small set of colors, typography, and a local project mark into the generated
  site and model JSON.

### Changed

- The project index now leads with project summary, then **Browse API**, the
  units table, architecture diagrams, and diagnostics last.
- The stylesheet derives its dark-mode accent variants deterministically from
  the configured tokens; the default colors are unchanged.
- Checked-in documented and scientific HTML examples now include the symbol
  index, header navigation, and theme control.
- Version metadata and portable-build defaults now report v0.5.2.

### Compatibility

- Existing `units/<UnitName>.html` routes, overload-aware symbol anchors, the
  project index role, diagram scope, source links, and search-index schema
  remain unchanged.
- With JavaScript disabled, the unit list, A–Z symbol index, category links,
  and diagram text fallbacks remain ordinary HTML, and the site follows the
  system color scheme when the interactive preference control is unavailable.
- Reader-facing named-theme galleries, arbitrary script injection, and remote
  theme assets remain out of scope.

### Validation

- The complete FPC 3.2.2 suite, CLI build, deterministic example goldens, and
  direct-file/default-`///` workflows pass.
- Headless Chrome runs over the generated index, unit page, and 2,657-entry
  `mathlib-fp` symbol index report clean consoles, applied `data-theme`, and a
  revealed theme control.
- Two runs of the latest 50-unit `mathlib-fp` commit produced 2,978 symbols,
  2,657 A–Z index entries, 175 identical generated files with audit digest
  `98B9DAB763AD46D83E71A607E30211F05B7CB1DCDDF1903A9E273809BAD88F9B`, and
  zero errors; every one of the 50 unit pages carries the theme control.
- The deployed showcase smoke check remains the post-merge release gate; the
  workflow validates the symbol index, theme control, and persistence script
  before upload and after deployment.

## [0.5.1] - 2026-08-15

### Added

- A native searchable unit switcher on every generated HTML unit page, with
  the complete deterministic unit list available without JavaScript.
- Keyboard filtering with a polite match count, ArrowUp/ArrowDown link
  movement, Escape focus restoration, and visible focus styling.
- Present-only on-page links for Types, Routines, Members, and Constants and
  variables using the established section fragments.
- Pre-deploy and post-deploy GitHub Pages assertions for the unit switcher,
  direct cross-unit link, category navigator, and enhancement script.

### Changed

- Unit navigation stacks at tablet widths and keeps its disclosure panel and
  bounded unit list inside phone viewports.
- Checked-in documented and scientific HTML examples now demonstrate direct
  unit and category navigation.
- Version metadata and portable-build defaults now report v0.5.1.

### Compatibility

- Existing `units/<UnitName>.html` routes, overload-aware symbol anchors, API
  index behavior, diagram scope, source links, and search-index schema remain
  unchanged.
- With JavaScript disabled, readers can still open the native disclosure and
  reach any unit directly; filtering and global symbol search remain enhanced
  behaviors that require the local script.

### Validation

- The complete FPC 3.2.2 suite, CLI build, deterministic example goldens, and
  direct-file/default-`///` workflows pass.
- Isolated Chrome checks cover desktop and 390-pixel layouts, filtering, live
  status, ArrowDown, Escape, category fragments, viewport fit, clean console,
  and two-action no-JavaScript unit navigation.
- Two runs of the latest 50-unit `mathlib-fp` commit produced 2,978 symbols,
  2,707 search entries, 174 identical generated files, zero errors, and zero
  navigation audit failures. A 50-unit browser check passed bounded scrolling,
  keyboard behavior, desktop layout, and 390-pixel responsive layout.
- The deployed showcase smoke check remains the post-merge release gate; the
  workflow validates the same navigation contract before upload and after
  deployment.

## [0.5.0] - 2026-08-12

### Added

- Paired `--repository-url` and `--source-link-template` options with strict
  origin, traversal, placeholder, path, and declaration-line validation.
- Model-backed source links in HTML and Markdown plus additive schema-v1
  repository metadata in `api-model.json`.
- Unit, symbol-kind, visibility, and documentation-status facets for the
  dependency-free offline search index.
- Keyboard result navigation, polite result status, explicit empty states,
  visible focus, and narrow-screen search layout.
- Per-symbol inheritance and implementation links in HTML and Markdown using
  the same resolved model identities as relationship diagrams.
- A GitHub Pages workflow that builds, validates, publishes, and smoke-checks
  the scientific API showcase from committed sources.

### Changed

- Resolved `@see`, dependency, parent, inheritance, and implementation links
  now share stable symbol-link helpers across renderers.
- Checked-in example output now includes repository source links without
  changing generated unit routes or overload-aware anchors.
- Version metadata and portable-build defaults now report v0.5.0.

### Validation

- The complete FPC 3.2.2 test suite, CLI build, production build, and portable
  Windows release smoke test pass.
- Browser checks cover search filtering and keyboard focus, empty results,
  Mermaid and KaTeX runtime output, console errors, and 320-pixel responsive
  layout.
- The three-unit nested Lazarus fixture produced six symbols and six source
  links with no warnings, errors, or escaping URLs.
- Two runs of pinned 45-unit `mathlib-fp` produced 2,338 symbols, 2,227
  searchable source links, zero errors or escaping URLs, and the identical
  full-tree SHA-256 digest
  `467EC29C5BE937C6A22165E18ADAD9A72FF8C3715C463518F1A779BF4596A826`.

## [0.4.0] - 2026-08-10

### Added

- Model-level authoring diagnostics with stable codes and documented warning
  and error severities.
- Parsed-signature checks for missing, duplicate, and unknown `@param`
  directives and invalid or conflicting `@returns` directives.
- Conservative project-local `@see` resolution stored as a symbol ID in the
  directive model, plus shared Markdown/HTML rendering of that result.
- Generated-route and anchor integrity diagnostics, deterministic
  `diagnostics.json`, `--min-documentation-coverage`, and `--fail-on` CI
  controls.
- Slash, brace, and paren fixtures covering every authoring rule.

### Changed

- Build diagnostics shown by the CLI, Markdown, and HTML now include their
  stable code.
- Version metadata and release guidance now describe v0.4.0 authoring
  feedback.

### Validation

- The complete FPC 3.2.2 suite and application build pass.
- Focused command-line checks confirm that default warning output exits 0,
  `--fail-on=warning` exits 1, and a missed 100% coverage target emits
  `PW411` and exits 1.
- The 45-unit `mathlib-fp` source corpus produced 2,338 symbols with zero
  errors and 2,676 actionable `PW401` warnings under the default local policy.

## [0.3.0] - 2026-08-09

### Added

- Direct `.lpi` Lazarus project and `.lpk` package inputs without starting
  Lazarus.
- Named/default build-mode selection and import of project/package source
  units, unit paths, include paths, defines, and target settings.
- Deterministic local-package discovery with repeatable `--package-path`
  roots and pruning of generated, vendor, example, and test trees.
- Fatal diagnostics for missing or ambiguous packages, unsupported macros,
  ambiguous build modes, malformed inputs, and cyclic package references.
- Focused multi-package Lazarus fixtures and end-to-end CLI validation.

### Changed

- Explicit CLI compiler options now merge over imported Lazarus settings while
  preserving the existing PasWeave defaults for unset categories.
- Source-list builds reuse the existing parser, model, and renderers, so direct
  file and directory input remains supported.
- Version metadata, README guidance, and parser documentation now describe
  Lazarus input behavior and precedence.

### Validation

- The complete automated suite and FPC 3.2.2 application build pass.
- A three-unit, two-package Lazarus fixture builds through the CLI with six
  symbols and no diagnostics; the installed Lazarus `charactermap_demo.lpi`
  project also builds with its local package graph and no diagnostics.

## [0.2.0] - 2026-08-02

### Added

- Repeatable `--unit-path`, `--include-path`, and `--define` compiler inputs.
- Explicit, normalized `--target-os` and `--target-cpu` selection with
  documented supported values and aliases.
- Deterministic transitive source-unit resolution through configured unit
  paths and nested include resolution through configured include paths.
- Source-backed locations and documentation extraction for declarations
  originating in include files when include paths are configured.
- Focused compiler-configuration fixtures for conditional declarations,
  nested and missing includes, competing search paths, transitive units, and
  host-independent target selection.

### Changed

- Compiler settings now live in a parser-independent configuration object;
  `fcl-passrc` types remain confined to the adapter.
- Configured include failures use a stable, source-aware “missing or
  unreadable” diagnostic, reflecting the information available from FPC 3.2.2.
- Version metadata, CLI help, README guidance, parser integration notes, and
  real-project validation now describe compiler-aware parsing and precedence.

### Compatibility

- With no compiler settings, PasWeave retains the original host target and
  parser arguments. A before/after SHA-256 comparison matched all 77 generated
  files in the documented example byte-for-byte.
- Direct file input, top-level and recursive directory discovery, and the
  default `///` workflow remain supported end to end.
- Generated JSON remains model schema version 1.

### Validation

- The complete automated suite and all checked-in Markdown/HTML golden outputs
  pass with FPC 3.2.2.
- `mathlib-fp` commit `6f3480b7e9494fcd4f72abb0f5c21dd30fde3e42`
  parsed all 45 units into 2,338 symbols with zero warnings or errors under
  explicit Windows x86-64 settings.
- All 163 configured `mathlib-fp` output files matched the unconfigured
  baseline byte-for-byte.

## [0.1.0-alpha.1] - 2026-08-01

PasWeave's first public alpha establishes the complete parser-to-static-site
pipeline and a portable Windows release.

### Added

- Free Pascal interface parsing through the reusable `fcl-passrc` libraries.
- A parser-independent project model with deterministic JSON schema version 1.
- Markdown and responsive static HTML output with stable symbol anchors,
  source locations, structured directives, and documentation coverage counts.
- Explicit PasWeave `///` documentation comments plus opt-in Pascal `{ ... }`
  and `(* ... *)` documentation comments.
- Offline symbol search, light and dark colour schemes, private-symbol
  filtering, and per-file error isolation.
- Offline KaTeX mathematics and linked Mermaid dependency and type-relationship
  diagrams with accessible zoom, pan, reset, and text fallbacks.
- Deterministic recursive source discovery with repeatable include and exclude
  globs while retaining single-file and non-recursive defaults.
- Fully documented example projects, checked-in Markdown and HTML showcases,
  parser fixtures, and real-world `mathlib-fp` validation.
- A raw, portable Windows x86-64 executable with embedded web assets, version
  reporting, a SHA-256 checksum, and tag-driven GitHub pre-releases.
- MIT licensing and third-party attribution for the embedded assets.

### Compatibility

- Source builds require Free Pascal 3.2.2 or newer with `fcl-passrc` and
  `fcl-json`; `{$mode objfpc}` is the primary target.
- The downloadable alpha executable targets Windows x86-64 and is unsigned.
- Generated JSON uses model schema version 1.

### Validation

- Parsed all 45 units in the tested `mathlib-fp` revision into 2,338 model
  symbols without parse errors, missing source positions, or duplicate IDs.
- Rendered 2,227 `mathlib-fp` API symbols and resolved 97 project-local
  dependency edges.
- Generated the scientific showcase with documentation for all 30 public API
  symbols, 16 display equations, and 65 inline mathematical expressions.
- Verified the portable executable in isolation, including all 67 extracted
  third-party assets byte-for-byte.

[Unreleased]: https://github.com/ikelaiah/pasweave/compare/v0.5.3...HEAD
[0.5.3]: https://github.com/ikelaiah/pasweave/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/ikelaiah/pasweave/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/ikelaiah/pasweave/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/ikelaiah/pasweave/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/ikelaiah/pasweave/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/ikelaiah/pasweave/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ikelaiah/pasweave/compare/v0.1.0-alpha.1...v0.2.0
[0.1.0-alpha.1]: https://github.com/ikelaiah/pasweave/releases/tag/v0.1.0-alpha.1
