# Static HTML renderer

PasWeave's HTML renderer consumes only the parser-independent documentation
model. A build writes a self-contained site beneath `html/`:

```text
html/
├── index.html
├── assets/
│   ├── app.js
│   ├── diagram.js
│   ├── katex/
│   │   ├── fonts/
│   │   ├── katex.min.css
│   │   ├── katex.min.js
│   │   └── LICENSE
│   ├── math.js
│   ├── mermaid/
│   │   ├── mermaid.tiny.js
│   │   └── LICENSE
│   ├── search-index.js
│   └── site.css
└── units/
    └── UnitName.html
```

The site works when `index.html` is opened directly from disk. Search data is
assigned by `search-index.js` rather than fetched as JSON, so browser security
rules for `file://` URLs do not disable search.

## Rendering contract

- The project index reports parsed, public, and documented symbol totals and
  links to every successfully parsed unit.
- Unit pages render public, protected, published, automated, and
  strict-protected API. Private and strict-private symbols, including members
  beneath private parents, remain JSON-only.
- HTML and Markdown use the same stable symbol anchors.
- Declarations and documentation text are HTML-escaped.
- Documentation links reject active `javascript:`, `data:`, and `vbscript:`
  schemes.
- Build diagnostics survive partial parsing and appear on the project index.
- The index maps every parsed unit and every project-local interface
  dependency into a linked flowchart. Dependencies outside the documented
  project remain on unit pages and are not invented as graph nodes.
- Every output is deterministic UTF-8 without a byte-order mark and uses LF
  line endings.

## Unit dependency diagram

The project index embeds deterministic Mermaid flowchart source. Units are
sorted before receiving stable node identifiers; edges follow sorted source
units and their already sorted interface dependency lists. Every graph node
links to the corresponding generated unit page. The initializer also requests
deterministic SVG identifiers from Mermaid.

The text dependency list is ordinary linked HTML and starts expanded. After a
successful diagram render it remains available in a collapsed `details`
element. If JavaScript is disabled, the local runtime is missing, or Mermaid
rejects the graph, the diagram stays hidden and the expanded text list remains
usable. Isolated units are included explicitly.

Only index pages load Mermaid. PasWeave uses the single-file Mermaid Tiny
browser build, so opening `index.html` through `file://` neither requires a
server nor requests lazy-loaded chunks. Mermaid's `securityLevel` is `loose`
to enable node links; diagram source is generated solely from parsed unit
names, fixed prose, and local unit filenames, never from documentation
Markdown or arbitrary HTML.

## Search

The offline search index contains one entry per renderable API symbol. Entries
include the name, qualified name, symbol kind, unit, target URL, and a short
documentation summary. Search requires all query terms and ranks exact and
prefix name matches ahead of general text matches. At most 24 results are
shown at once.

Press `/` to focus search and Escape to close it.

## Markdown and mathematics

The dependency-free Markdown conversion covers paragraphs, headings, bullet
and numbered lists, block quotes, fenced code, emphasis, strong text, inline
code, links, and inline or display mathematical delimiters. It does not
attempt to implement every Markdown extension.

`$...$` and standalone `$$...$$` fences are retained in elements marked with
`data-math-inline` and `data-math-display`. A local initializer renders only
those marked elements through KaTeX 0.18.1; PasWeave does not run a broad
auto-render pass over prose or code. KaTeX's default HTML and MathML output is
therefore available without a network connection.

Successful rendering replaces the marked node's content and records
`data-math-rendered="true"`. If KaTeX rejects an expression, its original
delimiters and source remain visible with an error style, a title containing
the parser message, and a console warning. A missing runtime likewise leaves
all source readable. Neither case fails the documentation build.

Inline dollar delimiters follow conservative boundaries to avoid confusing
currency with mathematics: the opening dollar must touch the content on its
right, the closing dollar must touch the content on its left, and the closing
dollar cannot be followed immediately by a digit. Write `\$` for a literal
dollar where the remaining text would otherwise be ambiguous. Double-dollar
display fences must occupy their own lines.

## KaTeX assets

The repository vendors the official KaTeX 0.18.1 browser distribution under
`assets/katex/`, including all CSS-referenced font formats and the upstream MIT
license. A build copies those bytes into `html/assets/katex/`; generated pages
refer only to local paths. See [the third-party notices](../THIRD_PARTY_NOTICES.md)
and [the vendoring record](../assets/katex/README.md) for provenance and
checksums.

When running a repository build, PasWeave discovers `assets/katex/` relative
to the executable or current working directory. A packaged installation may
place the directory beside the executable, under `share/pasweave/katex`, or
set `PASWEAVE_KATEX_ASSETS` to its exact location. The build stops with a clear
error if the required runtime, stylesheet, license, or fonts are absent;
silently producing a partially styled site would violate the offline-output
contract.

The initializer uses `throwOnError: true`, `strict: "warn"`, and
`trust: false`. The generated asset set and page references are deterministic.

## Mermaid assets

The repository vendors Mermaid Tiny 11.16.0 under `assets/mermaid/` with the
upstream MIT license. A build copies both files into
`html/assets/mermaid/`; generated pages refer only to that local runtime. See
[the third-party notices](../THIRD_PARTY_NOTICES.md) and
[the vendoring record](../assets/mermaid/README.md) for provenance and
checksums.

Asset discovery follows the KaTeX strategy: repository builds find the
directory relative to the executable or current working directory, packaged
installations may place it beside the executable or under
`share/pasweave/mermaid`, and `PASWEAVE_MERMAID_ASSETS` may specify the exact
directory. Missing runtime or license files stop the build rather than
silently weakening the offline-output contract.

## Source units

- `PasWeave.Render.HTML` builds pages and the search index.
- `PasWeave.Render.HTML.Markdown` safely converts the supported Markdown
  subset.
- `PasWeave.Render.HTML.Assets` owns the generated stylesheet and JavaScript.
- `PasWeave.Render.Support` owns renderer-neutral stable anchors.

Brace-comment documentation is not part of the renderer. It remains a parser
dialect decision because ordinary `{ ... }` blocks frequently contain section
labels or implementation notes rather than API prose.
