# PasWeave v0.6.0

PasWeave v0.6.0 adds safe incremental builds. Repeated builds detect unchanged
inputs and skip parse and render work, while a deterministic `manifest.json`
records every generated page and asset so stale outputs are removed only when
PasWeave proves it created them.

Highlights:

- a content-addressed **input fingerprint** hashes the PasWeave version, every
  build-affecting option, every reached source/include/project/package file,
  and the vendored KaTeX and Mermaid assets; an unchanged run reports
  `[up-to-date]` instead of rebuilding;
- a deterministic **`manifest.json`** records each output's path, SHA-256, and
  size, and is the ownership proof for stale-output removal;
- **ownership-based cleanup** deletes only files the prior manifest proves
  PasWeave created, never by extension or wildcard, so files such as
  `.nojekyll` are preserved;
- **atomic output writes** with the manifest written last mean an interrupted
  build is never published as successful and the next run repairs it;
- **`--clean`** forces a full rebuild, and clean and incremental results are
  byte-for-byte identical;
- a corrupted or schema-incompatible manifest is a **recoverable warning** that
  triggers a clean rebuild rather than a fatal error.

Validation includes the complete FPC 3.2.2 suite with new focused incremental
fixtures (SHA-256 vectors, fingerprint determinism and invalidation, manifest
determinism, interrupted-build detection, stale removal with unowned-file
preservation, and clean-versus-incremental byte parity). No runtime dependency
is added and generated output is unchanged except for the new `manifest.json`.

See [safe incremental builds](docs/incremental-builds.md) and
[generated output](docs/generated-output.md) for the manifest contract, cache
invalidation, and baseline methodology.
