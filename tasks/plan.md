# Implementation Plan: PasWeave v0.5.0 navigation and source traceability

## Overview

Add a renderer-neutral source-link contract, complete relationship navigation,
and an accessible filtered offline search experience without changing existing
unit URLs or stable symbol anchors. Publish the scientific example as the
representative GitHub Pages showcase and record validation evidence for the
examples, `mathlib-fp`, and the nested Lazarus fixture.

## Architecture decisions

- Store the normalized repository URL and relative source-link template in the
  project model. Validate them at the CLI boundary, then let both renderers use
  one URL builder over normalized root-relative source paths.
- Accept only deterministic relative templates containing exactly one
  `{path}` and `{line}`. Reject absolute URLs, parent traversal, query strings,
  fragments before the line placeholder, unknown placeholders, and repository
  URLs with query/fragment components.
- Preserve the existing route and anchor functions. Extend shared link helpers
  so `@see`, dependencies, parents, and resolved type relationships all use the
  same model IDs and renderer-specific route rules.
- Keep search dependency-free and offline. Emit explicit unit, kind,
  visibility, and documentation-status metadata, then filter and keyboard-
  navigate the deterministic in-memory index.
- Publish output generated from the committed scientific example through
  GitHub Pages; the workflow regenerates and verifies it before deployment.

## Task list

### Phase 1: Source traceability

- [x] Task 1: Add failing model/CLI tests for accepted and rejected repository
  URL plus source-link templates.
- [x] Task 2: Implement normalized source-link configuration and shared,
  line-aware URL generation for units and symbols.
- [x] Task 3: Render source links consistently in Markdown and HTML and expose
  the additive configuration in JSON.

### Checkpoint: Source links

- [x] Focused tests prove root-relative normalization, line fragments,
  escaping rejection, deterministic output, and unchanged output when source
  links are not configured.
- [x] The full parser/renderer suite remains green.

### Phase 2: Navigation and offline search

- [x] Task 4: Add failing renderer tests for relationship-link parity and
  search metadata/filter controls.
- [x] Task 5: Complete dependency, parent, resolved `@see`, and type-
  relationship links in both Markdown and HTML without changing routes or
  anchors.
- [x] Task 6: Add unit, symbol-kind, visibility, and documentation-status
  filters plus keyboard result navigation, visible focus, live status, and
  useful empty states.

### Checkpoint: Navigation

- [x] Focused tests cover filters, ArrowUp/ArrowDown/Enter/Escape behavior,
  visible focus styles, zero matches, and consistent link targets.
- [x] Search remains a local JavaScript asset and generated files remain
  deterministic UTF-8 with LF endings.

### Phase 3: Showcase, validation, and release contract

- [x] Task 7: Add a GitHub Pages workflow and committed scientific showcase
  generated with repository source links.
- [x] Task 8: Validate examples, the nested multi-package fixture, and
  `mathlib-fp`; record routes, filters, accessibility, math, diagrams, and
  stable-link evidence.
- [x] Task 9: Update README, detailed docs, changelog, roadmap, release note,
  release/version metadata, and sample outputs.
- [x] Task 10: Run the complete suite, production/portable builds where
  available, deterministic regeneration checks, and a five-axis code review.

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Template expansion permits navigation outside the repository URL | Unsafe or misleading source links | Accept a constrained relative grammar and validate both the template and expanded URL. |
| New search controls make keyboard use harder | Accessibility regression | Use native labelled controls, a live result count, roving result focus, and runtime browser checks. |
| Renderer-specific link logic drifts | HTML and Markdown disagree | Resolve identities in the model and centralize route construction in shared helpers. |
| Regenerated examples create noisy unrelated diffs | Review and stability risk | Keep anchors/routes unchanged and compare deterministic snapshots before updating them. |
| GitHub Pages cannot deploy before merge | Milestone evidence is incomplete | Prepare and locally verify the workflow/site; report the exact external merge/deployment step if this branch cannot publish directly. |

## Definition of done

- [x] Branch is `release/v0.5.0`.
- [ ] Every v0.5.0 roadmap exit criterion has code, fixtures, documentation,
  or explicit deployed-site evidence.
- [x] Existing unit URLs and symbol anchors are unchanged.
- [x] Full tests and production build pass, and direct-file/default-`///`
  workflows still work end to end.
