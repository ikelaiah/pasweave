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

implementation

uses
  SysUtils;

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
begin
  Result := PasWeave.Model.DocumentationSymbolAnchor(ASymbol);
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
