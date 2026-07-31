/// Demonstrates documented APIs that depend on another project unit.
unit Demo.Services;

{$mode objfpc}{$H+}

interface

uses
  Demo.Core;

type
  /// Associates a reusable greeter with one name.
  TNamedGreeter = class(TGreeter)
  private
    FName: string;
  public
    /// Creates a greeter for `AName`.
    ///
    /// @param AName Name retained by this instance.
    constructor Create(const AName: string);

    /// Builds an excited greeting for the retained name.
    ///
    /// @returns A greeting produced by the inherited API.
    function Welcome: string;

    /// Name included by `Welcome`.
    property Name: string read FName;
  end;

implementation

constructor TNamedGreeter.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TNamedGreeter.Welcome: string;
begin
  Result := GreetingFor(FName, gsExcited);
end;

end.
