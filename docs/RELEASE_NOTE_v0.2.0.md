# PasWeave v0.2.0

PasWeave `v0.2.0` makes interface parsing compiler-aware. Maintainers can now
describe the unit paths, include paths, conditional defines, target operating
system, and target CPU that select the public API seen by their Free Pascal
build.

## Highlights

- Repeat `--unit-path`, `--include-path`, and `--define` as needed.
- Select a normalized target with `--target-os` and `--target-cpu` instead of
  inheriting an accidental documentation-host target.
- Resolve project source units transitively in deterministic path order.
- Resolve nested include files and, when include paths are configured, retain
  include-backed source locations and documentation comments.
- Receive early input errors for invalid compiler settings and source-aware
  diagnostics when an include is missing or unreadable.
- Keep existing JSON, Markdown, HTML, and offline assets byte-for-byte
  unchanged when no compiler settings are supplied.

Example:

```text
pasweave build src --recursive \
  --unit-path=packages/core/src \
  --include-path=include \
  --define=USE_FAST_MATH \
  --target-os=linux \
  --target-cpu=aarch64
```

See [compiler-aware parsing](docs/compiler-aware-parsing.md) for supported
targets, aliases, path rules, precedence, diagnostics, and limitations.

## Precedence

- The documentation host supplies OS/CPU defaults only when explicit targets
  are absent.
- Repeated target options use the last value.
- Repeated defines are combined and normalized to uppercase.
- Unit and include paths retain command-line order; the first matching path
  wins.
- Main input units win over matching unit-path sources.

## Compatibility

The model schema remains version 1. Direct file input, directory discovery,
and `///` documentation remain the defaults. Lazarus `.lpi` and `.lpk` files
are not interpreted in this release; their compiler values must be supplied
manually.

Explicit targets are used for conditional interface selection, not code
generation. PasWeave validates OS and CPU values independently and does not
claim every possible pair is a supported FPC backend combination. Unit paths
resolve `.pas` and `.pp` source files, not compiled `.ppu` files.

## Validation

- The complete automated suite passes on FPC 3.2.2, including every existing
  checked-in Markdown and HTML golden output.
- A before/after compatibility audit matched all 77 generated documented-api
  files by SHA-256 when no compiler settings were supplied.
- The configured `mathlib-fp` audit parsed all 45 units into 2,338 symbols with
  zero warnings or errors. All 163 generated files matched the unconfigured
  baseline byte-for-byte.
