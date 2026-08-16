# Releasing PasWeave

PasWeave publishes a raw, portable Windows x86-64 executable. It does not
publish an installer or ZIP package.

## Release gate

A public release requires a project `LICENSE`. The release workflow refuses to
publish while that file is absent. PasWeave is distributed under the MIT
License committed at the repository root.

The Windows workflow runs the complete portable build on pull requests, pushes
to `main`, and manual dispatches. Only a pushed `v*` tag enables its publishing
step. This keeps ordinary CI validation separate from the decision to publish.

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

1. Update `PasWeaveVersion`, its regression assertion, and the README version
   badge.
2. Update `CHANGELOG.md` and add `docs/RELEASE_NOTE_<tag>.md`, including the
   leading `v` in the tag name.
3. Run the complete test suite and the portable release build.
4. Commit the release-ready source and merge it into `main`.
5. Wait for the Windows build on `main` to pass.
6. Create and push a matching tag such as `v0.2.0`.

The tag workflow repeats the standalone build and smoke test, then creates a
GitHub release containing only:

- `pasweave.exe`
- `pasweave.exe.sha256`

When `docs/RELEASE_NOTE_<tag>.md` exists, its contents become the GitHub release
description. Otherwise, GitHub generates release notes from the repository
history.

Tags containing a hyphen, including alpha and beta versions, are published as
GitHub pre-releases.

Do not draft the GitHub release manually. Pushing the tag starts the validated
build, and the workflow creates the release only after that build succeeds.

If a Windows build fails, consult the
[Windows CI troubleshooting guide](windows-ci-troubleshooting.md) before
changing or recreating a release tag.

## Publish the documentation showcase

The `Publish documentation showcase` workflow builds and tests PasWeave on
Ubuntu, regenerates the scientific example from committed sources, validates
its coverage, symbol index, unit and category navigation, reader themes,
source links, diagrams, and mathematics, then uploads only the self-contained
HTML tree. Pull requests run the build gate without configuring or publishing
Pages. A push to `main` enables Pages when necessary and deploys
automatically; once the workflow exists on the default branch, a maintainer
may also dispatch it on another reviewed branch.

The deploy job publishes through the protected `github-pages` environment to
`https://ikelaiah.github.io/pasweave/`, then requests the deployed index, unit
page, symbol index, and search index and checks the milestone contract again.
Treat a successful deployment and deployed-site smoke test as part of the
current discovery and reader-theme release gate.
