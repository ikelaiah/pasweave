# PasWeave v0.5.2

PasWeave v0.5.2 makes an unfamiliar API discoverable by browsing and lets
readers choose a comfortable color scheme without weakening the offline,
accessible generated-site contract.

Highlights:

- a generated **A–Z symbol index** (`symbols.html`) derived entirely from the
  documentation model, with stable links, letter sections, and category filters
  for types, routines, members, constants, and variables;
- a **Browse API** section on the project index that reports symbol totals by
  category, plus a persistent **Symbols A–Z** destination in every page header;
- a keyboard-accessible **System / Light / Dark** reader theme control with
  offline persistence that falls back safely when storage is unavailable or
  rejected, including under `file://`;
- a dependency-free inline bootstrap that applies the scheme before visible
  rendering, with native controls, KaTeX, Mermaid diagrams, focus states, and
  contrast synchronized through shared CSS tokens;
- restrained build-time branding through validated `--project-mark`,
  `--theme-accent`, `--theme-accent-2`, and `--theme-font` options; and
- updated documented/scientific examples plus Pages workflow assertions before
  upload and after deployment.

The project index now leads with project summary, Browse API, the units table,
architecture diagrams, and diagnostics last. Existing unit filenames,
overload-aware symbol anchors, the search-index schema, source links, and the
scope of both architecture diagrams are unchanged. No runtime dependency is
added. With JavaScript disabled, the unit list, A–Z symbol index, category
links, and diagram text fallbacks remain ordinary HTML, and the site follows
the system color scheme when the interactive preference control is
unavailable.

Validation includes the complete FPC 3.2.2 suite, deterministic checked-in
examples, headless Chrome checks over the index, unit page, and a 2,657-entry
`mathlib-fp` symbol index with clean consoles, and deterministic sample
goldens. Two builds of the latest 50-unit `mathlib-fp` commit produced 2,978
symbols, 2,657 A–Z index entries, 175 identical generated files with audit
digest `98B9DAB763AD46D83E71A607E30211F05B7CB1DCDDF1903A9E273809BAD88F9B`, and
zero errors; all 50 unit pages carry the theme control.

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
and the [HTML renderer guide](docs/html-renderer.md) for behavior, fallback,
and limitations. The public GitHub Pages smoke check is the final post-merge
release gate because the deployed showcase cannot contain this branch before
it reaches `main`.
