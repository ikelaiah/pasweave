# PasWeave v0.4.0

PasWeave v0.4.0 turns generated documentation into authoring feedback that can
be used in CI. It validates structured directives against parsed signatures,
keeps project-local reference links honest, and emits stable coded diagnostics
from the shared documentation model.

Highlights:

- stable warning and error codes, including parameter, return, reference,
  generated-route, and coverage diagnostics;
- parsed-signature validation for missing, duplicate, and unknown `@param`
  entries plus invalid or conflicting `@returns` directives;
- conservative model-level `@see` resolution across the current unit and its
  documented interface dependencies, with unresolved targets left unlinked;
- generated-anchor and unit-route integrity checks before output;
- a deterministic `diagnostics.json` artifact alongside `api-model.json`;
- `--min-documentation-coverage` and `--fail-on=warning` CI controls while
  retaining error-only failure by default; and
- regression fixtures for `///`, `{ ... }`, and `(* ... *)` comment forms.

See [authoring feedback and reference integrity](docs/authoring-feedback.md)
for the diagnostic contract and CI examples.

Validation includes the complete fixture suite, CLI checks for default and CI
failure policies, and a 45-unit `mathlib-fp` audit that generated 2,338
symbols with zero errors. Its 2,676 missing-parameter warnings demonstrate
why warning-level failure remains an explicit CI choice.
