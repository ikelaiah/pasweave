# Changelog

All notable changes to PasWeave are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/ikelaiah/pasweave/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/ikelaiah/pasweave/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/ikelaiah/pasweave/compare/v0.1.0-alpha.1...v0.2.0
[0.1.0-alpha.1]: https://github.com/ikelaiah/pasweave/releases/tag/v0.1.0-alpha.1
