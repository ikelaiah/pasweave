unit PasWeave.Render.Support;

{$mode objfpc}{$H+}

interface

uses
  PasWeave.Model;

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
function EscapeHTML(const AText: string): UTF8String;

implementation

uses
  SysUtils;

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
begin
  Result := PasWeave.Model.DocumentationSymbolAnchor(ASymbol);
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
