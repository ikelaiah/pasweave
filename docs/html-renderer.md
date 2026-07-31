# Static HTML renderer

PasWeave's HTML renderer consumes only the parser-independent documentation
model. A build writes a self-contained site beneath `html/`:

```text
html/
├── index.html
├── assets/
│   ├── app.js
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
- Every output is deterministic UTF-8 without a byte-order mark and uses LF
  line endings.

## Search

The offline search index contains one entry per renderable API symbol. Entries
include the name, qualified name, symbol kind, unit, target URL, and a short
documentation summary. Search requires all query terms and ranks exact and
prefix name matches ahead of general text matches. At most 24 results are
shown at once.

Press `/` to focus search and Escape to close it.

## Markdown and mathematics

The dependency-free HTML conversion currently covers paragraphs, headings,
bullet and numbered lists, block quotes, fenced code, emphasis, strong text,
inline code, links, and inline or display mathematical delimiters. It does not
attempt to implement every Markdown extension.

`$...$` and `$$...$$` source is retained in elements marked with
`data-math-inline` and `data-math-display`. This is the integration point for
the planned KaTeX phase; the current site does not load a remote renderer.

## Source units

- `PasWeave.Render.HTML` builds pages and the search index.
- `PasWeave.Render.HTML.Markdown` safely converts the supported Markdown
  subset.
- `PasWeave.Render.HTML.Assets` owns the generated stylesheet and JavaScript.
- `PasWeave.Render.Support` owns renderer-neutral stable anchors.

Brace-comment documentation is not part of the renderer. It remains a parser
dialect decision because ordinary `{ ... }` blocks frequently contain section
labels or implementation notes rather than API prose.
