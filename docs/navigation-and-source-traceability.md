# Navigation and source traceability

PasWeave v0.5.0 adds repository source links, complete model-backed
relationship navigation, and filtered offline search without changing the
existing unit-page or stable-symbol-anchor formats.

## v0.5.2 API discovery and reader themes

PasWeave v0.5.2 makes an unfamiliar API discoverable by browsing and lets
readers choose a comfortable color scheme without weakening the offline
contract.

Every build now writes `symbols.html`: a model-derived A–Z index of every
renderable non-unit symbol, grouped into letter sections with stable links and
category filters for types, routines, members, constants, and variables. The
complete list is ordinary HTML, so browsing works without JavaScript; the local
script adds category checkboxes, live counts, and category deep links. See the
[HTML renderer guide](html-renderer.md) for the markup and interaction details.

The project index now follows a discovery-first order: project summary,
**Browse API**, the units table, architecture diagrams, then diagnostics. The
**Browse API** section leads with an A–Z card and per-category cards, and every
page header persists a **Symbols Index** destination. Unit URLs, overload-aware
anchors, the search-index schema, source links, and both project diagrams
retain their v0.5.0 and v0.5.1 contracts.

Every page embeds a dependency-free theme bootstrap that publishes
`data-theme` before rendering, and a keyboard-accessible **System / Light /
Dark** control. An explicit choice is remembered through local storage when
available and falls back to the system scheme when storage is rejected,
including direct `file://` use. The stylesheet tokenizes all colors and
typography; KaTeX follows the active text color and Mermaid diagrams re-render
on theme change. Build-time branding adds validated `--project-mark`,
`--theme-accent`, `--theme-accent-2`, and `--theme-font` options whose
effective values are recorded additively in `api-model.json`.

The documented and scientific examples are golden-output fixtures for the new
markup and assets. An isolated headless Chrome run over the generated index,
unit page, and a 2,657-entry `mathlib-fp` symbol index reported clean consoles,
an applied `data-theme` attribute, and a revealed theme control. The latest
`mathlib-fp` commit `b5aea1c2d841fd82f9e98cb770c00fc04c2d9b17` produced 175
identical files across two runs, and all 50 unit pages carry the theme control.
See the [full audit](mathlib-fp-validation.md).

The Pages workflow applies the same symbol-index, header-navigation, and theme
assertions before upload and after deployment. The public showcase check is the
one post-merge release gate because the deployed site cannot contain this
branch before it reaches `main`.

## v0.5.1 unit and section navigation

PasWeave v0.5.1 adds direct navigation within and between generated unit
pages. Every unit page renders a native **Switch unit** disclosure containing
all units in deterministic alphabetical order. The current unit remains a
link and is identified with `aria-current="page"`. A reader can therefore
open the disclosure and follow any unit link in two actions without returning
to the API index.

The complete link list is present before JavaScript runs. The dependency-free
application script progressively adds a labelled text filter, polite match
count, ArrowUp and ArrowDown movement through visible links, and Escape-to-
close behavior with focus restoration. With JavaScript disabled, the native
disclosure and every direct unit link remain available; filtering and global
symbol search do not.

An **On this page** navigator links only to symbol groups that are actually
rendered in the current unit: Types, Routines, Members, and Constants and
variables. These links reuse the established group fragments. Unit filenames,
overload-aware symbol anchors, the API index, and both project-wide diagrams
retain their v0.5.0 contracts. Declarations have not been added to the project
graphs.

The documented and scientific examples are golden-output fixtures for the new
markup and assets. An isolated Chrome run verified the scientific unit pages
at 1280 and 390 CSS pixels, including filter status, ArrowDown, Escape, stable
category fragments, direct no-JavaScript unit navigation, viewport fit, and a
clean console.

The latest `mathlib-fp` main commit
`b5aea1c2d841fd82f9e98cb770c00fc04c2d9b17` contains 50 units. Two v0.5.1
builds produced the same 174 files with zero byte differences. All 50 unit
pages exposed all 50 unit links, one current-page state, and valid category
targets. A real-browser check confirmed the height-bounded 50-unit list,
filter and keyboard behavior, desktop layout, and 390-pixel phone layout.
See the [full audit](mathlib-fp-validation.md).

The Pages workflow applies the same switcher, direct-link, category, and
application-script assertions before upload and after deployment. The public
showcase check is the one post-merge release gate because the deployed site
cannot contain this branch before it reaches `main`.

## Repository source links

Source links are opt-in and require two command-line options together:

```text
pasweave build src --repository-url=https://github.com/example/project \
  '--source-link-template=blob/main/{path}#L{line}'
```

`--repository-url` is the stable HTTP or HTTPS base for the source repository.
`--source-link-template` is a URL path relative to that base. The template must
contain exactly one `{path}` and one `{line}` placeholder; `{line}` must occur
in the single URL fragment. Both the space-separated and `--option=value`
forms are accepted.

PasWeave normalizes each model source filename to forward slashes, requires it
to remain relative to the configured source root, URL-encodes non-path bytes,
and substitutes the positive declaration line. A source tree stored below a
repository subdirectory includes that prefix in the template:

```text
--repository-url=https://github.com/ikelaiah/pasweave
--source-link-template=blob/main/examples/scientific-api/{path}#L{line}
```

Unit headings and symbol metadata link to the same normalized repository
location in HTML and Markdown. `api-model.json` exposes the normalized
`repositoryUrl` and validated `sourceLinkTemplate` additively while retaining
schema version 1. Omitting both options retains plain source locations.

### Validation and rejection rules

PasWeave rejects configuration before writing output when:

- only one of the two source-link options is supplied;
- the repository URL is not HTTP(S), lacks a host, or contains whitespace, a
  backslash, credentials, query, fragment, placeholder, or encoded/literal
  path traversal;
- the template is absolute, starts at `/`, contains a query, contains current
  or parent traversal (including percent-encoded dot or separator bytes), or
  has leading/trailing whitespace;
- `{path}` or `{line}` is missing or repeated, `{line}` is not in the one URL
  fragment, or any unknown placeholder is present; or
- a model source filename is absolute, contains traversal, a drive/scheme
  colon, a query/fragment, or a control character.

These constraints keep every expanded link beneath the configured repository
base and exclude environment-, clock-, or host-dependent substitutions. The
rationale is recorded in
[ADR-0002](decisions/0002-repository-relative-source-links.md).

## Relationship navigation

All project-local semantic navigation uses the completed model rather than
renderer guesses:

- resolved `@see` directives use their stored `targetSymbolId`;
- interface dependencies link to the documented unit page;
- member parent links use the stable parent symbol ID; and
- inheritance and implementation entries link to resolved type symbol IDs.

Markdown and HTML select their own file extension but use the same unit route
and `DocumentationSymbolAnchor` fragment. Resolved type relationships now
appear beside each type in both formats in addition to the HTML overview
diagram and text fallback. Unresolved, ambiguous, private, or external targets
remain visible as plain code and never become guessed links.

No v0.5.0 change was made to `units/<UnitName>.html`,
`units/<UnitName>.md`, or the overload-aware symbol anchor algorithm. Golden
fixtures continue to pin those routes and fragments.

## Filtered offline search

`search-index.js` remains a deterministic local JavaScript assignment and now
stores these fields for every renderable symbol:

| Field | Purpose |
|---|---|
| `unit` | Unit filter and searchable text |
| `kind` | Symbol-kind filter |
| `visibility` | Visibility filter |
| `documented` | Documented/undocumented filter |
| `url` | Stable generated unit/anchor target |

The four filters compose with the existing token search and ranking. A filter
can be used without text. At most 24 entries are displayed, with the live
status explaining when additional results exist. Zero matches produce the
explicit message `No symbols match the current search and filters.`

The search input opens on focus and `/` focuses it from page content. Native,
visibly labelled selects remain keyboard accessible. ArrowDown moves from the
input to the first result; ArrowDown and ArrowUp wrap through result links;
Enter follows the focused link; Escape closes search. Result counts and empty
states use a polite live status. All links, inputs, selects, buttons, and
summary controls receive a visible `:focus-visible` outline. At 480 CSS pixels
or below, the header and search wrap, filters and statistics use one column,
and the content remains within the viewport.

## Validation evidence

### Checked-in examples

The documented and scientific golden outputs are generated with repository
links to their committed source directories. The complete automated suite
checks source links, relationship-link parity, unchanged anchor generation,
all search facets, metadata for documented and undocumented symbols, keyboard
behavior strings, focus styling, mobile rules, and deterministic output.

An isolated Edge runtime pass over the scientific showcase found:

- two Mermaid SVGs on the project index;
- 33 KaTeX-rendered expressions on `Scientific.Core` with zero math errors;
- five results for `gaussian`, with ArrowDown moving focus to the first result;
- 15 results when filtering to `Scientific.Analysis` without query text;
- the documented empty-result message for an impossible query; and
- zero page console or JavaScript runtime errors.

Desktop (1440 CSS pixels) and emulated-phone (320 CSS pixels) screenshots were
visually checked. The phone audit caught and fixed header/statistics horizontal
overflow before release.

### Nested multi-package project

`tests/fixtures/lazarus/multi-package/LazarusProject.lpi` was built in Release
mode through the CLI. It produced 3 units, 6 symbols, 3 HTML unit pages, and 6
source links with zero warnings, errors, or escaping URLs. Its search index
contains visibility and documentation fields.

### `mathlib-fp`

Pinned commit `6f3480b7e9494fcd4f72abb0f5c21dd30fde3e42` was built twice with
brace documentation, explicit Windows x86-64 compiler settings, and a
commit-pinned GitHub source template.

| Check | v0.5.0 result |
|---|---:|
| Units parsed | 45 of 45 |
| Model symbols | 2,338 |
| Renderable search entries | 2,227 |
| Line-aware source links | 2,227 |
| Search facets | 4 |
| Authoring warnings | 2,370 |
| Errors | 0 |
| Escaping source links | 0 |
| Generated files | 164 |

Both output trees had SHA-256
`467EC29C5BE937C6A22165E18ADAD9A72FF8C3715C463518F1A779BF4596A826`.
The warning count reflects the v0.4.0 directive rules applied to existing
brace documentation; warnings do not fail the default local workflow.

## GitHub Pages showcase

The `Publish documentation showcase` workflow tests and builds PasWeave on
Ubuntu, regenerates the scientific example from committed Pascal sources,
checks its coverage, search facets, diagrams, mathematics, source links, and
stable anchor, and uploads only the self-contained HTML tree. A deploy job
publishes the artifact to `https://ikelaiah.github.io/pasweave/` and performs
HTTP checks against the deployed index, unit page, and search index.

Pull requests run the build and generated-site contract checks without
configuring or publishing Pages. Pushes to `main` enable Pages when necessary
and publish automatically; once the workflow exists on the default branch, an
explicit manual dispatch can publish another reviewed branch.
