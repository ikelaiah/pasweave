# docs(discovery): correct symbol-index terminology for v0.5.6

## Summary

This PR corrects PasWeave's symbol-index wording so it no longer implies that
symbol names can only begin with A–Z. Symbols beginning with `_`, digits, or
other non-letter characters are valid and are grouped under the `#` section of
the index.

## What changed

- Canonical UI strings in `src/render/PasWeave.Render.HTML.pas`:
  - hero: "Browse the API using the symbol index, explore individual units, or
    search the complete public API reference.";
  - Browse API description: "Browse symbols by name or filter by kind.";
  - Symbols Index card: "Every public API symbol, indexed by name and filterable
    by kind." (unit count removed);
  - symbols page introduction: "Public API symbols indexed by name and grouped
    into navigable sections.";
  - meta description: "Symbol index for {project name}";
  - section-navigation `aria-label`: "Symbol index sections".
- Visible heading and navigation label remain **Symbols Index**; `symbols.html`,
  stable anchors, category links, filters, sorting, and the `#` grouping are
  unchanged.
- Updated focused assertions in `tests/PasWeave.SymbolIndexAndThemeTests.pas`
  for every changed user-facing and accessibility string, and added a test
  proving an underscore-leading symbol appears in the index, is grouped under
  the `#` section, and keeps a working stable link.
- Corrected misleading "A–Z symbol index" phrasing in living docs (README,
  html-renderer, generated-output, navigation, releasing, and both example
  READMEs and sample-output notes), keeping "alphabetical" only where it
  accurately describes unit sorting or the A–Z letter ordering.
- Preserved released history (old release notes, PR notes, completed task
  records, and the roadmap milestone records).
- Regenerated both examples' checked-in HTML outputs and bumped version
  metadata, portable-build default, README badge, and changelog to v0.5.6.

See [the HTML renderer guide](html-renderer.md) and
[navigation and source traceability](navigation-and-source-traceability.md)
for the surrounding discovery and theme behavior.

## Compatibility

- `symbols.html`, `units/<UnitName>.html`, stable anchors, category deep links,
  the search-index schema, reader themes, and branding options are unchanged.
- Direct file and directory inputs and default `///` documentation mode pass
  end to end.

## Validation

- [x] Complete automated suite passes with Free Pascal 3.2.2.
- [x] Production CLI builds and reports `PasWeave 0.5.6`.
- [x] Focused tests pin all revised user-facing and accessibility text.
- [x] Non-letter-symbol coverage proves `#` grouping and stable links.
- [x] Documented and scientific example goldens are regenerated and match.
- [x] No `v0.6.0+` implementation or preparatory contract is introduced.

## Merge and release checklist

- [x] `PasWeaveVersion`, its regression assertion, portable-build default, and
      README badge are set to `0.5.6`.
- [x] `CHANGELOG.md`, `RELEASE_NOTE_v0.5.6.md`, detailed docs, example goldens,
      and version regression test are updated.
- [ ] Push `release/v0.5.6` and open the pull request against `main`.
- [ ] Confirm PR checks pass.
- [ ] Merge the reviewed PR into `main`.
- [ ] Confirm the Pages deployment and deployed-site smoke test pass at
      `https://ikelaiah.github.io/pasweave/`.
- [ ] Confirm the post-merge Windows build on `main` passes.
- [ ] Tag the verified merge commit as `v0.5.6` and push the tag.
- [ ] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` with the v0.5.6 release note.
