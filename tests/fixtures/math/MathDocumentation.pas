unit MathDocumentation;

{$mode objfpc}{$H+}

interface

/// Demonstrates offline mathematical rendering.
///
/// Valid inline mathematics: $a^2 + b^2 = c^2$.
/// Escaped currency remains prose: \$5.
/// Double delimiters inside prose remain literal: $$not a display fence$$.
///
/// $$
/// \int_0^1 x^2\,dx = \frac{1}{3}
/// $$
///
/// Invalid inline mathematics remains readable: $\sqrt{$.
///
/// $$
/// \frac{1}{
/// $$
procedure MathExamples;

implementation

procedure MathExamples;
begin
end;

end.
