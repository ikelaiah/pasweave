# v0.5.2 task checklist

- [x] A–Z symbol index page derived entirely from the documentation model
- [x] Five category filters (types, routines, members, constants, variables)
- [x] Stable links, letter sections, and no-JavaScript browsing
- [x] Project index reordered to summary, Browse API, units, diagrams, diagnostics
- [x] Persistent Symbols Index header destination on every page
- [x] Keyboard-accessible System/Light/Dark reader theme control
- [x] Inline data-theme bootstrap applied before visible rendering
- [x] Safe persistence fallback when storage is unavailable or rejected
- [x] KaTeX, Mermaid diagrams, native controls, and contrast synchronized
- [x] Validated --project-mark, --theme-accent, --theme-accent-2, --theme-font
- [x] Effective branding tokens recorded additively in api-model.json
- [x] Documented API and scientific sample regeneration including symbols.html
- [x] Latest `mathlib-fp` discovery and determinism audit (175 files, 0 diffs)
- [x] Headless browser checks with clean consoles
- [x] Pages workflow deployed-showcase assertions
- [x] README, detailed docs, changelog, roadmap, and release note
- [x] Version metadata and portable-build default updated to `0.5.2`
- [x] Full suite, builds, deterministic checks, and five-axis review
- [x] No `v0.6.0+` work included

# v0.5.3 task checklist

- [x] Rename visible symbol-browser label to "Symbols Index"
- [x] Keep "A–Z" only in descriptive copy
- [x] Regenerate both examples' HTML goldens
- [x] Focused label assertions in the symbol-index tests
- [x] Version metadata and portable-build default updated to `0.5.3`
- [x] Changelog, roadmap status, release note, PR note, and README updated
- [x] Full suite and production build pass
- [x] No `v0.6.0+` work included

# v0.5.4 task checklist

- [x] Rename "Parsed symbols" card to "Parsed declarations"
- [x] "Public API symbols" equals the A–Z index population (units excluded)
- [x] Coverage and per-unit rows use the indexed population in HTML and Markdown
- [x] Markdown "Generated from N units and M declarations" wording
- [x] Keep the CI coverage metric (PW411) unchanged
- [x] Regenerate both examples' HTML and Markdown goldens
- [x] Focused stats assertions in the symbol-index tests
- [x] Version metadata, portable-build default, and workflow/portable-smoke
      assertions updated to `0.5.4`
- [x] Changelog, roadmap status, release note, PR note, and README updated
- [x] Full suite and production build pass
- [x] No `v0.6.0+` work included

# v0.5.5 task checklist

- [x] Rephrase the project-index hero copy
- [x] Preserve the `&#8211;` en-dash entity
- [x] Focused hero-copy assertion in the symbol-index tests
- [x] Regenerate both examples' HTML goldens
- [x] Version metadata and portable-build default updated to `0.5.5`
- [x] Changelog, release note, PR note, and README updated
- [x] Full suite and production build pass
- [x] No `v0.6.0+` work included

# v0.5.6 task checklist

- [x] Correct symbol-index terminology (no A–Z-only implication)
- [x] Use the six canonical UI strings in the renderer
- [x] Keep the "Symbols Index" heading and nav label
- [x] Do not change symbols.html, anchors, filters, sorting, or `#` grouping
- [x] No unit count or pluralization in the card/introduction
- [x] Focused assertions for all changed user-facing and accessibility text
- [x] Non-letter-symbol coverage (appears, `#` group, stable link)
- [x] Update misleading "A–Z symbol index" phrasing in living docs
- [x] Keep "alphabetical" only for unit sorting / A–Z letter ordering
- [x] Preserve released history, old notes, and completed task records
- [x] Regenerate both examples' HTML goldens
- [x] CHANGELOG Unreleased entry moved into the v0.5.6 section
- [x] Version metadata and portable-build default updated to `0.5.6`
- [x] Full suite and production build pass
- [x] No `v0.6.0+` work included

# v0.6.0 task checklist

- [x] Self-contained SHA-256 implementation with NIST-vector fixtures
- [x] Deterministic input fingerprint over version, options, source files, assets
- [x] Deterministic `manifest.json` (path, SHA-256, size) at the output root
- [x] Skip unchanged parse and render work; `[up-to-date]` exit parity
- [x] Ownership-based stale-output removal; never sweep by extension
- [x] Atomic output writes with manifest written last; interrupted-build recovery
- [x] `--clean` full-rebuild path; clean == incremental byte-for-byte
- [x] Recoverable corrupted-manifest diagnostic (warning + clean rebuild)
- [x] `--verbose` elapsed-time and peak-heap reporting
- [x] Focused incremental fixtures registered in the test suite
- [x] README, detailed docs, changelog, roadmap, and release/PR notes updated
- [x] Version metadata and portable-build default updated to `0.6.0`
- [x] Full suite and production build pass
- [x] No `v0.7.0+` work included




