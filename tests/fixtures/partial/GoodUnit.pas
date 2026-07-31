unit GoodUnit;

{$mode objfpc}{$H+}

interface

/// Reports whether this fixture parsed successfully.
function Ready: Boolean;

implementation

function Ready: Boolean;
begin
  Result := True;
end;

end.

