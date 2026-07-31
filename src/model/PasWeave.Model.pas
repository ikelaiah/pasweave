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

  TDocDirective = class
  public
    Name: string;
    Subject: string;
    Text: string;
    constructor Create(const AName, ASubject, AText: string);
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

implementation

constructor TDocDirective.Create(const AName, ASubject, AText: string);
begin
  inherited Create;
  Name := AName;
  Subject := ASubject;
  Text := AText;
end;

constructor TDocSymbol.Create;
begin
  inherited Create;
  Directives := TObjectList.Create(True);
  RelatedSymbolIDs := TStringList.Create;
end;

destructor TDocSymbol.Destroy;
begin
  RelatedSymbolIDs.Free;
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

end.

