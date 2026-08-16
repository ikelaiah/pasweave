# PasWeave v0.5.3

PasWeave v0.5.3 is a small label polish on top of the v0.5.2 API-discovery and
reader-theme release. The visible name of the generated symbol browser is now
the more professional **Symbols Index** instead of **Symbols A–Z**.

Highlights:

- the header link, the `symbols.html` page heading and breadcrumb, and the
  project-index **Browse API** card now read **Symbols Index**;
- the "A–Z" phrase is retained where it is descriptive, such as the Browse API
  card text ("Every public API symbol A–Z …") and the page description;
- the `symbols.html` route, stable symbol anchors, category filters, category
  deep links, reader themes, branding options, and every other v0.5.2 contract
  are unchanged.

Validation includes the complete FPC 3.2.2 suite, deterministic checked-in
example goldens regenerated for the new label, and direct-file/default-`///`
workflows. No runtime dependency is added.

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
and the [HTML renderer guide](docs/html-renderer.md) for behavior, fallback,
and limitations.
