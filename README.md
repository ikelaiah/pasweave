![PasWeave — Documentation, woven from Pascal source](assets/pasweave-banner.svg)

# 🧶 PasWeave

[![License: MIT](https://img.shields.io/badge/license-MIT-22c55e)](LICENSE)
[![Free Pascal](https://img.shields.io/badge/Free%20Pascal-3.2.2%2B-14b8a6)](docs/parser-integration.md)
[![Lazarus](https://img.shields.io/badge/Lazarus-.lpi%20%7C%20.lpk-7c3aed)](docs/lazarus-projects.md)
[![Windows](https://img.shields.io/badge/platform-Windows%20x86--64-2563eb)](docs/releasing.md)
[![Version](https://img.shields.io/badge/version-0.7.0-635bff)](CHANGELOG.md)
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
[Read the v0.7.0 release notes](docs/release-notes/RELEASE_NOTE_v0.7.0.md)

> **Project status:** PasWeave is pre-release software. It targets Free Pascal
> and `{$mode objfpc}` first; see [scope and limitations](#scope-and-limitations)
> before adopting it for production documentation.

<a id="quick-start"></a>

## 🚀 Quick start

**Prerequisites:** none for the portable Windows release. To compile from
source you need Free Pascal 3.2.2+, `fcl-passrc`, `fcl-json`, and `make`
(see [building from source](docs/building-from-source.md)).

**Option A — Windows (no install):** download portable `pasweave.exe` from
the [GitHub Releases page](https://github.com/ikelaiah/pasweave/releases),
place it anywhere, and run:

~~~powershell
.\pasweave.exe build path\to\project --output docs
~~~

**Option B — Linux / from source:**

~~~bash
make
./build/bin/pasweave build path/to/project --output docs
~~~

Then open `docs/html/index.html`. No installer, web server, internet
connection, or Free Pascal runtime is required to browse the output.

PasWeave accepts a Pascal unit, a directory of `.pas` and `.pp` units, a
Lazarus project (`.lpi`), or a Lazarus package (`.lpk`).

New to PasWeave? Start with the [documented API example](examples/documented-api/README.md)
(8 of 8 symbols documented, minimal `///` usage), then explore the
[scientific showcase](examples/scientific-api/README.md) (28 symbols,
equations, diagrams). Building on another platform? See
[building from source](docs/building-from-source.md).

## 🔎 See what it produces

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
- ⚡ **Fast on repeated builds.** Incremental builds skip unchanged parse and
  render work by default; pass `--clean` to force a full rebuild.
- ⚙️ **Automation friendly.** Deterministic Markdown and JSON make diffs and CI
  checks predictable.

## 📚 Document an API

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

## 🧭 Common workflows

> Copy-paste note: commands below are single-line so they work in both
> PowerShell and bash. On Windows use `.\pasweave.exe` (or
> `build\bin\pasweave.exe` from source); on Linux use `./build/bin/pasweave`.

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
pasweave build src --recursive --unit-path=packages/core/src --include-path=include --define=USE_FAST_MATH --target-os=linux --target-cpu=aarch64
~~~

Paths and defines are repeatable. Explicit target settings replace host
defaults. See [compiler-aware parsing](docs/compiler-aware-parsing.md) for
precedence, supported values, diagnostics, and limitations.

### Read a Lazarus project or package

Point PasWeave at an `.lpi` or `.lpk`; Lazarus itself is not started:

~~~text
pasweave build path/to/Application.lpi --build-mode=Release --package-path=path/to/local-packages --output docs
~~~

Command-line compiler options override imported values. See the
[Lazarus project and package guide](docs/lazarus-projects.md) for supported XML
elements, package discovery, and diagnostics.

### Link documentation back to source

Configure the repository origin and a repository-relative line template:

~~~text
pasweave build src --repository-url=https://github.com/example/project "--source-link-template=blob/main/{path}#L{line}"
~~~

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
for template validation and normalization.

### Brand the generated site

Set a local project mark, two accent colors, and the body font:

~~~text
pasweave build src --project-mark=ACME --theme-accent=#7c3aed --theme-accent-2=#0e7490 --theme-font="Avenir Next"
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

### Rebuild quickly with incremental caching

Repeated builds skip unchanged parse and render work automatically. A matching
run prints `[up-to-date]`; force a full rebuild with `--clean`:

~~~text
pasweave build src --output docs --clean
~~~

PasWeave writes a deterministic `manifest.json` and only ever removes files it
created before. See [safe incremental builds](docs/incremental-builds.md) for
the cache key, invalidation rules, and interruption recovery.

### Reproduce a build from a committed configuration

Commit one `pasweave.json` and rebuild with a single flag; explicit
command-line values still override it:

~~~text
pasweave build --config=pasweave.json
pasweave build --config=pasweave.json --project-name "Nightly API"
~~~

See [project configuration](docs/project-configuration.md) for the schema,
precedence rules, path validation, and the effective configuration recorded in
`api-model.json`.

## 📖 Documentation

Every guide is indexed in [docs/README.md](docs/README.md). Start with
[documentation comments](docs/documentation-comments.md) and
[generated output](docs/generated-output.md); follow task links from there.

| Guide | What it covers |
|---|---|
| [Documentation index](docs/README.md) | Grouped links to every guide, ADR, and release note |
| [Project configuration](docs/project-configuration.md) | One committed `pasweave.json`, precedence, and reproducibility |
| [Documentation comments](docs/documentation-comments.md) | Comment forms, association, and directives |
| [Generated output](docs/generated-output.md) | HTML, Markdown, JSON, diagnostics, and exit codes |
| [Source discovery](docs/source-discovery.md) | Recursion, include/exclude globs, and safety |
| [Compiler-aware parsing](docs/compiler-aware-parsing.md) | Paths, defines, targets, and precedence |
| [Lazarus projects and packages](docs/lazarus-projects.md) | `.lpi`, `.lpk`, build modes, and packages |
| [Authoring feedback](docs/authoring-feedback.md) | References, coverage, diagnostics, and CI |
| [Navigation and source links](docs/navigation-and-source-traceability.md) | Anchors, routes, symbol index, themes, and repository links |
| [HTML renderer](docs/html-renderer.md) | Offline rendering, search, themes, branding, safety, and diagrams |
| [Incremental builds](docs/incremental-builds.md) | Fingerprints, `manifest.json`, `--clean`, and stale-output safety |
| [Building from source](docs/building-from-source.md) | Requirements, compilation, tests, and release builds |
| [Parser integration](docs/parser-integration.md) | `fcl-passrc` adapter details |
| [Real-project validation](docs/mathlib-fp-validation.md) | `mathlib-fp` corpus results and determinism evidence |
| [Release procedure](docs/releasing.md) | Versioning, validation gates, and publishing |
| [Windows CI troubleshooting](docs/windows-ci-troubleshooting.md) | Runner, path, and tooling fixes |
| [Architecture decisions](docs/decisions/0001-model-driven-authoring-validation.md) | Why validation lives in the model (ADR-0001) |

## ⌨️ Commands

| Command | Description |
|---|---|
| `pasweave build <input> --output docs` | Generate HTML, Markdown, JSON, and diagnostics |
| `pasweave build --help` | Show all build options |
| `pasweave --version` | Print version |
| `make` | Compile `build/bin/pasweave` from source |
| `make test` | Compile and run the CLI and FPC test suites |
| `make test-cli` | Run only the compiled-CLI contract suite |
| `.\scripts\build-portable-windows.ps1` | Build portable Windows `dist\pasweave.exe` + checksum |
| `pwsh -File scripts\check-docs-links.ps1` | Verify relative documentation links |

## 🧱 Architecture

```text
src/cli/          Command-line pipeline (pasweave build)
src/parser/       fcl-passrc adapter, comments, Lazarus, compiler options
src/model/        Renderer-independent documentation model + JSON
src/validation/   Authoring diagnostics and coverage gates
src/render/       HTML, Markdown, links, shared helpers, offline assets
src/diagnostics/  Stable diagnostic codes and severities
src/incremental/  Fingerprints, manifest.json, atomic writes
src/support/      Shared filesystem helpers (PasWeave.FS)
tests/            Fixtures, shared assertions, CLI + focused regression suites
examples/         Minimal documented-api first, rich scientific-api second
```

Design rules: reuse `fcl-passrc` (no second parser), keep parser types out
of the model, keep renderers model-driven, keep shared model helpers in one
place (`PasWeave.Render.Support`), prefer explicit unresolved data over
guessed links. See [ADR-0001](docs/decisions/0001-model-driven-authoring-validation.md),
[ADR-0002](docs/decisions/0002-repository-relative-source-links.md), and
[ADR-0003](docs/decisions/0003-golden-output-and-cli-tests.md).

Supported platforms: portable releases target Windows x86-64 (see
[download integrity](#-download-integrity)). Source builds are compiled and
tested with FPC 3.2.2 on Windows and Ubuntu; the full fixture suite and the CLI
suite run on both hosts in CI. Broader compiler-version and platform coverage
is tracked in [roadmap v0.9.0](ROADMAP.md).

## 🆘 Troubleshooting

- `manifest.json is unreadable or invalid; rebuilding from scratch` — cached
  state was corrupt; the rebuild is the fix, no action needed.
- No output / wrong units — check `--recursive`, `--include`/`--exclude`
  precedence in [source discovery](docs/source-discovery.md).
- Missing Lazarus units — check `--package-path` and build-mode selection in
  [Lazarus projects](docs/lazarus-projects.md).
- CI failures on warnings/coverage — see
  [authoring feedback](docs/authoring-feedback.md) (`--fail-on`, `--min-documentation-coverage`).
- Windows runner issues — see
  [Windows CI troubleshooting](docs/windows-ci-troubleshooting.md).

<a id="scope-and-limitations"></a>

## 🛎️ Scope and limitations

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

## 🤝 Contribute

PasWeave requires Free Pascal 3.2.2 or newer plus the `fcl-passrc` and
`fcl-json` packages when compiling from source:

~~~text
make
make test
~~~

Run tests from the repository root so fixtures resolve. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow, test rules, golden
output policy, and how to add a CLI option; see
[building from source](docs/building-from-source.md) for direct FPC and
portable Windows build commands.

How to help: bug reports with a minimal `.pas` reproducer, focused pull
requests (one logical change + fixtures + docs), and real-world parser
fixtures. Keep `README.md`, `docs/`, `CHANGELOG.md`, and version metadata in
the same change; keep unrelated golden output byte-identical. The quality bar
for every milestone is defined in the [roadmap](ROADMAP.md).

The project history is in the [changelog](CHANGELOG.md); planned work and
acceptance evidence are in the [roadmap](ROADMAP.md).

## 👨‍💻 Download integrity

Each Windows release includes `pasweave.exe.sha256`:

~~~powershell
Get-FileHash .\pasweave.exe -Algorithm SHA256
~~~

Pre-release executables are not code-signed, so Windows may show a SmartScreen
warning. Download only from the PasWeave release page and compare the SHA-256
value before running the executable.

## 📄 License

PasWeave is released under the [MIT License](LICENSE). Bundled third-party
components retain their own licenses; see
[third-party notices](THIRD_PARTY_NOTICES.md).

## 🙏 Acknowledgments

- [Free Pascal Dev Team](https://www.freepascal.org/) for the Free Pascal compiler
- [Lazarus IDE Team](https://www.lazarus-ide.org/) for such an amazing IDE
- The helpful folks on various online communities:
    - [Unofficial Free Pascal Discord server](https://discord.com/channels/570025060312547359/570091337173696513)
    - [Free Pascal & Lazarus forum](https://forum.lazarus.freepascal.org/index.php)
    - [Tweaking4All Delphi, Lazarus, Free Pascal forum](https://www.tweaking4all.com/forum/delphi-lazarus-free-pascal/)
    - [Laz Planet - Blogspot](https://lazplanet.blogspot.com/) / [Laz Planet - GitLab](https://lazplanet.gitlab.io/)
    - [Delphi Basics](https://www.delphibasics.co.uk/index.html)
- Everyone who has helped make this project better
