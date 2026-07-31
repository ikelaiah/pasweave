/// Defines the core API for the documented PasWeave example.
///
/// Every renderable declaration in this unit uses PasWeave's explicit `///`
/// documentation marker.
unit Demo.Core;

{$mode objfpc}{$H+}

interface

type
  /// Selects the punctuation used in a generated greeting.
  TGreetingStyle = (gsFriendly, gsExcited);

  /// Creates greetings for callers.
  TGreeter = class
  public
    /// Builds a greeting for one person.
    ///
    /// @param AName Name to include in the greeting.
    /// @param AStyle Punctuation style for the result.
    /// @returns A friendly greeting containing `AName`.
    function GreetingFor(const AName: string;
      AStyle: TGreetingStyle = gsFriendly): string;
  end;

/// Adds two integer values.
///
/// The operation is $A + B$.
///
/// @param A Left operand.
/// @param B Right operand.
/// @returns The sum of `A` and `B`.
function Add(const A, B: Integer): Integer;

implementation

function TGreeter.GreetingFor(const AName: string;
  AStyle: TGreetingStyle): string;
begin
  Result := 'Hello, ' + AName;
  if AStyle = gsExcited then
    Result := Result + '!!'
  else
    Result := Result + '!';
end;

function Add(const A, B: Integer): Integer;
begin
  Result := A + B;
end;

end.
