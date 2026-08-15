![PasWeave — Documentation, woven from Pascal source](assets/pasweave-banner.svg)

# 🧶 PasWeave

[![License: MIT](https://img.shields.io/badge/license-MIT-22c55e)](LICENSE)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2%2B-14b8a6)](docs/parser-integration.md)
[![Lazarus](https://img.shields.io/badge/Lazarus-.lpi%20%7C%20.lpk-7c3aed)](docs/lazarus-projects.md)
[![Windows](https://img.shields.io/badge/platform-Windows%20x86--64-2563eb)](docs/releasing.md)
[![Version](https://img.shields.io/badge/version-0.5.6-635bff)](CHANGELOG.md)
[![Runtime dependencies: none](https://img.shields.io/badge/runtime%20dependencies-none-10b981)](https://github.com/ikelaiah/pasweave/releases)
[![Tests](https://img.shields.io/github/actions/workflow/status/ikelaiah/pasweave/pages.yml?branch=main&label=tests)](https://github.com/ikelaiah/pasweave/actions/workflows/pages.yml)
[![Documentation](https://img.shields.io/badge/docs-live-0ea5e9)](https://ikelaiah.github.io/pasweave/)
[![Status: pre-release](https://img.shields.io/badge/status-pre--release-f59e0b)](ROADMAP.md)

Modern API documentation for Free Pascal and Lazarus projects.

PasWeave turns Pascal source into searchable, offline HTML documentation,
linked Markdown, and structured JSON. Add `///` comments, run one command,
and publish the generated files anywhere.

**Zero runtime dependencies:** the portable Windows release is a single
executable with everything PasWeave needs to generate documentation, including
the assets for offline browsing—no installer, Free Pascal runtime, Lazarus,
network connection, or registry changes.

[View the live showcase](https://ikelaiah.github.io/pasweave/) ·
[Download for Windows](https://github.com/ikelaiah/pasweave/releases) ·
[Read the v0.5.6 release notes](RELEASE_NOTE_v0.5.6.md)

> **Project status:** PasWeave is pre-release software. It targets Free Pascal
> and `{$mode objfpc}` first; see [scope and limitations](#scope-and-limitations)
> before adopting it for production documentation.

<a id="quick-start"></a>

## 🚀 Quick start

Download the portable `pasweave.exe` from the
[GitHub Releases page](https://github.com/ikelaiah/pasweave/releases), place it
anywhere, and run:

~~~powershell
.\pasweave.exe build path\to\project --output docs
~~~

Open `docs/html/index.html`. No installer, web server, internet connection,
or Free Pascal runtime is required.

PasWeave accepts a Pascal unit, a directory of `.pas` and `.pp` units, a
Lazarus project (`.lpi`), or a Lazarus package (`.lpk`).

Building on another platform? See [building from source](docs/building-from-source.md).

## See what it produces

The [live PasWeave showcase](https://ikelaiah.github.io/pasweave/) is generated
from the checked-in scientific example. It documents 28 public API symbols and
renders its equations without a network connection.

For smaller examples, browse:

- the [documented API example](examples/documented-api/README.md), with 8 of
  8 public symbols documented;
- its checked-in [Markdown output](examples/documented-api/sample-output/markdown/index.md);
- the [scientific API example](examples/scientific-api/README.md), including
  dependency and type-relationship diagrams.

Each build can produce:

- a responsive, searchable static HTML site with a generated symbol index
  and a System / Light / Dark reader theme control;
- linked Markdown pages for repositories and other documentation systems;
- a deterministic JSON source model;
- machine-readable diagnostics for CI.

See [generated output](docs/generated-output.md) for the directory layout,
format details, schema notes, and exit codes.

<a id="why-pasweave"></a>

## ✨ Why PasWeave?

- 🧩 **Free Pascal and Lazarus aware.** Read units directly or import project,
  package, build-mode, path, define, and target settings from `.lpi` and
  `.lpk` files.
- 📦 **Zero runtime dependencies.** The portable Windows executable bundles
  search, diagrams, KaTeX, styles, and fonts for completely offline use.
- 🔎 **Easy to discover and navigate.** A symbol index, searchable unit
  switching, on-page category links, stable overload-aware anchors, source
  links, dependency diagrams, and class/interface relationships connect the
  API.
- 🎨 **Comfortable reader themes.** Readers pick System, Light, or Dark; their
  choice is remembered offline and follows them through `file://`. Projects can
  add restrained branding tokens for colors, typography, and a local mark.
- ✅ **Useful while authoring.** Find undocumented symbols, broken references,
  malformed directives, and coverage regressions before publishing.
- ⚙️ **Automation friendly.** Deterministic Markdown and JSON make diffs and CI
  checks predictable.

## Document an API

Place consecutive `///` lines immediately before an interface declaration:

~~~pascal
/// Returns the standard normal probability density.
///
/// @param X Point at which the density is evaluated.
/// @returns The probability density at `X`.
function NormalPDF(const X: Double): Double;
~~~

Then build the source directory:

~~~text
pasweave build src --output docs
~~~

PasWeave recognizes `@param`, `@returns`, `@raises`, `@deprecated`,
`@see`, and `@since`. It can also read deliberately selected Pascal block
comments. Ordinary `//` comments are never treated as API documentation.

See [documentation comments](docs/documentation-comments.md) for supported
forms, association rules, structured directives, and the block-comment
trade-offs.

## Common workflows

### Discover a nested source tree

Enable recursive discovery explicitly and exclude trees outside the public API:

~~~text
pasweave build src --recursive --exclude=generated/** --exclude=tests --exclude=vendor/**
~~~

`--include` and `--exclude` are repeatable, case-insensitive globs relative
to the source directory. Exclusions take precedence. See
[source discovery](docs/source-discovery.md) for matching and safety rules.

### Match a configured compiler target

Pass the source paths, defines, and target selected by the project build:

~~~text
pasweave build src --recursive \
  --unit-path=packages/core/src \
  --include-path=include \
  --define=USE_FAST_MATH \
  --target-os=linux \
  --target-cpu=aarch64
~~~

Paths and defines are repeatable. Explicit target settings replace host
defaults. See [compiler-aware parsing](docs/compiler-aware-parsing.md) for
precedence, supported values, diagnostics, and limitations.

### Read a Lazarus project or package

Point PasWeave at an `.lpi` or `.lpk`; Lazarus itself is not started:

~~~text
pasweave build path/to/Application.lpi --build-mode=Release \
  --package-path=path/to/local-packages --output docs
~~~

Command-line compiler options override imported values. See the
[Lazarus project and package guide](docs/lazarus-projects.md) for supported XML
elements, package discovery, and diagnostics.

### Link documentation back to source

Configure the repository origin and a repository-relative line template:

~~~text
pasweave build src \
  --repository-url=https://github.com/example/project \
  '--source-link-template=blob/main/{path}#L{line}'
~~~

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
for template validation and normalization.

### Brand the generated site

Set a local project mark, two accent colors, and the body font:

~~~text
pasweave build src \
  --project-mark=ACME \
  --theme-accent=#7c3aed \
  --theme-accent-2=#0e7490 \
  --theme-font="Avenir Next"
~~~

Defaults reproduce the built-in light and dark schemes; invalid values are
rejected before any output is written. See [the HTML renderer guide](docs/html-renderer.md)
for the reader theme control and branding contract.

### Enforce documentation coverage in CI

Require a coverage percentage and promote warnings to failures:

~~~text
pasweave build src --min-documentation-coverage=90 --fail-on=warning
~~~

The default is `--fail-on=error`, so authoring warnings do not block local
rendering. See [authoring feedback and reference integrity](docs/authoring-feedback.md)
for diagnostic codes and coverage rules.

## Documentation

| Guide | What it covers |
|---|---|
| [Documentation comments](docs/documentation-comments.md) | Comment forms, association, and directives |
| [Generated output](docs/generated-output.md) | HTML, Markdown, JSON, diagnostics, and exit codes |
| [Source discovery](docs/source-discovery.md) | Recursion, include/exclude globs, and safety |
| [Compiler-aware parsing](docs/compiler-aware-parsing.md) | Paths, defines, targets, and precedence |
| [Lazarus projects and packages](docs/lazarus-projects.md) | `.lpi`, `.lpk`, build modes, and packages |
| [Authoring feedback](docs/authoring-feedback.md) | References, coverage, diagnostics, and CI |
| [Navigation and source links](docs/navigation-and-source-traceability.md) | Anchors, routes, symbol index, themes, and repository links |
| [HTML renderer](docs/html-renderer.md) | Offline rendering, search, themes, branding, safety, and diagrams |
| [Building from source](docs/building-from-source.md) | Requirements, compilation, tests, and release builds |
| [Parser integration](docs/parser-integration.md) | `fcl-passrc` adapter details |

## Scope and limitations

PasWeave targets Free Pascal and `{$mode objfpc}` first. Delphi-compatible
syntax is accepted where it works naturally through FPC's `fcl-passrc`
parser; PasWeave does not maintain a separate Pascal parser.

Current limitations include:

- KaTeX supports a focused TeX subset, and Markdown conversion intentionally
  supports a focused Markdown subset;
- Lazarus package discovery requires local `.lpk` files;
- type relationships resolve only within the current unit and its interface
  dependencies, and implementation bodies are not analysed;
- brace and parenthesis comment modes cannot reliably distinguish API prose
  from section labels or commented-out code;
- unit paths resolve source `.pas` and `.pp` files, not compiled `.ppu`
  files, and do not recurse;
- explicit OS and CPU values are validated independently, but every possible
  pair is not necessarily a real FPC code-generation target;
- source-link configuration currently requires both command-line options;
- reader theme persistence depends on browser storage; when storage is
  rejected or unavailable the site safely follows the system scheme;
- unusual FPC syntax and every possible symbol kind are not yet covered by
  fixtures.

The parser-to-site pipeline has also been tested against all 50 source units in
the latest [`mathlib-fp`](https://github.com/ikelaiah/mathlib-fp): 2,978 symbols
were produced with zero errors, every generated unit page passed the v0.5.1
navigation audit, and the symbol index and reader themes passed the v0.5.2
discovery audit. Read the
[validation report](docs/mathlib-fp-validation.md) for the tested revision,
determinism result, responsive browser evidence, and comment-syntax findings.

PasWeave is not a fork of PasDoc or FPDoc. It explores a Free Pascal-first
workflow centred on Markdown, structured output, and modern static
documentation, while recognizing those projects' substantial contributions to
the Pascal ecosystem.

## Build and contribute

PasWeave requires Free Pascal 3.2.2 or newer plus the `fcl-passrc` and
`fcl-json` packages when compiling from source:

~~~text
make
make test
~~~

See [building from source](docs/building-from-source.md) for direct FPC and
portable Windows build commands. Bug reports, focused pull requests, and
real-world parser fixtures are welcome.

The project history is in the [changelog](CHANGELOG.md); planned work and
acceptance evidence are in the [roadmap](ROADMAP.md).

## Download integrity

Each Windows release includes `pasweave.exe.sha256`:

~~~powershell
Get-FileHash .\pasweave.exe -Algorithm SHA256
~~~

Pre-release executables are not code-signed, so Windows may show a SmartScreen
warning. Download only from the PasWeave release page and compare the SHA-256
value before running the executable.

## License

PasWeave is released under the [MIT License](LICENSE). Bundled third-party
components retain their own licenses; see
[third-party notices](THIRD_PARTY_NOTICES.md).
