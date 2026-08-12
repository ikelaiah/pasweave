# ADR-0002: Constrain source links to a repository-relative template

## Status

Accepted

## Date

2026-08-12

## Context

Source links combine parsed local filenames with user configuration and are
emitted into both HTML and Markdown. Accepting an arbitrary complete URL
template would allow a path to escape the intended repository, introduce
renderer-specific escaping rules, or substitute non-deterministic values such
as host paths and timestamps. Guessing GitHub-specific URLs from one base would
exclude other repository hosts and branches.

The parser already exposes normalized source-root-relative filenames and
positive declaration lines in the independent model. The renderers already
share stable symbol identities but require different generated page routes.

## Decision

Store a normalized HTTP(S) repository base and a validated relative template
on `TDocProject`. Require exactly one `{path}` and `{line}` placeholder, with
the line placeholder in one URL fragment. Reject absolute templates, query
strings, path traversal, unknown placeholders, malformed bases, and unsafe
source filenames before expansion.

Generate the complete external URL in one renderer-neutral helper. HTML and
Markdown render that value with their normal output escaping. Keep repository
configuration optional and additive in JSON schema version 1.

## Alternatives considered

### Accept an arbitrary absolute URL template

Rejected because the template could silently replace or escape the configured
repository origin and would make the base URL meaningless.

### Infer GitHub `blob/<branch>` URLs automatically

Rejected because repository hosts, branch names, monorepo prefixes, and line
fragment syntax are project choices. An explicit constrained template handles
those choices without host-specific code.

### Build source links independently in each renderer

Rejected because Markdown and HTML could normalize or reject the same source
path differently. Source identity and safety belong before presentation.

## Consequences

- Projects must provide both CLI values explicitly until project
  configuration is added in a later milestone.
- A template can prefix a source root located below the repository root and
  can pin a branch, tag, or commit.
- Arbitrary query-based repository viewers are not supported by the v0.5.0
  contract.
- Source links cannot incorporate time, environment variables, absolute host
  paths, or other non-deterministic values.
- Unit routes and symbol anchors remain unchanged because external source URLs
  are independent of generated-documentation routes.
