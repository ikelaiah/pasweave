# PasWeave v0.5.1

PasWeave v0.5.1 makes generated unit pages easy to traverse directly. Readers
can switch units or jump to the current unit's symbol categories without
returning to the API index or opening global search.

Highlights:

- a native **Switch unit** disclosure on every generated HTML unit page;
- all units linked directly in deterministic alphabetical order, so any unit
  is reachable from another in two actions even without JavaScript;
- local filtering with a polite match count, ArrowUp/ArrowDown movement,
  Escape focus restoration, and visible focus;
- present-only **On this page** links for Types, Routines, Members, and
  Constants and variables;
- height-bounded large-project navigation and responsive desktop, tablet, and
  phone layouts; and
- updated documented/scientific examples plus Pages workflow assertions before
  upload and after deployment.

The release preserves existing unit filenames, overload-aware symbol anchors,
source links, the API index's browse-all role, the search-index schema, and the
scope of dependency and type-relationship diagrams. It adds no runtime
dependency. With JavaScript disabled, the complete native unit list and all
category links remain usable; filtering and global symbol search require the
local application script.

Validation includes the complete FPC 3.2.2 suite, deterministic checked-in
examples, isolated Chrome checks at 1280 and 390 CSS pixels, keyboard and
no-JavaScript interaction, and a clean console. Two builds of the latest
50-unit `mathlib-fp` commit produced 2,978 symbols, 2,707 search entries, 174
identical generated files, zero errors, and zero unit-navigation audit
failures. Its real-browser check passed bounded 50-unit scrolling, filtering,
keyboard focus, and responsive layout.

See [navigation and source traceability](docs/navigation-and-source-traceability.md)
and the [HTML renderer guide](docs/html-renderer.md) for behavior, fallback,
and limitations. The public GitHub Pages smoke check is the final post-merge
release gate because the deployed showcase cannot contain this branch before
it reaches `main`.
