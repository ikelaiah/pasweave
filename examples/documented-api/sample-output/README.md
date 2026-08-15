# Generated output showcase

This directory contains a checked-in snapshot generated from the two Pascal
units in the parent directory. It lets visitors inspect PasWeave's output
without first installing Free Pascal or compiling the project.

- [Browse the Markdown project index](markdown/index.md)
- [Open the HTML project index](html/index.html) after cloning the repository
- [Browse the A–Z symbol index](html/symbols.html) after cloning the repository

The snapshot reports 10 of 10 public API symbols documented and includes both
unit pages. The HTML preview retains PasWeave's generated styling, offline
search, A–Z symbol index, reader theme control, direct unit and category
navigation, mathematical rendering, relationship diagrams, and diagram
controls.

The source snapshot was generated from the repository root with:

```text
build/bin/pasweave build examples/documented-api --output build/documented-api --project-name "Documented API example"
```

Normal PasWeave output is fully self-contained. To avoid checking in another
copy of roughly 3.9 MB of third-party files, this curated preview changes only
the KaTeX and Mermaid asset URLs to reuse the copies already stored in the
repository's top-level `assets` directory. The PasWeave-authored HTML, CSS,
JavaScript, and Markdown are otherwise the generated files.
