# fix(discovery): rename the symbol browser label to "Symbols Index" for v0.5.3

## Summary

This PR renames the visible label of the generated symbol browser from
**Symbols A–Z** to the more professional **Symbols Index** in the page header,
the `symbols.html` heading and breadcrumb, and the project-index Browse API
card. It is a cosmetic follow-up to the v0.5.2 milestone; the `symbols.html`
route, stable symbol anchors, category filters, deep links, reader themes, and
branding tokens are unchanged.

## What changed

- Header nav: `Symbols A&#8211;Z` → `Symbols Index` on every generated page.
- `symbols.html`: `<h1>` and breadcrumb now read **Symbols Index**.
- Browse API card: the card title reads **Symbols Index**; its descriptive
  text retains "A–Z" ("Every public API symbol A–Z across N units,
  filterable by kind.").
- The page description and documentation keep "A–Z symbol index" where it
  describes behavior rather than serving as a label.
- Version metadata, portable-build default, README badge, changelog, roadmap
  status, release note, and example goldens were updated to v0.5.3.

## Design and safety notes

- Only visible label text changed; no route, anchor, schema, or script
  selector changed.
- The label is validated by focused fixtures and pinned in both examples'
  regenerated golden output.

See [the HTML renderer guide](html-renderer.md) and
[navigation and source traceability](navigation-and-source-traceability.md)
for the surrounding discovery and theme behavior.

## Compatibility

- `symbols.html`, `units/<UnitName>.html`, stable symbol anchors, category
  deep links, the search-index schema, reader themes, and branding options
  are all unchanged.
- Direct file and directory inputs and default `///` documentation mode pass
  end to end.

## Validation

- [x] Complete automated suite passes with Free Pascal 3.2.2.
- [x] Production CLI builds and reports `PasWeave 0.5.3`.
- [x] Focused tests pin the new **Symbols Index** label in the header and page
      heading.
- [x] Documented and scientific example goldens are regenerated and match.
- [x] No `v0.6.0+` implementation or preparatory contract is introduced.

## Merge and release checklist

- [x] `PasWeaveVersion`, its regression assertion, portable-build default, and
      README badge are set to `0.5.3`.
- [x] `CHANGELOG.md`, `RELEASE_NOTE_v0.5.3.md`, roadmap status, detailed docs,
      example goldens, and version regression test are updated.
- [ ] Push `release/v0.5.3` and open the pull request against `main`.
- [ ] Confirm PR checks pass.
- [ ] Merge the reviewed PR into `main`.
- [ ] Confirm the Pages deployment and deployed-site smoke test pass at
      `https://ikelaiah.github.io/pasweave/`.
- [ ] Confirm the post-merge Windows build on `main` passes.
- [ ] Tag the verified merge commit as `v0.5.3` and push the tag.
- [ ] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` with the v0.5.3 release note.
