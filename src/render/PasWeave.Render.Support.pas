unit PasWeave.Render.Support;

{$mode objfpc}{$H+}

interface

uses
  PasWeave.Model;

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;

implementation

uses
  SysUtils;

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
