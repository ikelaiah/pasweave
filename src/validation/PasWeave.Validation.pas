unit PasWeave.Validation;

{$mode objfpc}{$H+}

interface

uses
  PasWeave.Diagnostics, PasWeave.Model;

const
  DiagnosticCodeMissingParameter = 'PW401';
  DiagnosticCodeDuplicateParameter = 'PW402';
  DiagnosticCodeUnknownParameter = 'PW403';
  DiagnosticCodeUnexpectedReturns = 'PW404';
  DiagnosticCodeDuplicateReturns = 'PW405';
  DiagnosticCodeUnresolvedSee = 'PW406';
  DiagnosticCodeBrokenGeneratedLink = 'PW407';
  DiagnosticCodeDuplicateAnchor = 'PW408';
  DiagnosticCodeDuplicatePage = 'PW409';
  DiagnosticCodeUnreachablePage = 'PW410';
  DiagnosticCodeCoverageThreshold = 'PW411';

type
  TDocumentationCoverage = record
    DocumentedSymbols: Integer;
    EligibleSymbols: Integer;
    Percentage: Integer;
  end;

procedure ValidateProject(AProject: TDocProject);
function CalculateDocumentationCoverage(AProject: TDocProject): TDocumentationCoverage;
procedure AddDocumentationCoverageDiagnostic(AProject: TDocProject;
  AMinimumPercentage: Integer);
function HasDiagnosticsAtOrAbove(AProject: TDocProject;
  ASeverity: TDiagnosticSeverity): Boolean;

implementation

uses
  Classes, SysUtils;

function FindSymbolByID(AUnit: TDocUnit; const AID: string): TDocSymbol;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AUnit.Symbols.Count - 1 do
    if SameText(TDocSymbol(AUnit.Symbols[I]).ID, AID) then
      Exit(TDocSymbol(AUnit.Symbols[I]));
end;

function FindProjectSymbolByID(AProject: TDocProject; const AID: string;
  out AUnit: TDocUnit): TDocSymbol;
var
  I: Integer;
begin
  Result := nil;
  AUnit := nil;
  for I := 0 to AProject.Units.Count - 1 do
  begin
    AUnit := TDocUnit(AProject.Units[I]);
    Result := FindSymbolByID(AUnit, AID);
    if Assigned(Result) then
      Exit;
  end;
  AUnit := nil;
end;

function FindUnitByName(AProject: TDocProject; const AName: string): TDocUnit;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    if SameText(TDocUnit(AProject.Units[I]).Name, AName) then
      Exit(TDocUnit(AProject.Units[I]));
end;

function IsDirectlyRenderable(ASymbol: TDocSymbol): Boolean;
begin
  Result := not (ASymbol.Visibility in [svPrivate, svStrictPrivate]);
end;

function IsEffectivelyRenderable(AUnit: TDocUnit;
  ASymbol: TDocSymbol): Boolean;
var
  ParentSymbol: TDocSymbol;
begin
  Result := IsDirectlyRenderable(ASymbol);
  ParentSymbol := ASymbol;
  while Result and (ParentSymbol.ParentSymbolID <> '') do
  begin
    ParentSymbol := FindSymbolByID(AUnit, ParentSymbol.ParentSymbolID);
    if not Assigned(ParentSymbol) then
      Break;
    Result := IsDirectlyRenderable(ParentSymbol);
  end;
end;

procedure AddDiagnostic(AProject: TDocProject; ASeverity: TDiagnosticSeverity;
  ASymbol: TDocSymbol; const ACode, AMessage: string);
var
  Diagnostic: TDiagnostic;
begin
  Diagnostic := TDiagnostic.Create(ASeverity, ASymbol.SourceFilename,
    ASymbol.SourceLine, ASymbol.SourceColumn, AMessage, '', ACode);
  if ASeverity = dsError then
    AProject.Errors.Add(Diagnostic)
  else
    AProject.Warnings.Add(Diagnostic);
end;

function CountDirectives(ASymbol: TDocSymbol; const AName: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ASymbol.Directives.Count - 1 do
    if SameText(TDocDirective(ASymbol.Directives[I]).Name, AName) then
      Inc(Result);
end;

function CountParameterDirectives(ASymbol: TDocSymbol;
  const AParameterName: string): Integer;
var
  I: Integer;
  Directive: TDocDirective;
begin
  Result := 0;
  for I := 0 to ASymbol.Directives.Count - 1 do
  begin
    Directive := TDocDirective(ASymbol.Directives[I]);
    if SameText(Directive.Name, 'param') and
      SameText(Directive.Subject, AParameterName) then
      Inc(Result);
  end;
end;

function HasParameter(ASymbol: TDocSymbol; const AParameterName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to ASymbol.ParameterNames.Count - 1 do
    if SameText(ASymbol.ParameterNames[I], AParameterName) then
      Exit(True);
end;

function FindNamedSymbol(AUnit: TDocUnit; const AName: string): TDocSymbol;
var
  I: Integer;
  Candidate: TDocSymbol;
begin
  Result := nil;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Candidate := TDocSymbol(AUnit.Symbols[I]);
    if SameText(Candidate.Name, AName) then
    begin
      if Assigned(Result) then
        Exit(nil);
      Result := Candidate;
    end;
  end;
end;

function FindQualifiedSymbol(AProject: TDocProject;
  const AQualifiedName: string): TDocSymbol;
var
  I: Integer;
  J: Integer;
  Candidate: TDocSymbol;
begin
  Result := nil;
  for I := 0 to AProject.Units.Count - 1 do
    for J := 0 to TDocUnit(AProject.Units[I]).Symbols.Count - 1 do
    begin
      Candidate := TDocSymbol(TDocUnit(AProject.Units[I]).Symbols[J]);
      if SameText(Candidate.QualifiedName, AQualifiedName) then
      begin
        if Assigned(Result) then
          Exit(nil);
        Result := Candidate;
      end;
    end;
end;

function ResolveSeeTarget(AProject: TDocProject; ASourceUnit: TDocUnit;
  const AReference: string): TDocSymbol;
var
  Candidate: TDocSymbol;
  DependencyUnit: TDocUnit;
  I: Integer;
begin
  Result := nil;
  if AReference = '' then
    Exit;
  if Pos('.', AReference) > 0 then
    Exit(FindQualifiedSymbol(AProject, AReference));

  Candidate := FindNamedSymbol(ASourceUnit, AReference);
  if Assigned(Candidate) then
    Exit(Candidate);
  for I := 0 to ASourceUnit.InterfaceDependencies.Count - 1 do
  begin
    DependencyUnit := FindUnitByName(AProject,
      ASourceUnit.InterfaceDependencies[I]);
    if not Assigned(DependencyUnit) then
      Continue;
    Candidate := FindNamedSymbol(DependencyUnit, AReference);
    if Assigned(Candidate) then
    begin
      if Assigned(Result) and (Result <> Candidate) then
        Exit(nil);
      Result := Candidate;
    end;
  end;
end;

procedure ValidateDirectiveSemantics(AProject: TDocProject;
  AUnit: TDocUnit; ASymbol: TDocSymbol);
var
  I: Integer;
  Directive: TDocDirective;
  TargetSymbol: TDocSymbol;
  TargetUnit: TDocUnit;
  ParameterName: string;
  ParameterDirectiveCount: Integer;
  ReturnDirectiveCount: Integer;
begin
  for I := 0 to ASymbol.ParameterNames.Count - 1 do
  begin
    ParameterName := ASymbol.ParameterNames[I];
    ParameterDirectiveCount := CountParameterDirectives(ASymbol, ParameterName);
    if ParameterDirectiveCount = 0 then
      AddDiagnostic(AProject, dsWarning, ASymbol, DiagnosticCodeMissingParameter,
        'missing @param documentation for parameter ' + ParameterName)
    else if ParameterDirectiveCount > 1 then
      AddDiagnostic(AProject, dsWarning, ASymbol, DiagnosticCodeDuplicateParameter,
        'duplicate @param documentation for parameter ' + ParameterName);
  end;

  for I := 0 to ASymbol.Directives.Count - 1 do
  begin
    Directive := TDocDirective(ASymbol.Directives[I]);
    if SameText(Directive.Name, 'param') and
      not HasParameter(ASymbol, Directive.Subject) then
      AddDiagnostic(AProject, dsWarning, ASymbol, DiagnosticCodeUnknownParameter,
        '@param does not match a parsed parameter: ' + Directive.Subject);
  end;

  ReturnDirectiveCount := CountDirectives(ASymbol, 'returns');
  if (ReturnDirectiveCount > 0) and not ASymbol.HasReturnValue then
    AddDiagnostic(AProject, dsWarning, ASymbol, DiagnosticCodeUnexpectedReturns,
      '@returns is only valid for a value-returning routine')
  else if ReturnDirectiveCount > 1 then
    AddDiagnostic(AProject, dsWarning, ASymbol, DiagnosticCodeDuplicateReturns,
      'conflicting @returns directives on one routine');

  for I := 0 to ASymbol.Directives.Count - 1 do
  begin
    Directive := TDocDirective(ASymbol.Directives[I]);
    if not SameText(Directive.Name, 'see') then
      Continue;
    Directive.TargetSymbolID := '';
    TargetSymbol := ResolveSeeTarget(AProject, AUnit, Directive.Subject);
    if Assigned(TargetSymbol) then
      TargetSymbol := FindProjectSymbolByID(AProject, TargetSymbol.ID, TargetUnit);
    if Assigned(TargetSymbol) and
      IsEffectivelyRenderable(TargetUnit, TargetSymbol) then
      Directive.TargetSymbolID := TargetSymbol.ID
    else
      AddDiagnostic(AProject, dsWarning, ASymbol, DiagnosticCodeUnresolvedSee,
        'unresolved project-local @see target: ' + Directive.Subject);
  end;
end;

procedure ValidateGeneratedOutput(AProject: TDocProject);
var
  Routes: TStringList;
  Anchors: TStringList;
  I: Integer;
  J: Integer;
  UnitModel: TDocUnit;
  Symbol: TDocSymbol;
  Anchor: string;
  ParentSymbol: TDocSymbol;
begin
  Routes := TStringList.Create;
  Anchors := TStringList.Create;
  try
    Routes.CaseSensitive := False;
    Anchors.CaseSensitive := True;
    for I := 0 to AProject.Units.Count - 1 do
    begin
      UnitModel := TDocUnit(AProject.Units[I]);
      if UnitModel.Symbols.Count = 0 then
        Continue;
      Symbol := TDocSymbol(UnitModel.Symbols[0]);
      if UnitModel.Name = '' then
      begin
        AddDiagnostic(AProject, dsError, Symbol, DiagnosticCodeUnreachablePage,
          'generated unit page has no stable route');
        Continue;
      end;
      if Routes.IndexOf(UnitModel.Name + '.html') >= 0 then
        AddDiagnostic(AProject, dsError, Symbol, DiagnosticCodeDuplicatePage,
          'duplicate generated unit page route: ' + UnitModel.Name + '.html')
      else
        Routes.Add(UnitModel.Name + '.html');

      Anchors.Clear;
      for J := 0 to UnitModel.Symbols.Count - 1 do
      begin
        Symbol := TDocSymbol(UnitModel.Symbols[J]);
        if not IsEffectivelyRenderable(UnitModel, Symbol) then
          Continue;
        Anchor := DocumentationSymbolAnchor(Symbol);
        if Anchors.IndexOf(Anchor) >= 0 then
          AddDiagnostic(AProject, dsError, Symbol, DiagnosticCodeDuplicateAnchor,
            'duplicate generated symbol anchor: ' + Anchor)
        else
          Anchors.Add(Anchor);
        if Symbol.ParentSymbolID <> '' then
        begin
          ParentSymbol := FindSymbolByID(UnitModel, Symbol.ParentSymbolID);
          if not Assigned(ParentSymbol) or
            not IsEffectivelyRenderable(UnitModel, ParentSymbol) then
            AddDiagnostic(AProject, dsError, Symbol,
              DiagnosticCodeBrokenGeneratedLink,
              'generated parent link does not target a rendered symbol');
        end;
      end;
    end;
  finally
    Anchors.Free;
    Routes.Free;
  end;
end;

procedure ValidateProject(AProject: TDocProject);
var
  I: Integer;
  J: Integer;
  UnitModel: TDocUnit;
begin
  for I := 0 to AProject.Units.Count - 1 do
  begin
    UnitModel := TDocUnit(AProject.Units[I]);
    for J := 0 to UnitModel.Symbols.Count - 1 do
      ValidateDirectiveSemantics(AProject, UnitModel,
        TDocSymbol(UnitModel.Symbols[J]));
  end;
  ValidateGeneratedOutput(AProject);
end;

function CalculateDocumentationCoverage(AProject: TDocProject): TDocumentationCoverage;
var
  I: Integer;
  J: Integer;
  UnitModel: TDocUnit;
  Symbol: TDocSymbol;
begin
  Result.DocumentedSymbols := 0;
  Result.EligibleSymbols := 0;
  for I := 0 to AProject.Units.Count - 1 do
  begin
    UnitModel := TDocUnit(AProject.Units[I]);
    for J := 0 to UnitModel.Symbols.Count - 1 do
    begin
      Symbol := TDocSymbol(UnitModel.Symbols[J]);
      if not IsEffectivelyRenderable(UnitModel, Symbol) then
        Continue;
      Inc(Result.EligibleSymbols);
      if Trim(Symbol.MarkdownDocumentation) <> '' then
        Inc(Result.DocumentedSymbols);
    end;
  end;
  if Result.EligibleSymbols = 0 then
    Result.Percentage := 100
  else
    Result.Percentage := (Result.DocumentedSymbols * 100) div
      Result.EligibleSymbols;
end;

procedure AddDocumentationCoverageDiagnostic(AProject: TDocProject;
  AMinimumPercentage: Integer);
var
  Coverage: TDocumentationCoverage;
  UnitModel: TDocUnit;
  Symbol: TDocSymbol;
begin
  Coverage := CalculateDocumentationCoverage(AProject);
  if Coverage.Percentage >= AMinimumPercentage then
    Exit;
  if AProject.Units.Count = 0 then
    Exit;
  UnitModel := TDocUnit(AProject.Units[0]);
  if UnitModel.Symbols.Count = 0 then
    Exit;
  Symbol := TDocSymbol(UnitModel.Symbols[0]);
  AddDiagnostic(AProject, dsError, Symbol, DiagnosticCodeCoverageThreshold,
    Format('documentation coverage %d%% is below required minimum %d%% (%d of %d renderable symbols documented)',
      [Coverage.Percentage, AMinimumPercentage, Coverage.DocumentedSymbols,
       Coverage.EligibleSymbols]));
end;

function HasDiagnosticsAtOrAbove(AProject: TDocProject;
  ASeverity: TDiagnosticSeverity): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to AProject.Warnings.Count - 1 do
    if TDiagnostic(AProject.Warnings[I]).Severity >= ASeverity then
      Exit(True);
  for I := 0 to AProject.Errors.Count - 1 do
    if TDiagnostic(AProject.Errors[I]).Severity >= ASeverity then
      Exit(True);
end;

end.
