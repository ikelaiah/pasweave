# feat(incremental): add safe incremental builds for v0.6.0

## Summary

This PR adds safe incremental builds. Repeated builds detect unchanged inputs
through a content-addressed fingerprint and skip parse and render work, while a
deterministic `manifest.json` records every generated page and asset so stale
outputs can be removed only when PasWeave proves it created them. Interrupted
builds are recovered on the next run, `--clean` forces a full rebuild, and
clean and incremental results are byte-for-byte identical.

## What changed

- New `src/incremental/PasWeave.Hashing.pas`: a self-contained SHA-256
  implementation with streaming file hashing.
- New `src/incremental/PasWeave.Incremental.pas`: manifest model and JSON,
  input-fingerprint computation, conservative input-file enumeration, atomic
  output writes with an in-memory output ledger, stale-output removal, and
  timing/heap helpers.
- `src/parser/PasWeave.Parser.pas`: exposes discovery `IsExcluded`/`IsIncluded`
  helpers and the include/exclude pattern lists for fingerprint enumeration.
- `src/render/PasWeave.Render.HTML.Assets.pas`: exposes the KaTeX/Mermaid asset
  directory finders and a `ThirdPartyAssetFingerprint`, and routes asset copies
  through the shared atomic write path.
- `src/render/PasWeave.Render.HTML.pas`, `PasWeave.Render.Markdown.pas`, and
  `PasWeave.Model.JSON.pas`: write all outputs atomically through the shared
  path that also feeds the manifest.
- `src/cli/PasWeave.CLI.pas`: computes the fingerprint before parsing, skips
  unchanged builds (`[up-to-date]`), honors a new `--clean` flag, writes
  `manifest.json`, reconciles stale outputs, warns on a corrupted manifest, and
  reports `--verbose` elapsed time and peak heap.
- New `tests/PasWeave.IncrementalTests.pas`, registered in the test harness:
  SHA-256 vectors, fingerprint determinism and invalidation, manifest
  determinism and interrupted-build detection, stale removal with unowned-file
  preservation, and clean-versus-incremental byte parity.
- Bumped version metadata, portable-build default, README badge, and changelog
  to v0.6.0.

See [safe incremental builds](incremental-builds.md) and
[generated output](generated-output.md) for the manifest contract, cache
invalidation, and clean-build behavior.

## Compatibility

- Incremental builds are additive: generated pages, JSON, Markdown, and assets
  are byte-for-byte unchanged; the only new output is `manifest.json`.
- Direct file and directory inputs, Lazarus inputs, and the default `///`
  workflow behave as before.
- No generated route, anchor, schema, theme, or branding contract changed.

## Validation

- [x] Complete automated suite passes with Free Pascal 3.2.2.
- [x] Production CLI builds and reports `PasWeave 0.6.0`.
- [x] Two independent clean builds produce identical trees.
- [x] An unchanged second run reports `[up-to-date]`; a changed source or option
      rebuilds.
- [x] Corrupted `manifest.json` is recoverable (warning plus clean rebuild).
- [x] No `v0.7.0+` implementation or preparatory contract is introduced.

## Merge and release checklist

- [x] `PasWeaveVersion`, its regression assertion, portable-build default, and
      README badge are set to `0.6.0`.
- [x] `CHANGELOG.md`, `RELEASE_NOTE_v0.6.0.md`, detailed docs, and version
      regression test are updated.
- [ ] Push `feature/v0.6.0` and open the pull request against `main`.
- [ ] Confirm PR checks pass.
- [ ] Merge the reviewed PR into `main`.
- [ ] Confirm the Pages deployment and deployed-site smoke test pass at
      `https://ikelaiah.github.io/pasweave/`.
- [ ] Confirm the post-merge Windows build on `main` passes.
- [ ] Tag the verified merge commit as `v0.6.0` and push the tag.
- [ ] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` with the v0.6.0 release note.
