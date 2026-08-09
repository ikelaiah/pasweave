unit PasWeave.Model;

{$mode objfpc}{$H+}

interface

uses
  Classes, Contnrs, PasWeave.Diagnostics;

type
  TSymbolKind = (
    skUnit,
    skClass,
    skInterface,
    skRecord,
    skEnumeration,
    skTypeAlias,
    skRoutine,
    skMethod,
    skConstructor,
    skDestructor,
    skProperty,
    skField,
    skConstant,
    skVariable
  );

  TSymbolVisibility = (
    svDefault,
    svPrivate,
    svProtected,
    svPublic,
    svPublished,
    svAutomated,
    svStrictPrivate,
    svStrictProtected
  );

  TTypeRelationshipKind = (
    trkInheritance,
    trkImplementation
  );

  TDocDirective = class
  public
    Name: string;
    Subject: string;
    Text: string;
    TargetSymbolID: string;
    constructor Create(const AName, ASubject, AText: string);
  end;

  TDocTypeRelationship = class
  public
    Kind: TTypeRelationshipKind;
    TargetName: string;
    DisplayName: string;
    TargetSymbolID: string;
    constructor Create(AKind: TTypeRelationshipKind;
      const ATargetName, ADisplayName: string);
  end;

  TDocSymbol = class
  public
    ID: string;
    Name: string;
    QualifiedName: string;
    Kind: TSymbolKind;
    Visibility: TSymbolVisibility;
    DeclarationText: string;
    SourceFilename: string;
    SourceLine: Integer;
    SourceColumn: Integer;
    RawDocumentation: string;
    MarkdownDocumentation: string;
    Directives: TObjectList;
    ParameterNames: TStringList;
    HasReturnValue: Boolean;
    TypeRelationships: TObjectList;
    ParentSymbolID: string;
    RelatedSymbolIDs: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

  TDocUnit = class
  public
    Name: string;
    SourceFilename: string;
    InterfaceDependencies: TStringList;
    Symbols: TObjectList;
    constructor Create;
    destructor Destroy; override;
  end;

  TDocProject = class
  public
    Name: string;
    SourceRoot: string;
    Units: TObjectList;
    Warnings: TObjectList;
    Errors: TObjectList;
    constructor Create;
    destructor Destroy; override;
    function SymbolCount: Integer;
  end;

function SymbolKindName(AKind: TSymbolKind): string;
function SymbolVisibilityName(AVisibility: TSymbolVisibility): string;
function TypeRelationshipKindName(AKind: TTypeRelationshipKind): string;
function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
function FindSymbolByID(AUnit: TDocUnit; const AID: string): TDocSymbol;
function FindProjectSymbolByID(AProject: TDocProject; const AID: string;
  out AUnit: TDocUnit): TDocSymbol;

implementation

uses
  SysUtils;

constructor TDocDirective.Create(const AName, ASubject, AText: string);
begin
  inherited Create;
  Name := AName;
  Subject := ASubject;
  Text := AText;
end;

constructor TDocTypeRelationship.Create(AKind: TTypeRelationshipKind;
  const ATargetName, ADisplayName: string);
begin
  inherited Create;
  Kind := AKind;
  TargetName := ATargetName;
  DisplayName := ADisplayName;
end;

constructor TDocSymbol.Create;
begin
  inherited Create;
  Directives := TObjectList.Create(True);
  ParameterNames := TStringList.Create;
  TypeRelationships := TObjectList.Create(True);
  RelatedSymbolIDs := TStringList.Create;
  RelatedSymbolIDs.Sorted := True;
  RelatedSymbolIDs.CaseSensitive := True;
  RelatedSymbolIDs.Duplicates := dupIgnore;
end;

destructor TDocSymbol.Destroy;
begin
  RelatedSymbolIDs.Free;
  TypeRelationships.Free;
  ParameterNames.Free;
  Directives.Free;
  inherited Destroy;
end;

constructor TDocUnit.Create;
begin
  inherited Create;
  InterfaceDependencies := TStringList.Create;
  InterfaceDependencies.Sorted := True;
  InterfaceDependencies.CaseSensitive := False;
  InterfaceDependencies.Duplicates := dupIgnore;
  Symbols := TObjectList.Create(True);
end;

destructor TDocUnit.Destroy;
begin
  Symbols.Free;
  InterfaceDependencies.Free;
  inherited Destroy;
end;

constructor TDocProject.Create;
begin
  inherited Create;
  Units := TObjectList.Create(True);
  Warnings := TObjectList.Create(True);
  Errors := TObjectList.Create(True);
end;

destructor TDocProject.Destroy;
begin
  Errors.Free;
  Warnings.Free;
  Units.Free;
  inherited Destroy;
end;

function TDocProject.SymbolCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Units.Count - 1 do
    Inc(Result, TDocUnit(Units[I]).Symbols.Count);
end;

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

function SymbolKindName(AKind: TSymbolKind): string;
begin
  case AKind of
    skUnit: Result := 'unit';
    skClass: Result := 'class';
    skInterface: Result := 'interface';
    skRecord: Result := 'record';
    skEnumeration: Result := 'enumeration';
    skTypeAlias: Result := 'type-alias';
    skRoutine: Result := 'routine';
    skMethod: Result := 'method';
    skConstructor: Result := 'constructor';
    skDestructor: Result := 'destructor';
    skProperty: Result := 'property';
    skField: Result := 'field';
    skConstant: Result := 'constant';
    skVariable: Result := 'variable';
  end;
end;

function SymbolVisibilityName(AVisibility: TSymbolVisibility): string;
begin
  case AVisibility of
    svDefault: Result := 'default';
    svPrivate: Result := 'private';
    svProtected: Result := 'protected';
    svPublic: Result := 'public';
    svPublished: Result := 'published';
    svAutomated: Result := 'automated';
    svStrictPrivate: Result := 'strict-private';
    svStrictProtected: Result := 'strict-protected';
  end;
end;

function TypeRelationshipKindName(AKind: TTypeRelationshipKind): string;
begin
  case AKind of
    trkInheritance: Result := 'inherits';
    trkImplementation: Result := 'implements';
  end;
end;

function AnchorNamePart(const AText: string): string;
var
  I: Integer;
  C: Char;
  LastWasDash: Boolean;
begin
  Result := '';
  LastWasDash := False;
  for I := 1 to Length(AText) do
  begin
    C := LowerCase(AText[I]);
    if C in ['a'..'z', '0'..'9'] then
    begin
      Result := Result + C;
      LastWasDash := False;
    end
    else if not LastWasDash and (Result <> '') then
    begin
      Result := Result + '-';
      LastWasDash := True;
    end;
  end;
  while (Result <> '') and (Result[Length(Result)] = '-') do
    Delete(Result, Length(Result), 1);
  if Result = '' then
    Result := 'symbol';
end;

function StableHash64(const AText: string): QWord;
var
  I: Integer;
begin
  Result := QWord($CBF29CE484222325);
  for I := 1 to Length(AText) do
  begin
    Result := Result xor Byte(AText[I]);
    Result := Result * QWord(1099511628211);
  end;
end;

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
begin
  Result := 'symbol-' + AnchorNamePart(ASymbol.QualifiedName) + '-' +
    LowerCase(IntToHex(StableHash64(ASymbol.ID), 16));
end;

end.
