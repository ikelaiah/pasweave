unit VendorUnit;

{$mode objfpc}{$H+}

interface

/// Identifies vendored source that can be explicitly excluded.
function VendorValue: Integer;

implementation

function VendorValue: Integer;
begin
  Result := 6;
end;

end.
