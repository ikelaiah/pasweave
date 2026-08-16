# Safe incremental builds

PasWeave detects unchanged inputs and skips redundant parse and render work so
repeated builds of large projects finish quickly, without weakening determinism
or deleting files it does not own. Incremental behavior is on by default; a
matching run reports `[up-to-date]` and exits with the same status as the
build that produced the output.

## How a build is decided

Before parsing anything, PasWeave computes an **input fingerprint** — a
SHA-256 over a canonical serialization of every input that can change the
output:

- the PasWeave version;
- every build-affecting option: source path, project name, comment styles,
  discovery globs and recursion, compiler paths/defines/targets, Lazarus build
  mode and package paths, repository and source-link settings, branding tokens,
  coverage threshold, failure severity, and the output directory;
- the content of every relevant source file (`.pas`, `.pp`, `.inc`, `.lpi`,
  and `.lpk`) reached through discovery, the configured unit and include paths,
  and, for single-file inputs, the file's own directory;
- a SHA-256 of the vendored KaTeX and Mermaid assets.

If a `manifest.json` from a previous build records the same fingerprint and
every listed output file still exists with the recorded size, PasWeave skips
parsing and rendering entirely. Content is hashed, so touching a file without
changing its bytes does not cause a rebuild, while any byte change does.

## The manifest

`manifest.json` is written at the output root beside `api-model.json`. It is
deterministic: the file list is sorted by path, each entry records the
output-relative path, its SHA-256, and its size, and no timestamps or
machine-specific data are stored. It records:

```text
schemaVersion, pasweaveVersion, inputFingerprint,
unitCount, symbolCount, attemptedCount, warningCount, errorCount,
outputs: [ { path, sha256, size }, ... ]
```

The manifest is also the source of truth for ownership. PasWeave only ever
deletes files that a previous manifest proves it created.

## Stale output removal

When a rebuild produces fewer files than the previous build (for example, a
unit was removed from the source tree), PasWeave removes the superseded pages
and assets listed in the prior manifest but absent from the new one. It never
sweeps an output directory by extension or wildcard, so files the user placed
there — such as a Pages `CNAME` or `.nojekyll` — are preserved.

## Interrupted builds and recovery

Every output file is written to a temporary name and atomically renamed into
place, and `manifest.json` is written only after every other file is committed.
A crash mid-build therefore leaves the previous manifest in place rather than a
mixed old/new site marked as successful. On the next run:

- if inputs changed, PasWeave rebuilds and reconciles stale outputs against the
  old manifest;
- if inputs are unchanged, the existence-and-size check against the manifest
  detects the missing or truncated files and rebuilds instead of skipping.

A manifest that is unreadable, malformed, or uses an unknown schema version is
treated as recoverable state: PasWeave reports a warning and performs a full
clean rebuild instead of failing.

## Clean builds

Pass `--clean` to force a full rebuild that ignores any prior fingerprint
decision. A clean rebuild and an incremental rebuild use the same write path,
so their outputs are byte-for-byte identical; this is asserted by the focused
incremental fixtures and by comparing two independent builds of the same
inputs.

## Cache invalidation

Any change below invalidates the cached result and forces a rebuild:

- a change to any source, include, project, or package file that discovery or
  parsing reaches;
- a change to any CLI option listed above;
- a change to the PasWeave version or to the vendored KaTeX/Mermaid assets;
- deletion, truncation, or corruption of a previously generated output file;
- a corrupted or schema-incompatible `manifest.json`.

## Time and peak-memory baselines

Run a build with `--verbose` to report elapsed wall-clock milliseconds and the
peak FPC-heap usage observed during the build:

```text
elapsed=5203 ms; peak-heap=104288 bytes
```

Baselines are reproducible measurements on the reference development host
(Windows x86-64, Free Pascal 3.2.2, unoptimized debug build):

| Corpus | Build | Elapsed | Peak heap |
|---|---:|---:|---:|
| Fixture suite (`tests/test_pasweave.pas`) | complete run | ~18 s | — |
| `examples/scientific-api` | clean | ~5.2 s | ~104 KB |
| `examples/scientific-api` | up to date | ~0.19 s | — |
| `examples/documented-api` | clean | ~5.1 s | ~51 KB |
| `examples/documented-api` | up to date | ~0.19 s | — |

Peak heap reflects `GetFPCHeapStatus.CurrHeapUsed` sampled after parsing and
after rendering; it is a lower bound that grows with corpus size. Record larger
corpora with the same command:

```text
pasweave build path/to/mathlib-fp --output build/mathlib-docs --recursive --verbose
```

`mathlib-fp` and a larger public Pascal corpus should be measured on the CI
validation host and recorded in the release notes when they are exercised.

## Compatibility

Incremental builds are additive. The generated pages, JSON, Markdown, and
assets are byte-for-byte unchanged from a non-incremental build; the only new
output is `manifest.json`. Direct file input and the default `///` workflow
behave exactly as before.
