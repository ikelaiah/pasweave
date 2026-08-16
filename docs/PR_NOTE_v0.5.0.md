# feat(navigation): add source traceability and filtered search for v0.5.0

## Summary

This PR completes the implementation and local-validation work for the
`v0.5.0` roadmap milestone. Readers can move from project overview to API
symbols, related types, and exact repository source lines across small and
large generated documentation sets.

The existing unit routes, overload-aware symbol anchors, offline-output
contract, direct-file input, and default `///` workflow remain intact. No
`v0.6.0` incremental-build work is included.

## What changed

- Added paired `--repository-url` and `--source-link-template` options.
- Added renderer-neutral source-link configuration to the project model and
  additive `repositoryUrl` and `sourceLinkTemplate` schema-v1 JSON fields.
- Added normalized, UTF-8-encoded, declaration-line source links to Markdown
  and HTML unit and symbol locations.
- Rejected unsafe repository bases, templates, and model paths, including
  absolute URLs, credentials, queries, fragments, unknown placeholders,
  literal traversal, percent-encoded traversal, and host-path leakage.
- Centralized resolved symbol-link construction for `@see`, parent, and type
  relationship targets; unresolved or external targets remain plain code.
- Added per-symbol inheritance and implementation links in HTML and Markdown.
- Added offline search filters for unit, symbol kind, visibility, and
  documentation status without introducing a runtime dependency.
- Added keyboard result navigation, polite result announcements, explicit
  empty states, visible focus, and a phone-width layout.
- Added a GitHub Pages workflow that rebuilds the scientific example from
  committed sources, validates its contract, enables Pages when necessary,
  deploys it, and smoke-checks the public result.
- Updated version metadata, examples and golden output, README, roadmap,
  changelog, renderer and release guides, validation evidence, ADR-0002, and
  the v0.5.0 release note.

## Design and safety notes

- Source links use one validated repository-relative template containing
  exactly one `{path}` and one fragment-scoped `{line}` placeholder.
- Repository and template paths reject both literal and encoded path
  normalization that could escape the configured repository root.
- Link identities come from the completed parser-independent model; renderers
  do not guess ambiguous or external targets.
- Search remains a deterministic `search-index.js` assignment that works from
  `file://` and requires no server or network connection.
- GitHub Pages pull-request runs build and validate the generated site without
  configuring or publishing Pages. Trusted `main` and manual runs can deploy.

See [ADR-0002](docs/decisions/0002-repository-relative-source-links.md) and
[navigation and source traceability](docs/navigation-and-source-traceability.md)
for the detailed contracts and alternatives.

## Compatibility

- Generated unit routes remain `units/<UnitName>.html` and
  `units/<UnitName>.md`.
- All checked stable symbol fragments match the v0.4.0 baseline.
- Omitting both source-link options retains plain source locations.
- Direct file and directory inputs and the default `///` documentation mode
  continue to work end to end.
- JSON remains schema version 1; the two source-link configuration fields are
  additive.
- HTML remains self-contained and offline, including search, KaTeX, Mermaid,
  styles, fonts, and licenses.

## Validation

- [x] Complete automated suite passes with Free Pascal 3.2.2.
- [x] Production CLI builds and reports `PasWeave 0.5.0`.
- [x] Portable Windows build, isolated scientific-example smoke test, embedded
      asset comparison, and checksum generation pass.
- [x] Checked-in Markdown, HTML, stylesheet, application-script, and search
      golden output matches the current renderers.
- [x] v0.4.0 unit routes and 36 checked symbol anchors remain unchanged.
- [x] Browser runtime checks cover query and facet filtering, Arrow-key focus,
      empty results, two Mermaid diagrams, 33 KaTeX-rendered elements, zero
      JavaScript errors, and a 320 CSS-pixel layout.
- [x] The nested three-unit Lazarus fixture produces six symbols and six
      source links with zero warnings, errors, or escaping URLs.
- [x] Two runs of pinned 45-unit `mathlib-fp` produce 2,338 symbols, 2,227
      searchable source links, zero errors or escaping URLs, and identical
      output-tree SHA-256
      `467EC29C5BE937C6A22165E18ADAD9A72FF8C3715C463518F1A779BF4596A826`.
- [x] The Pages workflow parses as YAML and its generated-site checks pass
      locally against the scientific example.

## Known limits

- Source links require both CLI options; project-file configuration is planned
  for v0.7.0.
- The v0.5.0 template contract supports HTTP(S), a relative path, and one line
  fragment. Query-based repository viewers are intentionally unsupported.
- Type resolution remains limited to the documented project and conservative
  dependency scope; ambiguous and external targets remain unresolved.
- The Pages workflow must exist on the default branch before it can be
  manually dispatched for another branch.

## Merge and release checklist

- [x] `PasWeaveVersion`, its regression assertion, portable-build default, and
      README badge are set to `0.5.0`.
- [x] `CHANGELOG.md`, `RELEASE_NOTE_v0.5.0.md`, roadmap status, detailed docs,
      examples, and golden output are updated.
- [x] Local tests, production build, portable release build, browser checks,
      nested-project validation, and `mathlib-fp` determinism checks pass.
- [x] Push `release/v0.5.0` and open the pull request against `main`.
- [x] PR checks, including the Pages generated-site build gate, pass.
- [x] Merge the reviewed PR into `main`.
- [x] Confirm the Pages deployment job and deployed-site smoke test pass at
      `https://ikelaiah.github.io/pasweave/`.
- [x] Confirm the post-merge Windows build on `main` passes.
- [x] Tag the verified merge commit as `v0.5.0` and push the tag.
- [x] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` with the v0.5.0 release note.
