unit TestSupport;

{$mode objfpc}{$H+}

interface

/// Identifies test support that can be explicitly excluded.
function TestValue: Integer;

implementation

function TestValue: Integer;
begin
  Result := 5;
end;

end.
