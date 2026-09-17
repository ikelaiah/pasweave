# PasWeave v0.2.0: compiler-aware parsing

Suggested PR title:

```text
feat(parser): add compiler-aware parsing for v0.2.0
```

## Summary

This PR completes the active `v0.2.0` roadmap milestone. PasWeave can now
parse the same conditional interface as a configured Free Pascal build instead
of silently relying on the documentation host's defaults.

No `v0.3.0` or later roadmap work is included.

## What changed

- Added repeatable `--unit-path`, `--include-path`, and `--define` options.
- Added explicit, normalized `--target-os` and `--target-cpu` options.
- Defined deterministic precedence for defaults and repeated command-line
  settings.
- Added transitive project-unit and nested-include resolution through
  configured paths, with first-match search-path ordering.
- Kept `fcl-passrc` types behind the parser adapter and out of the public
  model.
- Added stable diagnostics for invalid settings, missing paths, and missing or
  unreadable includes.
- Added focused fixtures for conditional declarations, target selection,
  nested and missing includes, competing search paths, and transitive units.
- Updated CLI help, README guidance, detailed documentation, roadmap status,
  changelog, version metadata, and release notes.

## Compatibility

- Supplying no compiler settings preserves the previous host-target behavior
  and parser arguments.
- All 77 generated documented-API files matched the pre-change baseline
  byte-for-byte by SHA-256 when no new settings were supplied.
- Direct file and directory inputs and the default `///` documentation flow
  remain supported end to end.
- Generated JSON remains model schema version 1.

## Validation

- [x] Complete automated test suite passes with Free Pascal 3.2.2.
- [x] All checked-in Markdown and HTML golden outputs pass unchanged.
- [x] Portable Windows release build and isolated smoke test pass.
- [x] Configured `mathlib-fp` audit parses all 45 units into 2,338 symbols with
      zero warnings or errors.
- [x] All 163 configured `mathlib-fp` output files match the unconfigured
      baseline byte-for-byte.
- [x] Release metadata reports `0.2.0`.

## Known limits

- Lazarus `.lpi` and `.lpk` files are not interpreted in this release; their
  compiler values must be supplied manually.
- Unit paths resolve Pascal source files (`.pas` and `.pp`), not compiled
  `.ppu` files.
- Target OS and CPU values are validated independently; PasWeave does not
  claim that every possible pair is an FPC-supported backend combination.

## Release checklist

- [x] `PasWeaveVersion`, its regression assertion, and README version badge
      are set to `0.2.0`.
- [x] `CHANGELOG.md` contains the `0.2.0` entry.
- [x] `RELEASE_NOTE_v0.2.0.md` is ready for the GitHub release description.
- [ ] PR checks pass.
- [ ] Merge this PR into `main`.
- [ ] The post-merge Windows build on `main` passes.
- [ ] Tag the verified merge commit as `v0.2.0` and push the tag.
- [ ] Confirm the tag workflow publishes `pasweave.exe` and
      `pasweave.exe.sha256` to the GitHub release.
