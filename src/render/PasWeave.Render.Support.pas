unit PasWeave.Render.Support;

{$mode objfpc}{$H+}

interface

uses
  PasWeave.Model;

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;

implementation

function DocumentationSymbolAnchor(ASymbol: TDocSymbol): string;
begin
  Result := PasWeave.Model.DocumentationSymbolAnchor(ASymbol);
end;

end.
