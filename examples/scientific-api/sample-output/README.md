# Scientific output showcase

This directory contains a checked-in snapshot of the equation-rich
`Scientific API showcase`. It documents both units and all 28 public API
symbols, including 16 display equations and 65 inline mathematical
expressions.

- [Browse the Markdown project index](markdown/index.md)
- [Open the HTML project index](html/index.html) after cloning the repository
- [Browse the symbol index](html/symbols.html) after cloning the repository

The HTML preview retains PasWeave's generated styling, offline search, symbol
index, reader theme control, KaTeX rendering, direct unit and category
navigation, linked dependency and relationship diagrams, and accessible diagram
controls.

The source snapshot was generated from the repository root with:

```text
build/bin/pasweave build examples/scientific-api --output build/scientific-api --project-name "Scientific API showcase"
```

Normal PasWeave output is fully self-contained. To avoid duplicating roughly
3.9 MB of third-party files, this curated preview changes only the KaTeX and
Mermaid asset URLs to reuse the copies already stored in the repository's
top-level `assets` directory. The PasWeave-authored HTML, CSS, JavaScript, and
Markdown are otherwise the generated files.
