program pasweave;

{$mode objfpc}{$H+}{$J+}
{$IFDEF PASWEAVE_PORTABLE_ASSETS}
{$R ../build/release/pasweave-assets.res}
{$ENDIF}

uses
  PasWeave.CLI;

begin
  Halt(RunPasWeave);
end.
