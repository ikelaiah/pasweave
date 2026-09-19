unit CoreUnit;

{$mode objfpc}{$H+}{$J+}

interface

uses
  SupportUnit;

/// Runs the fixture's core service.
procedure RunCore;

implementation

procedure RunCore;
begin
  RunSupport;
end;

end.
