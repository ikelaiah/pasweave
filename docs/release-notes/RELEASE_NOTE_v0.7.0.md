# PasWeave v0.7.0

PasWeave v0.7.0 hardens the pre-release pipeline and finishes the
documentation foundations: generated pages cannot smuggle active content,
output replacement cannot destroy the previous build, the compiled CLI contract
is covered by automated tests, and every relative documentation link is
checked in CI.

Highlights:

- **link allow-list** for documentation links. Only `http:`, `https:`,
  `mailto:`, fragment, and relative targets become links; control characters
  are stripped before the scheme check, so `java<TAB>script:` obfuscation can
  no longer produce a clickable active link;
- **atomic output replacement** on Windows through `MoveFileEx`. A failed
  write keeps the previous file, and temporary files are removed on failure;
- **cleaner input errors**: a missing source path exits with code 2 and a
  clear message instead of an internal error, and the CLI accepts
  `--output=DIR`;
- **defense in depth** for model-driven output: theme tokens are validated
  before CSS interpolation, and unit names are sanitized before they become
  output file names, so a programmatic model cannot inject styles or escape
  the output directory;
- **host-independent symbol IDs**: identifiers lowercase ASCII only, so IDs no
  longer depend on the host code page;
- **CLI test suite** (`tests/test_cli.pas`, `make test-cli`) starts the
  compiled executable and asserts exit codes, option parsing, incremental
  parity, manifest recovery, the coverage policy, and source-link
  configuration;
- **shared render helpers** in `PasWeave.Render.Support` replace duplicated
  ordering, renderability, anchor, count, and diagnostic-location logic across
  the HTML, Markdown, and validation layers;
- **documentation overhaul**: version notes moved to
  `docs/release-notes/` and `docs/pr-notes/`, every relative link fixed, a
  grouped index at `docs/README.md`, `CONTRIBUTING.md`, PR and issue templates,
  ADR-0003, and a CI link check.

Validation includes the complete FPC 3.2.2 suite on Windows and Ubuntu: the
CLI suite, the named model/renderer/parser cases, manifest-hardening cases,
`PW407`/`PW409`/`PW410` diagnostics, golden-output byte comparison for both
examples, and the portable Windows release build. No runtime dependency is
added and no feature behavior changes; the output of both examples is
byte-identical to v0.6.0.

See [documentation comments](../documentation-comments.md),
[generated output](../generated-output.md),
[incremental builds](../incremental-builds.md), and
[ADR-0003](../decisions/0003-golden-output-and-cli-tests.md) for the contracts
and verification strategy.
