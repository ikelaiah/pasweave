# Implementation Plan: PasWeave v0.3.0 Lazarus inputs

## Overview

Add parser-independent support for Lazarus `.lpi` projects and `.lpk`
packages. A project/package input will provide source files, unit/include
paths, conditional defines, target settings, build-mode selection, and local
package dependencies to the existing compiler-aware parser while preserving
direct file and directory input behavior.

## Architecture decisions

- Use FPC's XML DOM reader (`DOM`/`XMLRead`) in a new Lazarus configuration
  adapter; do not expose XML or FPC parser objects in the model.
- Treat explicit CLI compiler values as higher precedence than imported
  Lazarus values, which in turn take precedence over existing PasWeave
  defaults. Merge imported values only into unset CLI categories.
- Resolve only explicitly referenced local packages and package files found
  by deterministic, pruned search. Skip generated, vendor, example, and test
  trees during automatic search; `--package-path` is an explicit opt-in.
- Reject malformed or incomplete project/package configuration before
  parsing any source so missing packages, unsupported macros, ambiguous build
  modes, and dependency cycles cannot silently produce partial configuration.
- Keep the current `BuildProject` path for direct inputs and add a file-list
  entry point for project/package-selected sources.

## Task list

### Phase 1: Configuration foundation

- [x] Add focused Lazarus fixtures and tests for `.lpi`/`.lpk` XML parsing,
  build-mode selection, imported paths/defines/targets, and CLI precedence.
- [x] Implement normalized Lazarus configuration records/classes and XML
  value extraction, including supported macro expansion and diagnostics.
- [x] Extend compiler options with category-aware default merging.

### Checkpoint: Configuration foundation

- [x] New tests fail before implementation and pass after implementation.
- [x] Existing compiler-option and direct-input tests remain green.

### Phase 2: Package graph and source selection

- [x] Resolve referenced local packages deterministically with cycle,
  missing-file, ambiguity, and safe-directory diagnostics.
- [x] Import project units, package files, main units, unit paths, and include
  paths into a selected source set without traversing excluded trees.
- [x] Add a parser file-list build entry point and preserve transitive unit
  resolution through effective imported paths.

### Checkpoint: End-to-end project input

- [x] A multi-package fixture builds with no manually duplicated compiler
  settings.
- [x] Direct file and directory builds remain unchanged.
- [x] Deterministic JSON is identical across repeated project builds.

### Phase 3: Release contract

- [x] Add CLI options/help for Lazarus input, build mode, and package paths.
- [x] Update README, parser/project documentation, changelog, release note,
  roadmap status, and version metadata to `0.3.0`.
- [x] Validate against at least one real multi-package Lazarus project or a
  checked-in equivalent, then run the full test/build suite.

## Definition of done

- [x] Branch is `release/v0.3.0`.
- [x] Every new behavior has focused regression coverage.
- [x] Full automated tests pass and the application builds.
- [x] Direct inputs, default `///` comments, and existing golden outputs are
  unchanged.
