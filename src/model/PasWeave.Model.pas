unit PasWeave.Model;

{$mode objfpc}{$H+}

interface

uses
  Classes, Contnrs, PasWeave.Diagnostics;

type
  /// The declaration kind attached to a documented symbol.
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

  /// Source visibility; `svDefault` covers declarations outside a section.
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

  /// How a type relates to another type.
  TTypeRelationshipKind = (
    trkInheritance,
    trkImplementation
  );

  /// One structured documentation directive from a comment group.
  TDocDirective = class
  public
    /// Directive name without the `@`, for example `param` or `returns`.
    Name: string;
    /// Subject such as a parameter name; empty for `@returns` and `@since`.
    Subject: string;
    /// Directive body text with the name and subject removed.
    Text: string;
    /// Resolved symbol target for reference directives such as `@see`.
    TargetSymbolID: string;
    constructor Create(const AName, ASubject, AText: string);
  end;

  /// A resolved or unresolved inheritance/implementation relationship.
  TDocTypeRelationship = class
  public
    Kind: TTypeRelationshipKind;
    /// As written in the source, for example `TBase` or a specialization.
    TargetName: string;
    /// Display text when the source spelling differs from `TargetName`.
    DisplayName: string;
    /// Resolved target symbol ID; empty when unresolved.
    TargetSymbolID: string;
    constructor Create(AKind: TTypeRelationshipKind;
      const ATargetName, ADisplayName: string);
  end;

  /// One renderable declaration in a unit.
  TDocSymbol = class
  public
    /// Stable identity derived from kind, qualified name, and declaration.
    ID: string;
    Name: string;
    QualifiedName: string;
    Kind: TSymbolKind;
    Visibility: TSymbolVisibility;
    /// Canonical, optionally wrapped declaration text.
    DeclarationText: string;
    /// Unit-relative source path.
    SourceFilename: string;
    SourceLine: Integer;
    SourceColumn: Integer;
    /// Original comment text including delimiters.
    RawDocumentation: string;
    /// Normalized documentation body with directives removed.
    MarkdownDocumentation: string;
    /// Owned `TDocDirective` objects.
    Directives: TObjectList;
    /// Declared parameter names for routines.
    ParameterNames: TStringList;
    /// True when a routine declares a return type.
    HasReturnValue: Boolean;
    /// Owned `TDocTypeRelationship` objects.
    TypeRelationships: TObjectList;
    /// Owning symbol ID for members; empty for top-level declarations.
    ParentSymbolID: string;
    /// Sorted, deduplicated related symbol IDs.
    RelatedSymbolIDs: TStringList;
    constructor Create;
    destructor Destroy; override;
  end;

  /// One parsed source unit.
  TDocUnit = class
  public
    Name: string;
    /// Unit-relative source path.
    SourceFilename: string;
    /// Sorted, case-insensitive names of interface `uses` dependencies.
    InterfaceDependencies: TStringList;
    /// Owned `TDocSymbol` objects in declaration order.
    Symbols: TObjectList;
    constructor Create;
    destructor Destroy; override;
  end;

  /// The complete documentation model for a build.
  TDocProject = class
  public
    Name: string;
    SourceRoot: string;
    RepositoryURL: string;
    SourceLinkTemplate: string;
    /// Header brand mark; see @link(IsValidProjectMark).
    ProjectMark: string;
    /// Primary accent color; see @link(IsValidThemeColor).
    ThemeAccent: string;
    /// Secondary accent color.
    ThemeAccentAlt: string;
    /// Body font family; see @link(IsValidThemeFont).
    ThemeFont: string;
    /// Owned `TDocUnit` objects in discovery order.
    Units: TObjectList;
    /// Owned warnings (`TDiagnostic`).
    Warnings: TObjectList;
    /// Owned errors (`TDiagnostic`).
    Errors: TObjectList;
    constructor Create;
    destructor Destroy; override;
    /// Total declaration count across all units, including unit symbols.
    function SymbolCount: Integer;
  end;

const
  /// Brand mark used when none is configured.
  DefaultProjectMark = 'PW';
  DefaultThemeAccent = '#5b4ee6';
  DefaultThemeAccentAlt = '#0e8f81';
  DefaultThemeFont = 'Inter';

/// Stable lowercase name for a symbol kind, used in JSON and diagnostics.
function SymbolKindName(AKind: TSymbolKind): string;
/// Stable lowercase name for a visibility, used in JSON and diagnostics.
function SymbolVisibilityName(AVisibility: TSymbolVisibility): string;
/// Stable relationship verb (`inherits` or `implements`).
function TypeRelationshipKindName(AKind: TTypeRelationshipKind): string;
/// Deterministic, human-readable, overload-safe anchor for a symbol.
function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
/// Finds a symbol by exact ID inside one unit.
function FindSymbolByID(AUnit: TDocUnit; const AID: string): TDocSymbol;
/// Finds a symbol by exact ID across a project.
///
/// @param AUnit Receives the owning unit, or nil when not found.
function FindProjectSymbolByID(AProject: TDocProject; const AID: string;
  out AUnit: TDocUnit): TDocSymbol;
/// True for a 1-4 character alphanumeric branding mark.
function IsValidProjectMark(const AValue: string): Boolean;
/// True for a `#RGB`, `#RRGGBB`, or `#RRGGBBAA` color value.
function IsValidThemeColor(const AValue: string): Boolean;
/// True for a safe CSS font family name.
function IsValidThemeFont(const AValue: string): Boolean;

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
  ProjectMark := DefaultProjectMark;
  ThemeAccent := DefaultThemeAccent;
  ThemeAccentAlt := DefaultThemeAccentAlt;
  ThemeFont := DefaultThemeFont;
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

function IsValidProjectMark(const AValue: string): Boolean;
var
  I: Integer;
begin
  Result := (Length(AValue) >= 1) and (Length(AValue) <= 4);
  if not Result then
    Exit;
  for I := 1 to Length(AValue) do
    if not (AValue[I] in ['A'..'Z', 'a'..'z', '0'..'9']) then
      Exit(False);
end;

function IsValidThemeColor(const AValue: string): Boolean;
var
  I: Integer;
  DigitCount: Integer;
begin
  Result := (Length(AValue) > 1) and (AValue[1] = '#');
  if not Result then
    Exit;
  DigitCount := Length(AValue) - 1;
  if not (DigitCount in [3, 6, 8]) then
    Exit(False);
  for I := 2 to Length(AValue) do
    if not (AValue[I] in ['0'..'9', 'A'..'F', 'a'..'f']) then
      Exit(False);
end;

function IsValidThemeFont(const AValue: string): Boolean;
var
  I: Integer;
begin
  Result := (Length(AValue) >= 1) and (Length(AValue) <= 64);
  if not Result then
    Exit;
  if not (AValue[1] in ['A'..'Z', 'a'..'z', '0'..'9']) then
    Exit(False);
  for I := 2 to Length(AValue) do
    if not (AValue[I] in ['A'..'Z', 'a'..'z', '0'..'9', ' ', '-']) then
      Exit(False);
end;

end.
