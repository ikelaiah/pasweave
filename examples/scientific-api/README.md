# Scientific API example

This runnable two-unit library is PasWeave's equation-rich showcase. Its API
documentation covers vector geometry, Gaussian densities, numerical methods,
descriptive statistics, softmax, and Shannon entropy with inline and display
mathematics.

Build and run the small console program from the repository root:

```text
fpc -Mobjfpc -Sh -Fuexamples/scientific-api -FUbuild/units -FEbuild/bin examples/scientific-api/ScientificDemo.lpr
build/bin/ScientificDemo
```

Generate the documentation site with:

```text
build/bin/pasweave build examples/scientific-api --output build/scientific-api --project-name "Scientific API showcase"
```

The example deliberately exercises:

- numerous valid KaTeX inline and display equations;
- structured `@param`, `@returns`, and `@raises` directives;
- a cross-unit dependency;
- interface implementation and cross-unit inheritance relationships;
- fully documented public API coverage;
- deterministic Markdown, HTML, search, and diagram output.

A compact generated snapshot is checked in so the result can be inspected
without compiling PasWeave:

- [Markdown project index](sample-output/markdown/index.md)
- [HTML project index](sample-output/html/index.html) — clone the repository
  and open this file locally for styling, search, KaTeX, and Mermaid diagrams

The snapshot reports 30 of 30 public API symbols documented and contains 16
display equations plus 65 inline mathematical expressions. See the
[sample-output notes](sample-output/README.md) for how its assets are kept
compact.
