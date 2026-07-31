# `mathlib-fp` real-world validation

PasWeave's first substantial external test is
[`ikelaiah/mathlib-fp`](https://github.com/ikelaiah/mathlib-fp), as planned in
the project brief.

## Tested revision

- Branch: `main`
- Commit: `6f3480b7e9494fcd4f72abb0f5c21dd30fde3e42`
- Commit date: 2026-07-31
- FPC and `fcl-passrc`: 3.2.2

The validation command was:

```text
pasweave build C:\tmp\pasweave-mathlib-fp\src --output build\mathlib-docs --project-name mathlib-fp
```

## Results

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
| JSON size | 1,868,197 bytes |
| Markdown index pages | 1 |
| Markdown unit pages | 45 |
| Markdown size | 1,061,561 bytes |
| Broken Markdown links | 0 |
| Duplicate Markdown anchors | 0 |
| HTML index pages | 1 |
| HTML unit pages | 45 |
| HTML asset files | 3 |
| HTML site size | 2,888,844 bytes |
| Offline search entries | 2,227 |
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

Two independent runs produced the same JSON SHA-256:

```text
C76154919F7CD8D92E4F9D604AD87334BE983907845F8A2617C10859B32CE655
```

The Markdown tree was also deterministic. Its manifest hash, calculated from
each relative filename and file SHA-256, was:

```text
3A4EEB5419332F50B70EB52D7C4E63652F10A843D61DB7BB4E216F2F78D21162
```

The static HTML tree was deterministic under the same manifest-hash method:

```text
BDB77DAD0F2DD25662130A2697067D0CF6C783FB5B72426B3E14364035C64036
```

The HTML audit covered all page links, stylesheet and script references,
symbol fragments, and search-index URLs. Every generated file is UTF-8 without
a byte-order mark and uses LF line endings. Both JavaScript assets pass
`node --check`.

## Documentation coverage finding

The model contains zero documented symbols for this revision. This is not a
comment-association or parser error:

- `mathlib-fp/src` contains no `///` documentation lines;
- it contains approximately 1,155 plain brace-comment openings;
- 496 lines use one of PasWeave's initially recognised directive names, but
  those lines occur inside brace comments.

The current milestone intentionally recognises only consecutive `///` comments.
Treating every plain `{ ... }` block as public API documentation would also
capture section labels and implementation notes, so PasWeave does not do that
implicitly.

The Markdown renderer therefore emits 2,227 explicit undocumented warnings:
45 unit-level warnings and 2,182 symbol-level warnings. It omits 111 private
or strict-private symbols from the API pages; those symbols remain available
in the JSON model.

A later compatibility decision can either:

1. add an explicit, opt-in brace-comment documentation dialect with clear
   association rules; or
2. migrate selected public API comments in `mathlib-fp` to `///`.

The real-world parser, model conversion, source positions, symbol IDs, partial
failure architecture, deterministic JSON, linked Markdown pages, stable
anchors, searchable static HTML, offline asset paths, and public/private
filtering are validated. Documentation extraction from `mathlib-fp` remains
unsupported until that syntax decision is made deliberately.
