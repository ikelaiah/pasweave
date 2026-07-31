unit AlphaUnit;

{$mode objfpc}{$H+}

interface

/// Identifies a source beneath the included tree.
function AlphaValue: Integer;

implementation

function AlphaValue: Integer;
begin
  Result := 3;
end;

end.
