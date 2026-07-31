# PasWeave

PasWeave is an early-stage documentation generator designed primarily for
Free Pascal projects. It is written in Free Pascal and builds its source model
with FPC's reusable `fcl-passrc` parser libraries.

This repository currently contains a working parser-to-site pipeline:

- a `pasweave build` command for one Pascal unit or a non-recursive directory
  of `.pas` and `.pp` units;
- interface parsing through `fcl-passrc`;
- parser-independent project, unit, symbol, directive, and diagnostic models;
- association of consecutive `///` documentation lines captured by the
  parser;
- structural extraction of `@param`, `@returns`, `@raises`, `@deprecated`,
  `@see`, and `@since`;
- deterministic, human-readable UTF-8 JSON;
- a deterministic Markdown project index and one page per parsed unit;
- stable overload-aware anchors, internal dependency links, parent links,
  fenced Pascal declarations, directive sections, and visible undocumented
  API warnings;
- a responsive static HTML project index and one page per parsed unit;
- dependency-free, offline client-side search across every renderable API
  symbol;
- shared styling with light and dark colour schemes, safe Markdown-to-HTML
  conversion, and mathematical delimiters preserved for later rendering;
- per-file error isolation, concise summaries, and meaningful exit codes.

The Markdown renderer consumes only PasWeave's model. FPC parser classes remain
contained behind the adapter.

## Scope

PasWeave targets Free Pascal and `{$mode objfpc}` first. Delphi-compatible
syntax is accepted only where it works naturally through FPC's parser.
PasWeave does not contain a Pascal parser of its own.

PasWeave is not a fork of PasDoc or FPDoc. It explores a Free Pascal-first
workflow centred on Markdown, structured output and modern static
documentation. We appreciate the substantial work those projects have
contributed to the Pascal ecosystem.

## Requirements

- Free Pascal 3.2.2 or newer
- the FPC `fcl-passrc` and `fcl-json` packages

The current adapter was inspected and tested specifically against FPC 3.2.2.
See [the parser integration notes](docs/parser-integration.md) for the exact
APIs used and known uncertainties.

The first real-world run against all 45 source units in
[`mathlib-fp`](https://github.com/ikelaiah/mathlib-fp) produced 2,338 symbols
with no parse errors, missing source positions, or duplicate stable IDs. See
[the validation report](docs/mathlib-fp-validation.md) for the tested revision,
determinism result, and its important comment-syntax finding.

## Compile

With a POSIX-compatible `make`:

```text
make
make test
```

Directly with FPC from the repository root:

```text
mkdir -p build/bin build/tests build/units
fpc -Mobjfpc -Sh -Fusrc/cli -Fusrc/diagnostics -Fusrc/model -Fusrc/parser -Fusrc/render -FUbuild/units -FEbuild/bin src/pasweave.lpr
fpc -Mobjfpc -Sh -Fusrc/cli -Fusrc/diagnostics -Fusrc/model -Fusrc/parser -Fusrc/render -FUbuild/units -FEbuild/tests tests/test_pasweave.pas
```

On PowerShell, create the directories with:

```powershell
New-Item -ItemType Directory -Force build/bin, build/tests, build/units
```

Run the test executable from the repository root so it can find its fixture:

```text
build/tests/test_pasweave
```

## Use

```text
build/bin/pasweave build tests/fixtures --output build/docs
```

The command writes:

```text
build/docs/
├── api-model.json
├── html/
│   ├── index.html
│   ├── assets/
│   │   ├── app.js
│   │   ├── search-index.js
│   │   └── site.css
│   └── units/
│       └── SimpleUnit.html
└── markdown/
    ├── index.md
    └── units/
        └── SimpleUnit.md
```

The command exits with `0` when every input parsed, `1` when usable output was
produced with one or more per-file parse errors, `2` for command-line or input
errors, and `3` for an unexpected internal failure. `--verbose` adds the
underlying exception class and adapter mode without printing a stack trace.

## Documentation comments

Place consecutive `///` lines immediately before an interface declaration:

```pascal
/// Returns the standard normal probability density.
///
/// $$
/// \phi(x) = \frac{1}{\sqrt{2\pi}}e^{-x^2/2}
/// $$
///
/// @param X Point at which the density is evaluated.
/// @returns The probability density at `X`.
function NormalPDF(const X: Double): Double;
```

Ordinary Markdown and mathematical delimiters are retained in
`markdownDocumentation`. The original `///` form is retained in
`rawDocumentation`, while recognised directives are also emitted as structured
objects.

## Markdown output

`markdown/index.md` contains project totals, documentation coverage, links to
every successfully parsed unit, and any build diagnostics. Each unit page
contains:

- source and interface-dependency information;
- linked public and protected types, routines, members, constants, and
  variables;
- stable explicit anchors that distinguish overloads;
- fenced `pascal` declarations;
- preserved Markdown and mathematical delimiters;
- parameter, return, raised-exception, deprecation, version, and see-also
  sections;
- a visible warning for every undocumented API symbol.

Private and strict-private symbols remain in `api-model.json` but are omitted
from the generated API pages.

## Static HTML output

Open `html/index.html` directly in a browser. The generated site requires no
web server and no third-party runtime dependencies. It contains:

- a responsive project overview and linked unit pages;
- the same stable symbol anchors and visibility filtering as Markdown;
- escaped Pascal declarations and safely rendered documentation prose;
- preserved display and inline mathematical delimiters;
- an offline search index covering names, qualified names, kinds, units, and
  documentation summaries;
- keyboard search focus with `/` and dismissal with Escape;
- build diagnostics and visible documentation-coverage totals.

The HTML, stylesheet, JavaScript, and search index are deterministic UTF-8
files with LF line endings. See [the HTML renderer notes](docs/html-renderer.md)
for its offline-search, safety, and Markdown-subset contracts.

## Current limitations

- no KaTeX rendering yet; mathematical source is preserved and marked in the
  HTML for the next renderer phase;
- the dependency-free Markdown-to-HTML conversion intentionally supports a
  focused subset rather than every Markdown extension;
- no Mermaid diagrams or diagram pan and zoom;
- source directory discovery is non-recursive;
- no project/package file reader or configurable compiler search paths;
- no semantic type resolution or implementation-body analysis;
- only `///` documentation is extracted; plain brace comments such as those
  currently used by `mathlib-fp` are not treated as API documentation;
- blank-line adjacency for `///` groups is not yet independently verified
  against source text;
- no fixture coverage yet for every requested symbol kind or unusual FPC
  syntax;
- no license has been selected for the repository yet.

The absence of a license is intentional in this bootstrap commit: choosing an
open-source license is a maintainer decision, not a code-generation default.

## Roadmap

The next renderer milestone is KaTeX integration for the mathematical source
already marked in the HTML. Mermaid class and unit-dependency diagrams,
followed by interactive zooming and panning, come after that. An opt-in brace
comment dialect remains a separate compatibility decision because ordinary
brace comments often contain section labels and implementation notes rather
than public API documentation.
