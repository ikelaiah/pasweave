unit DependencyLeaf;

{$mode objfpc}{$H+}

interface

uses
  DependencyConsumer, DependencyCore;

/// Invokes the consumer at the edge of the fixture graph.
procedure InvokeConsumer;

implementation

procedure InvokeConsumer;
begin
  ConsumeCore;
end;

end.
