# ADR-0001: Keep authoring validation in the documentation model

## Status

Accepted

## Date

2026-08-10

## Context

PasWeave previously extracted structured directives but left each renderer to
attempt its own `@see` resolution. That made CI feedback incomplete and made
the model unable to say whether a visible link was trustworthy. Validation by
scraping generated HTML or Markdown would also couple correctness to a
renderer and duplicate parser knowledge.

## Decision

Capture parameter names and value-return information while the FPC adapter
still has its parser objects, then store only parser-independent data in the
public model. Run directive, reference, coverage, and route validation after
the project model and type relationships are complete. Store resolved `@see`
targets as symbol IDs on directives. Renderers consume those IDs and preserve
an unresolved source reference as plain code.

Diagnostics use stable codes in the same model lists as parser diagnostics.
`api-model.json` includes those lists and `diagnostics.json` serializes them as
a dedicated CI artifact.

## Alternatives considered

### Resolve `@see` independently in each renderer

Rejected because HTML and Markdown can silently disagree and neither result is
available to JSON consumers or CI.

### Parse declarations again from their rendered text

Rejected because it reimplements a subset of Pascal syntax and can diverge
from `fcl-passrc`.

### Validate links by scraping generated files

Rejected because renderer markup is not a semantic contract and this would not
help non-renderer outputs.

## Consequences

- The model gains additive routine-signature and directive-target fields while
  FPC parser classes remain adapter-internal.
- Authoring feedback is deterministic and shared across all outputs.
- Warning-level feedback remains practical during local work and can be
  promoted to a CI failure explicitly.
- URL and anchor validation stays tied to the model's stable route rules.
