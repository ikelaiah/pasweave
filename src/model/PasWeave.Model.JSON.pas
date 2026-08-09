unit PasWeave.Model.JSON;

{$mode objfpc}{$H+}

interface

uses
  PasWeave.Model;

function ProjectToJSON(AProject: TDocProject): UTF8String;
procedure WriteProjectJSON(AProject: TDocProject; const AFileName: string);
function DiagnosticsToJSON(AProject: TDocProject): UTF8String;
procedure WriteDiagnosticsJSON(AProject: TDocProject; const AFileName: string);

implementation

uses
  Classes, SysUtils, FPJSON, PasWeave.Diagnostics;

function SortedObjects(AList: TList; const AKeyPrefix: string): TStringList;
var
  I: Integer;
  Key: string;
begin
  Result := TStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupAccept;
  for I := 0 to AList.Count - 1 do
  begin
    if TObject(AList[I]) is TDocUnit then
      Key := TDocUnit(AList[I]).Name + #1 + TDocUnit(AList[I]).SourceFilename
    else if TObject(AList[I]) is TDocSymbol then
      Key := TDocSymbol(AList[I]).ID
    else if TObject(AList[I]) is TDiagnostic then
      Key := TDiagnostic(AList[I]).SourceFilename + #1 +
        Format('%.10d', [TDiagnostic(AList[I]).SourceLine]) + #1 +
        Format('%.10d', [TDiagnostic(AList[I]).SourceColumn]) + #1 +
        TDiagnostic(AList[I]).MessageText
    else
      Key := AKeyPrefix + Format('%.10d', [I]);
    Result.AddObject(Key, TObject(AList[I]));
  end;
end;

function StringArrayToJSON(AStrings: TStrings; ASort: Boolean): TJSONArray;
var
  Values: TStringList;
  I: Integer;
begin
  Result := TJSONArray.Create;
  Values := TStringList.Create;
  try
    Values.Assign(AStrings);
    if ASort then
    begin
      Values.Sorted := True;
      Values.CaseSensitive := True;
      Values.Duplicates := dupIgnore;
    end;
    for I := 0 to Values.Count - 1 do
      Result.Add(Values[I]);
  finally
    Values.Free;
  end;
end;

function DirectivesToJSON(ADirectives: TList): TJSONArray;
var
  I: Integer;
  Item: TJSONObject;
  Directive: TDocDirective;
begin
  Result := TJSONArray.Create;
  for I := 0 to ADirectives.Count - 1 do
  begin
    Directive := TDocDirective(ADirectives[I]);
    Item := TJSONObject.Create;
    Item.Add('name', Directive.Name);
    Item.Add('subject', Directive.Subject);
    Item.Add('text', Directive.Text);
    Item.Add('targetSymbolId', Directive.TargetSymbolID);
    Result.Add(Item);
  end;
end;

function TypeRelationshipsToJSON(ARelationships: TList): TJSONArray;
var
  I: Integer;
  Item: TJSONObject;
  Relationship: TDocTypeRelationship;
  Sorted: TStringList;
begin
  Result := TJSONArray.Create;
  Sorted := TStringList.Create;
  try
    Sorted.Sorted := True;
    Sorted.CaseSensitive := True;
    Sorted.Duplicates := dupAccept;
    for I := 0 to ARelationships.Count - 1 do
    begin
      Relationship := TDocTypeRelationship(ARelationships[I]);
      Sorted.AddObject(TypeRelationshipKindName(Relationship.Kind) + #1 +
        Relationship.TargetName + #1 + Relationship.DisplayName + #1 +
        Relationship.TargetSymbolID, Relationship);
    end;
    for I := 0 to Sorted.Count - 1 do
    begin
      Relationship := TDocTypeRelationship(Sorted.Objects[I]);
      Item := TJSONObject.Create;
      Item.Add('kind', TypeRelationshipKindName(Relationship.Kind));
      Item.Add('targetName', Relationship.TargetName);
      Item.Add('displayName', Relationship.DisplayName);
      Item.Add('targetSymbolId', Relationship.TargetSymbolID);
      Result.Add(Item);
    end;
  finally
    Sorted.Free;
  end;
end;

function SymbolToJSON(ASymbol: TDocSymbol): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('id', ASymbol.ID);
  Result.Add('name', ASymbol.Name);
  Result.Add('qualifiedName', ASymbol.QualifiedName);
  Result.Add('kind', SymbolKindName(ASymbol.Kind));
  Result.Add('visibility', SymbolVisibilityName(ASymbol.Visibility));
  Result.Add('declaration', ASymbol.DeclarationText);
  Result.Add('sourceFilename', ASymbol.SourceFilename);
  Result.Add('sourceLine', ASymbol.SourceLine);
  Result.Add('sourceColumn', ASymbol.SourceColumn);
  Result.Add('rawDocumentation', ASymbol.RawDocumentation);
  Result.Add('markdownDocumentation', ASymbol.MarkdownDocumentation);
  Result.Add('directives', DirectivesToJSON(ASymbol.Directives));
  Result.Add('parameterNames', StringArrayToJSON(ASymbol.ParameterNames, False));
  Result.Add('hasReturnValue', ASymbol.HasReturnValue);
  Result.Add('typeRelationships',
    TypeRelationshipsToJSON(ASymbol.TypeRelationships));
  Result.Add('parentSymbolId', ASymbol.ParentSymbolID);
  Result.Add('relatedSymbolIds',
    StringArrayToJSON(ASymbol.RelatedSymbolIDs, True));
end;

function SymbolsToJSON(ASymbols: TList): TJSONArray;
var
  Sorted: TStringList;
  I: Integer;
begin
  Result := TJSONArray.Create;
  Sorted := SortedObjects(ASymbols, 'symbol');
  try
    for I := 0 to Sorted.Count - 1 do
      Result.Add(SymbolToJSON(TDocSymbol(Sorted.Objects[I])));
  finally
    Sorted.Free;
  end;
end;

function UnitToJSON(AUnit: TDocUnit): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('name', AUnit.Name);
  Result.Add('sourceFilename', AUnit.SourceFilename);
  Result.Add('interfaceDependencies',
    StringArrayToJSON(AUnit.InterfaceDependencies, True));
  Result.Add('symbols', SymbolsToJSON(AUnit.Symbols));
end;

function UnitsToJSON(AUnits: TList): TJSONArray;
var
  Sorted: TStringList;
  I: Integer;
begin
  Result := TJSONArray.Create;
  Sorted := SortedObjects(AUnits, 'unit');
  try
    for I := 0 to Sorted.Count - 1 do
      Result.Add(UnitToJSON(TDocUnit(Sorted.Objects[I])));
  finally
    Sorted.Free;
  end;
end;

function DiagnosticListToJSON(ADiagnostics: TList): TJSONArray;
var
  Sorted: TStringList;
  I: Integer;
  Diagnostic: TDiagnostic;
  Item: TJSONObject;
begin
  Result := TJSONArray.Create;
  Sorted := SortedObjects(ADiagnostics, 'diagnostic');
  try
    for I := 0 to Sorted.Count - 1 do
    begin
      Diagnostic := TDiagnostic(Sorted.Objects[I]);
      Item := TJSONObject.Create;
      Item.Add('code', Diagnostic.Code);
      Item.Add('severity', DiagnosticSeverityName(Diagnostic.Severity));
      Item.Add('sourceFilename', Diagnostic.SourceFilename);
      Item.Add('sourceLine', Diagnostic.SourceLine);
      Item.Add('sourceColumn', Diagnostic.SourceColumn);
      Item.Add('message', Diagnostic.MessageText);
      Item.Add('details', Diagnostic.Details);
      Result.Add(Item);
    end;
  finally
    Sorted.Free;
  end;
end;

function ProjectToJSON(AProject: TDocProject): UTF8String;
var
  Root: TJSONObject;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('schemaVersion', 1);
    Root.Add('name', AProject.Name);
    Root.Add('sourceRoot', AProject.SourceRoot);
    Root.Add('units', UnitsToJSON(AProject.Units));
    Root.Add('warnings', DiagnosticListToJSON(AProject.Warnings));
    Root.Add('errors', DiagnosticListToJSON(AProject.Errors));
    Result := Root.FormatJSON([], 2);
    Result := UTF8String(StringReplace(string(Result), #13#10, #10,
      [rfReplaceAll]));
    if (Result = '') or (Result[Length(Result)] <> #10) then
      Result := Result + #10;
  finally
    Root.Free;
  end;
end;

function DiagnosticsToJSON(AProject: TDocProject): UTF8String;
var
  Root: TJSONObject;
  Diagnostics: TList;
  I: Integer;
begin
  Root := TJSONObject.Create;
  Diagnostics := TList.Create;
  try
    for I := 0 to AProject.Warnings.Count - 1 do
      Diagnostics.Add(AProject.Warnings[I]);
    for I := 0 to AProject.Errors.Count - 1 do
      Diagnostics.Add(AProject.Errors[I]);
    Root.Add('schemaVersion', 1);
    Root.Add('diagnostics', DiagnosticListToJSON(Diagnostics));
    Root.Add('warningCount', AProject.Warnings.Count);
    Root.Add('errorCount', AProject.Errors.Count);
    Result := UTF8String(StringReplace(string(Root.FormatJSON([], 2)), #13#10,
      #10, [rfReplaceAll]));
    if (Result = '') or (Result[Length(Result)] <> #10) then
      Result := Result + #10;
  finally
    Diagnostics.Free;
    Root.Free;
  end;
end;

procedure WriteDiagnosticsJSON(AProject: TDocProject; const AFileName: string);
var
  OutputStream: TFileStream;
  Data: UTF8String;
  ParentDirectory: string;
begin
  ParentDirectory := ExtractFileDir(AFileName);
  if (ParentDirectory <> '') and not ForceDirectories(ParentDirectory) then
    raise EFCreateError.CreateFmt('cannot create output directory: %s',
      [ParentDirectory]);
  Data := DiagnosticsToJSON(AProject);
  OutputStream := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(Data) > 0 then
      OutputStream.WriteBuffer(Data[1], Length(Data));
  finally
    OutputStream.Free;
  end;
end;

procedure WriteProjectJSON(AProject: TDocProject; const AFileName: string);
var
  OutputStream: TFileStream;
  Data: UTF8String;
  ParentDirectory: string;
begin
  ParentDirectory := ExtractFileDir(AFileName);
  if (ParentDirectory <> '') and not ForceDirectories(ParentDirectory) then
    raise EFCreateError.CreateFmt('cannot create output directory: %s',
      [ParentDirectory]);

  Data := ProjectToJSON(AProject);
  OutputStream := TFileStream.Create(AFileName, fmCreate);
  try
    if Length(Data) > 0 then
      OutputStream.WriteBuffer(Data[1], Length(Data));
  finally
    OutputStream.Free;
  end;
end;

end.
