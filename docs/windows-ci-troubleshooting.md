# Windows CI troubleshooting

This guide records the failures uncovered while preparing the first portable
Windows release. It explains the error signatures, their causes, and the fixes
that were verified against Free Pascal 3.2.2.

The source of truth is the
[Windows workflow](../.github/workflows/release-windows.yml), which calls the
[portable build script](../scripts/build-portable-windows.ps1).

## Where Windows validation runs

The same portable build runs for:

- pull requests, as a pre-merge check;
- pushes to `main`, as a pre-tag check;
- manual workflow dispatches; and
- pushed `v*` tags.

Only a `v*` tag enables the publishing step. Pull-request and `main` runs build
and test the executable, but their temporary `dist` directory is discarded
with the hosted runner.

## Failure signatures

### `ppcx64.exe can't be executed`

The Chocolatey `freepascal` package installed the Win32 distribution, while
the original release script assumed a native Win64 compiler named
`ppcx64.exe`.

PasWeave now downloads the checksum-pinned official combined Win32 and Win64
installer. Its Win32 `fpc.exe` driver invokes `ppcrossx64.exe` with
`-Twin64 -Px86_64`. CI verifies the compiler version, target CPU, target OS,
linker, and resource tools before starting the build.

Do not infer target support merely from the presence of `fpc.exe`. Verify it:

```powershell
& $fpc -Twin64 -Px86_64 -iV
& $fpc -Twin64 -Px86_64 -iTP
& $fpc -Twin64 -Px86_64 -iTO
```

The expected results are `3.2.2`, `x86_64`, and `win64`.

### `Free Pascal installer failed with exit code` with no number

The installer is a graphical Windows executable. Invoking it with PowerShell's
call operator did not reliably populate `$LASTEXITCODE`, so an empty value was
mistaken for failure.

The workflow uses `Start-Process -Wait -PassThru` and checks the returned
process object's `ExitCode`. This both waits for installation to finish and
reports a real status code.

### `sample mismatch ... expected=362 actual=375 position=29`

The renderer produced LF line endings, but the Windows checkout converted the
committed golden sample to CRLF. The extra 13 bytes were carriage returns, one
for each affected line break. The first mismatch occurred at the first
newline.

The repository now declares canonical LF text files in `.gitattributes`:

```gitattributes
* text=auto eol=lf
```

Check the effective rule with:

```powershell
git check-attr text eol -- examples/documented-api/sample-output/markdown/index.md
```

### `resource compiler "x86_64-win64-fpcres.exe" not found`

The minimum FPC installation can compile and run the test program, but it omits
`fpcres.exe`. The omission appears only when the portable executable embeds its
KaTeX and Mermaid resource archive.

The official installer places `fpcres.exe` in its `utils` component. CI now
installs the minimum compiler, target units, binutils, and `utils` components,
then verifies all required executables. Because the cross-compiler otherwise
looks for a target-prefixed resource compiler, the build script passes the
installed host tool explicitly with FPC's `-FC` option.

This failure demonstrates why compiling the tests alone is not a sufficient
release check: the complete asset-embedding and linking path must also run.

## Local release-equivalent check

On a Windows development machine with FPC 3.2.2 and `windres` available, run:

```powershell
.\scripts\build-portable-windows.ps1
```

The script compiles and runs the tests, builds the optimized executable,
checks its version, exercises it from an isolated directory, validates the
generated scientific documentation, verifies embedded assets byte-for-byte,
and writes the executable checksum.

A local run cannot reproduce every property of a GitHub-hosted Windows image.
The pull-request workflow is therefore the final pre-merge check.

## Recovering from a failed tag build

If a tag build fails before publication:

1. leave the failed GitHub Release absent;
2. fix the problem on a pull request;
3. wait for the pull-request check to pass;
4. merge the fix and wait for the `main` check to pass;
5. only then recreate the failed tag on the corrected `main` commit.

Do not draft a Release manually. A successful tag workflow creates it and
uploads `pasweave.exe` and `pasweave.exe.sha256`.

Before moving any tag, confirm that it has not produced a successful public
release. Successfully published version tags should be treated as immutable.

## Release invariant

The intended sequence is:

```text
pull request green -> merge -> main green -> push tag -> build green -> release
```

If any build stage is red, stop at that stage. Do not advance the release by
manually creating a GitHub Release.
