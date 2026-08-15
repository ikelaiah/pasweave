unit PasWeave.Render.Support;

{$mode objfpc}{$H+}

interface

uses
  Classes, PasWeave.Model;

const
  DocumentationSortSeparator = #255;

type
  TOrdinalStringList = class(TStringList)
  protected
    function CompareStrings(const S1, S2: string): Integer; override;
  end;

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
function DocumentationSymbolSortKey(ASymbol: TDocSymbol): string;
function EscapeHTML(const AText: string): UTF8String;
function LightenThemeColor(const AColor: string; AWeight: Integer): string;
function IsIndexedAPIKind(AKind: TSymbolKind): Boolean;

implementation

uses
  SysUtils;

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
    Result := 0;
  end;
end;

function LightenThemeColor(const AColor: string; AWeight: Integer): string;
var
  Digits: string;
  I: Integer;
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
    Channel := HexDigitValue(Digits[I * 2 + 1]) * 16 +
      HexDigitValue(Digits[I * 2 + 2]);
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

end.
