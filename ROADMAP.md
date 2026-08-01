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

### Portable Windows distribution

- Build one portable `pasweave.exe` with no installer.
- Embed the exact KaTeX and Mermaid payload required by the HTML renderer.
- Expose an explicit pre-release version through `--version`.
- Smoke-test the executable outside the repository asset layout.
- Publish the raw executable and its SHA-256 checksum from a version tag.

### Documentation comment dialects

PasWeave defines consecutive `///` comments as its explicit documentation
marker and recognizes them by default. This is a PasWeave convention, not a
special Free Pascal or `fcl-passrc` comment form: FPC sees `///` as an ordinary
`//` comment whose body starts with `/`. A project can opt into the Pascal
block-comment forms it uses for API documentation.

Command-line forms:

```text
--doc-comments=slash
--doc-comments=brace
--doc-comments=paren
--doc-comments=slash,brace,paren
--doc-comments=all
```

The CLI name `slash` means exactly consecutive `///` lines, never ordinary
`//` comments. It remains the default so ordinary source comments do not
silently become public documentation.

Completed acceptance criteria:

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

The `mathlib-fp` brace-mode audit found useful API prose and expected
false-positive section labels.

### Offline mathematical rendering

- Integrate KaTeX with the elements already marked by `data-math-inline` and
  `data-math-display`.
- Keep generated sites usable offline.
- Preserve the original mathematical source in JSON and Markdown.
- Report invalid expressions without failing the documentation build.
- Define a clear asset and license strategy before vendoring KaTeX.

KaTeX 0.18.1 is vendored with its MIT license and copied into each generated
site with its fonts. PasWeave renders only explicitly marked math nodes, keeps
invalid source readable, and avoids interpreting paired currency amounts as
mathematics. Fixture and browser checks cover valid, invalid, inline, display,
escaped-dollar, and offline-loading behavior.

### Unit dependency diagrams

- Generate Mermaid graphs from interface dependencies.
- Link diagram nodes to unit pages.
- Keep graph output deterministic.
- Keep the generated site usable without a network connection.
- Provide an accessible textual dependency list when diagrams are unavailable.

Mermaid Tiny 11.16.0 is vendored with its MIT license and copied into each
generated site. Graph nodes and edges follow stable sorted model data, local
unit links remain active, and an initially expanded linked text list survives
disabled JavaScript or diagram errors.

### Type relationships

- Capture explicit ancestors and implemented interfaces from typed
  `fcl-passrc` nodes rather than declaration text.
- Resolve targets against the declaring unit and its interface dependencies.
- Preserve generic display syntax while resolving its underlying declaration.
- Keep external and ambiguous targets explicitly unresolved.
- Emit deterministic, linked Mermaid graphs and readable text fallbacks.
- Cover inheritance, interface implementation, generics, unresolved
  ancestors, cross-unit scope, and declaration-text non-inference in fixtures.
- Validate the model and rendered diagram against all 45 `mathlib-fp` units.

The `mathlib-fp` audit found 34 explicit relationships. Seven resolve inside
the documented project; 27 standard-library ancestors remain honest
unresolved nodes because their declaring units are outside the source set.

### Diagram interaction

- Provide independent zoom, directional pan, and reset controls for every
  successfully rendered architecture diagram.
- Support keyboard panning, zooming, and reset while the diagram region has
  focus, plus mouse and pen dragging without intercepting linked nodes.
- Bound zoom to 50–300%, report the current scale to assistive technology,
  and respect reduced-motion preferences.
- Keep controls hidden when Mermaid is unavailable and retain the initially
  expanded linked text fallback when JavaScript is disabled or rendering
  fails.
- Exercise the controls, linked SVGs, independent diagram state, and fallback
  behavior in a real browser against fixtures and `mathlib-fp`.

The 45-unit `mathlib-fp` site retained all 79 SVG links across its two
diagrams. Browser checks reached both zoom bounds, panned, dragged, reset, and
confirmed that interacting with one diagram leaves the other unchanged.

### Project-aware source discovery

- Preserve single-file input and top-level-only directory discovery by
  default.
- Add opt-in deterministic recursion for `.pas` and `.pp` source trees.
- Support repeatable, root-relative include and exclude globs, with `*` and
  `?` confined to one path segment and `**` spanning directories.
- Make exclusions take precedence and prune matching generated, vendored, and
  test directories.
- Reject empty, absolute, and parent-traversing patterns.
- Cover nested units, `.pp` files, filters, precedence, unsafe patterns,
  deterministic output, and explicit-file compatibility in fixtures.
- Confirm that default and recursive `mathlib-fp` builds remain identical for
  its current flat source tree.

Lazarus project and package readers remain deferred until their compiler
paths, defines, and target settings can be represented honestly.

## Next: compiler-aware parsing configuration

- Expose repeatable unit paths, include paths, and conditional defines without
  leaking `fcl-passrc` types into the documentation model.
- Represent target OS and CPU settings explicitly instead of silently using
  host defaults.
- Normalize and validate compiler inputs with deterministic diagnostics.
- Add fixtures for include files, conditional declarations, and dependencies
  found through configured paths.
- Preserve current builds when no compiler configuration is supplied.
- Re-run `mathlib-fp` with explicit settings matching its supported build.

## Later opportunities

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
