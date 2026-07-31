unit GeneratedUnit;

{$mode objfpc}{$H+}

interface

/// Identifies a generated source that can be explicitly excluded.
function GeneratedValue: Integer;

implementation

function GeneratedValue: Integer;
begin
  Result := 2;
end;

end.
