# PasWeave v0.5.5

PasWeave v0.5.5 is a small copy polish on the project index. The hero paragraph
now reads:

> Browse the API using the A–Z symbol index, explore individual units, or
> search the complete public API reference.

The change is limited to that hero paragraph text; the en dash is preserved as
`&#8211;` in generated HTML. No routes, anchors, schema, reader themes, or
branding tokens changed.

Validation includes the complete FPC 3.2.2 suite, deterministic checked-in
example goldens regenerated for the new copy, a focused test that pins the new
wording, and direct-file/default-`///` workflows. No runtime dependency is
added.

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
and the [HTML renderer guide](docs/html-renderer.md) for behavior, fallback,
and limitations.
