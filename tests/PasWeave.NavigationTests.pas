unit PasWeave.NavigationTests;

{$mode objfpc}{$H+}

interface

procedure RunNavigationTests;

implementation

uses
  SysUtils, PasWeave.Model, PasWeave.Model.JSON, PasWeave.Parser,
  PasWeave.Render.HTML, PasWeave.Render.HTML.Assets,
  PasWeave.Render.Markdown, PasWeave.SourceLinks;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create('test failed: ' + AMessage);
end;

procedure CheckRejected(const ARepositoryURL, ATemplate,
  ADescription: string);
var
  Project: TDocProject;
  ErrorMessage: string;
begin
  Project := TDocProject.Create;
  try
    Check(not TryConfigureSourceLinks(Project, ARepositoryURL, ATemplate,
      ErrorMessage), ADescription + ' should be rejected');
    Check(ErrorMessage <> '', ADescription + ' should explain the rejection');
    Check((Project.RepositoryURL = '') and (Project.SourceLinkTemplate = ''),
      ADescription + ' should not partially configure the project');
  finally
    Project.Free;
  end;
end;

procedure CheckSourceLinkConfiguration;
var
  Project: TDocProject;
  ErrorMessage: string;
  FirstURL: string;
  SecondURL: string;
begin
  Project := TDocProject.Create;
  try
    Check(TryConfigureSourceLinks(Project,
      'https://github.com/ikelaiah/pasweave/',
      'blob/main/{path}#L{line}', ErrorMessage),
      'a deterministic repository-relative source template should be accepted');
    Check(ErrorMessage = '', 'accepted source-link configuration has no error');
    Check(Project.RepositoryURL = 'https://github.com/ikelaiah/pasweave',
      'repository URL should have a normalized trailing separator');
    Check(Project.SourceLinkTemplate = 'blob/main/{path}#L{line}',
      'source-link template should be retained verbatim after validation');

    FirstURL := SourceLinkURL(Project,
      'src\model\Name With Space.pas', 42);
    SecondURL := SourceLinkURL(Project,
      'src/model/Name With Space.pas', 42);
    Check(FirstURL =
      'https://github.com/ikelaiah/pasweave/blob/main/' +
      'src/model/Name%20With%20Space.pas#L42',
      'source links should be root-relative, URL encoded, and line aware: ' +
      FirstURL);
    Check(SecondURL = FirstURL,
      'source-link output should be independent of host path separators');
    Check(SourceLinkURL(Project, '../secret.pas', 1) = '',
      'source paths must not escape the configured repository');
    Check(SourceLinkURL(Project, '/absolute.pas', 1) = '',
      'absolute source paths must not produce repository links');
    Check(SourceLinkURL(Project, 'src/Unit.pas', 0) = '',
      'source links require a known positive source line');
  finally
    Project.Free;
  end;

  CheckRejected('', 'blob/main/{path}#L{line}',
    'a template without a repository URL');
  CheckRejected('https://github.com/ikelaiah/pasweave', '',
    'a repository URL without a template');
  CheckRejected('file:///tmp/pasweave', 'blob/main/{path}#L{line}',
    'a non-HTTP repository URL');
  CheckRejected('https://example.test/repo?ref=main',
    'src/{path}#L{line}', 'a repository URL with a query');
  CheckRejected('https://example.test/repo#readme',
    'src/{path}#L{line}', 'a repository URL with a fragment');
  CheckRejected('https://example.test/owner/repo/../other',
    'src/{path}#L{line}', 'a parent-traversing repository URL');
  CheckRejected('https://example.test/owner/%2e%2e/other',
    'src/{path}#L{line}', 'a percent-encoded traversing repository URL');
  CheckRejected('https://example.test/repo', '../src/{path}#L{line}',
    'a parent-traversing template');
  CheckRejected('https://example.test/repo',
    'blob/%2e%2e/{path}#L{line}', 'a percent-encoded traversing template');
  CheckRejected('https://example.test/repo',
    'blob%2f..%2fmain/{path}#L{line}',
    'a percent-encoded path-separator template');
  CheckRejected('https://example.test/repo',
    'https://attacker.test/{path}#L{line}', 'an absolute template');
  CheckRejected('https://example.test/repo', 'src/{path}',
    'a template without line information');
  CheckRejected('https://example.test/repo', 'src/file.pas#L{line}',
    'a template without the source path');
  CheckRejected('https://example.test/repo',
    'src/{path}#L{line}-{timestamp}', 'a template with an unknown placeholder');
end;

function FindSymbol(AUnit: TDocUnit; const AName: string): TDocSymbol;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AUnit.Symbols.Count - 1 do
    if SameText(TDocSymbol(AUnit.Symbols[I]).Name, AName) then
      Exit(TDocSymbol(AUnit.Symbols[I]));
end;

function FindUnit(AProject: TDocProject; const AName: string): TDocUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    if SameText(TDocUnit(AProject.Units[I]).Name, AName) then
      Exit(TDocUnit(AProject.Units[I]));
end;

procedure CheckRenderedSourceLinks;
var
  AddSymbol: TDocSymbol;
  AttemptedCount: Integer;
  ErrorMessage: string;
  HTML: UTF8String;
  JSON: UTF8String;
  Markdown: UTF8String;
  Project: TDocProject;
  SymbolURL: string;
  UnitModel: TDocUnit;
  UnitSymbol: TDocSymbol;
  UnitURL: string;
begin
  Project := BuildProject('tests/fixtures/SimpleUnit.pas',
    'Source links', AttemptedCount);
  try
    Check(TryConfigureSourceLinks(Project,
      'https://github.com/ikelaiah/pasweave',
      'blob/main/{path}#L{line}', ErrorMessage),
      'the renderer fixture source-link configuration should be valid');
    Check((AttemptedCount = 1) and (Project.Units.Count = 1),
      'the source-link renderer fixture should parse one unit');
    UnitModel := TDocUnit(Project.Units[0]);
    UnitSymbol := FindSymbol(UnitModel, UnitModel.Name);
    AddSymbol := FindSymbol(UnitModel, 'Add');
    Check(Assigned(UnitSymbol) and Assigned(AddSymbol),
      'source-link tests require the unit and Add symbols');
    UnitURL := SourceLinkURL(Project, UnitModel.SourceFilename,
      UnitSymbol.SourceLine);
    SymbolURL := SourceLinkURL(Project, AddSymbol.SourceFilename,
      AddSymbol.SourceLine);

    Markdown := RenderMarkdownUnit(Project, UnitModel);
    HTML := RenderHTMLUnit(Project, UnitModel);
    Check(Pos('](' + UnitURL + ')', string(Markdown)) > 0,
      'Markdown unit source should link to its repository line');
    Check(Pos('](' + SymbolURL + ')', string(Markdown)) > 0,
      'Markdown symbol source should link to its repository line');
    Check(Pos('href="' + UnitURL + '"', string(HTML)) > 0,
      'HTML unit source should link to its repository line');
    Check(Pos('href="' + SymbolURL + '"', string(HTML)) > 0,
      'HTML symbol source should link to its repository line');

    JSON := ProjectToJSON(Project);
    Check(Pos('"repositoryUrl" : "https://github.com/ikelaiah/pasweave"',
      string(JSON)) > 0,
      'JSON should expose the normalized source repository URL');
    Check(Pos('"sourceLinkTemplate" : "blob/main/{path}#L{line}"',
      string(JSON)) > 0,
      'JSON should expose the deterministic source-link template');
  finally
    Project.Free;
  end;
end;

procedure CheckRelationshipNavigation;
var
  AttemptedCount: Integer;
  BaseSymbol: TDocSymbol;
  BaseUnit: TDocUnit;
  ChildSymbol: TDocSymbol;
  ImplementationUnit: TDocUnit;
  HTML: UTF8String;
  Markdown: UTF8String;
  Project: TDocProject;
begin
  Project := BuildProject('tests/fixtures/relationships',
    'Relationship navigation', AttemptedCount);
  try
    BaseUnit := FindUnit(Project, 'RelationshipBase');
    ImplementationUnit := FindUnit(Project, 'RelationshipImplementations');
    Check(Assigned(BaseUnit) and Assigned(ImplementationUnit),
      'relationship navigation requires both fixture units');
    BaseSymbol := FindSymbol(BaseUnit, 'TBase');
    ChildSymbol := FindSymbol(ImplementationUnit, 'TChild');
    Check(Assigned(BaseSymbol) and Assigned(ChildSymbol),
      'relationship navigation requires source and target types');

    Markdown := RenderMarkdownUnit(Project, ImplementationUnit);
    HTML := RenderHTMLUnit(Project, ImplementationUnit);
    Check(Pos('RelationshipBase.md#' + MarkdownSymbolAnchor(BaseSymbol),
      string(Markdown)) > 0,
      'Markdown should link a resolved cross-unit type relationship');
    Check(Pos('RelationshipBase.html#' + HTMLSymbolAnchor(BaseSymbol),
      string(HTML)) > 0,
      'HTML should link a resolved cross-unit type relationship');
    Check(Pos('`TMissingBase`', string(Markdown)) > 0,
      'Markdown should preserve an unresolved relationship as plain code');
    Check(Pos('<code>TMissingBase</code>', string(HTML)) > 0,
      'HTML should preserve an unresolved relationship as plain code');
  finally
    Project.Free;
  end;
end;

procedure CheckUnitPageNavigation;
var
  AttemptedCount: Integer;
  ConsumerPosition: Integer;
  CoreHTML: UTF8String;
  CorePosition: Integer;
  CoreUnit: TDocUnit;
  I: Integer;
  IndependentHTML: UTF8String;
  IndependentPosition: Integer;
  IndependentUnit: TDocUnit;
  LeafHTML: UTF8String;
  LeafPosition: Integer;
  LeafUnit: TDocUnit;
  Project: TDocProject;
  UnitHTML: UTF8String;
  UnitModel: TDocUnit;
begin
  Project := BuildProject('tests/fixtures/dependencies',
    'Unit page navigation', AttemptedCount);
  try
    Check((AttemptedCount = 4) and (Project.Units.Count = 4),
      'unit navigation requires all four dependency fixtures');
    CoreUnit := FindUnit(Project, 'DependencyCore');
    LeafUnit := FindUnit(Project, 'DependencyLeaf');
    IndependentUnit := FindUnit(Project, 'IndependentUnit');
    Check(Assigned(CoreUnit) and Assigned(LeafUnit) and
      Assigned(IndependentUnit),
      'unit navigation requires the type, routine, and value fixtures');

    for I := 0 to Project.Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Project.Units[I]);
      UnitHTML := RenderHTMLUnit(Project, UnitModel);
      Check(Pos('<details class="unit-switcher" data-unit-switcher>',
        string(UnitHTML)) > 0,
        'every unit page should expose the native unit switcher');
      Check(Pos('data-unit-switcher-filter', string(UnitHTML)) > 0,
        'every unit switcher should expose its local search field');
      Check(Pos('href="DependencyConsumer.html"', string(UnitHTML)) > 0,
        'every unit page should directly link DependencyConsumer');
      Check(Pos('href="DependencyCore.html"', string(UnitHTML)) > 0,
        'every unit page should directly link DependencyCore');
      Check(Pos('href="DependencyLeaf.html"', string(UnitHTML)) > 0,
        'every unit page should directly link DependencyLeaf');
      Check(Pos('href="IndependentUnit.html"', string(UnitHTML)) > 0,
        'every unit page should directly link IndependentUnit');
      Check(Pos('href="' + HTMLUnitFilename(UnitModel) +
        '" aria-current="page"', string(UnitHTML)) > 0,
        'the current unit link should expose page state');
      Check(Pos('href="../index.html">API index</a>',
        string(UnitHTML)) > 0,
        'the API index should remain the canonical browse-all destination');
    end;

    LeafHTML := RenderHTMLUnit(Project, LeafUnit);
    ConsumerPosition := Pos('href="DependencyConsumer.html"',
      string(LeafHTML));
    CorePosition := Pos('href="DependencyCore.html"', string(LeafHTML));
    LeafPosition := Pos('href="DependencyLeaf.html"', string(LeafHTML));
    IndependentPosition := Pos('href="IndependentUnit.html"',
      string(LeafHTML));
    Check((ConsumerPosition > 0) and (CorePosition > ConsumerPosition) and
      (LeafPosition > CorePosition) and
      (IndependentPosition > LeafPosition),
      'the switcher should list units in deterministic alphabetical order');
    Check(Pos('<nav class="page-navigator" aria-label="On this page">',
      string(LeafHTML)) > 0,
      'unit pages should expose a labelled on-page navigator');
    Check(Pos('href="#routines">Routines</a>', string(LeafHTML)) > 0,
      'the routine fixture should link its rendered routine group');
    Check(Pos('href="#types">Types</a>', string(LeafHTML)) = 0,
      'the routine fixture should not link an absent type group');
    Check(Pos('href="#members">Members</a>', string(LeafHTML)) = 0,
      'the routine fixture should not link an absent member group');
    Check(Pos('href="#values">Constants and variables</a>',
      string(LeafHTML)) = 0,
      'the routine fixture should not link an absent value group');

    CoreHTML := RenderHTMLUnit(Project, CoreUnit);
    Check(Pos('href="#types">Types</a>', string(CoreHTML)) > 0,
      'the type fixture should link its rendered type group');
    Check(Pos('href="#routines">Routines</a>', string(CoreHTML)) = 0,
      'the type fixture should not link an absent routine group');

    IndependentHTML := RenderHTMLUnit(Project, IndependentUnit);
    Check(Pos('href="#values">Constants and variables</a>',
      string(IndependentHTML)) > 0,
      'the value fixture should link its rendered value group');
    Check(HTMLUnitFilename(LeafUnit) = 'DependencyLeaf.html',
      'navigation polish must preserve stable unit filenames');
  finally
    Project.Free;
  end;
end;

procedure CheckSearchContracts;
var
  AddPosition: Integer;
  AttemptedCount: Integer;
  IndexHTML: UTF8String;
  MemberPosition: Integer;
  ParentPosition: Integer;
  Project: TDocProject;
  Script: UTF8String;
  SearchIndex: UTF8String;
  Stylesheet: UTF8String;
  UnitPosition: Integer;
begin
  Project := BuildProject('tests/fixtures/SimpleUnit.pas',
    'Search filters', AttemptedCount);
  try
    IndexHTML := RenderHTMLIndex(Project);
    SearchIndex := RenderHTMLSearchIndex(Project);
    Stylesheet := HTMLStylesheet(Project);
    Check(Pos('data-search-unit', string(IndexHTML)) > 0,
      'search should expose a unit filter');
    Check(Pos('data-search-kind', string(IndexHTML)) > 0,
      'search should expose a symbol-kind filter');
    Check(Pos('data-search-visibility', string(IndexHTML)) > 0,
      'search should expose a visibility filter');
    Check(Pos('data-search-documentation', string(IndexHTML)) > 0,
      'search should expose a documentation-status filter');
    Check(Pos('role="status" aria-live="polite"', string(IndexHTML)) > 0,
      'search result changes should be announced politely');
    Check(Pos('"visibility" : "public"', string(SearchIndex)) > 0,
      'the offline search index should include symbol visibility');
    Check(Pos('"documented" : true', string(SearchIndex)) > 0,
      'the offline search index should identify documented symbols');
    Check(Pos('"documented" : false', string(SearchIndex)) > 0,
      'the offline search index should identify undocumented symbols');
    AddPosition := Pos('"name" : "Add"', string(SearchIndex));
    UnitPosition := Pos('"name" : "SimpleUnit"', string(SearchIndex));
    Check((AddPosition > 0) and (UnitPosition > AddPosition),
      'search ordering should place API symbols before their unit entry ' +
      'on every host platform');
    MemberPosition := Pos(
      '"qualifiedName" : "SimpleUnit.TCounter.GetValue"',
      string(SearchIndex));
    ParentPosition := Pos('"qualifiedName" : "SimpleUnit.TCounter"',
      string(SearchIndex));
    Check((MemberPosition > 0) and (ParentPosition > MemberPosition),
      'search ordering should place a member before its prefix parent ' +
      'on every host platform');
  finally
    Project.Free;
  end;

  Script := HTMLApplicationScript;
  Check(Pos('item.visibility', string(Script)) > 0,
    'offline search should apply the visibility filter');
  Check(Pos('item.documented', string(Script)) > 0,
    'offline search should apply the documentation-status filter');
  Check(Pos('event.key === "ArrowDown"', string(Script)) > 0,
    'search should move forward through results with ArrowDown');
  Check(Pos('event.key === "ArrowUp"', string(Script)) > 0,
    'search should move backward through results with ArrowUp');
  Check(Pos('.focus()', string(Script)) > 0,
    'search keyboard navigation should move browser focus');
  Check(Pos('No symbols match the current search and filters.',
    string(Script)) > 0,
    'search should provide a useful filtered empty state');
  Check(Pos('[data-unit-switcher]', string(Script)) > 0,
    'unit navigation should be progressively enhanced when present');
  Check(Pos('[data-unit-switcher-filter]', string(Script)) > 0,
    'unit navigation should expose client-side filtering');
  Check(Pos('item.hidden =', string(Script)) > 0,
    'unit filtering should preserve the native link list and hide mismatches');
  Check(Pos('No units match', string(Script)) > 0,
    'unit filtering should announce a useful empty state');
  Check(Pos('moveUnitFocus', string(Script)) > 0,
    'unit navigation should support arrow-key focus movement');
  Check(Pos('unitSwitcher.open = false', string(Script)) > 0,
    'Escape should close the unit switcher');

  Stylesheet := HTMLStylesheet(Project);
  Check(Pos(':focus-visible', string(Stylesheet)) > 0,
    'interactive search and navigation controls should have visible focus');
  Check(Pos('@media (max-width: 480px)', string(Stylesheet)) > 0,
    'the generated site should define a phone-width layout');
  Check(Pos('.stats { grid-template-columns: 1fr; }',
    string(Stylesheet)) > 0,
    'phone-width statistics should not force horizontal overflow');
  Check(Pos('.unit-switcher-panel {', string(Stylesheet)) > 0,
    'the unit switcher should have a distinct, usable panel');
  Check(Pos('.unit-switcher summary::before { content: "\25B8";',
    string(Stylesheet)) > 0,
    'the styled switcher should retain a visible disclosure indicator');
  Check(Pos('.unit-switcher[open] summary::before { ' +
    'transform: rotate(90deg); }',
    string(Stylesheet)) > 0,
    'the disclosure indicator should expose the open state');
  Check(Pos('.unit-switcher-list {', string(Stylesheet)) > 0,
    'the unit link list should have dedicated layout rules');
  Check(Pos('overflow-y: auto', string(Stylesheet)) > 0,
    'large projects should keep the unit list within the viewport');
  Check(Pos('.page-navigator {', string(Stylesheet)) > 0,
    'symbol categories should have a compact on-page navigator');
  Check(Pos('.symbol-group { scroll-margin-top:', string(Stylesheet)) > 0,
    'category links should account for the sticky site header');
  Check(Pos('  .unit-navigation { grid-template-columns: 1fr; }',
    string(Stylesheet)) > 0,
    'unit navigation should stack at narrow widths');
  Check(Pos('  .unit-switcher-panel { position: static;',
    string(Stylesheet)) > 0,
    'the switcher panel should stay within a phone viewport');
end;

procedure RunNavigationTests;
begin
  CheckSourceLinkConfiguration;
  CheckRenderedSourceLinks;
  CheckRelationshipNavigation;
  CheckUnitPageNavigation;
  CheckSearchContracts;
end;

end.
