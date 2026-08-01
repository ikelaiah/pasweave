# Releasing PasWeave

PasWeave publishes a raw, portable Windows x86-64 executable. It does not
publish an installer or ZIP package.

## Release gate

A public release requires a project `LICENSE`. The release workflow refuses to
publish while that file is absent. PasWeave is distributed under the MIT
License committed at the repository root.

## Build locally

From PowerShell at the repository root:

```powershell
.\scripts\build-portable-windows.ps1
```

The script:

1. embeds the vendored KaTeX and Mermaid assets;
2. compiles and runs the complete test suite;
3. builds an optimized Windows x86-64 `dist\pasweave.exe`;
4. checks the reported application version;
5. copies only the executable into an isolated directory;
6. documents the equation-rich scientific example there;
7. checks documentation coverage, mathematics, and relationship diagrams;
8. compares every extracted third-party asset byte-for-byte with its source;
9. writes `dist\pasweave.exe.sha256`.

## Publish

1. Update `PasWeaveVersion` and its regression assertion.
2. Run the complete test suite and the portable release build.
3. Commit the release-ready source.
4. Create and push a matching tag such as `v0.1.0-alpha.1`.

The tag workflow repeats the standalone build and smoke test, then creates a
GitHub release containing only:

- `pasweave.exe`
- `pasweave.exe.sha256`

Tags containing a hyphen, including alpha and beta versions, are published as
GitHub pre-releases.
