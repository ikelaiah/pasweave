# PasWeave v0.3.0

PasWeave v0.3.0 adds direct Lazarus project and package inputs. Common
multi-package builds can now be documented from their committed `.lpi`/`.lpk`
configuration without duplicating source paths, defines, include paths, or
target selection on the command line.

Highlights:

- reads `.lpi` projects and `.lpk` packages without starting Lazarus;
- selects named/default Lazarus build modes and imports target settings,
  search paths, defines, and Pascal source units;
- resolves referenced local packages transitively with deterministic ordering;
- gives explicit CLI compiler options precedence over project/package values;
- rejects missing, ambiguous, malformed, macro-unsupported, and cyclic package
  configuration before a partial build can be produced;
- prunes generated, vendor, example, and test trees during automatic package
  discovery, with repeatable `--package-path` opt-in roots; and
- preserves direct file/directory inputs and the existing renderer/model
  contracts.

See [the Lazarus project and package guide](docs/lazarus-projects.md) for the
supported XML subset, precedence rules, diagnostics, and limitations.

Validation includes the complete FPC 3.2.2 fixture suite, a checked-in
three-unit/two-package Lazarus project fixture, the installed Lazarus
`charactermap_demo.lpi` project with its local package graph, CLI generation
of JSON/Markdown/HTML, and direct-input compatibility tests.
