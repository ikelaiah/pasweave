# Authoring feedback and reference integrity

PasWeave v0.4.0 validates parsed documentation data after the complete
project model has been built. This makes authoring feedback deterministic and
available to the JSON, Markdown, and HTML outputs without inspecting rendered
pages.

## Diagnostic contract

Every diagnostic has a stable `code`, a severity, a source location, a
message, and optional details. The supported severities are:

| Severity | Meaning | Default exit behaviour |
|---|---|---|
| `warning` | Actionable documentation feedback; output remains useful. | Does not fail the build. |
| `error` | A parse, output-integrity, or configured-policy defect. | Fails the build. |

These codes are stable through v1.0.0:

| Code | Severity | Meaning |
|---|---|---|
| `PW000` | error | Generic parser or adapter diagnostic retained from earlier pipeline stages. |
| `PW401` | warning | A parsed routine parameter has no matching `@param`. |
| `PW402` | warning | More than one `@param` documents the same parsed parameter. |
| `PW403` | warning | An `@param` subject is absent from the parsed signature. |
| `PW404` | warning | `@returns` is attached to a declaration that does not return a value. |
| `PW405` | warning | A value-returning routine has conflicting multiple `@returns` directives. |
| `PW406` | warning | A project-local `@see` reference is unresolved or ambiguous. |
| `PW407` | error | A stored generated link target cannot be rendered safely. |
| `PW408` | error | Two rendered symbols would have the same generated anchor. |
| `PW409` | error | Two generated unit pages would use the same route. |
| `PW410` | error | A generated unit page has no stable route from the project index. |
| `PW411` | error | The configured documentation-coverage minimum was not reached. |

Directive diagnostics use their declaration's source position. PasWeave does
not pretend to know an individual directive column after a documentation group
has been normalized.

## Directive validation

For parsed routine, method, constructor, and destructor signatures, every
parsed parameter needs exactly one case-insensitive `@param` entry. Extra,
missing, and duplicate entries each receive their own code above.

`@returns` is valid only for declarations that the FPC parser identifies as
value-returning. One `@returns` is permitted; two or more conflict. PasWeave
does not require every function to have `@returns`, because concise API prose
can already state the result.

`@see` is deliberately conservative. A qualified reference must identify one
symbol in the documented project. An unqualified reference first searches the
current unit and then the documented units named by its interface `uses`
clause. It never guesses across unrelated units or external dependencies.
Ambiguous, private, and unavailable targets retain an empty `targetSymbolId`
and render as code rather than a misleading link.

The rule set is independent of comment syntax. It applies identically to the
default `///` form and the opt-in `{ ... }` and `(* ... *)` forms.

## Output integrity

Before output is written, PasWeave validates routes and anchors implied by the
model. Duplicate anchors, duplicate case-insensitive page routes, missing
generated parent targets, and unit pages without a stable index route are
errors. Generated HTML and Markdown consume `@see.targetSymbolId` directly;
they do not independently re-resolve prose references.

## CI policy

The useful local default is to fail only on errors. Use the options below to
make warnings and documentation coverage release gates:

```text
pasweave build src --fail-on=warning
pasweave build src --min-documentation-coverage=90 --fail-on=warning
```

`--fail-on` accepts `error` (the default) or `warning`. The latter fails on
either severity. `--min-documentation-coverage` accepts an integer from 0 to
100 and emits `PW411` when renderable documented symbols fall below it.
Coverage includes every effectively renderable symbol, including a unit symbol,
and excludes private and strict-private declarations and children of such
declarations.

Every build writes both `api-model.json` and `diagnostics.json`. The latter is
a compact model-derived artifact with schema version, ordered diagnostics, and
warning/error counts. It is suitable for CI reporting without scraping
Markdown or HTML.

## Real-project audit

The checked-out `mathlib-fp` validation corpus was rebuilt from its 45-unit
`src` tree with the default error-only policy. PasWeave produced 2,338 symbols
and 45 Markdown and HTML unit pages with zero errors and 2,676 `PW401`
warnings. Those warnings identify routine parameters without matching
structured documentation; the command correctly exited 0 under the useful
local default. Projects that want those findings to block CI can opt into
`--fail-on=warning`.
