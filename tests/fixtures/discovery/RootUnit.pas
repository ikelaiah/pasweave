unit RootUnit;

{$mode objfpc}{$H+}{$J+}

interface

/// Identifies the non-recursive root fixture.
function RootValue: Integer;

implementation

function RootValue: Integer;
begin
  Result := 1;
end;

end.
