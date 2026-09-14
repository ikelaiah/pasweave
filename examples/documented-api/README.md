# Documented API example

> **Start here.** This is the minimal copy-paste example: two units, 8 of 8
> symbols documented, one `@param`/`@returns` pattern to imitate. Once this
> builds, see the [scientific showcase](../scientific-api/README.md) for
> equations, diagrams, and interface inheritance.

This two-unit project demonstrates PasWeave's explicit `///` documentation
marker. FPC treats these as ordinary `//` comments; PasWeave associates only
the triple-slash form because `slash` is the default documentation style.

Build PasWeave from the repository root, then generate the example site:

```text
build/bin/pasweave build examples/documented-api --output build/documented-api --project-name "Documented API example" --repository-url=https://github.com/ikelaiah/pasweave "--source-link-template=blob/main/examples/documented-api/{path}#L{line}"
```

On Windows (PowerShell):

```powershell
build\bin\pasweave.exe build examples/documented-api --output build/documented-api --project-name "Documented API example" --repository-url=https://github.com/ikelaiah/pasweave "--source-link-template=blob/main/examples/documented-api/{path}#L{line}"
```

Open `build/documented-api/html/index.html` afterward. The index reports
`8 of 8 API symbols documented` (four in `Demo.Core`, four in
`Demo.Services`).

The generated index reports `8 of 8 API symbols documented`: four in
`Demo.Core` and four in `Demo.Services`. It also demonstrates structured
directives, inline mathematics, a project dependency, class inheritance,
line-aware repository links, filtered offline search, a generated symbol
index, a reader theme control, and the interactive diagrams. Each generated
unit page also demonstrates the native searchable unit switcher and
present-only on-page category navigation.

A compact generated snapshot is checked in for visitors who want to inspect
the output before building PasWeave:

- [Markdown project index](sample-output/markdown/index.md)
- [HTML project index](sample-output/html/index.html) — clone the repository
  and open this file locally for styling, search, math, and diagrams
- [Symbol index](sample-output/html/symbols.html) — clone the repository
  and open this file locally for the filterable symbol browser

See the [sample-output notes](sample-output/README.md) for how the preview
reuses the repository's existing third-party assets without duplicating them.
