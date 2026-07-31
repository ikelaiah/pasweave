unit SimpleUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes;

type
  /// Stores an integer value.
  TCounter = class
  private
    FValue: Integer;
  public
    /// Returns the stored value.
    function GetValue: Integer;
    property Value: Integer read GetValue;
  end;

  generic TBox<T> = class
  end;

  TIntegerBox = specialize TBox<Integer>;

/// Adds two integer values.
///
/// The mathematical definition is:
///
/// $$
/// \operatorname{Add}(A, B) = A + B
/// $$
///
/// @param A First value.
/// @param B Second value.
/// @returns The sum of `A` and `B`.
/// @see Reset Clears the fixture state.
function Add(const A, B: Integer): Integer;

procedure Reset;

implementation

function TCounter.GetValue: Integer;
begin
  Result := FValue;
end;

function Add(const A, B: Integer): Integer;
begin
  Result := A + B;
end;

procedure Reset;
begin
end;

end.
