# PasWeave documentation

This index groups every guide in the repository. Start with the
[README](../README.md) for the product overview and quick start, then pick the
page that matches your task.

## Getting started

| Guide | What it covers |
|---|---|
| [Documentation comments](documentation-comments.md) | `///` and opted-in block comment forms, association rules, and directives |
| [Generated output](generated-output.md) | HTML, Markdown, JSON, diagnostics, directory layout, and exit codes |
| [Building from source](building-from-source.md) | Requirements, direct FPC commands, tests, and release builds |

## Guides

| Guide | What it covers |
|---|---|
| [Source discovery](source-discovery.md) | Recursion, include/exclude globs, precedence, and safety |
| [Compiler-aware parsing](compiler-aware-parsing.md) | Unit/include paths, defines, targets, and precedence |
| [Lazarus projects and packages](lazarus-projects.md) | `.lpi`/`.lpk` inputs, build modes, package graphs, and diagnostics |
| [Authoring feedback](authoring-feedback.md) | Diagnostic codes, coverage rules, and CI thresholds |
| [Navigation and source links](navigation-and-source-traceability.md) | Anchors, routes, symbol index, themes, and repository links |
| [HTML renderer](html-renderer.md) | Offline rendering, search, themes, branding, safety, and diagrams |
| [Incremental builds](incremental-builds.md) | Input fingerprint, `manifest.json`, `--clean`, and stale-output safety |
| [Parser integration](parser-integration.md) | `fcl-passrc` adapter behavior and limits |
| [Real-project validation](mathlib-fp-validation.md) | `mathlib-fp` corpus results and determinism evidence |

## Contributing and releases

| Guide | What it covers |
|---|---|
| [Contributing](../CONTRIBUTING.md) | Local workflow, tests, documentation rules, and review expectations |
| [Release procedure](releasing.md) | Versioning, validation gates, and publishing |
| [Windows CI troubleshooting](windows-ci-troubleshooting.md) | Runner, path, and tooling fixes |

## Architecture decisions

| Record | Decision |
|---|---|
| [ADR-0001](decisions/0001-model-driven-authoring-validation.md) | Validation lives in the model |
| [ADR-0002](decisions/0002-repository-relative-source-links.md) | Repository-relative source links |
| [ADR-0003](decisions/0003-golden-output-and-cli-tests.md) | Byte-identical goldens and a compiled-CLI suite |
| [Decisions index](decisions/README.md) | All architecture decision records |

## Release notes

- [Release notes](release-notes/) — per-release highlights and validation evidence
- [Pull request notes](pr-notes/) — the reviewed change description for each
  milestone PR
