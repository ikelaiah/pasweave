# Static HTML renderer

PasWeave's HTML renderer consumes only the parser-independent documentation
model. A build writes a self-contained site beneath `html/`:

```text
html/
├── index.html
├── symbols.html
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

- The project index reports parsed declaration totals, a public API symbol
  total, and documentation coverage, and links to every successfully parsed
  unit. "Public API symbols" counts the same
  browsable population as the symbol index (renderable non-unit symbols),
  so the units count remains separate and coverage stays consistent with the
  index.
- Unit pages render public, protected, published, automated, and
  strict-protected API. Private and strict-private symbols, including members
  beneath private parents, remain JSON-only.
- The project index is ordered for documentation discovery: project summary,
  a **Browse API** section linking the symbol index, the units table,
  architecture diagrams, and build diagnostics last.
- A generated `symbols.html` symbol index lists every renderable non-unit
  API symbol, ordered by name and grouped into A–Z and `#` sections, with
  category filters for types, routines, members, constants, and variables.
- Every page header exposes a persistent **Symbols Index** destination alongside
  the units destination, and a keyboard-accessible reader theme control.
- Unit pages render public, protected, published, automated, and
  strict-protected API. Private and strict-private symbols, including members
  beneath private parents, remain JSON-only.
- HTML and Markdown use the same stable symbol anchors.
- Resolved dependency, parent, `@see`, inheritance, and implementation targets
  use model identities and those same anchors; unresolved targets remain
  visible as plain text rather than becoming guessed links.
- Declarations and documentation text are HTML-escaped.
- Documentation links reject active `javascript:`, `data:`, and `vbscript:`
  schemes.
- Build diagnostics survive partial parsing and appear on the project index.
- The index maps every parsed unit and every project-local interface
  dependency into a linked flowchart. Dependencies outside the documented
  project remain on unit pages and are not invented as graph nodes.
- The index maps explicit class inheritance, interface inheritance, and
  interface implementation from resolved model relationships. Resolved nodes
  link to stable symbol anchors; unresolved targets are labeled rather than
  guessed.
- Every output is deterministic UTF-8 without a byte-order mark and uses LF
  line endings.

## Unit and on-page navigation

Every generated unit page includes two local navigation layers above its unit
heading:

- a native **Switch unit** disclosure containing a deterministic alphabetical
  link to every parsed unit; and
- an **On this page** list containing only the non-empty symbol groups rendered
  on that unit page: Types, Routines, Members, and Constants and variables.

The switcher reuses the established `units/<UnitName>.html` filenames, and the
category links reuse the existing `#types`, `#routines`, `#members`, and
`#values` section IDs. Symbol IDs are unchanged. The project index remains the
canonical table of all units, coverage, and architectural relationships.

The complete unit list is ordinary HTML inside a native `details` element.
Without JavaScript, a reader opens the disclosure and follows any unit link in
two actions. With the local application script available, opening the switcher
focuses its labelled filter; the live status reports the number of matching
units, ArrowDown enters the visible links, ArrowDown and ArrowUp wrap through
them, and Escape closes the disclosure and returns focus to its summary.
Enter follows the focused native link.

The list is height-bounded and scrollable for large projects. At 760 CSS pixels
or below, the switcher and category navigator stack; at 480 CSS pixels or
below, the disclosure panel participates in normal layout so it cannot extend
beyond the phone viewport. Category targets use scroll margins for the sticky
site header.

Filtering and enhanced Arrow-key movement require JavaScript. With scripting
disabled, the complete alphabetical unit list and all category links remain
usable, while global symbol search is unavailable. The category navigator is
deliberately group-level; it does not duplicate the global search index with a
link for every declaration.

## Symbol index

Every build writes `symbols.html` beside the project index. It is derived
entirely from the documentation model and requires no manually maintained index
data. The page lists every renderable symbol except units themselves, so the
five category filters match the roadmap contract exactly: types, routines,
members, constants, and variables.

Symbols are sorted case-insensitively by name, then grouped into ordinary HTML
letter sections. Names beginning with `_`, digits, or other non-letter
characters are grouped under a `#` section. A letter bar links each present
section, and every entry links to its stable unit page and symbol anchor. The
complete list is server-rendered, so a reader can browse the whole index with
JavaScript disabled. The local application script adds category checkboxes that
hide non-matching native list entries, re-hide empty letter sections, and
announce the live filtered count through a polite status. Category deep links
such as `symbols.html#types` pre-select that filter when the script is
available.

The project index introduces the page through a **Browse API** section placed
directly beneath the project summary: a primary card linking the symbol index
with the total symbol count, plus one card per category that deep-links the
matching filter. The header also persists a **Symbols Index** link on every
generated page, including unit pages, while global search remains the fastest
known-name lookup and the project index remains the canonical unit and
architecture overview.

## Reader themes

Every page embeds a small dependency-free bootstrap in `<head>` that reads a
persisted reader choice from local storage and publishes it as `data-theme` on
the root element before the stylesheet applies. Valid choices are `system`,
`light`, and `dark`; the default is `system`. Reading is wrapped in a
`try/catch`, so rejected or unavailable storage, including documentation opened
directly through `file://`, safely falls back to the system scheme.

The stylesheet tokenizes every color and typography value as CSS custom
properties. The root default and the `[data-theme="system"]` state use the
light token set and follow `@media (prefers-color-scheme: dark)`; an explicit
`[data-theme="dark"]` applies the dark token set, and an explicit
`[data-theme="light"]` pins the light set regardless of the operating system.
Native controls follow the same choice through the `color-scheme` property.
KaTeX output inherits the active text color, and Mermaid diagrams select their
theme from `data-theme` and re-render when the reader changes scheme, so
mathematics, diagrams, focus states, and contrast stay synchronized without any
remote dependency.

A labelled native select offers **System**, **Light**, and **Dark**. It is
rendered `hidden` and revealed only by the application script, so pages with
scripting disabled simply follow the system color scheme. Changing the select
updates the root attribute immediately, persists the choice when storage is
available, and announces a `pasweave:themechange` event that the diagram
initializer listens for.

## Project branding

Build-time branding is a restrained, validated set of tokens rather than a
theme system. The CLI accepts:

```text
--project-mark=<1-4 alphanumeric characters>
--theme-accent=<#RGB|#RRGGBB|#RRGGBBAA>
--theme-accent-2=<color>
--theme-font=<safe family name>
```

The mark replaces the default `PW` brand mark in the header. The two colors
become the primary and secondary accent tokens, and the font name becomes the
body font family. Dark-mode accent variants are derived deterministically from
the configured colors; the built-in defaults reproduce the original light and
dark schemes. Invalid values are rejected before any output is written, and the
effective tokens are recorded additively in `api-model.json`. Reader-facing
named-theme galleries, arbitrary script injection, and remote theme assets are
explicitly out of scope.

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

## Class and interface relationship diagram

The relationship flowchart consumes `typeRelationships` from the independent
model. It does not inspect `declaration` text. Solid arrows point from a class
or interface to its ancestor; dotted arrows point from a class to an
implemented interface. Generic specializations resolve to the generic type
symbol while their complete source-like form remains available in JSON and the
text fallback.

Every resolved node links to its unit page and stable symbol fragment.
Ancestors outside the parsed source set and ambiguous references receive a
separate `[unresolved]` node, so similarly named external references are never
silently merged. Private and effectively private symbols remain excluded from
the rendered diagram under the normal HTML visibility contract.

Like the dependency view, the relationship diagram has an initially expanded
linked HTML list. The shared initializer collapses each fallback only after
that particular Mermaid source has produced an SVG; one failed diagram cannot
hide another diagram's fallback.

## Diagram interaction and fallback

Each successfully rendered diagram receives its own toolbar and view state.
Zoom changes in 25% steps between 50% and 300%; the live percentage is exposed
through an `output` element. Directional buttons pan by 96 pixels, and reset
returns the diagram to 100% at its top-left origin. Controls disable at their
current limits.

The rendered diagram is a labelled, focusable region. With that region
focused, the arrow keys pan, `+` and `-` zoom, and `0` resets. Mouse and pen
users can drag empty diagram space; dragging starts neither from link targets
nor controls, so Mermaid node links retain their normal behavior. Touch input
keeps the browser's native scrolling behavior. Each diagram remains
independent when both architecture views appear on the index.

Both axes can scroll within a height-bounded diagram viewport. Smooth button
and keyboard panning is disabled when the browser reports
`prefers-reduced-motion: reduce`.

The toolbar, help text, and focusable diagram remain hidden until Mermaid has
produced an SVG. The ordinary linked HTML fallback starts expanded in source
markup. It is collapsed only for a successfully rendered diagram, so disabled
JavaScript, a missing runtime, or an individual render failure leaves a
readable non-interactive view without exposing inert controls.

## Search

The offline search index contains one entry per renderable API symbol. Entries
include the name, qualified name, symbol kind, unit, visibility,
documentation status, target URL, and a short documentation summary. Search
requires all query terms and ranks exact and prefix name matches ahead of
general text matches. Native unit, kind, visibility, and documentation selects
compose with the query and can also be used without text. At most 24 results
are shown at once; the polite live status reports the total and explicitly
states when no symbols match.

Press `/` to focus search, ArrowDown to enter the results, ArrowUp or
ArrowDown to wrap through result links, and Escape to close it. Enter follows
the focused native link. All interactive controls have a visible
`:focus-visible` outline. At 480 CSS pixels or below the header, filters, and
statistics reflow to a single viewport-width column.

## Repository source links

When both repository options are configured, unit and symbol source locations
link to the exact declaration line in HTML and Markdown. The model owns the
normalized repository base and relative template; a shared helper rejects
unsafe source filenames and expands the link before either renderer escapes
it for output. Without configuration, locations remain plain text and existing
output routes are unchanged. See [navigation and source
traceability](navigation-and-source-traceability.md) for the full contract.

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
- `PasWeave.SourceLinks` validates and expands renderer-neutral repository
  links.
- `PasWeave.Render.Links` owns shared symbol-target selection.
- `PasWeave.Render.Support` owns renderer-neutral stable anchors.

Brace-comment documentation is not part of the renderer. It remains a parser
dialect decision because ordinary `{ ... }` blocks frequently contain section
labels or implementation notes rather than API prose.
