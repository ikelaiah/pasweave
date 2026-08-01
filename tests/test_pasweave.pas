program test_pasweave;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, FPJSON, JSONParser,
  PasWeave.Comments, PasWeave.Model, PasWeave.Model.JSON, PasWeave.Parser,
  PasWeave.Render.Markdown, PasWeave.Render.HTML,
  PasWeave.Render.HTML.Markdown, PasWeave.Render.HTML.Assets;

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

function FindUnitModel(AProject: TDocProject; const AName: string): TDocUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    if TDocUnit(AProject.Units[I]).Name = AName then
      Exit(TDocUnit(AProject.Units[I]));
end;

function FindTypeRelationship(ASymbol: TDocSymbol;
  AKind: TTypeRelationshipKind): TDocTypeRelationship;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to ASymbol.TypeRelationships.Count - 1 do
    if TDocTypeRelationship(ASymbol.TypeRelationships[I]).Kind = AKind then
      Exit(TDocTypeRelationship(ASymbol.TypeRelationships[I]));
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

function CountOccurrences(const AText, AValue: string): Integer;
var
  Position: Integer;
  Offset: Integer;
begin
  Result := 0;
  Offset := 1;
  Position := Pos(AValue, Copy(AText, Offset, MaxInt));
  while Position > 0 do
  begin
    Inc(Result);
    Inc(Offset, Position + Length(AValue) - 1);
    Position := Pos(AValue, Copy(AText, Offset, MaxInt));
  end;
end;

function ReadUTF8File(const AFilename: string): UTF8String;
var
  InputStream: TFileStream;
begin
  InputStream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Result, InputStream.Size);
    if Length(Result) > 0 then
      InputStream.ReadBuffer(Result[1], Length(Result));
  finally
    InputStream.Free;
  end;
end;

function WithoutTrailingLineBreaks(const AText: UTF8String): UTF8String;
begin
  Result := AText;
  while (Length(Result) > 0) and
    (Result[Length(Result)] in [#10, #13]) do
    Delete(Result, Length(Result), 1);
end;

function SampleOutputMatches(const AExpected, AFilename: UTF8String): Boolean;
var
  Actual: UTF8String;
  Expected: UTF8String;
  Position: Integer;
begin
  Expected := WithoutTrailingLineBreaks(AExpected);
  Actual := WithoutTrailingLineBreaks(ReadUTF8File(string(AFilename)));
  Result := Expected = Actual;
  if not Result then
  begin
    Position := 1;
    while (Position <= Length(Expected)) and
      (Position <= Length(Actual)) and
      (Expected[Position] = Actual[Position]) do
      Inc(Position);
    WriteLn(StdErr, 'sample mismatch: ', AFilename, ' expected=',
      Length(Expected), ' actual=', Length(Actual), ' position=', Position);
  end;
end;

function RetargetSampleIndexAssets(const AHTML: UTF8String): UTF8String;
begin
  Result := UTF8String(StringReplace(string(AHTML),
    'href="assets/katex/', 'href="../../../../assets/katex/',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result),
    'src="assets/katex/', 'src="../../../../assets/katex/',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result),
    'src="assets/mermaid/', 'src="../../../../assets/mermaid/',
    [rfReplaceAll]));
end;

function RetargetSampleUnitAssets(const AHTML: UTF8String): UTF8String;
begin
  Result := UTF8String(StringReplace(string(AHTML),
    'href="../assets/katex/', 'href="../../../../../assets/katex/',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result),
    'src="../assets/katex/', 'src="../../../../../assets/katex/',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result),
    'src="../assets/mermaid/', 'src="../../../../../assets/mermaid/',
    [rfReplaceAll]));
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
  MathProject: TDocProject;
  MathUnit: TDocUnit;
  MathSymbol: TDocSymbol;
  MathHTML: UTF8String;
  MathMarkdown: UTF8String;
  DependencyProject: TDocProject;
  DependencyGraph: UTF8String;
  ExpectedDependencyGraph: UTF8String;
  DependencyIndexHTML: UTF8String;
  RelationshipProject: TDocProject;
  RelationshipBaseUnit: TDocUnit;
  RelationshipImplementationUnit: TDocUnit;
  RelationshipSymbol: TDocSymbol;
  TypeRelationship: TDocTypeRelationship;
  RelationshipGraph: UTF8String;
  RelationshipIndexHTML: UTF8String;
  ExampleProject: TDocProject;
  ExampleIndexHTML: UTF8String;
  ExampleCoreUnit: TDocUnit;
  ExampleServicesUnit: TDocUnit;
  ExampleGreetingSymbol: TDocSymbol;
  ScientificProject: TDocProject;
  ScientificCoreUnit: TDocUnit;
  ScientificAnalysisUnit: TDocUnit;
  ScientificIndexHTML: UTF8String;
  ScientificCoreHTML: UTF8String;
  ScientificAnalysisHTML: UTF8String;
  ScientificSymbol: TDocSymbol;
  DiscoveryProject: TDocProject;
  SecondDiscoveryProject: TDocProject;
  DiscoveryOptions: TSourceDiscoveryOptions;
  InputErrorRaised: Boolean;
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
    Check(AddSymbol.DeclarationText =
      'function Add(const A: Integer; const B: Integer): Integer',
      'short routine declarations should use canonical Pascal spacing');
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
    Check(Pos('href="assets/katex/katex.min.css"', string(IndexHTML)) > 0,
      'HTML index should load the local KaTeX stylesheet');
    Check(Pos('src="assets/katex/katex.min.js"', string(IndexHTML)) > 0,
      'HTML index should load the local KaTeX runtime');
    Check(Pos('src="assets/mermaid/mermaid.tiny.js"',
      string(IndexHTML)) > 0,
      'HTML index should load the local Mermaid runtime');
    Check(Pos('src="assets/diagram.js"', string(IndexHTML)) > 0,
      'HTML index should load the dependency diagram initializer');
    Check(Pos('data-dependency-fallback open', string(IndexHTML)) > 0,
      'HTML index should expose the text dependency fallback by default');
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
    Check(Pos('src="../assets/math.js"', string(UnitHTML)) > 0,
      'HTML unit pages should load the offline math initializer');
    Check(Pos('mermaid.tiny.js', string(UnitHTML)) = 0,
      'HTML unit pages without diagrams should not load Mermaid');
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
    Check(Pos('data-math-inline', string(RenderInlineMarkdown(
      'Price: \$5'))) = 0,
      'escaped currency should not become inline mathematics');
    Check(string(RenderInlineMarkdown('Price: \$5')) = 'Price: $5',
      'escaped currency should render without its Markdown escape');
    Check(Pos('data-math-inline', string(RenderInlineMarkdown(
      'Costs $20 and $30.'))) = 0,
      'paired currency amounts should not become inline mathematics');
    Check(Pos('data-math-inline', string(RenderInlineMarkdown(
      'Linear expression: $2x + 1$.'))) > 0,
      'inline mathematics may start with a digit when its closing delimiter ' +
      'is not followed by one');
    Check(Pos('data-math-inline', string(RenderInlineMarkdown(
      'Spaced delimiters: $ not math $.'))) = 0,
      'inline math delimiters should touch their mathematical content');
    Check(Pos('data-math-inline', string(RenderInlineMarkdown(
      'Literal $$value$$'))) = 0,
      'double dollar delimiters in prose should not become inline math');

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
    Check(FileExists('build/test-docs/html/assets/math.js'),
      'HTML renderer should write its math initializer');
    Check(FileExists('build/test-docs/html/assets/diagram.js'),
      'HTML renderer should write its diagram initializer');
    Check(FileExists('build/test-docs/html/assets/search-index.js'),
      'HTML renderer should write its offline search index');
    Check(FileExists('build/test-docs/html/assets/katex/katex.min.js'),
      'HTML renderer should copy the KaTeX runtime');
    Check(FileExists('build/test-docs/html/assets/katex/katex.min.css'),
      'HTML renderer should copy the KaTeX stylesheet');
    Check(FileExists('build/test-docs/html/assets/katex/LICENSE'),
      'HTML renderer should copy the KaTeX license');
    Check(FileExists('build/test-docs/html/assets/katex/fonts/' +
      'KaTeX_Main-Regular.woff2'),
      'HTML renderer should copy the KaTeX fonts');
    Check(FileExists('build/test-docs/html/assets/mermaid/mermaid.tiny.js'),
      'HTML renderer should copy the Mermaid runtime');
    Check(FileExists('build/test-docs/html/assets/mermaid/LICENSE'),
      'HTML renderer should copy the Mermaid license');
  finally
    Project.Free;
  end;

  Check(KaTeXVersion = '0.18.1',
    'the tested KaTeX asset version should be explicit');
  Check(Pos('throwOnError: true', string(HTMLMathScript)) > 0,
    'math initialization should detect invalid expressions');
  Check(Pos('trust: false', string(HTMLMathScript)) > 0,
    'math initialization should not trust active TeX commands');
  Check(Pos('data-math-error', string(HTMLMathScript)) > 0,
    'math initialization should visibly mark invalid expressions');
  Check(MermaidVersion = '11.16.0',
    'the tested Mermaid asset version should be explicit');
  Check(Pos('startOnLoad: false', string(HTMLDiagramScript)) > 0,
    'diagram initialization should be controlled by PasWeave');
  Check(Pos('securityLevel: "loose"', string(HTMLDiagramScript)) > 0,
    'diagram initialization should permit generated unit links');
  Check(Pos('deterministicIds: true', string(HTMLDiagramScript)) > 0,
    'diagram initialization should request deterministic SVG identifiers');
  Check(Pos('suppressErrors: true', string(HTMLDiagramScript)) > 0,
    'diagram initialization should retain the text fallback on errors');
  Check((Pos('var MIN_SCALE = 0.5;', string(HTMLDiagramScript)) > 0) and
    (Pos('var MAX_SCALE = 3;', string(HTMLDiagramScript)) > 0),
    'diagram zoom should have explicit accessible bounds');
  Check(Pos('data-diagram-scale', string(HTMLDiagramScript)) > 0,
    'diagram controls should expose their current view state');
  Check(Pos('event.key === "ArrowLeft"',
    string(HTMLDiagramScript)) > 0,
    'diagram interaction should include keyboard panning');
  Check(Pos('container.addEventListener("pointerdown"',
    string(HTMLDiagramScript)) > 0,
    'diagram interaction should include mouse and pen dragging');
  Check(Pos('prefers-reduced-motion: reduce',
    string(HTMLDiagramScript)) > 0,
    'diagram interaction should respect reduced-motion preferences');
  Check(Pos('overscroll-behavior: contain; scroll-behavior: smooth',
    string(HTMLStylesheet)) = 0,
    'pointer dragging should not inherit delayed smooth scrolling');

  DependencyProject := BuildProject('tests/fixtures/dependencies',
    'DependencyFixture', AttemptedCount);
  try
    Check(AttemptedCount = 4,
      'all dependency diagram fixtures should be attempted');
    Check(DependencyProject.Errors.Count = 0,
      'dependency diagram fixtures should parse without errors');
    Check(DependencyProject.Units.Count = 4,
      'dependency diagram fixtures should produce four units');
    DependencyGraph := RenderMermaidDependencyGraph(DependencyProject);
    ExpectedDependencyGraph :=
      'flowchart LR' + #10 +
      '  accTitle: Unit dependency graph' + #10 +
      '  accDescr: Project units point to units imported by their interface ' +
        'uses clauses.' + #10 +
      '  unit0001["DependencyConsumer"]' + #10 +
      '  unit0002["DependencyCore"]' + #10 +
      '  unit0003["DependencyLeaf"]' + #10 +
      '  unit0004["IndependentUnit"]' + #10 +
      '  unit0001 --> unit0002' + #10 +
      '  unit0003 --> unit0001' + #10 +
      '  unit0003 --> unit0002' + #10 +
      '  click unit0001 "units/DependencyConsumer.html" "Open ' +
        'DependencyConsumer documentation" _self' + #10 +
      '  click unit0002 "units/DependencyCore.html" "Open DependencyCore ' +
        'documentation" _self' + #10 +
      '  click unit0003 "units/DependencyLeaf.html" "Open DependencyLeaf ' +
        'documentation" _self' + #10 +
      '  click unit0004 "units/IndependentUnit.html" "Open IndependentUnit ' +
        'documentation" _self' + #10;
    Check(DependencyGraph = ExpectedDependencyGraph,
      'Mermaid graph source should be complete and deterministic');
    Check(Pos('Classes', string(DependencyGraph)) = 0,
      'Mermaid graph should omit dependencies outside the documented project');
    Check(DependencyGraph =
      RenderMermaidDependencyGraph(DependencyProject),
      'repeated Mermaid graph rendering should be deterministic');

    DependencyIndexHTML := RenderHTMLIndex(DependencyProject);
    Check(Pos('<div class="diagram-toolbar" data-diagram-toolbar ' +
      'role="toolbar" aria-label="Unit dependency diagram controls" ' +
      'hidden>', string(DependencyIndexHTML)) > 0,
      'dependency diagrams should provide controls hidden until rendering');
    Check(Pos('id="unit-dependency-diagram" role="region" ' +
      'aria-label="Interactive unit dependency diagram"',
      string(DependencyIndexHTML)) > 0,
      'dependency diagrams should expose a labelled interactive region');
    Check(Pos('aria-describedby="unit-dependency-diagram-help" ' +
      'tabindex="0" aria-hidden="true" hidden>',
      string(DependencyIndexHTML)) > 0,
      'dependency diagrams should be keyboard focusable after rendering');
    Check(Pos('data-diagram-zoom-in aria-controls=' +
      '"unit-dependency-diagram"', string(DependencyIndexHTML)) > 0,
      'dependency zoom controls should identify their diagram');
    Check(Pos('unit0001 --&gt; unit0002',
      string(DependencyIndexHTML)) > 0,
      'HTML should safely embed Mermaid graph source');
    Check(Pos('<code>DependencyConsumer</code></a> uses <a href="units/' +
      'DependencyCore.html"><code>DependencyCore</code></a>.',
      string(DependencyIndexHTML)) > 0,
      'text fallback should link both ends of each project dependency');
    Check(Pos('<code>IndependentUnit</code></a> has no project-local ' +
      'interface dependencies.', string(DependencyIndexHTML)) > 0,
      'text fallback should include isolated units');
    WriteHTMLDocumentation(DependencyProject,
      'build/dependency-test-docs/html');
    Check(FileExists('build/dependency-test-docs/html/assets/mermaid/' +
      'mermaid.tiny.js'),
      'dependency fixture site should contain its offline Mermaid runtime');
    Check(FileExists('build/dependency-test-docs/html/units/' +
      'DependencyCore.html'),
      'dependency fixture diagram targets should be generated');
  finally
    DependencyProject.Free;
  end;

  RelationshipProject := BuildProject('tests/fixtures/relationships',
    'RelationshipFixture', AttemptedCount);
  try
    Check(AttemptedCount = 3,
      'all relationship fixtures should be attempted');
    Check(RelationshipProject.Errors.Count = 0,
      'relationship fixtures should parse without errors');
    RelationshipBaseUnit := FindUnitModel(RelationshipProject,
      'RelationshipBase');
    RelationshipImplementationUnit := FindUnitModel(RelationshipProject,
      'RelationshipImplementations');
    Check(Assigned(RelationshipBaseUnit) and
      Assigned(RelationshipImplementationUnit),
      'both relationship fixture units should be modeled');

    RelationshipSymbol := FindSymbol(RelationshipBaseUnit, 'IExtended');
    TypeRelationship := FindTypeRelationship(RelationshipSymbol,
      trkInheritance);
    Check(Assigned(TypeRelationship) and
      (TypeRelationship.TargetSymbolID =
        'interface:relationshipbase.ibase'),
      'interface inheritance should resolve within its unit');

    RelationshipSymbol := FindSymbol(RelationshipImplementationUnit,
      'TChild');
    Check(RelationshipSymbol.TypeRelationships.Count = 2,
      'a class should retain its ancestor and implemented interface');
    TypeRelationship := FindTypeRelationship(RelationshipSymbol,
      trkInheritance);
    Check(Assigned(TypeRelationship) and
      (TypeRelationship.TargetSymbolID = 'class:relationshipbase.tbase'),
      'class inheritance should resolve through interface uses');
    TypeRelationship := FindTypeRelationship(RelationshipSymbol,
      trkImplementation);
    Check(Assigned(TypeRelationship) and
      (TypeRelationship.TargetSymbolID =
        'interface:relationshipbase.ibase'),
      'interface implementation should resolve through interface uses');

    RelationshipSymbol := FindSymbol(RelationshipImplementationUnit,
      'TGenericChild');
    TypeRelationship := FindTypeRelationship(RelationshipSymbol,
      trkInheritance);
    Check(Assigned(TypeRelationship) and
      (TypeRelationship.TargetName = 'TGenericBase') and
      (TypeRelationship.DisplayName =
        'specialize TGenericBase<T>') and
      (TypeRelationship.TargetSymbolID =
        'class:relationshipbase.tgenericbase'),
      'generic ancestors should resolve by their typed AST destination');

    RelationshipSymbol := FindSymbol(RelationshipImplementationUnit,
      'TUnresolvedChild');
    TypeRelationship := FindTypeRelationship(RelationshipSymbol,
      trkInheritance);
    Check(Assigned(TypeRelationship) and
      (TypeRelationship.TargetName = 'TMissingBase') and
      (TypeRelationship.TargetSymbolID = ''),
      'unavailable ancestors should remain explicitly unresolved');
    RelationshipSymbol := FindSymbol(RelationshipImplementationUnit,
      'TUnscopedChild');
    TypeRelationship := FindTypeRelationship(RelationshipSymbol,
      trkInheritance);
    Check(Assigned(TypeRelationship) and
      (TypeRelationship.TargetName = 'TUnscopedBase') and
      (TypeRelationship.TargetSymbolID = ''),
      'a type in an unrelated project unit should not be guessed as a target');
    Check(FindSymbol(RelationshipImplementationUnit,
      'TChildAlias').TypeRelationships.Count = 0,
      'type aliases should not gain relationships from declaration text');
    Check(Pos('"typeRelationships"',
      string(ProjectToJSON(RelationshipProject))) > 0,
      'JSON should expose the resolved relationship model');

    RelationshipGraph := RenderMermaidTypeRelationshipGraph(
      RelationshipProject);
    Check(RelationshipGraph = RenderMermaidTypeRelationshipGraph(
      RelationshipProject),
      'relationship Mermaid source should be deterministic');
    Check(Pos('flowchart BT' + #10,
      string(RelationshipGraph)) = 1,
      'relationship graph should orient descendants toward ancestors');
    Check(Pos('type0005 -. implements .-> type0001',
      string(RelationshipGraph)) > 0,
      'relationship graph should distinguish interface implementation');
    Check(Pos('type0006 -->|inherits| type0004',
      string(RelationshipGraph)) > 0,
      'relationship graph should link specialized generic inheritance');
    Check(Pos('unresolved0001["[unresolved] TMissingBase"]',
      string(RelationshipGraph)) > 0,
      'relationship graph should label unresolved ancestors');
    Check(Pos('click type0006 "units/RelationshipImplementations.html#',
      string(RelationshipGraph)) > 0,
      'resolved relationship nodes should link to symbol documentation');

    RelationshipIndexHTML := RenderHTMLIndex(RelationshipProject);
    Check(Pos('<h2 id="type-relationships">Class and interface ' +
      'relationships</h2>', string(RelationshipIndexHTML)) > 0,
      'HTML index should include the relationship diagram section');
    Check(Pos('inherits from unresolved type <code>TMissingBase</code>.',
      string(RelationshipIndexHTML)) > 0,
      'HTML should include a readable unresolved relationship fallback');
    Check(Pos('<details class="diagram-fallback relationship-fallback" ' +
      'data-diagram-fallback open>', string(RelationshipIndexHTML)) > 0,
      'relationship fallback should start expanded without JavaScript');
    Check(Pos('aria-label="Class and interface relationship diagram ' +
      'controls" hidden>', string(RelationshipIndexHTML)) > 0,
      'relationship diagrams should have an independent toolbar');
    Check(Pos('id="type-relationship-diagram" role="region" ' +
      'aria-label="Interactive class and interface relationship diagram"',
      string(RelationshipIndexHTML)) > 0,
      'relationship diagrams should expose a labelled interactive region');
    Check(Pos('id="type-relationship-diagram-help" ' +
      'class="diagram-help" data-diagram-help hidden>',
      string(RelationshipIndexHTML)) > 0,
      'relationship diagrams should describe keyboard and pointer controls');
    Check(Pos('as <code>specialize TGenericBase&lt;T&gt;</code>',
      string(RelationshipIndexHTML)) > 0,
      'text fallback should preserve a generic relationship display name');
    WriteHTMLDocumentation(RelationshipProject,
      'build/relationship-test-docs/html');
    Check(FileExists('build/relationship-test-docs/html/units/' +
      'RelationshipBase.html'),
      'relationship diagram symbol targets should be generated');
  finally
    RelationshipProject.Free;
  end;

  MathProject := BuildProject(
    'tests/fixtures/math/MathDocumentation.pas',
    'MathDocumentationFixture', AttemptedCount);
  try
    Check(MathProject.Errors.Count = 0,
      'invalid KaTeX should not fail the documentation build');
    MathUnit := TDocUnit(MathProject.Units[0]);
    MathSymbol := FindSymbol(MathUnit, 'MathExamples');
    Check(Assigned(MathSymbol), 'math fixture routine should be modeled');
    Check(Pos('$a^2 + b^2 = c^2$', MathSymbol.MarkdownDocumentation) > 0,
      'the model should preserve valid inline mathematical source');
    Check(Pos('$\sqrt{$', MathSymbol.MarkdownDocumentation) > 0,
      'the model should preserve invalid mathematical source');
    Check(Pos('\$5', MathSymbol.MarkdownDocumentation) > 0,
      'the model should preserve escaped currency source');

    MathMarkdown := RenderMarkdownUnit(MathProject, MathUnit);
    MathHTML := RenderHTMLUnit(MathProject, MathUnit);
    Check(Pos('$a^2 + b^2 = c^2$', string(MathMarkdown)) > 0,
      'Markdown output should preserve inline mathematical source');
    Check(Pos('\frac{1}{', string(MathMarkdown)) > 0,
      'Markdown output should preserve invalid display mathematical source');
    Check(CountOccurrences(string(MathHTML), 'data-math-inline>') = 2,
      'HTML should mark valid and invalid inline expressions');
    Check(CountOccurrences(string(MathHTML), 'data-math-display>') = 2,
      'HTML should mark valid and invalid display expressions');
    Check(Pos('Escaped currency remains prose: $5.', string(MathHTML)) > 0,
      'HTML should keep escaped currency as prose');
    Check(Pos('$$not a display fence$$', string(MathHTML)) > 0,
      'HTML should retain non-fence double delimiters as prose');
    WriteHTMLDocumentation(MathProject, 'build/math-test-docs/html');
    Check(FileExists('build/math-test-docs/html/assets/math.js'),
      'math fixture site should contain the initializer');
    Check(FileExists('build/math-test-docs/html/assets/katex/fonts/' +
      'KaTeX_Math-Italic.woff2'),
      'math fixture site should be independently usable offline');
  finally
    MathProject.Free;
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
    Check(FindSymbol(DialectUnit,
      'PlainSlashOnly').MarkdownDocumentation = '',
      'slash mode should mean /// and never capture ordinary // comments');
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
    Check(FindSymbol(DialectUnit,
      'PlainSlashOnly').MarkdownDocumentation = '',
      'all mode should never capture ordinary // comments');
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

  DiscoveryProject := BuildProject('tests/fixtures/discovery',
    'NonRecursiveDiscoveryFixture', AttemptedCount);
  try
    Check((AttemptedCount = 1) and (DiscoveryProject.Units.Count = 1),
      'directory discovery should remain non-recursive by default');
    Check(TDocUnit(DiscoveryProject.Units[0]).Name = 'RootUnit',
      'non-recursive discovery should retain the root unit');
  finally
    DiscoveryProject.Free;
  end;

  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  try
    DiscoveryOptions.Recursive := True;
    DiscoveryProject := BuildProject('tests/fixtures/discovery',
      'RecursiveDiscoveryFixture', AttemptedCount,
      DefaultDocumentationCommentStyles, DiscoveryOptions);
    try
      Check((AttemptedCount = 6) and (DiscoveryProject.Units.Count = 6),
        'recursive discovery should include nested .pas and .pp units');
      Check(FindUnitModel(DiscoveryProject, 'BetaUnit').SourceFilename =
        'src/deep/BetaUnit.pp',
        'recursive source filenames should be root-relative and normalized');
      SecondDiscoveryProject := BuildProject('tests/fixtures/discovery',
        'RecursiveDiscoveryFixture', AttemptedCount,
        DefaultDocumentationCommentStyles, DiscoveryOptions);
      try
        Check(ProjectToJSON(DiscoveryProject) =
          ProjectToJSON(SecondDiscoveryProject),
          'recursive discovery and model ordering should be deterministic');
      finally
        SecondDiscoveryProject.Free;
      end;
    finally
      DiscoveryProject.Free;
    end;
  finally
    DiscoveryOptions.Free;
  end;

  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  try
    DiscoveryOptions.Recursive := True;
    DiscoveryOptions.AddIncludePattern('src/**');
    DiscoveryOptions.AddExcludePattern('src/deep/**');
    DiscoveryProject := BuildProject('tests/fixtures/discovery',
      'DiscoveryPrecedenceFixture', AttemptedCount,
      DefaultDocumentationCommentStyles, DiscoveryOptions);
    try
      Check((AttemptedCount = 1) and
        Assigned(FindUnitModel(DiscoveryProject, 'AlphaUnit')) and
        not Assigned(FindUnitModel(DiscoveryProject, 'BetaUnit')),
        'recursive exclusions should take precedence over includes');
    finally
      DiscoveryProject.Free;
    end;
  finally
    DiscoveryOptions.Free;
  end;

  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  try
    DiscoveryOptions.Recursive := True;
    DiscoveryOptions.AddExcludePattern('generated/**');
    DiscoveryOptions.AddExcludePattern('tests');
    DiscoveryOptions.AddExcludePattern('vendor/**');
    DiscoveryProject := BuildProject('tests/fixtures/discovery',
      'ExcludedDiscoveryFixture', AttemptedCount,
      DefaultDocumentationCommentStyles, DiscoveryOptions);
    try
      Check((AttemptedCount = 3) and (DiscoveryProject.Units.Count = 3),
        'recursive exclusions should prune generated, test, and vendor trees');
      Check(not Assigned(FindUnitModel(DiscoveryProject, 'GeneratedUnit')) and
        not Assigned(FindUnitModel(DiscoveryProject, 'TestSupport')) and
        not Assigned(FindUnitModel(DiscoveryProject, 'VendorUnit')),
        'excluded directories should contribute no units');
    finally
      DiscoveryProject.Free;
    end;
  finally
    DiscoveryOptions.Free;
  end;

  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  try
    DiscoveryOptions.Recursive := True;
    DiscoveryOptions.AddIncludePattern('src/**/*.pas');
    DiscoveryProject := BuildProject('tests/fixtures/discovery',
      'IncludedDiscoveryFixture', AttemptedCount,
      DefaultDocumentationCommentStyles, DiscoveryOptions);
    try
      Check((AttemptedCount = 1) and
        Assigned(FindUnitModel(DiscoveryProject, 'AlphaUnit')),
        'recursive includes should support ** and extension filtering');
    finally
      DiscoveryProject.Free;
    end;
  finally
    DiscoveryOptions.Free;
  end;

  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  try
    DiscoveryOptions.Recursive := True;
    DiscoveryOptions.AddIncludePattern('SRC/?LPHAUNIT.PAS');
    DiscoveryProject := BuildProject('tests/fixtures/discovery',
      'CaseInsensitiveDiscoveryFixture', AttemptedCount,
      DefaultDocumentationCommentStyles, DiscoveryOptions);
    try
      Check((AttemptedCount = 1) and
        Assigned(FindUnitModel(DiscoveryProject, 'AlphaUnit')),
        'discovery globs should be case-insensitive and support ?');
    finally
      DiscoveryProject.Free;
    end;
  finally
    DiscoveryOptions.Free;
  end;

  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  try
    InputErrorRaised := False;
    try
      DiscoveryOptions.AddExcludePattern('../outside');
    except
      on E: EPasWeaveInputError do
        InputErrorRaised := True;
    end;
    Check(InputErrorRaised,
      'discovery patterns should not escape the source directory');

    InputErrorRaised := False;
    try
      DiscoveryOptions.AddIncludePattern('/absolute');
    except
      on E: EPasWeaveInputError do
        InputErrorRaised := True;
    end;
    Check(InputErrorRaised,
      'discovery patterns should reject absolute paths');

    InputErrorRaised := False;
    try
      DiscoveryOptions.AddIncludePattern('');
    except
      on E: EPasWeaveInputError do
        InputErrorRaised := True;
    end;
    Check(InputErrorRaised,
      'discovery patterns should reject empty values');

    DiscoveryOptions.Recursive := True;
    InputErrorRaised := False;
    try
      DiscoveryProject := BuildProject(
        'tests/fixtures/discovery/RootUnit.pas',
        'InvalidFileDiscoveryFixture', AttemptedCount,
        DefaultDocumentationCommentStyles, DiscoveryOptions);
      DiscoveryProject.Free;
    except
      on E: EPasWeaveInputError do
        InputErrorRaised := True;
    end;
    Check(InputErrorRaised,
      'discovery options should require a source directory');
  finally
    DiscoveryOptions.Free;
  end;

  DiscoveryOptions := TSourceDiscoveryOptions.Create;
  try
    DiscoveryOptions.Recursive := True;
    DiscoveryOptions.AddIncludePattern('missing/**');
    InputErrorRaised := False;
    try
      DiscoveryProject := BuildProject('tests/fixtures/discovery',
        'EmptyDiscoveryFixture', AttemptedCount,
        DefaultDocumentationCommentStyles, DiscoveryOptions);
      DiscoveryProject.Free;
    except
      on E: EPasWeaveInputError do
        InputErrorRaised := True;
    end;
    Check(InputErrorRaised,
      'source discovery should reject an empty matched source set');
  finally
    DiscoveryOptions.Free;
  end;

  ExampleProject := BuildProject('examples/documented-api',
    'Documented API example', AttemptedCount);
  try
    Check(AttemptedCount = 2,
      'both documented example units should be attempted');
    Check((ExampleProject.Errors.Count = 0) and
      (ExampleProject.Units.Count = 2),
      'the documented example should parse both units without errors');
    ExampleIndexHTML := RenderHTMLIndex(ExampleProject);
    Check(Pos('10 of 10 API symbols documented',
      string(ExampleIndexHTML)) > 0,
      'the documented example should showcase complete /// coverage');
    ExampleCoreUnit := FindUnitModel(ExampleProject, 'Demo.Core');
    ExampleServicesUnit := FindUnitModel(ExampleProject, 'Demo.Services');
    Check(Assigned(ExampleCoreUnit) and Assigned(ExampleServicesUnit),
      'the documented example should expose both sample units');
    ExampleGreetingSymbol := FindSymbol(ExampleCoreUnit, 'GreetingFor');
    Check(Assigned(ExampleGreetingSymbol),
      'the documented example should expose its greeting method');
    Check(ExampleGreetingSymbol.DeclarationText =
      'function GreetingFor(' + #10 +
      '  const AName: string;' + #10 +
      '  AStyle: TGreetingStyle = gsFriendly' + #10 +
      '): string',
      'long declarations should wrap intentionally and retain defaults');
    Check(SampleOutputMatches(RenderMarkdownIndex(ExampleProject),
      'examples/documented-api/sample-output/markdown/index.md'),
      'the Markdown sample index should match current renderer output');
    Check(SampleOutputMatches(RenderMarkdownUnit(ExampleProject,
      ExampleCoreUnit),
      'examples/documented-api/sample-output/markdown/units/Demo.Core.md'),
      'the Demo.Core Markdown sample should match current renderer output');
    Check(SampleOutputMatches(RenderMarkdownUnit(ExampleProject,
      ExampleServicesUnit),
      'examples/documented-api/sample-output/markdown/units/Demo.Services.md'),
      'the Demo.Services Markdown sample should match current renderer output');
    Check(SampleOutputMatches(RetargetSampleIndexAssets(ExampleIndexHTML),
      'examples/documented-api/sample-output/html/index.html'),
      'the HTML sample index should match current renderer output');
    Check(SampleOutputMatches(RetargetSampleUnitAssets(RenderHTMLUnit(
      ExampleProject, ExampleCoreUnit)),
      'examples/documented-api/sample-output/html/units/Demo.Core.html'),
      'the Demo.Core HTML sample should match current renderer output');
    Check(SampleOutputMatches(RetargetSampleUnitAssets(RenderHTMLUnit(
      ExampleProject, ExampleServicesUnit)),
      'examples/documented-api/sample-output/html/units/Demo.Services.html'),
      'the Demo.Services HTML sample should match current renderer output');
    Check(SampleOutputMatches(HTMLStylesheet,
      'examples/documented-api/sample-output/html/assets/site.css') and
      SampleOutputMatches(HTMLApplicationScript,
      'examples/documented-api/sample-output/html/assets/app.js') and
      SampleOutputMatches(HTMLMathScript,
      'examples/documented-api/sample-output/html/assets/math.js') and
      SampleOutputMatches(HTMLDiagramScript,
      'examples/documented-api/sample-output/html/assets/diagram.js') and
      SampleOutputMatches(RenderHTMLSearchIndex(ExampleProject),
      'examples/documented-api/sample-output/html/assets/search-index.js'),
      'the HTML sample assets should match current renderer output');
  finally
    ExampleProject.Free;
  end;

  ScientificProject := BuildProject('examples/scientific-api',
    'Scientific API showcase', AttemptedCount);
  try
    Check((AttemptedCount = 2) and (ScientificProject.Units.Count = 2) and
      (ScientificProject.Errors.Count = 0),
      'the scientific example should parse both units without errors');
    Check(ScientificProject.SymbolCount = 32,
      'the scientific example should expose its complete model');
    ScientificCoreUnit := FindUnitModel(ScientificProject,
      'Scientific.Core');
    ScientificAnalysisUnit := FindUnitModel(ScientificProject,
      'Scientific.Analysis');
    Check(Assigned(ScientificCoreUnit) and Assigned(ScientificAnalysisUnit),
      'the scientific example should expose both documented units');

    ScientificIndexHTML := RenderHTMLIndex(ScientificProject);
    ScientificCoreHTML := RenderHTMLUnit(ScientificProject,
      ScientificCoreUnit);
    ScientificAnalysisHTML := RenderHTMLUnit(ScientificProject,
      ScientificAnalysisUnit);
    Check(Pos('30 of 30 API symbols documented',
      string(ScientificIndexHTML)) > 0,
      'the scientific example should have complete public API coverage');
    Check(CountOccurrences(string(ScientificCoreHTML),
      'data-math-inline>') + CountOccurrences(string(ScientificAnalysisHTML),
      'data-math-inline>') = 65,
      'the scientific example should showcase 65 inline expressions');
    Check(CountOccurrences(string(ScientificCoreHTML),
      'data-math-display>') + CountOccurrences(
      string(ScientificAnalysisHTML), 'data-math-display>') = 16,
      'the scientific example should showcase 16 display equations');

    ScientificSymbol := FindSymbol(ScientificCoreUnit, 'TRealFunction');
    Check(Assigned(ScientificSymbol),
      'the scientific real-function base should be present');
    TypeRelationship := FindTypeRelationship(ScientificSymbol,
      trkImplementation);
    Check(Assigned(TypeRelationship) and
      (TypeRelationship.TargetSymbolID <> ''),
      'the scientific function interface should resolve semantically');
    ScientificSymbol := FindSymbol(ScientificAnalysisUnit,
      'TGaussianFunction');
    Check(Assigned(ScientificSymbol),
      'the scientific Gaussian function should be present');
    TypeRelationship := FindTypeRelationship(ScientificSymbol,
      trkInheritance);
    Check(Assigned(TypeRelationship) and
      (TypeRelationship.TargetSymbolID <> ''),
      'the scientific cross-unit inheritance should resolve semantically');

    Check(SampleOutputMatches(RenderMarkdownIndex(ScientificProject),
      'examples/scientific-api/sample-output/markdown/index.md'),
      'the scientific Markdown index should match current renderer output');
    Check(SampleOutputMatches(RenderMarkdownUnit(ScientificProject,
      ScientificCoreUnit),
      'examples/scientific-api/sample-output/markdown/units/Scientific.Core.md'),
      'the Scientific.Core Markdown sample should remain synchronized');
    Check(SampleOutputMatches(RenderMarkdownUnit(ScientificProject,
      ScientificAnalysisUnit),
      'examples/scientific-api/sample-output/markdown/units/Scientific.Analysis.md'),
      'the Scientific.Analysis Markdown sample should remain synchronized');
    Check(SampleOutputMatches(RetargetSampleIndexAssets(ScientificIndexHTML),
      'examples/scientific-api/sample-output/html/index.html'),
      'the scientific HTML index should match current renderer output');
    Check(SampleOutputMatches(RetargetSampleUnitAssets(ScientificCoreHTML),
      'examples/scientific-api/sample-output/html/units/Scientific.Core.html'),
      'the Scientific.Core HTML sample should remain synchronized');
    Check(SampleOutputMatches(RetargetSampleUnitAssets(
      ScientificAnalysisHTML),
      'examples/scientific-api/sample-output/html/units/Scientific.Analysis.html'),
      'the Scientific.Analysis HTML sample should remain synchronized');
    Check(SampleOutputMatches(HTMLStylesheet,
      'examples/scientific-api/sample-output/html/assets/site.css') and
      SampleOutputMatches(HTMLApplicationScript,
      'examples/scientific-api/sample-output/html/assets/app.js') and
      SampleOutputMatches(HTMLMathScript,
      'examples/scientific-api/sample-output/html/assets/math.js') and
      SampleOutputMatches(HTMLDiagramScript,
      'examples/scientific-api/sample-output/html/assets/diagram.js') and
      SampleOutputMatches(RenderHTMLSearchIndex(ScientificProject),
      'examples/scientific-api/sample-output/html/assets/search-index.js'),
      'the scientific HTML sample assets should remain synchronized');
  finally
    ScientificProject.Free;
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
