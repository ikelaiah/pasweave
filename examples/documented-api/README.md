# Documented API example

This two-unit project demonstrates PasWeave's explicit `///` documentation
marker. FPC treats these as ordinary `//` comments; PasWeave associates only
the triple-slash form because `slash` is the default documentation style.

Build PasWeave from the repository root, then generate the example site:

```text
build/bin/pasweave build examples/documented-api --output build/documented-api --project-name "Documented API example"
```

On Windows, use `build\bin\pasweave.exe` if your shell does not resolve the
executable suffix automatically. Open `build/documented-api/html/index.html`
afterward.

The generated index reports `10 of 10 API symbols documented`: five in
`Demo.Core` and five in `Demo.Services`. It also demonstrates structured
directives, inline mathematics, a project dependency, class inheritance,
offline search, and the interactive diagrams.
