/// Provides numerical methods and elementary statistical transforms.
///
/// The routines illustrate documentation ranging from short inline symbols
/// such as $\mu$ and $\sigma$ to complete display equations.
unit Scientific.Analysis;

{$mode objfpc}{$H+}

interface

uses
  Scientific.Core;

type
  /// Owns a finite sequence $(x_1,\ldots,x_n)$ of real values.
  TDoubleArray = array of Double;

  /// Represents a Gaussian density with mean $\mu$ and deviation $\sigma$.
  ///
  /// $$
  /// \mathcal{N}(x\mid\mu,\sigma^2)=
  /// \frac{1}{\sigma\sqrt{2\pi}}
  /// \exp\!\left[-\frac{(x-\mu)^2}{2\sigma^2}\right].
  /// $$
  TGaussianFunction = class(TRealFunction)
  private
    FMean: Double;
    FStandardDeviation: Double;
  public
    /// Creates $\mathcal{N}(\mu,\sigma^2)$ for a positive $\sigma$.
    ///
    /// @param AMean Distribution mean $\mu$.
    /// @param AStandardDeviation Standard deviation $\sigma>0$.
    /// @raises Exception When $\sigma\leq 0$.
    constructor Create(const AMean, AStandardDeviation: Double);

    /// Evaluates the Gaussian probability density at $x$.
    ///
    /// @param X Observation $x$.
    /// @returns The density $\mathcal{N}(x\mid\mu,\sigma^2)$.
    function Evaluate(const X: Double): Double; override;

    /// Distribution mean $\mu=\mathbb{E}[X]$.
    property Mean: Double read FMean;

    /// Standard deviation $\sigma=\sqrt{\operatorname{Var}(X)}$.
    property StandardDeviation: Double read FStandardDeviation;
  end;

/// Evaluates the logistic sigmoid.
///
/// $$
/// \operatorname{sigmoid}(x)=\frac{1}{1+e^{-x}}.
/// $$
///
/// @param X Real argument $x$.
/// @returns A value strictly between zero and one.
function Logistic(const X: Double): Double;

/// Evaluates a normal probability density without constructing an object.
///
/// $$
/// p(x)=\frac{e^{-z^2/2}}{\sigma\sqrt{2\pi}},
/// \qquad z=\frac{x-\mu}{\sigma}.
/// $$
///
/// @param X Observation $x$.
/// @param Mean Distribution mean $\mu$.
/// @param StandardDeviation Positive standard deviation $\sigma$.
/// @returns The normal density $p(x)$.
/// @raises Exception When $\sigma\leq 0$.
function NormalPDF(const X, Mean, StandardDeviation: Double): Double;

/// Performs one Newton-Raphson root update.
///
/// $$
/// x_{k+1}=x_k-\frac{f(x_k)}{f'(x_k)}.
/// $$
///
/// @param F Function $f$ whose root is sought.
/// @param Derivative Derivative function $f'$.
/// @param X Current approximation $x_k$.
/// @returns The next approximation $x_{k+1}$.
/// @raises Exception When $f'(x_k)$ is numerically zero.
function NewtonStep(const F, Derivative: IRealFunction;
  const X: Double): Double;

/// Estimates an integral with one Simpson panel.
///
/// $$
/// \int_a^b f(x)\,dx \approx
/// \frac{b-a}{6}\left[
/// f(a)+4f\!\left(\frac{a+b}{2}\right)+f(b)
/// \right].
/// $$
///
/// @param F Integrand $f$.
/// @param A Lower bound $a$.
/// @param B Upper bound $b$.
/// @returns The Simpson estimate of the definite integral.
function SimpsonEstimate(const F: IRealFunction;
  const A, B: Double): Double;

/// Computes the arithmetic mean of $n$ observations.
///
/// $$
/// \bar{x}=\frac{1}{n}\sum_{i=1}^{n}x_i.
/// $$
///
/// @param Values Observations $(x_1,\ldots,x_n)$.
/// @returns Their arithmetic mean $\bar{x}$.
/// @raises Exception When the sequence is empty.
function ArithmeticMean(const Values: array of Double): Double;

/// Computes population variance around the arithmetic mean.
///
/// $$
/// \sigma^2=\frac{1}{n}\sum_{i=1}^{n}(x_i-\bar{x})^2.
/// $$
///
/// @param Values Observations $(x_1,\ldots,x_n)$.
/// @returns Their population variance $\sigma^2$.
/// @raises Exception When the sequence is empty.
function PopulationVariance(const Values: array of Double): Double;

/// Converts arbitrary scores into a categorical probability distribution.
///
/// $$
/// \operatorname{softmax}(z_i)=
/// \frac{e^{z_i-m}}{\sum_{j=1}^{n}e^{z_j-m}},
/// \qquad m=\max_j z_j.
/// $$
///
/// Subtracting $m$ leaves the result unchanged while improving numerical
/// stability.
///
/// @param Values Scores $(z_1,\ldots,z_n)$.
/// @returns Probabilities whose sum is one, or an empty sequence.
function Softmax(const Values: array of Double): TDoubleArray;

/// Computes Shannon entropy in bits.
///
/// $$
/// H(P)=-\sum_{i=1}^{n}p_i\log_2 p_i,
/// \qquad 0\log_2 0:=0.
/// $$
///
/// @param Probabilities Values $p_i\in[0,1]$.
/// @returns The information entropy $H(P)$ in bits.
/// @raises Exception When a probability lies outside $[0,1]$.
function Entropy(const Probabilities: array of Double): Double;

implementation

uses
  Math, SysUtils;

constructor TGaussianFunction.Create(const AMean,
  AStandardDeviation: Double);
begin
  inherited Create;
  if AStandardDeviation <= 0 then
    raise Exception.Create('standard deviation must be positive');
  FMean := AMean;
  FStandardDeviation := AStandardDeviation;
end;

function TGaussianFunction.Evaluate(const X: Double): Double;
begin
  Result := NormalPDF(X, FMean, FStandardDeviation);
end;

function Logistic(const X: Double): Double;
var
  Exponential: Double;
begin
  if X >= 0 then
    Result := 1 / (1 + Exp(-X))
  else
  begin
    Exponential := Exp(X);
    Result := Exponential / (1 + Exponential);
  end;
end;

function NormalPDF(const X, Mean, StandardDeviation: Double): Double;
var
  Z: Double;
begin
  if StandardDeviation <= 0 then
    raise Exception.Create('standard deviation must be positive');
  Z := (X - Mean) / StandardDeviation;
  Result := Exp(-0.5 * Sqr(Z)) /
    (StandardDeviation * Sqrt(2 * Pi));
end;

function NewtonStep(const F, Derivative: IRealFunction;
  const X: Double): Double;
var
  Slope: Double;
begin
  Slope := Derivative.Evaluate(X);
  if Abs(Slope) < 1.0E-15 then
    raise Exception.Create('derivative is numerically zero');
  Result := X - F.Evaluate(X) / Slope;
end;

function SimpsonEstimate(const F: IRealFunction;
  const A, B: Double): Double;
var
  Midpoint: Double;
begin
  Midpoint := (A + B) / 2;
  Result := (B - A) / 6 *
    (F.Evaluate(A) + 4 * F.Evaluate(Midpoint) + F.Evaluate(B));
end;

function ArithmeticMean(const Values: array of Double): Double;
var
  I: Integer;
begin
  if Length(Values) = 0 then
    raise Exception.Create('mean requires at least one value');
  Result := 0;
  for I := Low(Values) to High(Values) do
    Result := Result + Values[I];
  Result := Result / Length(Values);
end;

function PopulationVariance(const Values: array of Double): Double;
var
  Average: Double;
  I: Integer;
begin
  if Length(Values) = 0 then
    raise Exception.Create('variance requires at least one value');
  Average := ArithmeticMean(Values);
  Result := 0;
  for I := Low(Values) to High(Values) do
    Result := Result + Sqr(Values[I] - Average);
  Result := Result / Length(Values);
end;

function Softmax(const Values: array of Double): TDoubleArray;
var
  I: Integer;
  Maximum: Double;
  Total: Double;
begin
  Result := nil;
  SetLength(Result, Length(Values));
  if Length(Values) = 0 then
    Exit;

  Maximum := Values[Low(Values)];
  for I := Low(Values) + 1 to High(Values) do
    if Values[I] > Maximum then
      Maximum := Values[I];

  Total := 0;
  for I := Low(Values) to High(Values) do
  begin
    Result[I] := Exp(Values[I] - Maximum);
    Total := Total + Result[I];
  end;
  for I := Low(Result) to High(Result) do
    Result[I] := Result[I] / Total;
end;

function Entropy(const Probabilities: array of Double): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := Low(Probabilities) to High(Probabilities) do
  begin
    if (Probabilities[I] < 0) or (Probabilities[I] > 1) then
      raise Exception.Create('probabilities must lie between zero and one');
    if Probabilities[I] > 0 then
      Result := Result - Probabilities[I] * Ln(Probabilities[I]) / Ln(2);
  end;
end;

end.
