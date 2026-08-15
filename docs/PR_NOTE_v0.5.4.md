# fix(discovery): align index totals and coverage with the symbol index for v0.5.4

## Summary

This PR fixes a count inconsistency on the project index: the **Public API
symbols** card counted unit declarations, while the A–Z symbol index
deliberately omits them, so the cards and the index disagreed. The totals and
coverage are now based on the same renderable non-unit population, and the
misleading **Parsed symbols** label becomes **Parsed declarations**.

## What changed

- Renamed the project-index **Parsed symbols** card to **Parsed declarations**;
  its value still counts every model declaration (units and private symbols
  included).
- **Public API symbols** now equals `TotalIndexedSymbolCount`, matching the
  A–Z symbol index entries exactly (units excluded).
- Documentation coverage and the units-section "X of Y API symbols documented"
  line use `TotalDocumentedIndexedSymbolCount` / `TotalIndexedSymbolCount`.
- Per-unit **API symbols / Documented** rows in HTML and Markdown now use the
  indexed per-unit counts, so the rows sum to the project totals.
- The Markdown index's "Generated from N units and M symbols" line now says
  "declarations", and its documented-API-symbols total matches the HTML.
- Version metadata, portable-build default, README badge, changelog, roadmap
  status, release note, example READMEs, workflow/portable-smoke assertions,
  and both examples' regenerated goldens were updated to v0.5.4.

## Design and safety notes

- The A–Z symbol index is the single source of truth for the "public API
  symbols" population (`IsIndexedAPIKind` in `PasWeave.Render.Support`), so
  the index, the stats cards, the coverage, and the per-unit rows can never
  drift apart again.
- The model-level CI coverage metric behind `--min-documentation-coverage`
  (`PW411`) is intentionally unchanged; it still counts every renderable
  symbol, preserving the documented CI meaning. Only the rendered index
  presentation changed.
- Units remain excluded from "public API symbols" because units have their own
  navigation and are not normal API symbols; the separate **Units** card keeps
  that count visible.

See [the HTML renderer guide](html-renderer.md) and
[navigation and source traceability](navigation-and-source-traceability.md)
for the surrounding discovery and theme behavior.

## Compatibility

- `symbols.html`, `units/<UnitName>.html`, stable symbol anchors, category
  deep links, the search-index schema, reader themes, and branding options are
  unchanged.
- Direct file and directory inputs and default `///` documentation mode pass
  end to end.
- Example showcases now report 8 of 8 (documented) and 28 of 28 (scientific)
  documented public API symbols.

## Validation

- [x] Complete automated suite passes with Free Pascal 3.2.2.
- [x] Production CLI builds and reports `PasWeave 0.5.4`.
- [x] Focused tests pin the new card labels and confirm the public total and
      coverage population equal the A–Z index population.
- [x] Documented and scientific example goldens (HTML and Markdown) are
      regenerated and match.
- [x] No `v0.6.0+` implementation or preparatory contract is introduced.

## Merge and release checklist

- [x] `PasWeaveVersion`, its regression assertion, portable-build default, and
      README badge are set to `0.5.4`.
- [x] `CHANGELOG.md`, `RELEASE_NOTE_v0.5.4.md`, roadmap status, detailed docs,
      example goldens, workflow/portable-smoke assertions, and version
      regression test are updated.
- [ ] Push `release/v0.5.4` and open the pull request against `main`.
- [ ] Confirm PR checks pass.
- [ ] Merge the reviewed PR into `main`.
- [ ] Confirm the Pages deployment and deployed-site smoke test pass at
      `https://ikelaiah.github.io/pasweave/`.
- [ ] Confirm the post-merge Windows build on `main` passes.
- [ ] Tag the verified merge commit as `v0.5.4` and push the tag.
- [ ] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` with the v0.5.4 release note.
