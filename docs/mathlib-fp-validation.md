# `mathlib-fp` real-world validation

PasWeave's first substantial external test is
[`ikelaiah/mathlib-fp`](https://github.com/ikelaiah/mathlib-fp), as planned in
the project brief.

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

## Default `slash` results

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

The default intentionally recognises only consecutive `///` comments. Treating
every plain `{ ... }` block as public API documentation would also capture
section labels and implementation notes, so PasWeave does not do that
implicitly.

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
