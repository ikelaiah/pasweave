unit PasWeave.NavigationTests;

{$mode objfpc}{$H+}

interface

procedure RunNavigationTests;

implementation

uses
  SysUtils, PasWeave.Model, PasWeave.Model.JSON, PasWeave.Parser,
  PasWeave.Render.HTML, PasWeave.Render.Markdown, PasWeave.SourceLinks;

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
  CheckRejected('https://example.test/repo', '../src/{path}#L{line}',
    'a parent-traversing template');
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

procedure RunNavigationTests;
begin
  CheckSourceLinkConfiguration;
  CheckRenderedSourceLinks;
end;

end.
