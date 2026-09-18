# ADR-0003: Byte-identical goldens and a compiled-CLI suite gate every change

## Status
Accepted

## Date
2026-09-17

## Context

PasWeave generates HTML, Markdown, JSON, diagnostics, and a manifest. Three
properties are part of its product contract:

- generated output is deterministic, so checked-in examples and CI diffs can be
  trusted;
- the CLI is the primary interface, so option parsing, exit codes, and
  diagnostics are user-facing behavior, not implementation detail;
- renderers, model, and parser must be safe to refactor without silently
  changing output.

Before this decision, the checked-in examples were compared byte-for-byte by
the fixture suite, but the CLI itself had no automated test: option parsing,
exit codes (`0` success, `1` diagnostics, `2` input error, `3` internal error),
`--fail-on`, the coverage gate, `--clean`, and `[up-to-date]` messaging were
verified only by manual runs and shell greps in CI. Internal helper duplication
across renderers also made it easy for one renderer to drift from another
without a test noticing.

## Decision

1. Checked-in example output is the golden contract. Any PR that touches a
   renderer must leave unrelated golden output byte-identical; an intentional
   output change must regenerate both examples and say why in the changelog.
2. The CLI gets its own suite (`tests/test_cli.pas`) that starts the compiled
   `build/bin/pasweave` and asserts observable behavior: exit codes, messages,
   incremental parity, manifest recovery, and source-link validation. It runs
   in `make test` and in the portable release script against the release
   executable.
3. Shared model-derived helpers (ordering, renderability, anchors, counts,
   diagnostics locations) have exactly one definition in
   `PasWeave.Render.Support`; HTML, Markdown, and validation consume them.
4. A documentation link check (`scripts/check-docs-links.ps1`) runs in CI so
   moved guides cannot leave broken relative links.

## Alternatives Considered

### Unit-test the CLI argument parser in-process
- Pros: fast, no process management.
- Cons: would require exporting parser internals purely for tests and would
  not catch exit-code or stream behavior. Rejected as weaker evidence.

### Snapshot the CLI output with recorded transcripts
- Pros: catches message changes.
- Cons: brittle against paths and environment. Rejected in favor of targeted
  assertions on stable markers.

### Keep per-renderer helper copies
- Pros: no cross-module dependency.
- Cons: the duplicated families had already drifted in subtle ways (encoding,
  cycle handling, invalid-color behavior). Rejected: one definition removes
  the drift class entirely.

## Consequences

- Refactors are safe to review: the golden comparison proves output is
  unchanged, and the moving of helper definitions is mechanical.
- The CLI suite depends on a built executable, so `make test` builds the CLI
  first; `PASWEAVE_BIN` allows testing another binary (used by the portable
  release script).
- Validation depends on `PasWeave.Render.Support` for renderability rules.
  Support only depends on the model and diagnostics, so no parser types leak
  into validation.
- A future renderer split (for example extracting HTML diagram or page code)
  must keep the same public entry points so the golden tests stay valid.
