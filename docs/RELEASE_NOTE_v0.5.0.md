# PasWeave v0.5.0

PasWeave v0.5.0 makes generated documentation easier to traverse from project
overview to symbol, related type, and original source. The release preserves
existing unit URLs and overload-aware anchors while adding secure source-link
templates and richer dependency-free offline search.

Highlights:

- validated `--repository-url` and `--source-link-template` options with
  normalized root-relative paths and declaration-line links;
- source-link configuration shared by HTML, Markdown, and the JSON model;
- consistent resolved `@see`, dependency, parent, inheritance, and
  implementation links across HTML and Markdown;
- offline search filters for unit, symbol kind, visibility, and documentation
  status;
- keyboard result navigation, polite result announcements, visible focus,
  explicit empty states, and phone-width responsive behavior;
- updated committed example output with stable repository source links; and
- a deployment-ready GitHub Pages workflow that rebuilds, validates, deploys,
  and smoke-checks the scientific API showcase at
  `https://ikelaiah.github.io/pasweave/`.

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
for the template contract, accessibility behavior, validation results, and
known constraints.

Validation includes the complete FPC 3.2.2 suite, production and CLI builds,
real Chromium rendering and interaction checks, the three-unit nested Lazarus
fixture, and two deterministic runs of the pinned 45-unit `mathlib-fp` corpus.
The latter produced 2,338 symbols, 2,227 searchable and source-linked API
entries, zero errors, zero escaping links, and identical output-tree digests.
