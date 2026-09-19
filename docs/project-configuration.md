# Project configuration

A project can commit one `pasweave.json` file and reproduce a build without
restating stable options on every command line:

~~~text
pasweave build --config=pasweave.json
~~~

The file is declarative data only. It cannot run scripts, load plugins, fetch
remote resources, or expand environment variables; those stay out of scope
through `v1.0.0`.

## Precedence

Values are applied in this order, lowest first:

1. documented defaults (`comments: slash`, `visibility: public`, output
   `build/docs`, failure threshold `error`);
2. the project configuration file;
3. explicit command-line options.

Command-line options therefore always win. For repeatable options
(`include`, `exclude`, `unitPaths`, `includePaths`, `defines`,
`packagePaths`), the first command-line instance replaces the configured list
rather than appending to it. `--no-recursive` overrides
`discovery.recursive: true`, and `--visibility` overrides the configured
policy.

## Paths

Every path in the file is relative to the directory containing
`pasweave.json`:

- `source` (input unit, directory, or Lazarus project/package);
- `output` (generated documentation root);
- `compiler.unitPaths`, `compiler.includePaths`, `compiler.packagePaths`.

Absolute paths and parent traversal that escapes the configuration directory
are rejected, so a committed configuration stays portable and cannot read or
write outside the project.

## Schema (version 1)

Only the listed keys are accepted at each level; unknown keys and wrong types
are errors.

~~~json
{
  "version": 1,
  "source": "src",
  "output": "build/docs",
  "comments": "slash",
  "visibility": "public",
  "project": {
    "name": "My API",
    "mark": "API",
    "repositoryUrl": "https://github.com/example/project",
    "sourceLinkTemplate": "blob/main/{path}#L{line}",
    "theme": {
      "accent": "#7c3aed",
      "accent2": "#0e7490",
      "font": "Avenir Next"
    }
  },
  "discovery": {
    "recursive": true,
    "include": ["src/**"],
    "exclude": ["generated/**", "vendor/**"]
  },
  "compiler": {
    "unitPaths": ["packages/core/src"],
    "includePaths": ["include"],
    "defines": ["USE_FAST_MATH"],
    "targetOs": "linux",
    "targetCpu": "aarch64",
    "buildMode": "Release",
    "packagePaths": ["packages"]
  },
  "coverage": {
    "minimum": 90,
    "failOn": "warning"
  }
}
~~~

| Key | Meaning |
|---|---|
| `version` | Required; must be `1`. |
| `source` | Input to document when no positional input is given. |
| `output` | Output root; default `build/docs`. |
| `comments` | Comment styles: `slash`, `brace`, `paren`, comma-separated, or `all`. |
| `visibility` | `public` (default) documents the public API only; `all` also documents private and strict-private declarations. |
| `project.name` | Display title; otherwise derived from the input. |
| `project.mark` | 1–4 character header mark. |
| `project.repositoryUrl` | Repository origin; must be paired with `project.sourceLinkTemplate`. |
| `project.sourceLinkTemplate` | Repository-relative template with `{path}` and `{line}`. |
| `project.theme.*` | Accent colors and body font; same validation as the CLI options. |
| `discovery.recursive` | Enables recursive discovery; `--no-recursive` overrides it. |
| `discovery.include` / `exclude` | Repeatable globs with the same rules as `--include`/`--exclude`; exclusions win. |
| `compiler.unitPaths` / `includePaths` | Search paths, validated to exist. |
| `compiler.defines` | Conditional defines; plain Pascal identifiers. |
| `compiler.targetOs` / `targetCpu` | Normalized like `--target-os`/`--target-cpu`. |
| `compiler.buildMode` | Required for `.lpi` inputs when no default mode is unique. |
| `compiler.packagePaths` | Additional Lazarus package roots. |
| `coverage.minimum` | Documentation coverage gate (`0`–`100`). |
| `coverage.failOn` | `error` (default) or `warning`. |

## Reproducibility

The effective normalized configuration is written to `api-model.json` as
`configuration`, alongside `configurationSource` (the file path, or empty when
none was used). The configuration file is also part of the incremental build
fingerprint, so editing it invalidates cached output. Combined with
`manifest.json`, a recorded build can be reproduced from the same commit,
configuration file, and command line.

## Validation and errors

Configuration problems are input errors: the CLI exits with code `2` and
prints a message naming the offending key, for example
`unknown configuration key: project.naem` or
`compiler.targetOs is not a supported FPC target: plan9`. Invalid JSON, a
missing file, an unsupported `version`, absolute paths, and escaping path
traversal are rejected the same way.

`pasweave build --help` lists `--config`, `--visibility`, and `--no-recursive`.

## Examples

Document a directory with committed sources and links:

~~~text
pasweave build --config=pasweave.json
~~~

Override the title for one run without editing the file:

~~~text
pasweave build --config=pasweave.json --project-name "Nightly API"
~~~

Document internal declarations too (the private members are rendered, and
coverage follows the same population):

~~~text
pasweave build --config=pasweave.json --visibility=all --clean
~~~
