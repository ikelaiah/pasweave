# PasWeave v0.1.0-alpha.1

PasWeave's first public alpha turns Free Pascal interface declarations and
their documentation comments into a searchable, equation-capable static API
site. It also emits deterministic Markdown and a reusable JSON model.

This is an early release intended for evaluation and feedback. The output is
already useful, but project configuration and parts of the semantic model will
continue to evolve before a stable release.

## Download

Download these two files from the release assets:

- `pasweave.exe`
- `pasweave.exe.sha256`

The executable is a portable Windows x86-64 application: there is no installer
or ZIP package, and Free Pascal is not required at runtime. Place it anywhere
and run:

```powershell
.\pasweave.exe --version
.\pasweave.exe build path\to\project --output docs
```

The HTML site is self-contained for offline use. PasWeave extracts its embedded
KaTeX and Mermaid resources into the generated site's asset directory.

Verify the download before running it:

```powershell
Get-FileHash .\pasweave.exe -Algorithm SHA256
Get-Content .\pasweave.exe.sha256
```

The values must match. This alpha is not code-signed, so Windows may display a
SmartScreen warning.

## Highlights

- Builds its source model with Free Pascal's reusable `fcl-passrc` parser
  libraries rather than guessing from declaration text.
- Generates deterministic JSON schema version 1, Markdown, and responsive
  static HTML.
- Provides offline symbol search, documentation coverage counts, stable links,
  structured directives, source positions, and light and dark colour schemes.
- Renders marked inline and display mathematics with offline KaTeX.
- Produces linked Mermaid diagrams from resolved unit dependencies,
  inheritance, and interface implementation relationships.
- Gives every diagram accessible zoom, pan, and reset controls plus a readable
  non-interactive text fallback.
- Supports single files, top-level directories, and opt-in recursive discovery
  with repeatable include and exclude globs.
- Isolates parse failures by file and returns meaningful process exit codes.

## Documentation comments

The safe default recognizes consecutive `///` lines. This is an explicit
PasWeave convention: Free Pascal sees them as ordinary line comments, and
ordinary `//` comments are not documentation.

Pascal block comments can be enabled per project:

```powershell
.\pasweave.exe build src --output docs --doc-comments=brace
.\pasweave.exe build src --output docs --doc-comments=paren
.\pasweave.exe build src --output docs --doc-comments=all
```

Enabled adjacent forms can be mixed in source order. Documentation must
immediately precede an interface declaration; a blank line ends the
association. Compiler directives such as `{$mode objfpc}` and `(*$...*)` are
never documentation.

Structured `@param`, `@returns`, `@raises`, `@deprecated`, `@see`, and `@since`
directives are extracted from documentation groups.

## Compatibility

| Area | This release |
| --- | --- |
| Portable binary | Windows x86-64; self-contained and unsigned |
| Source builds | Free Pascal 3.2.2+ with `fcl-passrc` and `fcl-json` |
| Primary Pascal mode | `{$mode objfpc}` |
| Delphi syntax | Accepted only where FPC's parser handles it naturally |
| JSON model | Schema version 1 |
| Generated site | Static and offline; JavaScript enhances search, mathematics, and diagrams |

## Validation

The full test suite and an isolated portable-executable smoke test run before
the release workflow publishes any binary.

Against the recorded `mathlib-fp` revision, PasWeave parsed all 45 units into
2,338 model symbols with no parse errors, missing source positions, or
duplicate stable IDs. It rendered 2,227 API symbols and resolved 97
project-local dependency edges. Because that project contains no PasWeave
`///` comments, default documentation coverage is correctly 0 of 2,227;
enabling brace comments finds 570 documented API symbols, with the documented
section-label false-positive caveat described in the validation report.

The equation-rich scientific showcase documents all 30 public API symbols and
contains 16 display equations and 65 inline mathematical expressions. The
portable smoke test also verifies all 67 extracted third-party assets
byte-for-byte.

See the complete [mathlib-fp validation report](docs/mathlib-fp-validation.md)
and the checked-in [scientific API showcase](examples/scientific-api/README.md).

## Known alpha limitations

- The Windows executable is not code-signed.
- Compiler-aware project and package configuration is not implemented yet.
- Source-backed comment association currently operates on the main unit file;
  declarations originating from include files do not yet receive it.
- Type relationship resolution is intentionally scoped and may leave standard
  library or otherwise out-of-scope ancestors unresolved.
- Opting ordinary block comments into documentation can capture section labels;
  review coverage findings when enabling `brace` or `paren` on an existing
  codebase.
- Markdown and mathematical rendering deliberately support a focused,
  documented subset.

See the [README limitations](README.md#current-limitations) and
[roadmap](ROADMAP.md) for the current boundaries and next milestones.

## License and attribution

PasWeave is released under the [MIT License](LICENSE). Embedded KaTeX and
Mermaid components retain their own license notices in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

Questions, bugs, and real-world compatibility reports are welcome in
[GitHub Issues](https://github.com/ikelaiah/pasweave/issues).
