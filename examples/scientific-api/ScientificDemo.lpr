program ScientificDemo;

{$mode objfpc}{$H+}

uses
  SysUtils, Scientific.Core, Scientific.Analysis;

var
  Direction: TVector2;
  Distribution: IRealFunction;
  Probabilities: TDoubleArray;
  Scores: array[0..2] of Double;
begin
  Direction := Normalize(Vector2(3, 4));
  Distribution := TGaussianFunction.Create(0, 1);
  Scores[0] := 1;
  Scores[1] := 2;
  Scores[2] := 3;
  Probabilities := Softmax(Scores);

  WriteLn(Format('unit vector = (%.2f, %.2f)',
    [Direction.X, Direction.Y]));
  WriteLn(Format('normal density at zero = %.6f',
    [Distribution.Evaluate(0)]));
  WriteLn(Format('softmax entropy = %.6f bits',
    [Entropy(Probabilities)]));
end.
