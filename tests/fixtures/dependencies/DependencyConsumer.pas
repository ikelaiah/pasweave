unit DependencyConsumer;

{$mode objfpc}{$H+}

interface

uses
  Classes, DependencyCore;

/// Returns a value supplied by the core unit.
function ConsumeCore: TCoreValue;

implementation

function ConsumeCore: TCoreValue;
begin
  Result := 0;
end;

end.
