# Vendored Mermaid assets

This directory contains the unmodified Mermaid Tiny browser bundle from
Mermaid 11.16.0, downloaded from the official `@mermaid-js/tiny@11.16.0` npm
package.

Upstream: <https://github.com/mermaid-js/mermaid>

Downloaded npm tarball SHA-256:

```text
7F78BBF73C5B7321210257CFFB5459CD55530C07405B14351817FD43655FE101
```

Imported-file SHA-256:

```text
mermaid.tiny.js  A1BC2282B3D935693780F77931382C517E72EB72FF3427752CBB29941DE11BEE
```

Mermaid Tiny is used because it includes flowchart support in one browser
file without lazy-loaded diagram chunks. PasWeave copies the runtime and
license into each generated HTML site and never loads Mermaid from a CDN.

Mermaid is distributed under the MIT License. Its unmodified license text is
in [LICENSE](LICENSE). This notice applies only to the vendored Mermaid files
and does not select or alter a license for PasWeave itself.
