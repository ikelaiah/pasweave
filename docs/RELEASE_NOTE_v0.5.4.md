# PasWeave v0.5.4

PasWeave v0.5.4 makes the project index's numbers mean what they say. The
previous "Public API symbols" total included the unit declarations, while the
A–Z symbol index deliberately omits them, so the cards disagreed.

Highlights:

- **Parsed declarations** replaces **Parsed symbols** and still counts every
  model declaration, including unit declarations and private symbols;
- **Public API symbols** now counts exactly the renderable non-unit population
  that the A–Z symbol index lists (unit declarations excluded), so the units
  count stays separate and the totals agree;
- documentation coverage and the per-unit **API symbols / Documented** rows use
  that same indexed population for both numerator and denominator;
- the Markdown index uses the same totals and now says "declarations" in its
  generated-from line.

The scientific showcase now reports `2 Units / 32 Parsed declarations /
28 Public API symbols / 100% Documented`, and the documented example reports
`8 of 8`. The `symbols.html` route, stable anchors, category filters, reader
themes, and branding tokens are unchanged. The CI coverage metric behind
`--min-documentation-coverage` (`PW411`) still counts every renderable symbol,
so existing CI thresholds keep their meaning.

Validation includes the complete FPC 3.2.2 suite, deterministic example goldens
regenerated for the new totals, and direct-file/default-`///` workflows. No
runtime dependency is added.

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
and the [HTML renderer guide](docs/html-renderer.md) for behavior, fallback,
and limitations.
