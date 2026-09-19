# PasWeave v0.8.0

PasWeave v0.8.0 adds reproducible project configuration. Commit one
`pasweave.json`, build with `--config=pasweave.json`, and the effective
configuration is recorded with the output so the build can be reproduced from
the same commit and file.

Highlights:

- **versioned configuration format**: `pasweave.json`, `"version": 1`, strictly
  declarative. It covers source and output selection, comment styles,
  visibility, project title and branding, repository/source-link settings,
  discovery globs, compiler paths/defines/targets/build mode/package paths, and
  coverage thresholds;
- **documented precedence**: defaults, then the configuration file, then
  explicit command-line values. Any CLI instance of a repeatable option
  replaces the configured list; `--no-recursive` and
  `--visibility=public|all` override configured booleans and policies;
- **safe paths**: every path in the file resolves from the configuration
  directory; absolute paths and parent traversal that escapes that directory
  are rejected, so a committed configuration stays portable and cannot touch
  files outside the project;
- **strict validation**: unknown keys, wrong types, unsupported versions,
  invalid colors/fonts/targets/defines/coverage values, and invalid globs are
  rejected with key-named input errors and exit code 2;
- **visibility policy**: `public` (default) documents the public API exactly as
  before; `all` also documents private and strict-private declarations, with
  coverage and the symbol index following the same population;
- **reproducibility**: `api-model.json` records `configurationSource` and the
  effective normalized `configuration` text, and the configuration file is part
  of the incremental build fingerprint, so editing it invalidates cached
  output;
- **out of scope by design**: no scripts, plugins, remote resources, or
  environment expansion in the configuration.

Validation includes the complete FPC 3.2.2 suite: 24 configuration unit cases
(full, minimal, and 22 rejection cases), CLI suite coverage for config-only
builds, precedence, config-relative output, model exposure, and
`visibility=all` rendering, plus byte-identical generated output when no
configuration is used. The portable Windows build runs the same gates.

See the [project configuration guide](../project-configuration.md),
[generated output](../generated-output.md), and
[CHANGELOG.md](../../CHANGELOG.md) for the schema, precedence rules, and
recorded fields.
