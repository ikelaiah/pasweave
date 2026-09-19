unit BetaUnit;

{$mode objfpc}{$H+}{$J+}

interface

/// Identifies a deeply nested `.pp` source.
function BetaValue: Integer;

implementation

function BetaValue: Integer;
begin
  Result := 4;
end;

end.
