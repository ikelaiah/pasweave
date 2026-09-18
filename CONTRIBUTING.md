# Contributing to PasWeave

Thanks for helping improve PasWeave. This guide covers the local workflow,
the quality bar, and the documentation rules every change must follow.

## Prerequisites

- Free Pascal 3.2.2 or newer with the `fcl-passrc` and `fcl-json` packages
- `make` (Git for Windows, MSYS2, or any POSIX `make`)
- A `pwsh` shell for the documentation link check (optional locally; required
  in CI)

## Build and test

Run every command from the repository root; fixture and golden paths are
relative to it.

```text
make            # compile build/bin/pasweave
make test       # compile and run the CLI suite, then the model/renderer suite
make test-cli   # only the compiled-CLI contract suite
make clean      # remove build/
```

`make test` compiles `tests/test_pasweave.pas` and `tests/test_cli.pas`. The
CLI suite starts `build/bin/pasweave` and checks option parsing, exit codes,
incremental messaging, and diagnostics exactly as a user sees them. Set
`PASWEAVE_BIN` to test a different executable.

Verify documentation links before pushing:

```text
pwsh -NoProfile -File scripts/check-docs-links.ps1
```

## Test rules

- Add a focused regression fixture before or with every behavior change.
  Fixtures live under `tests/fixtures/<area>/`.
- Assert behavior, not implementation: prefer public renderer/model output and
  compiled-CLI output over private helpers.
- Name the case under test with `BeginTest('...')` from
  `tests/PasWeave.TestSupport.pas`; a failing `Check` then names the behavior.
- Keep tests deterministic: no timestamps, randomness, locale, or absolute
  paths. Delete scratch output directories before writing and asserting.
- Every suite reports failures without aborting the remaining suites, and the
  process exits non-zero when anything failed.

## Golden output

The checked-in examples under `examples/*/sample-output/` are byte-compared by
the suite. After an intentional output change:

1. Confirm the change is the point of the PR and explain it in the changelog.
2. Regenerate both examples with the commands in their `sample-output/README.md`.
3. Re-run `make test`; unrelated golden output must stay byte-identical.
4. Keep `examples/*/sample-output/README.md` commands synchronized with what
   actually produced the snapshot.

## Adding a CLI option

1. Parse it in `src/cli/PasWeave.CLI.pas` and reject invalid values with
   `EPasWeaveInputError` so the process exits 2.
2. Include the option in the build fingerprint config so incremental builds
   invalidate when it changes.
3. Add the option to the usage text and to the relevant guide in `docs/`.
4. Add a `tests/test_cli.pas` case for the success and failure paths.
5. Record it under `[Unreleased]` in `CHANGELOG.md`.

## Documentation rules

- Update `README.md`, the relevant `docs/` guide, `CHANGELOG.md`, and version
  metadata in the same change. The milestone quality gate in `ROADMAP.md`
  treats documentation as part of the change, not a follow-up.
- Prefer a link to the canonical guide over repeating an explanation that will
  drift. `docs/incremental-builds.md`, for example, is the canonical source for
  cache behavior.
- Use `///` comments for the public API of `src/` units; PasWeave should be
  able to document itself.
- Run the link checker before pushing; CI fails on broken relative links.

## Pull requests

- Keep one logical change per PR with its fixtures and docs. Large mechanical
  moves are acceptable only when behavior is proven unchanged by the suite.
- Describe what changed, why, and how it was verified. `[Unreleased]` changelog
  entries are the source for release notes later.
- Ensure the full suite passes on Windows and Ubuntu; CI runs both.
