# `mathlib-fp` real-world validation

PasWeave's first substantial external test is
[`ikelaiah/mathlib-fp`](https://github.com/ikelaiah/mathlib-fp), as planned in
the project brief.

## `v0.5.2` API-discovery and reader-theme revalidation

The latest `mathlib-fp` `main` revision available on 2026-08-15 was
`b5aea1c2d841fd82f9e98cb770c00fc04c2d9b17` (committed 2026-08-12). It contains
50 Pascal units. The source directory was built twice with brace documentation,
explicit `win64`/`x86_64` compiler settings, source links pinned to that exact
revision, and the new branding options:

```text
pasweave build mathlib-fp/src --output build/mathlib-v052 \
  --project-name mathlib-fp --doc-comments=brace \
  --unit-path mathlib-fp/src --target-os win64 --target-cpu x86_64 \
  --repository-url=https://github.com/ikelaiah/mathlib-fp \
  '--source-link-template=blob/b5aea1c2d841fd82f9e98cb770c00fc04c2d9b17/src/{path}#L{line}' \
  --project-mark ML
```

| Check | Result |
|---|---:|
| Source units parsed | 50 of 50 |
| Model symbols | 2,978 |
| Renderable search entries | 2,707 |
| A–Z symbol index entries | 2,657 |
| Symbol index letter sections | 26 |
| Unit pages | 50 |
| Unit pages with the theme control | 50 of 50 |
| Generated files | 175 |
| Authoring warnings | 2,846 |
| Errors | 0 |
| Differing files between runs | 0 |

The project index followed the new discovery-first order (summary, Browse API,
units, dependency diagram, relationship diagram, diagnostics), the `symbols.html`
page contained `data-symbol-index`, `data-symbol-filter`, and 2,657
`data-symbol-entry` rows with kind badges, and every unit page embedded the
`data-theme` bootstrap and the `data-theme-control` select. Under the v0.5.4
count contract, the 2,657 A–Z index entries are exactly the project's "public
API symbols": the 2,978 model symbols split into 50 unit declarations plus the
renderable non-unit API (private symbols are excluded). The two complete
output trees had the same audit digest, calculated as SHA-256 over sorted
relative-path and file-SHA-256 rows:

```text
98B9DAB763AD46D83E71A607E30211F05B7CB1DCDDF1903A9E273809BAD88F9B
```

An isolated headless Chrome run opened `symbols.html` directly through
`file://`. The 2,657-entry page rendered all letter sections and kind badges,
the bootstrap published `data-theme="system"`, the theme control was revealed,
and the console reported no errors or warnings. The index and unit-page runs
reported the same clean-console result.

The warning count comes from applying the existing authoring rules to upstream
brace comments. It is non-fatal under the default local policy and is not a
discovery or theme failure.

## `v0.5.1` navigation-polish revalidation

The latest `mathlib-fp` `main` revision available on 2026-08-15 was
`b5aea1c2d841fd82f9e98cb770c00fc04c2d9b17` (committed 2026-08-12). It has
grown to 50 Pascal units. The source directory was built twice with brace
documentation, explicit `win64`/`x86_64` compiler settings, and source links
pinned to that exact revision:

```text
pasweave build mathlib-fp/src --output build/mathlib-v051-a \
  --project-name mathlib-fp --doc-comments=brace \
  --unit-path mathlib-fp/src --target-os win64 --target-cpu x86_64 \
  --repository-url=https://github.com/ikelaiah/mathlib-fp \
  '--source-link-template=blob/b5aea1c2d841fd82f9e98cb770c00fc04c2d9b17/src/{path}#L{line}'
```

| Check | Result |
|---|---:|
| Source units parsed | 50 of 50 |
| Model symbols | 2,978 |
| Renderable search entries | 2,707 |
| Unit pages | 50 |
| Direct unit links on every unit page | 50 |
| Generated files | 174 |
| Authoring warnings | 2,846 |
| Errors | 0 |
| Navigation audit failures | 0 |
| Differing files between runs | 0 |

Every unit page contained the native searchable switcher, exactly one
`aria-current="page"` link, and valid targets for every rendered on-page
category link. The API index retained both its unit-dependency and type-
relationship diagrams. The two complete output trees had the same audit
digest, calculated as SHA-256 over sorted relative-path and file-SHA-256 rows:

```text
EE702B7A8727050A786AA4DF329F6B34EC8DFF7E7ECAFA508ED014C123C75952
```

An isolated Chrome run opened `AlgebraLib.Determinants.html` from the first
output tree. At 1280 CSS pixels, the 50-unit list was height-bounded and
scrollable; filtering to `TimeSeriesLib.TimeSeries` announced one result;
ArrowDown focused that direct link; and Escape closed the switcher and restored
summary focus. At 390 CSS pixels, the navigation stacked, the panel stayed
inside the viewport, the long list remained bounded, and the document had no
horizontal overflow. The final run reported no console warnings or errors.

The warning count comes from applying the existing authoring rules to upstream
brace comments. It is non-fatal under the default local policy and is not a
navigation failure.

## `v0.5.0` navigation and source-traceability revalidation

Commit `6f3480b7e9494fcd4f72abb0f5c21dd30fde3e42` was built twice with brace
documentation, explicit `win64`/`x86_64` compiler settings, and a source-link
template pinned to that exact commit:

```text
pasweave build C:\tmp\mathlib-fp\src --output build\mathlib-v050 \
  --project-name mathlib-fp --doc-comments=brace \
  --unit-path C:\tmp\mathlib-fp\src --target-os win64 --target-cpu x86_64 \
  --repository-url=https://github.com/ikelaiah/mathlib-fp \
  '--source-link-template=blob/6f3480b7e9494fcd4f72abb0f5c21dd30fde3e42/src/{path}#L{line}'
```

| Check | Result |
|---|---:|
| Source units parsed | 45 of 45 |
| Model symbols | 2,338 |
| Renderable search entries | 2,227 |
| Line-aware source links | 2,227 |
| Search facets | 4 |
| Authoring warnings | 2,370 |
| Errors | 0 |
| Escaping source links | 0 |
| Generated files | 164 |

Every rendered source link retained the configured GitHub repository and
commit prefix. Both complete output trees had SHA-256
`467EC29C5BE937C6A22165E18ADAD9A72FF8C3715C463518F1A779BF4596A826`,
confirming deterministic JSON, Markdown, HTML, search metadata, and source
URLs. The warning count reflects v0.4.0 authoring rules applied to ordinary
brace comments and remains non-fatal under the default local policy. Detailed
navigation and browser evidence is recorded in [navigation and source
traceability](navigation-and-source-traceability.md).

## `v0.2.0` configured-build revalidation

The same tested revision was re-run with settings matching its Windows
x86-64 FPC 3.2.2 build: its `src` directory as both the documented source and
unit path, and explicit `win64`/`x86_64` targets.

```text
pasweave build C:\tmp\pasweave-mathlib-fp\src --output build\v020-mathlib-baseline --project-name mathlib-fp
pasweave build C:\tmp\pasweave-mathlib-fp\src --output build\v020-mathlib-configured --project-name mathlib-fp --unit-path C:\tmp\pasweave-mathlib-fp\src --target-os win64 --target-cpu x86_64
```

| Check | Unconfigured | Configured | Difference |
|---|---:|---:|---:|
| Source units attempted | 45 | 45 | 0 |
| Source units parsed | 45 | 45 | 0 |
| Symbols generated | 2,338 | 2,338 | 0 |
| Warnings | 0 | 0 | 0 |
| Errors | 0 | 0 | 0 |
| Generated files | 163 | 163 | 0 |
| JSON bytes | 1,947,826 | 1,947,826 | 0 |
| Markdown files | 46 | 46 | 0 |
| Markdown bytes | 1,022,548 | 1,022,548 | 0 |
| HTML files | 116 | 116 | 0 |
| HTML bytes | 6,853,533 | 6,853,533 | 0 |

Every corresponding generated file had the same SHA-256 digest. The model
digest in both runs was:

```text
384E59B1D4423CAFB07E5D2FFCF1C3515575522955BC32A4D48F48B4C0EB3F59
```

There are therefore no configured-versus-unconfigured output differences to
explain for this revision. All 45 project units are already selected by the
source-directory input, so the matching unit path adds no unit. The only
target-dependent code found in the source tree is inside an implementation
body, while PasWeave deliberately parses interfaces only. Explicit Windows
x86-64 target symbols consequently select the same documented interface as
the Windows host defaults.

## Tested revision

- Branch: `main`
- Commit: `6f3480b7e9494fcd4f72abb0f5c21dd30fde3e42`
- Commit date: 2026-07-31
- FPC and `fcl-passrc`: 3.2.2

The default and opt-in brace validation commands were:

```text
pasweave build C:\tmp\pasweave-mathlib-fp\src --output build\mathlib-docs --project-name mathlib-fp
pasweave build C:\tmp\pasweave-mathlib-fp\src --output build\mathlib-brace-docs --project-name mathlib-fp --doc-comments=brace
```

## Default `slash` (`///` only) results

| Check | Result |
|---|---:|
| Source units attempted | 45 |
| Source units parsed | 45 |
| Symbols generated | 2,338 |
| Parse warnings | 0 |
| Parse errors | 0 |
| Duplicate stable IDs | 0 |
| Symbols missing a source line | 0 |
| Symbols missing a source column | 0 |
| Unique interface dependencies | 24 |
| JSON size | 1,985,131 bytes |
| Markdown index pages | 1 |
| Markdown unit pages | 45 |
| Markdown size | 1,061,561 bytes |
| Broken Markdown links | 0 |
| Duplicate Markdown anchors | 0 |
| HTML index pages | 1 |
| HTML unit pages | 45 |
| HTML asset files | 70 |
| HTML site size | 6,892,668 bytes |
| Offline search entries | 2,227 |
| Unit diagram nodes | 45 |
| Project-local diagram edges | 97 |
| Units without project-local outgoing edges | 9 |
| Explicit type relationships | 34 |
| Project-resolved type relationships | 7 |
| External/unresolved type relationships | 27 |
| Linked type diagram nodes | 34 |
| Broken HTML links or asset references | 0 |
| Broken search-result targets | 0 |
| Duplicate HTML IDs | 0 |

The generated model contained:

| Kind | Count |
|---|---:|
| unit | 45 |
| class | 61 |
| interface | 7 |
| record | 117 |
| enumeration | 40 |
| type alias | 125 |
| routine | 298 |
| method | 1,048 |
| constructor | 3 |
| destructor | 2 |
| property | 56 |
| field | 502 |
| constant | 34 |

Two independent runs with type relationships produced the same JSON SHA-256:

```text
18B8029D2ACC456D0A807507ADDF3C69442FC34F1C2247552449276DE12985B6
```

The Markdown tree was also deterministic. Its current manifest hash,
calculated from each relative filename and file SHA-256, was:

```text
22E8488E113F2B6F1A5A373FC288480D1A77F69ABABC0F0250C0146CFC872CCD
```

The interaction-enabled build produced 163 files. Two independent runs had
zero per-file hash differences. Their HTML index SHA-256 was:

```text
AC4AB8E4C1281F62513E947C3622E0B3E057B9A8859AA65288D09E884B11D2C2
```

## Source-discovery compatibility

The tested `mathlib-fp/src` tree contains all 45 Pascal units at its top
level. A default build and a build with `--recursive` each parsed all 45 units
and generated the same 2,338 symbols with no warnings or errors. Their JSON
files were byte-identical and retained the established SHA-256:

```text
18B8029D2ACC456D0A807507ADDF3C69442FC34F1C2247552449276DE12985B6
```

This confirms that recursive discovery is opt-in and does not perturb the
existing flat-project result. The dedicated nested-tree fixture supplies the
meaningful recursion and include/exclude coverage that this repository cannot.

The HTML audit covered all page links, stylesheet and script references,
symbol fragments, and search-index URLs. Every PasWeave-authored text file is
UTF-8 without a byte-order mark and uses LF line endings; vendored KaTeX and
Mermaid files are copied byte for byte. The site contains 60 local KaTeX font
files, has no remote page dependency, and all generated and vendored
JavaScript assets pass `node --check`.

## Unit dependency diagram findings

The graph contains all 45 parsed units, 97 project-local interface-dependency
edges, and nine units without a project-local outgoing edge. A further 92
interface-dependency references point outside the documented source set; they
remain visible on unit pages and are deliberately not represented as invented
graph nodes.

A browser run opened the generated index directly through `file://` and
rendered all 45 linked nodes and 97 edges from local assets. The SVG exposed
the generated accessible title and description, repeat loads produced the same
SVG identifier, and the linked text fallback collapsed only after successful
rendering. The static fallback remains expanded in the source document for
disabled or unavailable JavaScript.

## Class and interface relationship findings

The typed AST exposed 34 explicit relationships across 33 source types: 33
inheritance edges and one interface-implementation edge. Seven targets resolve
inside the documented project, including cross-unit inheritance from
`EngineeringLib.DSP.EDSPError` to
`EngineeringLib.Common.ESignalError`. The local implementation edge from
`AlgebraLib.Matrices.TMatrixKit` to `IMatrix` also resolves to the interface
symbol rather than being inferred from declaration text.

The other 27 targets are standard-library ancestors outside the documented
source set: 25 `Exception` references plus `EInvalidArgument` and
`TInterfacedObject`. They remain individual `[unresolved]` nodes. This is
expected scope behavior, not a parse failure or a false positive; PasWeave
does not invent undocumented RTL nodes.

The local browser rendered both architecture diagrams from vendored assets.
The SVGs contained 131 edges in total (97 unit dependencies and 34 type
relationships), and all 34 resolved/source type nodes linked to generated
symbol fragments. The implementation edge rendered dotted, inheritance edges
rendered solid, the accessible relationship title was present, and its text
fallback collapsed only after successful rendering. Inspection found no
relationship false positives: every edge corresponds to an explicit typed AST
ancestor or interface entry.

## Diagram interaction findings

The same direct `file://` browser run exposed two labelled, keyboard-focusable
diagram regions and two independent toolbars only after Mermaid succeeded.
Together the SVGs retained 79 working links: 45 unit nodes and 34 source type
nodes. The relationship diagram reached both its 50% and 300% bounds, disabled
further zoom at each limit, accepted keyboard zoom and panning, moved 100
pixels through an actual mouse drag, and reset to 100% at the origin without
changing the dependency diagram's scale.

The browser also reported the help text and live scale output for both
diagrams. A separate run with JavaScript disabled found both toolbars and both
diagram containers hidden, both linked text fallbacks expanded, and no SVGs.
This verifies the interaction layer does not weaken the non-interactive
fallback contract.

## Default documentation coverage

The model contains zero documented symbols for this revision. This is not a
comment-association or parser error:

- `mathlib-fp/src` contains no `///` documentation lines;
- it contains approximately 1,155 plain brace-comment openings;
- 496 lines use one of PasWeave's initially recognised directive names, but
  those lines occur inside brace comments.

The CLI name `slash` means only PasWeave's consecutive `///` documentation
marker, not ordinary `//` comments. FPC treats `///` as a normal `//` comment;
the documentation meaning belongs to PasWeave. Treating every plain `{ ... }`
block as public API documentation would also capture section labels and
implementation notes, so PasWeave does not do that implicitly.

The Markdown renderer therefore emits 2,227 explicit undocumented warnings:
45 unit-level warnings and 2,182 symbol-level warnings. It omits 111 private
or strict-private symbols from the API pages; those symbols remain available
in the JSON model.

Projects can now either:

1. opt into brace-comment documentation with `--doc-comments=brace`; or
2. migrate selected public API comments in `mathlib-fp` to `///`.

## Opt-in `brace` audit

The brace-mode run parsed the same 45 units and generated the same 2,338
symbols with no warnings or errors. It associated brace documentation with 615
model symbols. Of those, 570 are renderable API symbols across 25 units and 45
are private or nested beneath private declarations. The generated index reports
570 documented symbols out of 2,227 renderable symbols, or 25.6% coverage.

The useful extraction is substantial. It includes detailed matrix, finance,
statistics, combinatorics, geometry, and probability API prose as well as
short descriptions for types and constants. Existing supported tags were
extracted into 496 structured directives on 197 symbols:

| Directive | Count |
|---|---:|
| `@param` | 312 |
| `@returns` | 184 |

Another 200 symbols retain project-specific tags such as `@description`,
`@usage`, `@warning`, and `@example` in Markdown because those names are not
currently part of PasWeave's structured-directive contract. No compiler
directive was captured as documentation.

Two current brace-mode runs produced 163 files each with no per-file hash
differences. The HTML index SHA-256 was:

```text
C7FFAA3D3B0C023374F7C6E7C4F4A09802ADE8EFFCEDC045AE84229E3E1801E1
```

Their JSON SHA-256 was:

```text
B8B5B20A84412C2741392CBE0A91C3B2B962D4481BBF3E3CFAE606E898B3DB93
```

The brace JSON is 2,423,124 bytes. The documentation dialect changes only
documentation fields; both modes contain the same 34 typed relationships.

### Mathematical-delimiter findings

The first HTML pass marked 23 apparent inline expressions, all in
`FinanceLib.Interest` examples. Inspection showed that every one was a false
positive formed by two currency amounts, such as `$10,000 and returned
$12,500`. KaTeX is permissive enough to render this prose as TeX rather than
rejecting it, so error fallback alone could not protect the examples.

PasWeave now applies conservative inline-dollar boundaries: a closing dollar
followed immediately by a digit cannot end an expression, and delimiter-adjacent
whitespace is rejected. The repeated 45-unit brace-mode run contains zero math
markers, correctly reflecting that this revision has currency examples but no
delimited formulas. Dedicated fixtures still cover valid and invalid inline
and display mathematics, including a valid numeric-leading expression.

### False-positive findings

Ordinary brace comments do not carry enough syntax to distinguish prose for a
declaration from a section heading. Manual and pattern-assisted review found
nine unambiguous standalone dashed section labels attached to the first method
in their section, for example `--- Basic Filtering ---` on
`TSignalKit.MovingAverage` and `---- Inverse trig ----` on
`TTrigKit.ArcSin`. A broader audit identified 23 additional short
category-like comments, including `Length conversions` and `Unit compatibility
checking`; some are useful summaries, so they are reported as candidates
rather than definite errors.

The first audit also exposed trailing field comments drifting onto the next
field. PasWeave now rejects a block group whose earliest comment does not start
on an otherwise blank source line, and the fixture suite covers that case.
After the fix, inline record-field notes are not counted as documentation. No
obvious commented-out declaration was attached in this `mathlib-fp` revision,
although a dedicated fixture records that this remains an unavoidable risk
when ordinary block comments are enabled.

The real-world parser, model conversion, source positions, symbol IDs, partial
failure architecture, deterministic outputs, comment association, structured
directive extraction, linked pages, stable anchors, offline search, and
public/private filtering are therefore validated. Brace mode is useful for
this project, but its reported coverage should be interpreted with the
section-label caveat above.
