# Vendored KaTeX assets

This directory contains the unmodified browser distribution from KaTeX
0.18.1, downloaded from the official `katex@0.18.1` npm package.

Upstream: <https://github.com/KaTeX/KaTeX>

Downloaded npm tarball SHA-256:

```text
7E6100B7FE6439BA91D918D8CB2873171A9FDEC979281D508959CF5F7DBA1DA8
```

Imported-file SHA-256 values:

```text
katex.min.js   68B9115510B8CEDB9909A10DE7799C94C0707481296F755C0A8888CB8FCDE216
katex.min.css  0FB711C9C74CB1718661933948B653FBC09A627DA5DDE8926B4D10585370993E
```

`katex.min.css` references all 60 files beneath `fonts/`, so the TTF, WOFF,
and WOFF2 variants are kept together. PasWeave copies this directory into each
generated HTML site and never loads KaTeX from a CDN.

KaTeX is distributed under the MIT License. Its unmodified license text is in
[LICENSE](LICENSE). This notice applies only to the vendored KaTeX files and
does not select or alter a license for PasWeave itself.
