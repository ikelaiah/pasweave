# Implementation Plan: PasWeave v0.4.0 authoring feedback

## Overview

Add a deterministic, model-level authoring-validation pass. It will validate
documentation directives and project-local references after parsing, expose
stable coded diagnostics in both the API model and a dedicated diagnostics
artifact, and let CI fail on coverage or warning-level feedback without making
the default local workflow noisy.

## Architecture decisions

- Keep validation separate from the FPC adapter and renderers. The parser
  populates parsed routine-signature data, then invokes one model-only
  validation pass after type-relationship resolution.
- Store a resolved `@see` symbol ID on the existing directive model. Markdown
  and HTML therefore consume the same conservative resolution result rather
  than independently guessing links.
- Treat authoring-rule findings as warnings by default. Output-integrity
  failures and an explicitly configured coverage threshold are errors; CI can
  promote warnings with `--fail-on=warning`.
- Preserve the existing JSON model schema version and add diagnostic fields
  additively. Emit a separate `diagnostics.json` from those same model lists,
  never by inspecting renderer output.

## Task list

### Phase 1: Validation foundation

- [ ] Add stable diagnostic codes, routine-signature model data, and
  deterministic diagnostics JSON serialization.
- [ ] Add parser-independent authoring validation for parameter, return, and
  conservative project-local `@see` rules.
- [ ] Add focused slash, brace, and paren fixtures plus failing validation
  tests before the implementation.

### Checkpoint: Model validation

- [ ] Focused validation tests pass.
- [ ] Existing parser and renderer tests stay green.

### Phase 2: Build integrity and CI controls

- [ ] Validate rendered-route invariants: duplicate anchors/pages, dangling
  generated links, and route reachability as build defects.
- [ ] Add coverage calculation, `--min-documentation-coverage`, and
  `--fail-on` CLI behavior.
- [ ] Write `diagnostics.json` alongside `api-model.json`.

### Checkpoint: CI behavior

- [ ] The executable reports coded diagnostics and exits according to the
  configured failure severity.
- [ ] HTML and Markdown consume resolved `@see` IDs consistently.

### Phase 3: Release contract

- [ ] Document diagnostic codes, severities, CI usage, and the validation
  design decision.
- [ ] Update README, changelog, roadmap, release note, and version metadata.
- [ ] Run the full suite, build the executable, perform focused CLI smoke
  checks, and review the change across correctness, architecture, security,
  and performance.

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| FPC routine forms are varied | Incorrect `@param` checks | Capture names directly from the parser AST, not declaration text. |
| A guessed `@see` link misleads readers | Incorrect navigation | Resolve only current-unit, qualified, or dependency-unit candidates; ambiguity remains unresolved. |
| New warnings disrupt local use | Poor adoption | Warning diagnostics do not change the default successful exit status. |
| Renderer drift reintroduces broken links | Broken generated navigation | Renderers use the resolved directive ID and validation checks route/anchor invariants. |

## Definition of done

- [ ] Branch is `release/v0.5.0` as requested.
- [ ] v0.4.0 exit criteria are documented and covered across all three accepted
  documentation-comment forms.
- [ ] The full test suite and production build pass.
- [ ] Direct input and default `///` rendering continue to work end to end.
