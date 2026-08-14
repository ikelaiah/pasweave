# Documentation comments

PasWeave uses consecutive `///` lines as its default documentation syntax:

```pascal
/// Returns the standard normal probability density.
///
/// $$
/// \phi(x) = \frac{1}{\sqrt{2\pi}}e^{-x^2/2}
/// $$
///
/// @param X Point at which the density is evaluated.
/// @returns The probability density at `X`.
function NormalPDF(const X: Double): Double;
```

Free Pascal reads `///` as an ordinary `//` comment. PasWeave gives the third
slash its documentation meaning: `--doc-comments=slash` means consecutive
`///` lines only, never ordinary `//` comments.

Ordinary Markdown and mathematical delimiters are retained in
`markdownDocumentation`. The original comment form is retained in
`rawDocumentation`, while recognised directives are also emitted as structured
objects.

## Supported comment forms

Projects that use Pascal block comments for API documentation can opt into one
or both block forms:

| `--doc-comments` value | Source form treated as documentation |
|---|---|
| `slash` | Consecutive `///` lines only; plain `//` is ignored |
| `brace` | Standalone `{ ... }` comments |
| `paren` | Standalone `(* ... *)` comments |
| `all` | `slash`, `brace`, and `paren` together |

```text
pasweave build src --doc-comments=slash
pasweave build src --doc-comments=brace
pasweave build src --doc-comments=paren
pasweave build src --doc-comments=slash,brace,paren
pasweave build src --doc-comments=all
```

The space-separated form, such as `--doc-comments brace`, is also accepted.
Enabled forms may be mixed in one standalone group and are merged in source
order:

```pascal
/// Computes a scaled value.
{ @param X Input value. }
(* @returns The scaled result. *)
function Scale(const X: Double): Double;
```

## Association rules

A documentation group must directly precede its interface declaration. A blank
line, compiler directive, disabled comment form, or other source token ends the
association.

Block groups must start on an otherwise blank source line. This prevents a
trailing comment such as `X: Double; { describes X }` from drifting onto the
next declaration. Compiler directives in `{$...}` and `(*$...*)` are never
documentation.

Opting into `brace` or `paren` is intentionally broad: section labels and
commented-out declarations can look exactly like documentation. Enable those
forms only when the project's comment conventions make that trade-off safe.

## Structured directives

PasWeave extracts these directives from associated documentation:

- `@param`
- `@returns`
- `@raises`
- `@deprecated`
- `@see`
- `@since`

See [authoring feedback and reference integrity](authoring-feedback.md) for
directive validation, project-local references, documentation coverage, and
stable diagnostic codes.
