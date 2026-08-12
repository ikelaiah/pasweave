# Documented API example

This two-unit project demonstrates PasWeave's explicit `///` documentation
marker. FPC treats these as ordinary `//` comments; PasWeave associates only
the triple-slash form because `slash` is the default documentation style.

Build PasWeave from the repository root, then generate the example site:

```text
build/bin/pasweave build examples/documented-api --output build/documented-api --project-name "Documented API example" --repository-url=https://github.com/ikelaiah/pasweave '--source-link-template=blob/main/examples/documented-api/{path}#L{line}'
```

On Windows, use `build\bin\pasweave.exe` if your shell does not resolve the
executable suffix automatically. Open `build/documented-api/html/index.html`
afterward.

The generated index reports `10 of 10 API symbols documented`: five in
`Demo.Core` and five in `Demo.Services`. It also demonstrates structured
directives, inline mathematics, a project dependency, class inheritance,
line-aware repository links, filtered offline search, and the interactive
diagrams.

A compact generated snapshot is checked in for visitors who want to inspect
the output before building PasWeave:

- [Markdown project index](sample-output/markdown/index.md)
- [HTML project index](sample-output/html/index.html) — clone the repository
  and open this file locally for styling, search, math, and diagrams

See the [sample-output notes](sample-output/README.md) for how the preview
reuses the repository's existing third-party assets without duplicating them.
