unit PasWeave.ValidationTests;

{$mode objfpc}{$H+}

interface

procedure RunValidationTests;

implementation

uses
  Classes, SysUtils, FPJSON, JSONParser, PasWeave.Comments,
  PasWeave.Diagnostics, PasWeave.Model, PasWeave.Model.JSON,
  PasWeave.Parser, PasWeave.Render.HTML, PasWeave.Render.Markdown,
  PasWeave.Validation;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create('validation test failed: ' + AMessage);
end;

function FindUnitModel(AProject: TDocProject; const AName: string): TDocUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    if SameText(TDocUnit(AProject.Units[I]).Name, AName) then
      Exit(TDocUnit(AProject.Units[I]));
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

function FindDirective(ASymbol: TDocSymbol; const AName,
  ASubject: string): TDocDirective;
var
  I: Integer;
  Candidate: TDocDirective;
begin
  Result := nil;
  for I := 0 to ASymbol.Directives.Count - 1 do
  begin
    Candidate := TDocDirective(ASymbol.Directives[I]);
    if SameText(Candidate.Name, AName) and
      SameText(Candidate.Subject, ASubject) then
      Exit(Candidate);
  end;
end;

function HasDiagnosticCode(ADiagnostics: TList; const ACode: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ADiagnostics.Count - 1 do
    if TDiagnostic(ADiagnostics[I]).Code = ACode then
      Exit(True);
end;

procedure CheckDirectiveDiagnostics(AProject: TDocProject;
  AFunctionSymbol: TDocSymbol; const AStyleName: string);
var
  LocalSee: TDocDirective;
  MissingSee: TDocDirective;
begin
  Check(Assigned(AFunctionSymbol), AStyleName + ' fixture should parse the function');
  Check((AFunctionSymbol.ParameterNames.Count = 2) and
    SameText(AFunctionSymbol.ParameterNames[0], 'A') and
    SameText(AFunctionSymbol.ParameterNames[1], 'B'),
    AStyleName + ' fixture should retain parsed parameter names');
  Check(AFunctionSymbol.HasReturnValue,
    AStyleName + ' fixture should retain the parsed return kind');
  Check(HasDiagnosticCode(AProject.Warnings, DiagnosticCodeMissingParameter),
    AStyleName + ' fixture should report missing @param entries');
  Check(HasDiagnosticCode(AProject.Warnings, DiagnosticCodeDuplicateParameter),
    AStyleName + ' fixture should report duplicate @param entries');
  Check(HasDiagnosticCode(AProject.Warnings, DiagnosticCodeUnknownParameter),
    AStyleName + ' fixture should report unknown @param entries');
  Check(HasDiagnosticCode(AProject.Warnings, DiagnosticCodeDuplicateReturns),
    AStyleName + ' fixture should report conflicting @returns entries');
  Check(HasDiagnosticCode(AProject.Warnings, DiagnosticCodeUnexpectedReturns),
    AStyleName + ' fixture should reject @returns on procedures');
  Check(HasDiagnosticCode(AProject.Warnings, DiagnosticCodeUnresolvedSee),
    AStyleName + ' fixture should preserve unresolved @see targets');

  LocalSee := FindDirective(AFunctionSymbol, 'see', 'LocalTarget');
  MissingSee := FindDirective(AFunctionSymbol, 'see', 'MissingTarget');
  Check(Assigned(LocalSee) and (LocalSee.TargetSymbolID <> ''),
    AStyleName + ' fixture should resolve local @see targets in the model');
  Check(Assigned(MissingSee) and (MissingSee.TargetSymbolID = ''),
    AStyleName + ' fixture should keep unresolved @see targets honest');
end;

procedure CheckStyleFixture(const APath, AUnitName, AStyleName: string;
  AStyles: TDocumentationCommentStyles);
var
  Project: TDocProject;
  UnitModel: TDocUnit;
  FunctionSymbol: TDocSymbol;
  ProcedureSymbol: TDocSymbol;
  AttemptedCount: Integer;
begin
  Project := BuildProject(APath, AStyleName + ' validation fixture',
    AttemptedCount, AStyles);
  try
    Check(Project.Errors.Count = 0,
      AStyleName + ' fixture authoring feedback should be warnings by default');
    UnitModel := FindUnitModel(Project, AUnitName);
    FunctionSymbol := FindSymbol(UnitModel, 'CheckedFunction');
    ProcedureSymbol := FindSymbol(UnitModel, 'ProcedureWithReturnDirective');
    CheckDirectiveDiagnostics(Project, FunctionSymbol, AStyleName);
    Check(Assigned(ProcedureSymbol) and not ProcedureSymbol.HasReturnValue,
      AStyleName + ' fixture should retain a procedure return kind');
  finally
    Project.Free;
  end;
end;

procedure CheckOutputIntegrityDiagnostics;
var
  Project: TDocProject;
  UnitModel: TDocUnit;
  FirstSymbol: TDocSymbol;
  SecondSymbol: TDocSymbol;
begin
  Project := TDocProject.Create;
  try
    UnitModel := TDocUnit.Create;
    UnitModel.Name := 'IntegrityFixture';
    FirstSymbol := TDocSymbol.Create;
    FirstSymbol.ID := 'duplicate-symbol-id';
    FirstSymbol.Name := 'First';
    FirstSymbol.QualifiedName := 'IntegrityFixture.First';
    FirstSymbol.Kind := skRoutine;
    FirstSymbol.Visibility := svPublic;
    SecondSymbol := TDocSymbol.Create;
    SecondSymbol.ID := 'duplicate-symbol-id';
    SecondSymbol.Name := 'Second';
    SecondSymbol.QualifiedName := 'IntegrityFixture.First';
    SecondSymbol.Kind := skRoutine;
    SecondSymbol.Visibility := svPublic;
    UnitModel.Symbols.Add(FirstSymbol);
    UnitModel.Symbols.Add(SecondSymbol);
    Project.Units.Add(UnitModel);

    ValidateProject(Project);
    Check(HasDiagnosticCode(Project.Errors, DiagnosticCodeDuplicateAnchor),
      'duplicate generated anchors should be build defects');
  finally
    Project.Free;
  end;
end;

procedure RunValidationTests;
var
  Project: TDocProject;
  UnitModel: TDocUnit;
  FunctionSymbol: TDocSymbol;
  DependencySee: TDocDirective;
  AttemptedCount: Integer;
  Coverage: TDocumentationCoverage;
  Parsed: TJSONData;
  Markdown: UTF8String;
  HTML: UTF8String;
begin
  CheckStyleFixture('tests/fixtures/validation/slash', 'FeedbackSlash',
    'slash', [dcsSlash]);
  CheckStyleFixture('tests/fixtures/validation/brace', 'FeedbackBrace',
    'brace', [dcsBrace]);
  CheckStyleFixture('tests/fixtures/validation/paren', 'FeedbackParen',
    'paren', [dcsParen]);

  Project := BuildProject('tests/fixtures/validation/slash',
    'slash validation fixture', AttemptedCount, [dcsSlash]);
  try
    UnitModel := FindUnitModel(Project, 'FeedbackSlash');
    FunctionSymbol := FindSymbol(UnitModel, 'CheckedFunction');
    DependencySee := FindDirective(FunctionSymbol, 'see',
      'FeedbackDependency.DependencyTarget');
    Check(Assigned(DependencySee) and (DependencySee.TargetSymbolID <> ''),
      'direct interface dependencies should supply conservative @see targets');
    Markdown := RenderMarkdownUnit(Project, UnitModel);
    HTML := RenderHTMLUnit(Project, UnitModel);
    Check(Pos('](FeedbackDependency.md#', string(Markdown)) > 0,
      'Markdown should consume the resolved dependency @see target');
    Check(Pos('href="FeedbackDependency.html#', string(HTML)) > 0,
      'HTML should consume the resolved dependency @see target');

    Coverage := CalculateDocumentationCoverage(Project);
    Check((Coverage.EligibleSymbols > 0) and
      (Coverage.DocumentedSymbols < Coverage.EligibleSymbols),
      'coverage should count renderable documented symbols from the model');
    AddDocumentationCoverageDiagnostic(Project, 100);
    Check(HasDiagnosticCode(Project.Errors, DiagnosticCodeCoverageThreshold),
      'configured coverage shortfalls should be build defects');
    Check(HasDiagnosticsAtOrAbove(Project, dsWarning),
      'warning failure thresholds should observe authoring feedback');
    Check(HasDiagnosticsAtOrAbove(Project, dsError),
      'error failure thresholds should observe configured coverage failures');

    Parsed := GetJSON(DiagnosticsToJSON(Project));
    try
      Check(Parsed.JSONType = jtObject,
        'diagnostics output should be valid JSON');
      Check(Pos('"code" : "' + DiagnosticCodeMissingParameter + '"',
        string(DiagnosticsToJSON(Project))) > 0,
        'diagnostics output should include stable diagnostic codes');
    finally
      Parsed.Free;
    end;
  finally
    Project.Free;
  end;

  CheckOutputIntegrityDiagnostics;
end;

end.
