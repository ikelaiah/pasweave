# Parser integration

PasWeave's first adapter was developed against the installed Free Pascal
3.2.2 `fcl-passrc` sources, not from remembered API names. The relevant
sources are `packages/fcl-passrc/src/pparser.pp`,
`packages/fcl-passrc/src/pastree.pp`, and the bundled
`packages/fcl-passrc/examples/parsepp.pp`.

The concrete integration is:

1. `PParser.ParseSource` accepts an array of compiler-style arguments plus
   target OS and CPU strings and returns a `PasTree.TPasModule`. In FPC 3.2.2,
   `ParseUnit` constructs `TPasModule` itself rather than the also-declared
   `TPasUnitModule`, so the adapter identifies a unit by its populated
   `InterfaceSection`.
2. Parsing requires a `TPasTreeContainer` subclass. PasWeave implements both
   the required filename/line `CreateElement` overload and the virtual
   `TPasSourcePos` overload. The latter retains the column that the base
   overload would otherwise discard.
3. Documentation association is source-backed rather than based on
   `TPasElement.DocComment`. The adapter reads the unit once, uses each tree
   node's declaration line as the boundary, and scans backwards for enabled
   standalone comment forms. This retains exact delimiters, enforces blank-line
   gaps, merges mixed forms in source order, and treats compiler directives as
   barriers. `fcl-passrc` still supplies declaration identity and positions;
   PasWeave is not parsing Pascal declarations itself. The meaning of `///` is
   defined by PasWeave; FPC tokenizes it as an ordinary `//` comment and does
   not classify it as API documentation.
4. `TPasTreeContainer.InterfaceOnly := True` stops before implementation
   parsing. Interface declarations are read from
   `TPasModule.InterfaceSection.Declarations`, and dependencies come from
   `TPasSection.UsesClause`. FPC injects its implicit `System` unit into that
   clause; PasWeave filters it so the model describes source-level
   dependencies.
5. Declaration text starts from the tree node's `GetDeclaration(True)` where
   it is reliable. The adapter reconstructs the declaration categories where
   FPC 3.2.2 returns incomplete syntax, converts supported `PasTree` node
   classes immediately into PasWeave model objects, then frees the FPC tree.
   No `PasTree` type crosses the adapter's public interface.
6. `EParserError` provides filename, row, and column properties. The adapter
   converts it to PasWeave's parser-independent diagnostic type.
7. Class ancestors and implemented interfaces come from
   `TPasClassType.AncestorType` and `TPasClassType.Interfaces`. Generic
   specializations retain their source-like display text while their
   `TPasSpecializeType.DestType` supplies the lookup name. After every unit is
   converted, PasWeave resolves those names against the declaring unit and its
   interface `uses` units and stores only stable model symbol IDs.
8. Source discovery is implemented outside `fcl-passrc`. Directory input is
   top-level-only by default; `--recursive` walks nested directories, then a
   case-insensitive sorted list fixes parse and output order. Repeatable
   root-relative include/exclude globs select `.pas` and `.pp` inputs before
   parsing, with exclusions taking precedence. This keeps project enumeration
   deterministic without asking the parser to guess a build system.

The container's `FindElement` currently returns `nil`, matching the minimal
bundled `parsepp` example. This allows unresolved type references to remain
unresolved in the temporary FPC tree. PasWeave's renderer-independent project
pass resolves explicit class/interface relationships after all source units
have been parsed. It does not search unrelated units globally, parse
declaration strings, or invent a target when a name is ambiguous. Runtime and
package ancestors outside the documented source set therefore remain
explicitly unresolved.

## Known behaviour and uncertainty

- Documentation comment styles are selected per build. `slash` means exactly
  consecutive `///` lines and is the default; it never includes ordinary `//`
  comments. `brace`, `paren`, comma-separated combinations, and `all` are
  explicit opt-ins.
- A blank line, compiler directive, disabled comment form, or source token
  ends a documentation group. The earliest block in a group must begin on an
  otherwise blank source line, preventing a trailing comment on one
  declaration from attaching to the next declaration.
- Comment text is normalised to LF in the model. Raw delimiters are preserved,
  as are Markdown and mathematical source in normalized bodies.
- The source-backed lookup currently uses the main unit file. A declaration
  supplied by an include file may have a correct FPC source position but does
  not yet receive documentation from that include file.
- The adapter supplies `-Mobjfpc`; source mode directives can still change
  scanner mode in the normal FPC way.
- Include paths, defines, and other compiler arguments are not exposed by the
  CLI yet.
- Lazarus `.lpi` and `.lpk` files are not read yet because PasWeave cannot
  faithfully represent all of their compiler settings.
- The mapping covers the requested initial symbol categories, but unusual
  generic, helper, Objective-C, and compiler-extension nodes have not yet been
  validated with fixtures.
- Only the interface is parsed. Syntax errors solely in an implementation
  section are therefore intentionally outside this iteration's diagnostics.
- The adapter was verified with FPC 3.2.2. Compatibility with FPC trunk must
  be tested rather than assumed.

## Declaration reconstruction in FPC 3.2.2

Real-world validation exposed several declaration-text gaps in the installed
tree:

- `TPasClassType` does not override `GetDeclaration`, so it returns only its
  name rather than a class or interface header.
- `TPasSpecializeType.GetDeclaration` emits `<` but does not append `>`.
  Generic template parameters also render empty when requested through
  `TPasElement.GetDeclaration(False)`.

PasWeave reconstructs compact class, interface, record, and specialization
headers from the typed tree fields. It also reconstructs affected procedure
and property signatures with their typed arguments and result types. Members
are represented as separate symbols, so compact `class ... end` and
`record ... end` headers avoid duplicating entire member lists in every type
declaration.
