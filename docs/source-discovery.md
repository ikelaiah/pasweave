# Source discovery

PasWeave accepts either one Pascal unit or a source directory. A directory is
searched only at its top level by default, preserving the behavior of earlier
releases. Add `--recursive` when nested source directories are intentional.

```text
pasweave build src --recursive
```

Directory discovery admits only `.pas` and `.pp` files. Candidate paths are
normalized to `/`, compared case-insensitively, and sorted before parsing so
filesystem enumeration order cannot change the generated model.

## Include and exclude globs

`--include` and `--exclude` may each be repeated. Both `--option=value` and
`--option value` forms are accepted. Filters apply to the top-level candidates
even when recursion is not enabled.

```text
pasweave build src --recursive --include=library/** --exclude=library/generated/** --exclude=tests --exclude=vendor/**
```

Patterns use these rules:

- patterns are relative to the supplied source directory;
- matching is case-insensitive;
- `*` matches zero or more characters inside one path segment;
- `?` matches exactly one character inside one path segment;
- `**` as a complete path segment matches across directories;
- a pattern containing `/` matches the complete root-relative path;
- a pattern without `/` matches a candidate file's basename at any depth and,
  for exclusions, also matches directory basenames;
- no include patterns means every discovered `.pas` and `.pp` file is
  included unless excluded;
- when both sets match, exclusion wins;
- matching excluded directories are not traversed.

Include filters do not add other extensions: a pattern such as `**/*` still
selects only `.pas` and `.pp` files. Empty patterns, absolute paths, and any
pattern containing a `..` path segment are rejected rather than allowed to
escape the source root. A build that matches no Pascal units is an input
error.

Discovery options apply only to directory input. Supplying `--recursive`,
`--include`, or `--exclude` with an explicit source file is rejected because
there is no discovery set to filter.

PasWeave also interprets Lazarus `.lpi` and `.lpk` files. Unit paths, include
paths, conditional defines, and target OS/CPU settings can be supplied
manually as described in [compiler-aware parsing](compiler-aware-parsing.md),
or imported from project/package files as described in
[Lazarus project and package inputs](lazarus-projects.md).
