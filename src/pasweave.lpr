program pasweave;

{$mode objfpc}{$H+}
{$IFDEF PASWEAVE_PORTABLE_ASSETS}
{$R ../build/release/pasweave-assets.res}
{$ENDIF}

uses
  PasWeave.CLI;

begin
  Halt(RunPasWeave);
end.
