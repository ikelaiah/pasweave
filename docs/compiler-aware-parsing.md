# Compiler-aware parsing

PasWeave `v0.2.0` accepts the compiler inputs needed to make conditional
interface parsing reproducible without reading a Lazarus project or package.
All settings are converted into parser-independent strings before the
`fcl-passrc` adapter is called.

## Command-line options

| Option | Meaning | Repeatable |
|---|---|---:|
| `--unit-path=<directory>` | Find source units named by interface `uses` clauses | Yes |
| `--include-path=<directory>` | Find `{$I ...}` and `{$INCLUDE ...}` files | Yes |
| `--define=<name>` | Define a conditional-compilation symbol | Yes |
| `--target-os=<os>` | Select the target operating-system symbols | No |
| `--target-cpu=<cpu>` | Select the target CPU and width symbols | No |

Every option also accepts a space-separated value. For example:

```text
pasweave build src --recursive \
  --unit-path=packages/core/src \
  --unit-path packages/numerics/src \
  --include-path=include \
  --define=USE_FAST_MATH \
  --target-os=linux \
  --target-cpu=aarch64
```

Relative paths are resolved from PasWeave's working directory, expanded to
absolute paths, checked before parsing, and passed to the adapter without
shell re-tokenization. Defines are Pascal identifiers, are normalized to
uppercase, and cannot contain `=` or a value.

## Defaults and precedence

The effective settings are deterministic:

1. With no compiler options, the target OS and CPU are the host values used by
   the PasWeave binary. The adapter receives the same arguments as `v0.1.0`.
2. An explicit `--target-os` or `--target-cpu` replaces its host default. If
   either option is repeated, the last command-line value wins.
3. Defines are combined. Case-insensitive duplicates are ignored after their
   first occurrence.
4. Unit and include paths retain command-line order. The first matching path
   wins. Duplicate normalized paths are ignored after their first occurrence.
5. For includes, configured paths are searched in order and the source unit's
   directory follows them. For units, sources already selected by the main
   file/directory input win; unresolved interface dependencies are then
   searched through configured unit paths in order, with `.pas` preferred to
   `.pp` in one path.

Target-derived CPU-width symbols are applied after user defines so the
configured CPU cannot expose both `CPU32` and `CPU64`. `FPC`, the canonical
target name, common OS-family symbols, and the canonical `CPU<name>` symbol
are supplied consistently to `fcl-passrc`.

## Supported target values

Values are case-insensitive and are normalized before adapter use.

Supported OS values are:

```text
aix amiga aros beos darwin dragonfly freebsd haiku linux morphos
netbsd openbsd qnx solaris win32 win64 wince
```

Accepted OS aliases are `windows32`/`windows-32`,
`windows64`/`windows-64`, `macos`/`macosx`, and `sunos`.

Supported CPU values are:

```text
aarch64 arm i386 mips mipsel mips64 mips64el powerpc powerpc64
riscv32 riscv64 sparc sparc64 wasm32 x86_64
```

Accepted CPU aliases are `arm64`, `amd64`, `x64`, `x86-64`, `x86`, and
`x86-32`.

PasWeave validates each value but does not claim that every OS/CPU pair is a
real FPC backend combination. The adapter uses these settings only to select
the interface seen by conditional compilation; it does not compile machine
code.

## Includes and project units

Nested includes use the same configured include paths. When at least one
include path is configured, declarations originating in an include retain that
include's source filename, line, column, and source-backed documentation
comment instead of borrowing text from the main unit.

Configured unit paths are source paths, corresponding to FPC's `-Fu` concept.
After the explicitly selected source set is parsed, PasWeave follows unresolved
interface dependencies into those paths. Resolution is transitive, so a found
source unit can introduce another project dependency. The adapter still emits
only PasWeave model objects and stable string IDs; no `PasTree` object crosses
its boundary.

Runtime or third-party units available only as compiled `.ppu` files are not
added to the documentation project. They remain named external dependencies,
as they did before `v0.2.0`.

## Diagnostics

Configuration errors are rejected before output generation and return process
exit code `2`. Stable messages cover:

- missing, non-directory, or unreadable configured paths;
- empty or invalid conditional defines; and
- unsupported target OS or CPU values.

An include that cannot be opened produces a per-file parser diagnostic at the
including source filename, line, and column. The stable message is
`include file is missing or unreadable: <name>`. Other source files continue
to parse, usable output is generated, and the command returns `1`.

The FPC 3.2.2 file resolver reports the same failure for a missing file and an
existing file it cannot open, so PasWeave deliberately does not guess which
filesystem condition occurred.

## Compatibility and limitations

- Supplying no new compiler options preserves `v0.1.0` JSON, Markdown, HTML,
  and asset bytes. The regression suite also compares an empty compiler-options
  object with the legacy overload.
- To preserve that byte-level contract, a build with no compiler options keeps
  the legacy main-file-only documentation lookup even when a local include is
  found automatically. Supplying an include path enables include-backed
  documentation lookup.
- Unit paths search only their top-level directory and conventional
  `<unit-name>.pas` or `<unit-name>.pp` source names. They do not recurse,
  interpret FPC configuration files, or search compiled units.
- Lazarus `.lpi` and `.lpk` inputs are not read in this release. Their settings
  must be supplied explicitly on the command line.
- Parsing remains interface-only. Conditional implementation bodies do not
  affect generated API documentation.
