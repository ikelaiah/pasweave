unit ConditionalAPI;

{$mode objfpc}{$H+}

interface

{$IFDEF FEATURE_ALPHA}
/// Available when FEATURE_ALPHA is configured.
procedure AlphaFeature;
{$ELSE}
procedure DefaultFeature;
{$ENDIF}

{$IFDEF MSWINDOWS}
procedure WindowsTarget;
{$ENDIF}

{$IFDEF UNIX}
procedure UnixTarget;
{$ENDIF}

{$IFDEF CPU32}
procedure ThirtyTwoBitTarget;
{$ENDIF}

{$IFDEF CPU64}
procedure SixtyFourBitTarget;
{$ENDIF}

{$IFDEF CPUAARCH64}
procedure AArch64Target;
{$ENDIF}

implementation

end.
