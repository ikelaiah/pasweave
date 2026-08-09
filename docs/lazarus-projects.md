# Lazarus project and package inputs

PasWeave v0.3.0 accepts a Lazarus project (`.lpi`) or package (`.lpk`) as the
input to `pasweave build`. It reads the XML directly and never starts Lazarus.
The selected files are passed through the same `fcl-passrc` adapter used for
direct Pascal inputs.

## Usage

```text
pasweave build path/to/Application.lpi --output build/docs
pasweave build path/to/Application.lpi --build-mode=Release \
  --package-path=path/to/packages --output build/docs
pasweave build path/to/RuntimePackage.lpk --output build/docs
```

`--build-mode` is repeatable in the command syntax only as a single selected
value; supplying it more than once uses the last CLI value. If it is omitted,
PasWeave selects the one Lazarus mode marked `Default="True"`. A project with
several default modes, or several modes with no default, is rejected unless a
named mode is supplied. A named mode must exist exactly once, ignoring case.

`--package-path` may be repeated. These roots are explicit package search
roots, so their generated, vendor, example, and test subdirectories are not
pruned. The project/package directory is searched automatically, but those
directory names are pruned there. A package referenced by an explicit
`Filename` is accepted even when it is under a pruned directory.

## Imported values and precedence

The effective compiler configuration follows this order, from strongest to
weakest:

| Priority | Source | Behavior |
|---|---|---|
| 1 | Explicit PasWeave CLI options | A supplied path/define category replaces the imported category; explicit OS/CPU replaces the imported target. |
| 2 | Selected `.lpi` mode, project settings, and referenced `.lpk` settings | Project settings are read before package settings; package paths and defines are added, while the project target remains authoritative. |
| 3 | PasWeave defaults | Host target values and the existing direct-input defaults remain in effect when the input does not specify them. |

The reader imports these XML values:

- `.lpi` `ProjectOptions/Units/Unit/Filename` Pascal units that belong to the
  project, its `RequiredPackages`, root `CompilerOptions`, and selected build
  mode `CompilerOptions`;
- `.lpk` `Files/Item/Filename` Pascal units, `RequiredPkgs`, compiler search
  paths, and `UsageOptions/UnitPath` values;
- `SearchPaths/OtherUnitFiles` as unit paths and `SearchPaths/IncludeFiles`
  as include paths;
- `Other/CustomOptions` values for `-dNAME`, `-FiPATH`, `-FuPATH`, `-TOS`, and
  `-PCPU`, plus `<Target><OS>`/`<Target><CPU>` (and their `TargetOS` and
  `TargetCPU` aliases).

Non-Pascal project resources such as `.lpr`, `.lfm`, and `.lrs` are not source
units for this interface-only pipeline. Generated output macros such as
`$(ProjOutDir)` and `$(PkgOutDir)` are deliberately skipped when they occur in
search paths. `$(ProjDir)`, `$(PkgDir)`, `$(TargetOS)`, `$(TargetCPU)`, and the
common `$(LCLWidgetType)` selection (`win32` for Windows targets and `gtk2`
for other targets), and the empty optional `$(IDEBuildOptions)` macro are
supported; every other macro is an input error.

## Package resolution and diagnostics

Referenced packages are resolved before source parsing. A package reference
must resolve to one local `.lpk` file by its explicit filename or package
basename/name. Missing files, multiple candidates, malformed XML, unsupported
macros, duplicate default/selected modes, and cyclic package references are
fatal configuration diagnostics. No partially imported configuration is
returned after one of these failures.

Automatic package scanning skips directories named `build`, `dist`,
`generated`, `vendor`, `vendored`, `example`, `examples`, `test`, `tests`,
`lib`, `obj`, and `.git`. This prevents generated or non-production trees from
silently changing the selected package graph. Add a package root explicitly
with `--package-path` when that behavior is intentional.

Direct `.pas`/`.pp` file and directory input remains unchanged. Source
discovery flags (`--recursive`, `--include`, and `--exclude`) apply to direct
directory input and are rejected for Lazarus project/package input because
they would otherwise silently override the project file's source set.

The checked-in multi-package fixture covers a project, two transitive local
packages, selected build-mode settings, CLI precedence, pruned duplicate
packages, missing packages, ambiguous packages, unsupported macros, and cyclic
references. The full test suite builds it through the normal parser and
renderer pipeline.
