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

procedure CheckSearchContracts;
var
  AddPosition: Integer;
  AttemptedCount: Integer;
  IndexHTML: UTF8String;
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

  Stylesheet := HTMLStylesheet;
  Check(Pos(':focus-visible', string(Stylesheet)) > 0,
    'interactive search and navigation controls should have visible focus');
  Check(Pos('@media (max-width: 480px)', string(Stylesheet)) > 0,
    'the generated site should define a phone-width layout');
  Check(Pos('.stats { grid-template-columns: 1fr; }',
    string(Stylesheet)) > 0,
    'phone-width statistics should not force horizontal overflow');
end;

procedure RunNavigationTests;
begin
  CheckSourceLinkConfiguration;
  CheckRenderedSourceLinks;
  CheckRelationshipNavigation;
  CheckSearchContracts;
end;

end.
