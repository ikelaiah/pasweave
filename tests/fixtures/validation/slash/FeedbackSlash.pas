unit FeedbackSlash;

{$mode objfpc}{$H+}

interface

uses
  FeedbackDependency;

/// A project-local target in this unit.
procedure LocalTarget;

/// Deliberately malformed directive coverage for validation tests.
/// @param A First input value.
/// @param A Duplicate input value.
/// @param Extra Not present in the signature.
/// @returns The computed result.
/// @returns A conflicting second result description.
/// @see LocalTarget Local target.
/// @see FeedbackDependency.DependencyTarget Dependency target.
/// @see MissingTarget This target must remain unresolved.
function CheckedFunction(const A, B: Integer): Integer;

/// @returns Procedures do not return a value.
procedure ProcedureWithReturnDirective;

implementation

procedure LocalTarget;
begin
end;

function CheckedFunction(const A, B: Integer): Integer;
begin
  Result := A + B;
end;

procedure ProcedureWithReturnDirective;
begin
end;

end.
