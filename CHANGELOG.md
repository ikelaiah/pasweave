# Changelog

All notable changes to PasWeave are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/ikelaiah/pasweave/compare/v0.1.0-alpha.1...HEAD
[0.1.0-alpha.1]: https://github.com/ikelaiah/pasweave/releases/tag/v0.1.0-alpha.1
