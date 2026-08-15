# docs(discovery): refine project-index hero copy for v0.5.5

## Summary

This PR rephrases the project-index hero paragraph from "Browse the API from
the A–Z symbol index, jump to a unit, or search the complete public reference."
to "Browse the API using the A–Z symbol index, explore individual units, or
search the complete public API reference." It is a pure copy change; the
`&#8211;` en-dash entity is preserved in generated HTML.

## What changed

- Updated the canonical hero copy in `src/render/PasWeave.Render.HTML.pas`.
- Added a focused assertion in `tests/PasWeave.SymbolIndexAndThemeTests.pas`
  that verifies the new hero copy (with the entity intact).
- Regenerated both examples' checked-in `sample-output/html/index.html`.
- Updated version metadata, portable-build default, README badge, changelog,
  roadmap status, and the v0.5.5 release note.

## Design and safety notes

- No routes, anchors, schema, themes, branding, or scripts changed; only the
  hero paragraph text.
- The en dash is emitted as `&#8211;` exactly as before, so rendered output is
  identical apart from the wording.

See [the HTML renderer guide](html-renderer.md) and
[navigation and source traceability](navigation-and-source-traceability.md)
for the surrounding discovery and theme behavior.

## Compatibility

- `symbols.html`, `units/<UnitName>.html`, stable anchors, category deep
  links, the search-index schema, reader themes, and branding options are
  unchanged.
- Direct file and directory inputs and default `///` documentation mode pass
  end to end.

## Validation

- [x] Complete automated suite passes with Free Pascal 3.2.2.
- [x] Production CLI builds and reports `PasWeave 0.5.5`.
- [x] Focused test pins the new hero copy.
- [x] Documented and scientific example goldens are regenerated and match.
- [x] No `v0.6.0+` implementation or preparatory contract is introduced.

## Merge and release checklist

- [x] `PasWeaveVersion`, its regression assertion, portable-build default, and
      README badge are set to `0.5.5`.
- [x] `CHANGELOG.md`, `RELEASE_NOTE_v0.5.5.md`, roadmap status, example
      goldens, and version regression test are updated.
- [ ] Push `release/v0.5.5` and open the pull request against `main`.
- [ ] Confirm PR checks pass.
- [ ] Merge the reviewed PR into `main`.
- [ ] Confirm the Pages deployment and deployed-site smoke test pass at
      `https://ikelaiah.github.io/pasweave/`.
- [ ] Confirm the post-merge Windows build on `main` passes.
- [ ] Tag the verified merge commit as `v0.5.5` and push the tag.
- [ ] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` with the v0.5.5 release note.
