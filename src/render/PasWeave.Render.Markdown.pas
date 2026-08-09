unit PasWeave.Render.Markdown;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  PasWeave.Model;

function MarkdownUnitFilename(AUnit: TDocUnit): string;
function MarkdownSymbolAnchor(ASymbol: TDocSymbol): string;
function RenderMarkdownIndex(AProject: TDocProject): UTF8String;
function RenderMarkdownUnit(AProject: TDocProject;
  AUnit: TDocUnit): UTF8String;
procedure WriteMarkdownDocumentation(AProject: TDocProject;
  const AOutputDirectory: string);

implementation

uses
  Classes, SysUtils, PasWeave.Diagnostics, PasWeave.Render.Support,
  PasWeave.Render.Links;

type
  TSymbolKinds = set of TSymbolKind;

const
  TypeKinds: TSymbolKinds = [
    skClass, skInterface, skRecord, skEnumeration, skTypeAlias
  ];
  RoutineKinds: TSymbolKinds = [skRoutine];
  MemberKinds: TSymbolKinds = [
    skMethod, skConstructor, skDestructor, skProperty, skField
  ];
  ValueKinds: TSymbolKinds = [skConstant, skVariable];

procedure AppendLine(var AOutput: UTF8String; const ALine: UTF8String = '');
begin
  AOutput := AOutput + ALine + #10;
end;

function EscapeTableCell(const AText: string): UTF8String;
begin
  Result := UTF8String(StringReplace(AText, '|', '\|', [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result), #13#10, ' ',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result), #10, ' ',
    [rfReplaceAll]));
  Result := UTF8String(StringReplace(string(Result), #13, ' ',
    [rfReplaceAll]));
end;

function MarkdownUnitFilename(AUnit: TDocUnit): string;
begin
  Result := AUnit.Name + '.md';
end;

function MarkdownSymbolAnchor(ASymbol: TDocSymbol): string;
begin
  Result := DocumentationSymbolAnchor(ASymbol);
end;

function SortedUnits(AProject: TDocProject): TStringList;
var
  I: Integer;
  UnitModel: TDocUnit;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupAccept;
  for I := 0 to AProject.Units.Count - 1 do
  begin
    UnitModel := TDocUnit(AProject.Units[I]);
    Result.AddObject(UnitModel.Name + #1 + UnitModel.SourceFilename, UnitModel);
  end;
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

function SortedSymbols(AUnit: TDocUnit; AKinds: TSymbolKinds): TStringList;
var
  I: Integer;
  Symbol: TDocSymbol;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupAccept;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if (Symbol.Kind in AKinds) and IsEffectivelyRenderable(AUnit, Symbol) then
      Result.AddObject(Symbol.QualifiedName + #1 + Symbol.ID, Symbol);
  end;
end;

function UnitSymbol(AUnit: TDocUnit): TDocSymbol;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AUnit.Symbols.Count - 1 do
    if TDocSymbol(AUnit.Symbols[I]).Kind = skUnit then
      Exit(TDocSymbol(AUnit.Symbols[I]));
end;

function RenderableSymbolCount(AUnit: TDocUnit): Integer;
var
  I: Integer;
  Symbol: TDocSymbol;
begin
  Result := 0;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if IsEffectivelyRenderable(AUnit, Symbol) then
      Inc(Result);
  end;
end;

function DocumentedSymbolCount(AUnit: TDocUnit): Integer;
var
  I: Integer;
  Symbol: TDocSymbol;
begin
  Result := 0;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if IsEffectivelyRenderable(AUnit, Symbol) and
      (Trim(Symbol.MarkdownDocumentation) <> '') then
      Inc(Result);
  end;
end;

procedure RenderDirectives(var AOutput: UTF8String; AProject: TDocProject;
  AUnit: TDocUnit; ASymbol: TDocSymbol);
var
  I: Integer;
  Directive: TDocDirective;
  HasParameters: Boolean;
  HasRaises: Boolean;
  HasSee: Boolean;
  HasReturns: Boolean;
  HasSince: Boolean;
begin
  HasParameters := False;
  HasRaises := False;
  HasSee := False;
  HasReturns := False;
  HasSince := False;

  for I := 0 to ASymbol.Directives.Count - 1 do
  begin
    Directive := TDocDirective(ASymbol.Directives[I]);
    if Directive.Name = 'deprecated' then
    begin
      if Directive.Text <> '' then
        AppendLine(AOutput, '> **Deprecated:** ' + UTF8String(Directive.Text))
      else
        AppendLine(AOutput, '> **Deprecated.**');
      AppendLine(AOutput);
    end;
  end;

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'param' then
    begin
      if not HasParameters then
      begin
        AppendLine(AOutput, '#### Parameters');
        AppendLine(AOutput);
        AppendLine(AOutput, '| Name | Description |');
        AppendLine(AOutput, '|---|---|');
        HasParameters := True;
      end;
      Directive := TDocDirective(ASymbol.Directives[I]);
      AppendLine(AOutput, '| `' + UTF8String(Directive.Subject) + '` | ' +
        EscapeTableCell(Directive.Text) + ' |');
    end;
  if HasParameters then
    AppendLine(AOutput);

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'returns' then
    begin
      Directive := TDocDirective(ASymbol.Directives[I]);
      if not HasReturns then
      begin
        AppendLine(AOutput, '#### Returns');
        AppendLine(AOutput);
        HasReturns := True;
      end;
      AppendLine(AOutput, UTF8String(Directive.Text));
      AppendLine(AOutput);
    end;

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'raises' then
    begin
      if not HasRaises then
      begin
        AppendLine(AOutput, '#### Raises');
        AppendLine(AOutput);
        AppendLine(AOutput, '| Exception | Condition |');
        AppendLine(AOutput, '|---|---|');
        HasRaises := True;
      end;
      Directive := TDocDirective(ASymbol.Directives[I]);
      AppendLine(AOutput, '| `' + UTF8String(Directive.Subject) + '` | ' +
        EscapeTableCell(Directive.Text) + ' |');
    end;
  if HasRaises then
    AppendLine(AOutput);

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'since' then
    begin
      Directive := TDocDirective(ASymbol.Directives[I]);
      if not HasSince then
        HasSince := True;
      if Directive.Text <> '' then
        AppendLine(AOutput, '**Since:** `' + UTF8String(Directive.Subject) +
          '` - ' + UTF8String(Directive.Text))
      else
        AppendLine(AOutput, '**Since:** `' + UTF8String(Directive.Subject) +
          '`');
    end;
  if HasSince then
    AppendLine(AOutput);

  for I := 0 to ASymbol.Directives.Count - 1 do
    if TDocDirective(ASymbol.Directives[I]).Name = 'see' then
    begin
      if not HasSee then
      begin
        AppendLine(AOutput, '#### See also');
        AppendLine(AOutput);
        HasSee := True;
      end;
      Directive := TDocDirective(ASymbol.Directives[I]);
      if Directive.Text <> '' then
        AppendLine(AOutput, '- ' + RenderMarkdownSeeLink(AProject, AUnit,
          Directive) + ' - ' + UTF8String(Directive.Text))
      else
        AppendLine(AOutput, '- ' + RenderMarkdownSeeLink(AProject, AUnit,
          Directive));
    end;
  if HasSee then
    AppendLine(AOutput);
end;

procedure RenderDocumentation(var AOutput: UTF8String; AProject: TDocProject;
  AUnit: TDocUnit; ASymbol: TDocSymbol);
begin
  if Trim(ASymbol.MarkdownDocumentation) = '' then
  begin
    AppendLine(AOutput,
      '> **Warning:** This API symbol has no documentation.');
    AppendLine(AOutput);
  end
  else
  begin
    AOutput := AOutput + UTF8String(ASymbol.MarkdownDocumentation);
    if (AOutput = '') or (AOutput[Length(AOutput)] <> #10) then
      AppendLine(AOutput);
    AppendLine(AOutput);
  end;
  RenderDirectives(AOutput, AProject, AUnit, ASymbol);
end;

procedure RenderDeclaration(var AOutput: UTF8String;
  const ADeclaration: string);
begin
  if ADeclaration = '' then
    Exit;
  AppendLine(AOutput, '```pascal');
  AOutput := AOutput + UTF8String(ADeclaration);
  if AOutput[Length(AOutput)] <> #10 then
    AppendLine(AOutput);
  AppendLine(AOutput, '```');
  AppendLine(AOutput);
end;

function SymbolLocation(ASymbol: TDocSymbol): string;
begin
  Result := ASymbol.SourceFilename;
  if ASymbol.SourceLine > 0 then
  begin
    Result := Result + ':' + IntToStr(ASymbol.SourceLine);
    if ASymbol.SourceColumn > 0 then
      Result := Result + ':' + IntToStr(ASymbol.SourceColumn);
  end;
end;

procedure RenderSymbol(var AOutput: UTF8String; AProject: TDocProject;
  AUnit: TDocUnit; ASymbol: TDocSymbol);
var
  ParentSymbol: TDocSymbol;
begin
  AppendLine(AOutput, '<a id="' +
    UTF8String(MarkdownSymbolAnchor(ASymbol)) + '"></a>');
  AppendLine(AOutput, '### `' + UTF8String(ASymbol.QualifiedName) + '`');
  AppendLine(AOutput);
  AppendLine(AOutput, '**Kind:** `' + UTF8String(SymbolKindName(ASymbol.Kind)) +
    '`; **Visibility:** `' +
    UTF8String(SymbolVisibilityName(ASymbol.Visibility)) +
    '`; **Source:** `' + UTF8String(SymbolLocation(ASymbol)) + '`');
  AppendLine(AOutput);

  ParentSymbol := FindSymbolByID(AUnit, ASymbol.ParentSymbolID);
  if Assigned(ParentSymbol) and (ParentSymbol.Kind <> skUnit) then
  begin
    AppendLine(AOutput, '**Parent:** [`' +
      UTF8String(ParentSymbol.QualifiedName) + '`](#' +
      UTF8String(MarkdownSymbolAnchor(ParentSymbol)) + ')');
    AppendLine(AOutput);
  end;

  RenderDeclaration(AOutput, ASymbol.DeclarationText);
  RenderDocumentation(AOutput, AProject, AUnit, ASymbol);
end;

procedure RenderSymbolGroup(var AOutput: UTF8String; AProject: TDocProject;
  AUnit: TDocUnit; const AHeading: string; AKinds: TSymbolKinds);
var
  Symbols: TStringList;
  I: Integer;
begin
  Symbols := SortedSymbols(AUnit, AKinds);
  try
    if Symbols.Count = 0 then
      Exit;
    AppendLine(AOutput, '## ' + UTF8String(AHeading));
    AppendLine(AOutput);
    for I := 0 to Symbols.Count - 1 do
      RenderSymbol(AOutput, AProject, AUnit,
        TDocSymbol(Symbols.Objects[I]));
  finally
    Symbols.Free;
  end;
end;

function DiagnosticLocation(ADiagnostic: TDiagnostic): string;
begin
  Result := ADiagnostic.SourceFilename;
  if ADiagnostic.SourceLine > 0 then
  begin
    Result := Result + ':' + IntToStr(ADiagnostic.SourceLine);
    if ADiagnostic.SourceColumn > 0 then
      Result := Result + ':' + IntToStr(ADiagnostic.SourceColumn);
  end;
end;

function RenderMarkdownIndex(AProject: TDocProject): UTF8String;
var
  Units: TStringList;
  I: Integer;
  UnitModel: TDocUnit;
  PublicCount: Integer;
  DocumentedCount: Integer;
  Diagnostic: TDiagnostic;
begin
  Result := '';
  AppendLine(Result, '# ' + UTF8String(AProject.Name) + ' API');
  AppendLine(Result);
  AppendLine(Result, '**Source root:** `' + UTF8String(AProject.SourceRoot) +
    '`');
  AppendLine(Result);
  if AProject.Units.Count = 1 then
    AppendLine(Result, 'Generated from 1 unit and ' +
      UTF8String(IntToStr(AProject.SymbolCount)) + ' symbols.')
  else
    AppendLine(Result, 'Generated from ' +
      UTF8String(IntToStr(AProject.Units.Count)) + ' units and ' +
      UTF8String(IntToStr(AProject.SymbolCount)) + ' symbols.');
  AppendLine(Result);

  PublicCount := 0;
  DocumentedCount := 0;
  for I := 0 to AProject.Units.Count - 1 do
  begin
    Inc(PublicCount, RenderableSymbolCount(TDocUnit(AProject.Units[I])));
    Inc(DocumentedCount, DocumentedSymbolCount(TDocUnit(AProject.Units[I])));
  end;
  AppendLine(Result, '**Documented API symbols:** ' +
    UTF8String(IntToStr(DocumentedCount)) + ' of ' +
    UTF8String(IntToStr(PublicCount)));
  AppendLine(Result);

  AppendLine(Result, '## Units');
  AppendLine(Result);
  AppendLine(Result, '| Unit | Source | API symbols | Documented |');
  AppendLine(Result, '|---|---|---:|---:|');
  Units := SortedUnits(AProject);
  try
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      AppendLine(Result, '| [' + UTF8String(UnitModel.Name) + '](units/' +
        UTF8String(MarkdownUnitFilename(UnitModel)) + ') | `' +
        EscapeTableCell(UnitModel.SourceFilename) + '` | ' +
        UTF8String(IntToStr(RenderableSymbolCount(UnitModel))) + ' | ' +
        UTF8String(IntToStr(DocumentedSymbolCount(UnitModel))) + ' |');
    end;
  finally
    Units.Free;
  end;
  AppendLine(Result);

  if (AProject.Warnings.Count > 0) or (AProject.Errors.Count > 0) then
  begin
    AppendLine(Result, '## Build diagnostics');
    AppendLine(Result);
    for I := 0 to AProject.Warnings.Count - 1 do
    begin
      Diagnostic := TDiagnostic(AProject.Warnings[I]);
      AppendLine(Result, '- **Warning ' + UTF8String(Diagnostic.Code) + '** `' +
        UTF8String(DiagnosticLocation(Diagnostic)) + '`: ' +
        UTF8String(Diagnostic.MessageText));
    end;
    for I := 0 to AProject.Errors.Count - 1 do
    begin
      Diagnostic := TDiagnostic(AProject.Errors[I]);
      AppendLine(Result, '- **Error ' + UTF8String(Diagnostic.Code) + '** `' +
        UTF8String(DiagnosticLocation(Diagnostic)) + '`: ' +
        UTF8String(Diagnostic.MessageText));
    end;
    AppendLine(Result);
  end;
end;

function RenderMarkdownUnit(AProject: TDocProject;
  AUnit: TDocUnit): UTF8String;
var
  I: Integer;
  Dependency: string;
  DependencyUnit: TDocUnit;
  ThisUnitSymbol: TDocSymbol;
begin
  Result := '';
  AppendLine(Result, '# Unit `' + UTF8String(AUnit.Name) + '`');
  AppendLine(Result);
  AppendLine(Result, '[Project index](../index.md)');
  AppendLine(Result);
  AppendLine(Result, '**Source:** `' + UTF8String(AUnit.SourceFilename) + '`');
  AppendLine(Result);

  ThisUnitSymbol := UnitSymbol(AUnit);
  if Assigned(ThisUnitSymbol) then
  begin
    if Trim(ThisUnitSymbol.MarkdownDocumentation) = '' then
    begin
      AppendLine(Result,
        '> **Warning:** This unit has no documentation.');
      AppendLine(Result);
    end
    else
      RenderDocumentation(Result, AProject, AUnit, ThisUnitSymbol);
  end;

  AppendLine(Result, '## Interface dependencies');
  AppendLine(Result);
  if AUnit.InterfaceDependencies.Count = 0 then
  begin
    AppendLine(Result, 'None.');
    AppendLine(Result);
  end
  else
  begin
    for I := 0 to AUnit.InterfaceDependencies.Count - 1 do
    begin
      Dependency := AUnit.InterfaceDependencies[I];
      DependencyUnit := FindUnitByName(AProject, Dependency);
      if Assigned(DependencyUnit) then
        AppendLine(Result, '- [`' + UTF8String(Dependency) + '`](' +
          UTF8String(MarkdownUnitFilename(DependencyUnit)) + ')')
      else
        AppendLine(Result, '- `' + UTF8String(Dependency) + '`');
    end;
    AppendLine(Result);
  end;

  RenderSymbolGroup(Result, AProject, AUnit, 'Types', TypeKinds);
  RenderSymbolGroup(Result, AProject, AUnit, 'Routines', RoutineKinds);
  RenderSymbolGroup(Result, AProject, AUnit, 'Members', MemberKinds);
  RenderSymbolGroup(Result, AProject, AUnit, 'Constants and variables',
    ValueKinds);
end;

procedure WriteUTF8File(const AFileName: string; const AData: UTF8String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(AData) > 0 then
      Stream.WriteBuffer(AData[1], Length(AData));
  finally
    Stream.Free;
  end;
end;

procedure WriteMarkdownDocumentation(AProject: TDocProject;
  const AOutputDirectory: string);
var
  UnitsDirectory: string;
  Units: TStringList;
  I: Integer;
  UnitModel: TDocUnit;
begin
  UnitsDirectory := IncludeTrailingPathDelimiter(AOutputDirectory) + 'units';
  if not ForceDirectories(UnitsDirectory) then
    raise EFCreateError.CreateFmt('cannot create Markdown output directory: %s',
      [UnitsDirectory]);

  WriteUTF8File(IncludeTrailingPathDelimiter(AOutputDirectory) + 'index.md',
    RenderMarkdownIndex(AProject));

  Units := SortedUnits(AProject);
  try
    for I := 0 to Units.Count - 1 do
    begin
      UnitModel := TDocUnit(Units.Objects[I]);
      WriteUTF8File(IncludeTrailingPathDelimiter(UnitsDirectory) +
        MarkdownUnitFilename(UnitModel),
        RenderMarkdownUnit(AProject, UnitModel));
    end;
  finally
    Units.Free;
  end;
end;

end.
