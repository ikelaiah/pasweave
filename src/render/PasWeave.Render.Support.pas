unit PasWeave.Render.Support;

{$mode objfpc}{$H+}{$J+}

interface

uses
  Classes, PasWeave.Diagnostics, PasWeave.Model;

const
  DocumentationSortSeparator = #255;

type
  TOrdinalStringList = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  end;

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
  ConstantKinds: TSymbolKinds = [skConstant];
  VariableKinds: TSymbolKinds = [skVariable];
  AllKinds: TSymbolKinds = [
    skUnit, skClass, skInterface, skRecord, skEnumeration, skTypeAlias,
    skRoutine, skMethod, skConstructor, skDestructor, skProperty, skField,
    skConstant, skVariable
  ];

procedure AppendLine(var AOutput: UTF8String; const ALine: UTF8String = '');
function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
function DocumentationSymbolSortKey(ASymbol: TDocSymbol): string;
function EscapeHTML(const AText: string): UTF8String;
function SafeFileNameBase(const AName: string): string;
function LightenThemeColor(const AColor: string; AWeight: Integer): string;
function IsIndexedAPIKind(AKind: TSymbolKind): Boolean;

function SortedUnits(AProject: TDocProject): TStringList;
function FindUnitByName(AProject: TDocProject; const AName: string): TDocUnit;
function IsDirectlyRenderable(ASymbol: TDocSymbol): Boolean;
function IsEffectivelyRenderable(AUnit: TDocUnit;
  ASymbol: TDocSymbol): Boolean;
function SortedSymbols(AUnit: TDocUnit; AKinds: TSymbolKinds): TStringList;
function UnitSymbol(AUnit: TDocUnit): TDocSymbol;
function IndexedSymbolCount(AUnit: TDocUnit): Integer;
function DocumentedIndexedSymbolCount(AUnit: TDocUnit): Integer;
function IndexOfObject(AList: TStringList; AObject: TObject): Integer;
function DiagnosticLocation(ADiagnostic: TDiagnostic): string;

implementation

uses
  SysUtils;

procedure AppendLine(var AOutput: UTF8String; const ALine: UTF8String = '');
begin
  AOutput := AOutput + ALine + #10;
end;

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
begin
  Result := PasWeave.Model.DocumentationSymbolAnchor(ASymbol);
end;

function HexDigitValue(const C: Char): Integer;
begin
  case C of
    '0'..'9': Result := Ord(C) - Ord('0');
    'a'..'f': Result := 10 + Ord(C) - Ord('a');
    'A'..'F': Result := 10 + Ord(C) - Ord('A');
  else
    Result := -1;
  end;
end;

{ Lightens an `#RGB` or `#RRGGBB` color. Anything else, including invalid hex
  digits, is returned unchanged rather than silently becoming a wrong color.
  An eight-digit `#RRGGBBAA` value is treated as its opaque `#RRGGBB` part. }
function LightenThemeColor(const AColor: string; AWeight: Integer): string;
var
  Digits: string;
  I: Integer;
  HighDigit: Integer;
  LowDigit: Integer;
  Channel: Integer;
begin
  Result := AColor;
  if (Length(AColor) < 4) or (AColor[1] <> '#') then
    Exit;
  Digits := Copy(AColor, 2, MaxInt);
  if Length(Digits) = 3 then
    Digits := Digits[1] + Digits[1] + Digits[2] + Digits[2] +
      Digits[3] + Digits[3];
  if Length(Digits) < 6 then
    Exit;
  Result := '#';
  for I := 0 to 2 do
  begin
    HighDigit := HexDigitValue(Digits[I * 2 + 1]);
    LowDigit := HexDigitValue(Digits[I * 2 + 2]);
    if (HighDigit < 0) or (LowDigit < 0) then
    begin
      Result := AColor;
      Exit;
    end;
    Channel := HighDigit * 16 + LowDigit;
    Channel := Channel + ((255 - Channel) * AWeight) div 100;
    Result := Result + IntToHex(Channel, 2);
  end;
end;

function DocumentationSymbolSortKey(ASymbol: TDocSymbol): string;
begin
  if ASymbol.Kind = skUnit then
    Result := '1'
  else
    Result := '0';
  Result := Result + ASymbol.QualifiedName + DocumentationSortSeparator +
    ASymbol.ID;
end;

function IsIndexedAPIKind(AKind: TSymbolKind): Boolean;
begin
  Result := AKind <> skUnit;
end;

function TOrdinalStringList.CompareStrings(const S1, S2: string): Integer;
var
  I: Integer;
  SharedLength: Integer;
begin
  SharedLength := Length(S1);
  if Length(S2) < SharedLength then
    SharedLength := Length(S2);
  for I := 1 to SharedLength do
    if Byte(S1[I]) <> Byte(S2[I]) then
    begin
      if Byte(S1[I]) < Byte(S2[I]) then
        Exit(-1)
      else
        Exit(1);
    end;
  if Length(S1) < Length(S2) then
    Result := -1
  else if Length(S1) > Length(S2) then
    Result := 1
  else
    Result := 0;
end;

function EscapeHTML(const AText: string): UTF8String;
var
  Value: string;
begin
  Value := StringReplace(AText, '&', '&amp;', [rfReplaceAll]);
  Value := StringReplace(Value, '<', '&lt;', [rfReplaceAll]);
  Value := StringReplace(Value, '>', '&gt;', [rfReplaceAll]);
  Value := StringReplace(Value, '"', '&quot;', [rfReplaceAll]);
  Value := StringReplace(Value, '''', '&#39;', [rfReplaceAll]);
  Result := UTF8String(Value);
end;

{ Model names become output file names, so path separators and Windows-invalid
  characters must never survive. Replacing (rather than rejecting) keeps
  rendering total for unusual but parseable unit names. }
function SafeFileNameBase(const AName: string): string;
const
  InvalidFileNameCharacters = ['/', '\', ':', '*', '?', '"', '<', '>', '|'];
  ReservedDeviceNames: array[0..21] of string = (
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9');
var
  I: Integer;
  C: Char;
  Base: string;
  Stem: string;
begin
  Base := '';
  for I := 1 to Length(AName) do
  begin
    C := AName[I];
    if (C in InvalidFileNameCharacters) or (Ord(C) < 32) then
      Base := Base + '_'
    else
      Base := Base + C;
  end;
  Base := Trim(Base);
  while (Base <> '') and ((Base[Length(Base)] = '.') or
    (Base[Length(Base)] = ' ')) do
    Delete(Base, Length(Base), 1);
  if (Base = '') or (Base = '.') or (Base = '..') then
    Base := 'unit';
  Stem := Base;
  I := Pos('.', Stem);
  if I > 0 then
    Stem := Copy(Stem, 1, I - 1);
  for I := Low(ReservedDeviceNames) to High(ReservedDeviceNames) do
    if SameText(Stem, ReservedDeviceNames[I]) then
    begin
      Base := '_' + Base;
      Break;
    end;
  Result := Base;
end;

function SortedUnits(AProject: TDocProject): TStringList;
var
  I: Integer;
  UnitModel: TDocUnit;
begin
  Result := TOrdinalStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupAccept;
  for I := 0 to AProject.Units.Count - 1 do
  begin
    UnitModel := TDocUnit(AProject.Units[I]);
    Result.AddObject(UnitModel.Name + DocumentationSortSeparator +
      UnitModel.SourceFilename, UnitModel);
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
  Depth: Integer;
begin
  Result := IsDirectlyRenderable(ASymbol);
  ParentSymbol := ASymbol;
  Depth := 0;
  while Result and (ParentSymbol.ParentSymbolID <> '') do
  begin
    Inc(Depth);
    if Depth > AUnit.Symbols.Count then
      Break;
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
  Result := TOrdinalStringList.Create;
  Result.Sorted := True;
  Result.CaseSensitive := True;
  Result.Duplicates := dupAccept;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if (Symbol.Kind in AKinds) and IsEffectivelyRenderable(AUnit, Symbol) then
      Result.AddObject(DocumentationSymbolSortKey(Symbol), Symbol);
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

function IndexedSymbolCount(AUnit: TDocUnit): Integer;
var
  I: Integer;
  Symbol: TDocSymbol;
begin
  Result := 0;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if IsIndexedAPIKind(Symbol.Kind) and
      IsEffectivelyRenderable(AUnit, Symbol) then
      Inc(Result);
  end;
end;

function DocumentedIndexedSymbolCount(AUnit: TDocUnit): Integer;
var
  I: Integer;
  Symbol: TDocSymbol;
begin
  Result := 0;
  for I := 0 to AUnit.Symbols.Count - 1 do
  begin
    Symbol := TDocSymbol(AUnit.Symbols[I]);
    if IsIndexedAPIKind(Symbol.Kind) and
      IsEffectivelyRenderable(AUnit, Symbol) and
      (Trim(Symbol.MarkdownDocumentation) <> '') then
      Inc(Result);
  end;
end;

function IndexOfObject(AList: TStringList; AObject: TObject): Integer;
begin
  for Result := 0 to AList.Count - 1 do
    if AList.Objects[Result] = AObject then
      Exit;
  Result := -1;
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

end.
