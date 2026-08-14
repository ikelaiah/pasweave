# Building from source

These instructions are for contributors and platforms without a portable
PasWeave release. Windows users who only want to generate documentation can
download `pasweave.exe` from the
[GitHub Releases page](https://github.com/ikelaiah/pasweave/releases) instead.

## Requirements

- Free Pascal 3.2.2 or newer
- the FPC `fcl-passrc` and `fcl-json` packages
- a POSIX-compatible `make`, or the equivalent direct FPC commands below

The parser adapter is tested specifically against FPC 3.2.2. See the
[parser integration notes](parser-integration.md) for the exact APIs and known
uncertainties.

## Build and test with Make

From the repository root:

```text
make
make test
```

Run the generated test executable from the repository root so it can find its
fixture:

```text
build/tests/test_pasweave
```

## Build directly with FPC

Create the output directories first. With a POSIX-compatible shell:

```text
mkdir -p build/bin build/tests build/units
```

With PowerShell:

```powershell
New-Item -ItemType Directory -Force build/bin, build/tests, build/units
```

Compile the CLI and tests from the repository root:

```text
fpc -Mobjfpc -Sh -Fusrc/cli -Fusrc/diagnostics -Fusrc/model -Fusrc/parser -Fusrc/render -Fusrc/validation -FUbuild/units -FEbuild/bin src/pasweave.lpr
fpc -Mobjfpc -Sh -Fusrc/cli -Fusrc/diagnostics -Fusrc/model -Fusrc/parser -Fusrc/render -Fusrc/validation -FUbuild/units -FEbuild/tests tests/test_pasweave.pas
```

## Build the portable Windows executable

```powershell
.\scripts\build-portable-windows.ps1
```

The script writes `dist\pasweave.exe` and its checksum, then performs an
isolated smoke test. It does not create an installer or ZIP package. See the
[release procedure](releasing.md) for version-tag rules, validation, and the
public-release license gate.
