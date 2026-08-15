# PasWeave roadmap

PasWeave is currently preparing `v0.5.2`. The parser-to-site pipeline works;
the path to `v1.0.0` is about making that pipeline understand real project
builds, improving author feedback and navigation, scaling it safely, and then
freezing the public contracts.

This roadmap defines outcomes and release gates rather than dates. A milestone
is complete only when its behavior is documented, covered by focused fixtures,
and validated against real Free Pascal projects. Work may move between
milestones when a compatibility issue blocks an earlier outcome, but the
`v1.0.0` quality bar does not move with it.

## Product contract through `v1.0.0`

### Documentation comment syntax

PasWeave accepts exactly three source forms for API documentation:

| CLI name | Accepted source form | Default |
|---|---|---:|
| `slash` | Consecutive `///` lines | Yes |
| `brace` | Standalone `{ ... }` blocks | No |
| `paren` | Standalone `(* ... *)` blocks | No |

`--doc-comments=all` is only shorthand for `slash,brace,paren`. The accepted
syntax set is closed through `v1.0.0`; adding more comment dialects is not part
of this roadmap.

The association rules remain deliberately conservative:

- `slash` never includes ordinary `//` comments.
- `brace` and `paren` are opt-in because ordinary Pascal block comments can
  contain implementation notes, section labels, or disabled code.
- Enabled forms may be adjacent and are merged in source order.
- A documentation group must directly precede an interface declaration; a
  blank line, disabled comment form, compiler directive, or other source token
  ends the association.
- `{$...}` and `(*$...*)` compiler directives are never documentation.
- Original delimiters remain available in `rawDocumentation`; normalized body
  text and supported directives remain renderer-independent model data.
- `{** ... }` and `(** ... *)` do not gain separate marker semantics. When
  their enclosing `brace` or `paren` form is enabled, any additional leading
  `*` belongs to the comment body under the same ordinary block-form rules.
- Plain `//`, C-style `/* ... */`, Javadoc/Doxygen `/** ... */`, and comments
  inferred from implementation code are out of scope.

### Architecture and output boundaries

- Target Free Pascal and `{$mode objfpc}` first; accept Delphi-compatible
  syntax only where it works naturally through FPC's parser.
- Reuse `fcl-passrc`; do not create a second Pascal parser.
- Keep FPC parser objects behind the adapter and out of the public model.
- Keep JSON, Markdown, and HTML renderers dependent on the same model.
- Preserve deterministic UTF-8 output, stable ordering, and offline HTML.
- Prefer explicit unresolved data and precise diagnostics over guessed links,
  relationships, prose, or compiler behavior.
- Keep the command-line pipeline usable at the end of every milestone.

## Current baseline — `v0.1.0-alpha.1`

The first alpha established the complete vertical slice:

- interface parsing through `fcl-passrc`, per-file error isolation, and a
  renderer-independent model;
- the three documentation-comment forms and their opt-in association rules;
- structured `@param`, `@returns`, `@raises`, `@deprecated`, `@see`, and
  `@since` extraction;
- deterministic JSON, linked Markdown, and responsive static HTML;
- stable overload-aware anchors, documentation coverage, offline search, and
  light and dark color schemes;
- offline KaTeX mathematics and linked Mermaid dependency and type diagrams
  with accessible controls and text fallbacks;
- deterministic recursive discovery with include and exclude globs;
- portable Windows packaging with embedded assets and a SHA-256 checksum;
- fixture coverage plus validation against all 45 units in `mathlib-fp`.

This baseline remains supported while the compiler and project inputs become
more complete.

## Previous release — `v0.2.0` — Compiler-aware parsing

**Outcome:** PasWeave can parse the same interface a configured Free Pascal
build sees instead of silently inheriting the documentation host's defaults.

Status: completed on 2026-08-02. The behavior, precedence, supported targets,
diagnostics, compatibility evidence, fixtures, and `mathlib-fp` revalidation
are recorded in [compiler-aware parsing](docs/compiler-aware-parsing.md), the
[real-project audit](docs/mathlib-fp-validation.md), and the
[changelog](CHANGELOG.md).

Exit criteria:

- Accept repeatable unit paths, include paths, and conditional defines.
- Represent target OS and CPU explicitly and normalize their values before
  passing them to the parser adapter.
- Define deterministic precedence for defaults and command-line settings.
- Resolve include files and project units through configured paths without
  leaking `fcl-passrc` types into the model.
- Report missing paths, unreadable includes, invalid defines, and unsupported
  target values with stable source-aware diagnostics.
- Cover conditional declarations, nested includes, competing search paths,
  missing inputs, and host-independent target selection in fixtures.
- Re-run `mathlib-fp` with settings matching its supported build and explain
  every difference from the unconfigured baseline.
- Preserve current output byte-for-byte when no new compiler settings are
  supplied.

## `v0.3.0` — Lazarus project and package inputs

**Outcome:** common Lazarus projects can describe their source set and parser
configuration without duplicating it manually on the PasWeave command line.

Status: completed on 2026-08-09. The behavior, precedence, supported XML
inputs, package-isolation rules, diagnostics, fixtures, and multi-package
validation are recorded in [Lazarus project and package inputs](docs/lazarus-projects.md),
the [changelog](CHANGELOG.md), and the v0.3.0 release note.

Exit criteria:

- Read `.lpi` projects and `.lpk` packages without starting Lazarus.
- Select a documented target or build mode and import its source paths,
  include paths, defines, target settings, and main units.
- Define and test precedence between explicit CLI options, project/package
  settings, and PasWeave defaults.
- Discover referenced local packages without traversing generated, vendored,
  example, or test trees unless they are explicitly included.
- Diagnose missing package files, unsupported macros, ambiguous targets, and
  cyclic package references without partial silent configuration.
- Keep direct file and directory inputs fully supported.
- Validate at least one multi-package Lazarus project in addition to focused
  fixtures.

## `v0.4.0` — Authoring feedback and reference integrity

**Outcome:** maintainers can use PasWeave in CI to find documentation defects,
not only to render the documentation that already exists.

Status: completed on 2026-08-10. The diagnostic contract, conservative
reference rules, output-integrity checks, CI thresholds, fixtures, and model
design rationale are recorded in [authoring feedback and reference
integrity](docs/authoring-feedback.md), [ADR-0001](docs/decisions/0001-model-driven-authoring-validation.md),
the [changelog](CHANGELOG.md), and the v0.4.0 release note.

Exit criteria:

- Assign stable diagnostic codes and documented severity levels.
- Detect missing or duplicate `@param` entries against parsed signatures.
- Validate `@returns` against routine kind and flag conflicting directives.
- Resolve project-local `@see` targets with the same conservative scope rules
  used for type relationships; preserve honest unresolved targets.
- Report broken internal links, duplicate anchors, and unreachable generated
  pages as build defects.
- Add configurable documentation-coverage and diagnostic failure thresholds
  suitable for CI while retaining a useful default local workflow.
- Provide a machine-readable diagnostics output based on the existing model
  rather than a renderer-specific scrape.
- Exercise all rules across `///`, `{ ... }`, and `(* ... *)` fixtures without
  broadening the accepted syntax set.

## `v0.5.0` — Navigation and source traceability

**Outcome:** readers can move efficiently from project overview to API symbol,
related type, and original source in both small and large documentation sets.

Status: completed on 2026-08-12. The source-template safety contract,
relationship-link rules, search behavior, accessibility checks, browser
evidence, deployed GitHub Pages showcase, and real-project validation are
recorded in [navigation and source
traceability](docs/navigation-and-source-traceability.md),
[ADR-0002](docs/decisions/0002-repository-relative-source-links.md), the
[changelog](CHANGELOG.md), and the v0.5.0 release note.

Exit criteria:

- Add repository URL templates and line-aware source links with normalized,
  root-relative paths.
- Reject source-link templates that can escape the configured repository URL
  or produce non-deterministic output.
- Add search filters for unit, symbol kind, visibility, and documentation
  status while retaining dependency-free offline search.
- Provide keyboard-accessible search and navigation with visible focus and
  useful empty-result states.
- Link resolved `@see`, dependency, parent, and type-relationship targets
  consistently across HTML and Markdown.
- Keep URLs and symbol anchors stable unless a documented schema migration
  requires a change.
- Validate navigation against the examples, `mathlib-fp`, and at least one
  nested multi-package project.
- Publish a representative PasWeave-generated static HTML showcase from
  committed example sources at `https://ikelaiah.github.io/pasweave/`, and
  validate its navigation, search, mathematics, diagrams, accessibility, and
  stable links as a deployed GitHub Pages site.

## `v0.5.1` — Navigation polish

**Outcome:** readers can move between units and sections without returning to
the API index or using global symbol search.

Status: implemented on 2026-08-15. Focused fixtures, both checked-in examples,
the complete suite, isolated desktop/phone/no-JavaScript browser checks, and
the latest 50-unit `mathlib-fp` audit pass. The Pages workflow now checks the
same contract before upload and after deployment. The milestone remains
pending until that public deployed-site smoke check succeeds after merge.
Evidence is recorded in [navigation and source
traceability](docs/navigation-and-source-traceability.md), the
[HTML renderer guide](docs/html-renderer.md), the
[real-project audit](docs/mathlib-fp-validation.md), the
[changelog](CHANGELOG.md), and the v0.5.1 release note.

Exit criteria:

- Add a keyboard-accessible, searchable unit switcher to every generated unit
  page.
- Allow any unit to be reached from another unit in at most two actions.
- Add an on-page navigator for the symbol categories present in the current
  unit, such as types, constants, variables, routines, classes, and
  interfaces.
- Preserve stable unit URLs and symbol anchors.
- Keep the API index as the canonical browse-all view.
- Retain dependency and relationship diagrams for architectural exploration;
  do not add declarations to a project-wide graph.
- Preserve dependency-free offline behavior and useful no-JavaScript
  navigation.
- Validate keyboard navigation and responsive layout against the examples,
  the latest `mathlib-fp` corpus, and the deployed showcase.

## `v0.5.2` — API discovery and reader themes

**Outcome:** readers can discover an unfamiliar API by browsing as well as by
searching, and can choose a comfortable color scheme without weakening the
offline, accessible generated-site contract.

Status: implemented on 2026-08-15. Focused fixtures, both checked-in examples,
the complete suite, isolated desktop/phone/no-JavaScript browser checks, and
the latest 50-unit `mathlib-fp` audit pass. The Pages workflow now checks the
symbol index, header navigation, and reader-theme contract before upload and
after deployment. The milestone remains pending until that public deployed-site
smoke check succeeds after merge. Evidence is recorded in [navigation and source
traceability](docs/navigation-and-source-traceability.md), the
[HTML renderer guide](docs/html-renderer.md), the
[real-project audit](docs/mathlib-fp-validation.md), the
[changelog](CHANGELOG.md), and the v0.5.2 release note.

Exit criteria:

- Reorder the project index around documentation discovery: project summary,
  Browse API, units, architecture diagrams, then diagnostics and coverage.
  Architectural views remain available without delaying the primary route
  into the reference.
- Add a generated A–Z symbol index with stable links and filters for types,
  routines, members, constants, and variables. It must be derived entirely
  from the documentation model and require no manually maintained index data.
- Make the symbol index an obvious persistent destination from generated HTML
  while retaining the project index as the canonical unit and architecture
  overview and global search as the fastest known-name lookup.
- Add a keyboard-accessible reader theme control with `System`, `Light`, and
  `Dark` choices. `System` remains the default and follows
  `prefers-color-scheme`.
- Remember an explicit reader choice where browser storage is available, but
  fall back safely to `System` when storage is unavailable or rejected,
  including when documentation is opened directly through `file://`.
- Apply the selected scheme before visible page rendering where practical,
  and keep native controls, KaTeX content, Mermaid diagrams, focus states, and
  contrast synchronized with it without introducing a remote dependency.
- Provide restrained build-time project branding through a small validated
  set of theme tokens for colors, typography, and a local project mark. Keep
  reader-facing named-theme galleries, arbitrary script injection, and remote
  theme assets out of scope.
- Preserve useful no-JavaScript browsing: unit and A–Z symbol indexes remain
  ordinary HTML, while the site follows the system color scheme when the
  interactive preference control is unavailable.
- Validate index usability, theme persistence and fallback, responsive layout,
  keyboard operation, contrast, diagrams, and direct-from-disk behavior
  against both examples, the latest `mathlib-fp` corpus, and the deployed
  showcase.

## `v0.6.0` — Safe incremental builds

**Outcome:** repeated builds of large projects are faster without weakening
determinism or deleting files PasWeave does not own.

Exit criteria:

- Record a deterministic manifest of generated pages and assets.
- Skip unchanged parse and render work only when all relevant source,
  configuration, renderer, and asset inputs match.
- Remove stale outputs only when the prior manifest proves PasWeave created
  them; never sweep an output directory by extension or broad wildcard.
- Recover safely from an interrupted build without publishing a mixed old/new
  site as successful output.
- Provide an explicit clean-build path and prove it is byte-for-byte identical
  to a correct incremental result.
- Establish time and peak-memory baselines for the fixture suite,
  `mathlib-fp`, and a larger public Pascal corpus.
- Document cache invalidation and make corrupted cache state a recoverable
  diagnostic rather than a fatal mystery.

## `v0.7.0` — Reproducible project configuration

**Outcome:** a project can commit one reviewable PasWeave configuration and
reproduce a build without restating stable options on every command line.

Exit criteria:

- Add one versioned project configuration format covering stable CLI options.
- Define precedence as explicit CLI values over project configuration over
  documented defaults.
- Resolve every relative path from a documented base and reject parent
  traversal where it would escape that base.
- Support project title, repository/source-link settings, output selection,
  visibility policy, and coverage thresholds.
- Keep arbitrary script injection, remote runtime dependencies, and executable
  renderer plugins out of the `v1.0.0` scope.
- Include the effective normalized configuration in diagnostics or model
  metadata so a build can be reproduced.

## `v0.8.0` — Portability and ecosystem validation

**Outcome:** PasWeave has an evidence-backed support matrix and is tested
outside its original Windows development path.

Exit criteria:

- Build and run the full fixture suite on supported Windows and Linux targets.
- Validate behavior across the supported Free Pascal compiler versions rather
  than assuming compatibility from `3.2.2` alone.
- Define the binary-release target matrix from successful CI evidence and
  publish a checksum for every artifact.
- Keep generated JSON, Markdown, HTML, anchors, and search data identical
  across supported hosts for the same logical inputs.
- Add at least two substantial public Pascal validation projects with
  different comment and project-layout conventions.
- Record parser gaps, unsupported language modes, and platform limitations in
  a maintained compatibility document.
- Verify offline assets and third-party notices in every packaged artifact.

## `v0.9.0` — Contract freeze and release candidates

**Outcome:** the CLI, configuration, model schema, URLs, and renderer behavior
are ready to become supported `v1.0.0` contracts.

Exit criteria:

- Freeze and document command names, option meanings, exit codes, diagnostic
  codes, configuration keys, and precedence rules.
- Publish the JSON schema and define compatibility rules for future additive
  and breaking changes.
- Freeze stable-anchor and generated-URL rules with migration fixtures for any
  pre-release format changes.
- Complete accessibility checks for keyboard navigation, screen-reader names,
  contrast, reduced motion, diagrams, mathematics, and no-JavaScript fallbacks.
- Complete security review of Markdown rendering, URL generation, local asset
  handling, source links, project-file input, and output cleanup.
- Run clean and incremental determinism checks on every validation corpus and
  supported platform.
- Publish at least one release candidate and resolve all known defects that
  could corrupt output, misdocument public API, delete unrelated files, or
  break a frozen contract.
- Finish the installation, quick-start, configuration, CI, migration,
  troubleshooting, and release documentation.

## `v1.0.0` — Stable Free Pascal documentation pipeline

`v1.0.0` is ready when a maintainer can point PasWeave at a supported file,
source tree, Lazarus project, or Lazarus package and receive deterministic,
offline, navigable API documentation with actionable diagnostics and a stable
machine-readable model.

The release must satisfy all earlier milestone gates and additionally:

- support exactly the documented `///`, `{ ... }`, and `(* ... *)` comment
  forms with `///` as the safe default;
- carry no unresolved critical or data-loss defects;
- pass the full fixture, golden-output, package-isolation, browser,
  accessibility, security, and corpus-validation suites;
- publish the support matrix, known limitations, schema compatibility policy,
  and upgrade guidance;
- produce reproducible release artifacts and checksums for every advertised
  binary platform;
- preserve a complete source-build path for platforms without a published
  binary; and
- use semantic versioning for subsequent CLI, configuration, schema, and URL
  contract changes.

## Quality gate for every milestone

No milestone is complete with code alone. Each release must:

- add focused regression fixtures before or with the behavior;
- keep unrelated golden output unchanged;
- update the README, detailed documentation, changelog, and version metadata
  together;
- run the complete automated suite and the relevant real-project audits;
- document new limitations and diagnostics instead of hiding them; and
- leave direct file input and the default `///` workflow working end to end.
