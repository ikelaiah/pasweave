program test_pasweave;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, FPJSON, JSONParser,
  PasWeave.Comments, PasWeave.Model, PasWeave.Model.JSON, PasWeave.Parser,
  PasWeave.Render.Markdown, PasWeave.Render.HTML,
  PasWeave.Render.HTML.Markdown;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create('test failed: ' + AMessage);
end;

function FindSymbol(AUnit: TDocUnit; const AName: string): TDocSymbol;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AUnit.Symbols.Count - 1 do
    if TDocSymbol(AUnit.Symbols[I]).Name = AName then
      Exit(TDocSymbol(AUnit.Symbols[I]));
end;

function HasDirective(ASymbol: TDocSymbol; const AName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = AName then
      Exit(True);
end;

procedure RunTests;
var
  Project: TDocProject;
  PartialProject: TDocProject;
  AttemptedCount: Integer;
  UnitModel: TDocUnit;
  AddSymbol: TDocSymbol;
  ResetSymbol: TDocSymbol;
  CounterSymbol: TDocSymbol;
  IntegerBoxSymbol: TDocSymbol;
  FirstJSON: UTF8String;
  SecondJSON: UTF8String;
  IndexMarkdown: UTF8String;
  UnitMarkdown: UTF8String;
  SecondUnitMarkdown: UTF8String;
  IndexHTML: UTF8String;
  UnitHTML: UTF8String;
  SecondUnitHTML: UTF8String;
  SearchIndex: UTF8String;
  ParsedJSON: TJSONData;
  DialectProject: TDocProject;
  DialectUnit: TDocUnit;
  DialectSymbol: TDocSymbol;
  MixedSymbol: TDocSymbol;
  CommentStyles: TDocumentationCommentStyles;
  SlashPosition: Integer;
  BracePosition: Integer;
  ParenPosition: Integer;
begin
  Check(TryParseDocumentationCommentStyles('slash, brace,paren',
    CommentStyles), 'combined documentation comment styles should parse');
  Check(CommentStyles = AllDocumentationCommentStyles,
    'combined documentation comment styles should enable every form');
  Check(TryParseDocumentationCommentStyles('ALL', CommentStyles),
    'the all shorthand should be case insensitive');
  Check(CommentStyles = AllDocumentationCommentStyles,
    'the all shorthand should enable every form');
  Check(not TryParseDocumentationCommentStyles('slash,unknown',
    CommentStyles), 'unknown documentation comment styles should fail');
  Check(CommentStyles = [],
    'failed documentation comment parsing should not leave partial styles');
  Check(DocumentationCommentStylesText([dcsBrace, dcsSlash]) =
    'slash,brace', 'documentation comment styles should have stable text');

  Project := BuildProject('tests/fixtures/SimpleUnit.pas',
    'PasWeaveFixture', AttemptedCount);
  try
    Check(AttemptedCount = 1, 'one fixture should be attempted');
    Check(Project.Errors.Count = 0, 'fixture should parse without errors');
    Check(Project.Units.Count = 1, 'fixture should produce one unit');

    UnitModel := TDocUnit(Project.Units[0]);
    Check(UnitModel.Name = 'SimpleUnit', 'unit name should be parsed');
    Check(UnitModel.InterfaceDependencies.IndexOf('Classes') >= 0,
      'interface dependency should be captured');
    Check(UnitModel.InterfaceDependencies.Count = 1,
      'implicit compiler units should not be reported as source dependencies');

    AddSymbol := FindSymbol(UnitModel, 'Add');
    Check(Assigned(AddSymbol), 'Add routine should be in the model');
    Check(AddSymbol.QualifiedName = 'SimpleUnit.Add',
      'routine should have a qualified name');
    Check(Pos('function Add', AddSymbol.DeclarationText) = 1,
      'declaration should include the routine kind and name');
    Check(Pos('routine:simpleunit.add#', AddSymbol.ID) = 1,
      'routine ID should derive from its qualified name and signature');
    Check(AddSymbol.SourceLine > 0, 'source line should be captured');
    Check(AddSymbol.SourceColumn > 0, 'source column should be captured');
    Check(Pos('/// Adds two integer values.', AddSymbol.RawDocumentation) > 0,
      'raw documentation should retain /// syntax');
    Check(Pos('\operatorname{Add}(A, B) = A + B',
      AddSymbol.MarkdownDocumentation) > 0,
      'mathematics should be preserved in Markdown');
    Check(AddSymbol.Directives.Count = 4,
      'structured directives should be extracted');

    ResetSymbol := FindSymbol(UnitModel, 'Reset');
    Check(Assigned(ResetSymbol), 'Reset routine should be in the model');
    Check(ResetSymbol.MarkdownDocumentation = '',
      'Reset should remain undocumented');
    CounterSymbol := FindSymbol(UnitModel, 'TCounter');
    Check(Assigned(CounterSymbol), 'TCounter class should be in the model');
    Check(Pos('TCounter = class', CounterSymbol.DeclarationText) = 1,
      'class declarations should include the type name and class keyword');
    IntegerBoxSymbol := FindSymbol(UnitModel, 'TIntegerBox');
    Check(Assigned(IntegerBoxSymbol),
      'specialized type alias should be in the model');
    Check(IntegerBoxSymbol.DeclarationText =
      'TIntegerBox = specialize TBox<Integer>',
      'specialized type declarations should include their closing bracket');

    FirstJSON := ProjectToJSON(Project);
    SecondJSON := ProjectToJSON(Project);
    Check(FirstJSON = SecondJSON, 'JSON should be deterministic');
    ParsedJSON := GetJSON(FirstJSON);
    try
      Check(ParsedJSON.JSONType = jtObject, 'output should be valid JSON');
      Check(TJSONObject(ParsedJSON).Get('schemaVersion', 0) = 1,
        'JSON should include its schema version');
    finally
      ParsedJSON.Free;
    end;

    IndexMarkdown := RenderMarkdownIndex(Project);
    UnitMarkdown := RenderMarkdownUnit(Project, UnitModel);
    SecondUnitMarkdown := RenderMarkdownUnit(Project, UnitModel);
    Check(UnitMarkdown = SecondUnitMarkdown,
      'Markdown should be deterministic');
    Check(Pos('[SimpleUnit](units/SimpleUnit.md)',
      string(IndexMarkdown)) > 0,
      'project index should link to the unit page');
    Check(Pos('```pascal' + #10 + 'function Add',
      string(UnitMarkdown)) > 0,
      'unit page should contain a fenced Pascal declaration');
    Check(Pos('\operatorname{Add}(A, B) = A + B',
      string(UnitMarkdown)) > 0,
      'unit page should preserve mathematical Markdown');
    Check(Pos('| `A` | First value. |', string(UnitMarkdown)) > 0,
      'unit page should render parameter directives');
    Check(Pos('#### Returns', string(UnitMarkdown)) > 0,
      'unit page should render the returns directive');
    Check(Pos('](#' + MarkdownSymbolAnchor(ResetSymbol) + ')',
      string(UnitMarkdown)) > 0,
      'see directives should link to symbols on the same page');
    Check(Pos('This API symbol has no documentation.',
      string(UnitMarkdown)) > 0,
      'unit page should warn about undocumented API symbols');
    Check(Pos('## Types', string(UnitMarkdown)) > 0,
      'unit page should group public types');
    Check(Pos('## Members', string(UnitMarkdown)) > 0,
      'unit page should group public members');
    Check(Pos('SimpleUnit.TCounter.FValue', string(UnitMarkdown)) = 0,
      'unit page should exclude private members');

    IndexHTML := RenderHTMLIndex(Project);
    UnitHTML := RenderHTMLUnit(Project, UnitModel);
    SecondUnitHTML := RenderHTMLUnit(Project, UnitModel);
    SearchIndex := RenderHTMLSearchIndex(Project);
    Check(UnitHTML = SecondUnitHTML, 'HTML should be deterministic');
    Check(Pos('<!doctype html>', string(IndexHTML)) = 1,
      'HTML index should be a complete document');
    Check(Pos('href="units/SimpleUnit.html"', string(IndexHTML)) > 0,
      'HTML index should link to the unit page');
    Check(Pos('<pre class="declaration"><code class="language-pascal">' +
      #10 + 'function Add', string(UnitHTML)) > 0,
      'HTML unit page should contain an escaped Pascal declaration');
    Check(Pos('TBox&lt;T&gt; = class', string(UnitHTML)) > 0,
      'HTML should escape declaration syntax');
    Check(Pos('data-math-display', string(UnitHTML)) > 0,
      'HTML unit page should identify display mathematics');
    Check(Pos('\operatorname{Add}(A, B) = A + B', string(UnitHTML)) > 0,
      'HTML unit page should preserve mathematical source');
    Check(Pos('href="#' + HTMLSymbolAnchor(ResetSymbol) + '"',
      string(UnitHTML)) > 0,
      'HTML see directives should link to symbols on the same page');
    Check(HTMLSymbolAnchor(ResetSymbol) = MarkdownSymbolAnchor(ResetSymbol),
      'HTML and Markdown should share stable symbol anchors');
    Check(Pos('This API symbol has no documentation.',
      string(UnitHTML)) > 0,
      'HTML should warn about undocumented API symbols');
    Check(Pos('SimpleUnit.TCounter.FValue', string(UnitHTML)) = 0,
      'HTML should exclude private members');
    Check(Pos('window.PASWEAVE_SEARCH_INDEX', string(SearchIndex)) = 1,
      'HTML search index should be an offline JavaScript asset');
    Check(Pos('"qualifiedName" : "SimpleUnit.Reset"',
      string(SearchIndex)) > 0,
      'HTML search index should contain public symbols');
    Check(Pos('&lt;script&gt;',
      string(RenderInlineMarkdown('<script>'))) > 0,
      'HTML Markdown rendering should escape source HTML');
    Check(Pos('href=', string(RenderInlineMarkdown(
      '[unsafe](javascript:alert(1))'))) = 0,
      'HTML Markdown rendering should reject active link schemes');

    WriteMarkdownDocumentation(Project, 'build/test-docs/markdown');
    Check(FileExists('build/test-docs/markdown/index.md'),
      'renderer should write the project index');
    Check(FileExists('build/test-docs/markdown/units/SimpleUnit.md'),
      'renderer should write the unit page');
    WriteHTMLDocumentation(Project, 'build/test-docs/html');
    Check(FileExists('build/test-docs/html/index.html'),
      'HTML renderer should write the project index');
    Check(FileExists('build/test-docs/html/units/SimpleUnit.html'),
      'HTML renderer should write the unit page');
    Check(FileExists('build/test-docs/html/assets/site.css'),
      'HTML renderer should write its stylesheet');
    Check(FileExists('build/test-docs/html/assets/app.js'),
      'HTML renderer should write its application script');
    Check(FileExists('build/test-docs/html/assets/search-index.js'),
      'HTML renderer should write its offline search index');
  finally
    Project.Free;
  end;

  DialectProject := BuildProject(
    'tests/fixtures/comments/CommentDialects.pas',
    'CommentDialectDefaultFixture', AttemptedCount);
  try
    Check(DialectProject.Errors.Count = 0,
      'comment dialect fixture should parse with the default style');
    DialectUnit := TDocUnit(DialectProject.Units[0]);
    Check(FindSymbol(DialectUnit, 'SlashOnly').MarkdownDocumentation =
      'Slash documentation.', 'slash comments should remain the default');
    Check(FindSymbol(DialectUnit, 'BraceOnly').MarkdownDocumentation = '',
      'brace comments should be disabled by default');
    Check(FindSymbol(DialectUnit, 'ParenOnly').MarkdownDocumentation = '',
      'paren comments should be disabled by default');
    Check(FindSymbol(DialectUnit, 'Mixed').MarkdownDocumentation = '',
      'a disabled adjacent form should stop a default slash group');
    Check(FindSymbol(DialectUnit,
      'AfterSlashBlankLine').MarkdownDocumentation = '',
      'a blank line should end default slash documentation association');
  finally
    DialectProject.Free;
  end;

  DialectProject := BuildProject(
    'tests/fixtures/comments/CommentDialects.pas',
    'CommentDialectBraceFixture', AttemptedCount, [dcsBrace]);
  try
    DialectUnit := TDocUnit(DialectProject.Units[0]);
    Check(FindSymbol(DialectUnit, 'BraceOnly').MarkdownDocumentation =
      'Brace documentation.', 'brace-only mode should capture brace comments');
    Check(FindSymbol(DialectUnit, 'BraceOnly').RawDocumentation =
      '{ Brace documentation. }',
      'brace raw documentation should preserve both delimiters');
    Check(FindSymbol(DialectUnit, 'SlashOnly').MarkdownDocumentation = '',
      'brace-only mode should not capture slash comments');
  finally
    DialectProject.Free;
  end;

  DialectProject := BuildProject(
    'tests/fixtures/comments/CommentDialects.pas',
    'CommentDialectParenFixture', AttemptedCount, [dcsParen]);
  try
    DialectUnit := TDocUnit(DialectProject.Units[0]);
    Check(FindSymbol(DialectUnit, 'ParenOnly').MarkdownDocumentation =
      'Paren documentation.', 'paren-only mode should capture paren comments');
    Check(FindSymbol(DialectUnit, 'ParenOnly').RawDocumentation =
      '(* Paren documentation. *)',
      'paren raw documentation should preserve both delimiters');
    Check(FindSymbol(DialectUnit, 'BraceOnly').MarkdownDocumentation = '',
      'paren-only mode should not capture brace comments');
  finally
    DialectProject.Free;
  end;

  DialectProject := BuildProject(
    'tests/fixtures/comments/CommentDialects.pas',
    'CommentDialectAllFixture', AttemptedCount,
    AllDocumentationCommentStyles);
  try
    Check(DialectProject.Errors.Count = 0,
      'comment dialect fixture should parse with every style');
    DialectUnit := TDocUnit(DialectProject.Units[0]);
    MixedSymbol := FindSymbol(DialectUnit, 'Mixed');
    Check(Assigned(MixedSymbol), 'mixed comment declaration should be modeled');
    SlashPosition := Pos('/// Mixed slash summary.',
      MixedSymbol.RawDocumentation);
    BracePosition := Pos('{', MixedSymbol.RawDocumentation);
    ParenPosition := Pos('(*', MixedSymbol.RawDocumentation);
    Check((SlashPosition > 0) and (SlashPosition < BracePosition) and
      (BracePosition < ParenPosition),
      'mixed raw documentation should retain delimiters in source order');
    Check(Copy(MixedSymbol.RawDocumentation,
      Length(MixedSymbol.RawDocumentation) - 1, 2) = '*)',
      'mixed raw documentation should preserve its final paren delimiter');
    Check(Pos('Mixed slash summary.', MixedSymbol.MarkdownDocumentation) > 0,
      'mixed Markdown should include the slash body');
    Check(Pos('Mixed brace detail.', MixedSymbol.MarkdownDocumentation) > 0,
      'mixed Markdown should include the brace body');
    Check(Pos('Mixed paren detail.', MixedSymbol.MarkdownDocumentation) > 0,
      'mixed Markdown should include the paren body');
    Check(Pos('@param', MixedSymbol.MarkdownDocumentation) = 0,
      'structured directives should be removed from mixed Markdown');
    Check((MixedSymbol.Directives.Count = 3) and
      HasDirective(MixedSymbol, 'param') and
      HasDirective(MixedSymbol, 'returns') and
      HasDirective(MixedSymbol, 'since'),
      'structured directives should be extracted across a mixed group');

    Check(FindSymbol(DialectUnit, 'AfterBlankLine').MarkdownDocumentation = '',
      'a blank line should end documentation association');
    Check(FindSymbol(DialectUnit, 'FirstAfterGroup').MarkdownDocumentation =
      'Documentation attached to one declaration.',
      'a group should attach to its immediately following declaration');
    Check(FindSymbol(DialectUnit, 'SecondAfterGroup').MarkdownDocumentation = '',
      'a group should not attach to a second declaration');
    Check(FindSymbol(DialectUnit,
      'BraceDirectiveBarrier').MarkdownDocumentation = '',
      'brace compiler directives should never become documentation');
    Check(FindSymbol(DialectUnit,
      'ParenDirectiveBarrier').MarkdownDocumentation = '',
      'paren compiler directives should never become documentation');

    Check(FindSymbol(DialectUnit,
      'TAfterSectionLabel').MarkdownDocumentation = 'Types',
      'opted-in ordinary section labels should be exposed for audit');
    Check(FindSymbol(DialectUnit,
      'TAfterDisabledCode').MarkdownDocumentation =
      'procedure RemovedRoutine;',
      'opted-in disabled code comments should be exposed for audit');
    Check(FindSymbol(DialectUnit, 'Next').MarkdownDocumentation = '',
      'a trailing comment should not shift to the next declaration');
    DialectSymbol := FindSymbol(DialectUnit, 'FSecret');
    Check(Assigned(DialectSymbol) and
      (DialectSymbol.MarkdownDocumentation = 'Internal storage.'),
      'private declarations should retain documentation in the model');
    Check(Pos('CommentDialects.TVisibilityFixture.FSecret',
      string(RenderHTMLUnit(DialectProject, DialectUnit))) = 0,
      'private declarations should remain excluded from rendered API docs');
    Check(ProjectToJSON(DialectProject) = ProjectToJSON(DialectProject),
      'mixed comment JSON should be deterministic');
  finally
    DialectProject.Free;
  end;

  PartialProject := BuildProject('tests/fixtures/partial',
    'PartialFailureFixture', AttemptedCount);
  try
    Check(AttemptedCount = 2, 'both partial-failure fixtures should be attempted');
    Check(PartialProject.Units.Count = 1,
      'the valid unit should survive another unit failing');
    Check(PartialProject.Errors.Count = 1,
      'the invalid unit should produce one diagnostic');
    Check(TDocUnit(PartialProject.Units[0]).Name = 'GoodUnit',
      'the valid unit should remain in the model');
    Check(ProjectToJSON(PartialProject) <> '',
      'partial failure should still produce JSON');
    Check(Pos('## Build diagnostics',
      string(RenderMarkdownIndex(PartialProject))) > 0,
      'partial failure should appear in the Markdown index');
    Check(Pos('<h2>Diagnostics</h2>',
      string(RenderHTMLIndex(PartialProject))) > 0,
      'partial failure should appear in the HTML index');
  finally
    PartialProject.Free;
  end;
end;

begin
  try
    RunTests;
    WriteLn('All PasWeave tests passed.');
  except
    on E: Exception do
    begin
      WriteLn(StdErr, E.Message);
      Halt(1);
    end;
  end;
end.
