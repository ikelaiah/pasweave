# PasWeave v0.5.6

PasWeave v0.5.6 corrects the symbol-index terminology so the generated copy no
longer implies that symbol names can only begin with A–Z. Symbols beginning
with `_`, digits, or other non-letter characters are valid and are grouped
under the `#` section of the index.

Highlights:

- the project-index hero now reads "Browse the API using the symbol index,
  explore individual units, or search the complete public API reference.";
- the **Browse API** section says "Browse symbols by name or filter by kind.";
- the **Symbols Index** card says "Every public API symbol, indexed by name and
  filterable by kind." (the unit count was removed);
- the symbols page introduction says "Public API symbols indexed by name and
  grouped into navigable sections.";
- the symbol-section navigation accessible label reads "Symbol index sections".

No routes, stable anchors, category links, filters, sorting, or `#` grouping
changed. Living documentation was updated from "A–Z symbol index" to "symbol
index" (or "A–Z and `#` sections" where behavior is explained), while
"alphabetical" is retained only where it accurately describes unit sorting or
the A–Z letter ordering.

Validation includes the complete FPC 3.2.2 suite, deterministic example goldens
regenerated for the revised copy, focused tests that also prove an underscore-
leading symbol appears in the index, is grouped under `#`, and keeps a working
stable link, and direct-file/default-`///` workflows. No runtime dependency is
added.

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
and the [HTML renderer guide](docs/html-renderer.md) for behavior, fallback,
and limitations.
