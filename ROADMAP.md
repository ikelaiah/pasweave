# PasWeave roadmap

PasWeave is being built as a sequence of usable documentation pipelines. Each
milestone should leave the command-line application functional, deterministic,
and covered by small fixtures before broader features are added.

This roadmap records direction rather than release dates. Priorities may move
when real Free Pascal projects expose a more immediate compatibility need.

## Completed

### Parser, model, JSON, and Markdown foundation

- Parse Free Pascal unit interfaces through `fcl-passrc`.
- Keep FPC parser classes behind an adapter.
- Represent units, symbols, documentation, directives, and diagnostics in a
  renderer-independent model.
- Generate deterministic UTF-8 JSON and linked Markdown pages.
- Preserve Markdown and mathematical delimiters from `///` documentation.
- Continue building when an individual unit fails to parse.
- Validate the pipeline against fixtures and all 45 units in `mathlib-fp`.

### Searchable static HTML

- Generate a responsive project index and one page per unit.
- Share stable symbol anchors with Markdown.
- Render a safe, focused Markdown subset without remote dependencies.
- Provide an offline JavaScript search index.
- Support light and dark colour schemes.
- Preserve inline and display mathematics for a later renderer.
- Audit generated links, assets, anchors, search targets, and deterministic
  output against `mathlib-fp`.

## Next: documentation comment dialects

PasWeave currently recognizes consecutive `///` comments. The next milestone
will allow a project to opt into the Pascal comment forms it uses for API
documentation.

Planned command-line forms:

```text
--doc-comments=slash
--doc-comments=brace
--doc-comments=paren
--doc-comments=slash,brace,paren
--doc-comments=all
```

The default will remain `slash` so ordinary source comments do not silently
become public documentation.

Acceptance criteria:

- Recognize enabled `///`, `{ ... }`, and `(* ... *)` documentation.
- Merge adjacent enabled comment forms in source order.
- Require documentation to immediately precede its declaration; a blank line
  ends the association.
- Never treat `{$...}` or `(*$...*)` compiler directives as documentation.
- Preserve original delimiters in `rawDocumentation`.
- Normalize combined bodies into `markdownDocumentation`.
- Extract existing structured directives across a mixed comment group.
- Attach each group to only the following interface declaration.
- Add fixtures for mixed forms, blank lines, directives, section labels,
  disabled code, and private declarations.
- Re-run `mathlib-fp` with brace comments enabled and report both useful
  coverage and false-positive findings.

Explicit block-documentation markers such as `{** ... }` and `(** ... *)`
may later be recognized independently of the ordinary-comment settings.

## Planned: mathematical rendering

- Integrate KaTeX with the elements already marked by `data-math-inline` and
  `data-math-display`.
- Keep generated sites usable offline.
- Preserve the original mathematical source in JSON and Markdown.
- Report invalid expressions without failing the documentation build.
- Define a clear asset and license strategy before vendoring KaTeX.

## Planned: diagrams

### Unit dependencies

- Generate Mermaid graphs from interface dependencies.
- Link diagram nodes to unit pages.
- Keep graph output deterministic.

### Type relationships

- Expand semantic type resolution where required.
- Generate class and interface relationship diagrams from resolved model data.
- Avoid guessing relationships from declaration text alone.

### Interaction

- Add accessible zooming, panning, and reset controls.
- Provide a readable non-interactive fallback.

## Later opportunities

- Recursive source discovery and project/package file readers.
- Configurable compiler search paths, defines, targets, and include paths.
- Source-code links and repository URL templates.
- Search filters for unit, kind, visibility, and documentation coverage.
- Incremental builds and stale-output cleanup.
- Lazarus integration after the command-line workflow is stable.
- Additional output formats only when they can consume the existing model.

## Continuing constraints

- Target Free Pascal and `{$mode objfpc}` first.
- Use FPC's reusable parser libraries rather than writing a Pascal parser.
- Keep the documentation model independent from renderers.
- Prefer deterministic, offline output and small dependencies.
- Do not infer public prose or type relationships when source intent is
  ambiguous.
- Keep diagnostics precise, including filenames and source positions.
