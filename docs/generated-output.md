# Generated output

A successful build writes a self-contained documentation bundle:

```text
build/docs/
├── api-model.json
├── diagnostics.json
├── html/
│   ├── index.html
│   ├── assets/
│   │   ├── app.js
│   │   ├── diagram.js
│   │   ├── katex/
│   │   ├── math.js
│   │   ├── mermaid/
│   │   ├── search-index.js
│   │   └── site.css
│   └── units/
│       └── SimpleUnit.html
└── markdown/
    ├── index.md
    └── units/
        └── SimpleUnit.md
```

## Static HTML

Open `html/index.html` directly in a browser. The generated site needs no web
server or network connection; its KaTeX and Mermaid runtimes, styles, fonts,
and licenses are included in the output.

The HTML site provides:

- a responsive project overview and linked unit pages;
- searchable API symbols with unit, kind, visibility, and documentation-status
  filters;
- stable symbol anchors and repository source links when configured;
- safely rendered documentation prose and escaped Pascal declarations;
- offline KaTeX rendering, with invalid expressions left readable as source;
- linked project-dependency and type-relationship diagrams with accessible
  text fallbacks, zoom, pan, reset, keyboard controls, and independent state;
- build diagnostics and documentation-coverage totals.

Private and strict-private symbols remain in `api-model.json` but are omitted
from the generated API pages. See the [HTML renderer notes](html-renderer.md)
for the rendering, search, safety, and Markdown-subset contracts.

## Markdown

`markdown/index.md` contains project totals, documentation coverage, links to
each successfully parsed unit, and build diagnostics. Unit pages contain:

- source and interface-dependency information;
- linked public and protected symbols;
- overload-aware anchors and fenced Pascal declarations;
- preserved Markdown and mathematical delimiters;
- parameter, return, exception, deprecation, version, and see-also sections;
- a visible warning for each undocumented API symbol.

## JSON model and diagnostics

`api-model.json` is deterministic, human-readable UTF-8 JSON. It contains the
parser-independent project, unit, symbol, directive, and diagnostic models.

Class and interface symbols expose a `typeRelationships` array. Each entry
records:

- `kind` (`inherits` or `implements`);
- the typed-AST `targetName`;
- its source-like `displayName`;
- a stable `targetSymbolId` when the target resolves inside the documented
  project.

An empty target ID is an explicit unresolved result. Routine symbols also
expose parser-derived `parameterNames` and `hasReturnValue`. Directive objects
contain `targetSymbolId` for a resolved project-local `@see`; an empty value is
deliberately unresolved.

When source links are configured, the top-level model records the normalized
`repositoryUrl` and `sourceLinkTemplate`. These fields are additive schema-v1
changes.

`diagnostics.json` contains the same stable diagnostic codes shown on the HTML
and Markdown indexes, ready for CI systems to consume.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | No diagnostic met the configured `--fail-on` severity |
| `1` | Usable output was produced with a failing diagnostic |
| `2` | Command-line or input error |
| `3` | Unexpected internal failure |

`--fail-on=error` is the default. `--fail-on=warning` also fails on authoring
feedback. Add `--verbose` for diagnostic details without a stack trace.

All generated HTML, CSS, JavaScript, search-index, Markdown, and JSON files use
deterministic UTF-8 output with LF line endings.
