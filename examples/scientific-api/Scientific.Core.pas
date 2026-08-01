/// Defines geometric primitives and scalar-function abstractions.
///
/// Vectors use Cartesian coordinates:
///
/// $$
/// \mathbf{v} = \begin{bmatrix}v_x \\ v_y\end{bmatrix} \in \mathbb{R}^2.
/// $$
unit Scientific.Core;

{$mode objfpc}{$H+}

interface

type
  /// Represents a real-valued function $f\colon\mathbb{R}\to\mathbb{R}$.
  IRealFunction = interface
    ['{F818D9E1-A267-4D1C-8B29-F09CA113159F}']
    /// Evaluates $f(x)$ at one real argument.
    ///
    /// @param X Argument supplied to the function.
    /// @returns The scalar value $f(X)$.
    function Evaluate(const X: Double): Double;
  end;

  /// Supplies reference counting for concrete real-valued functions.
  TRealFunction = class(TInterfacedObject, IRealFunction)
  public
    /// Evaluates the concrete function at $x$.
    ///
    /// @param X Argument supplied to the function.
    /// @returns The scalar value $f(X)$.
    function Evaluate(const X: Double): Double; virtual; abstract;
  end;

  /// Stores a vector $\mathbf{v}=(v_x,v_y)$ in the Euclidean plane.
  TVector2 = record
    /// Horizontal component $v_x$.
    X: Double;
    /// Vertical component $v_y$.
    Y: Double;
  end;

/// Constructs the vector $\mathbf{v}=(x,y)$.
///
/// @param X Horizontal component $v_x$.
/// @param Y Vertical component $v_y$.
/// @returns A vector containing both components.
function Vector2(const X, Y: Double): TVector2;

/// Computes the Euclidean inner product.
///
/// $$
/// \mathbf{a}\cdot\mathbf{b}=a_xb_x+a_yb_y.
/// $$
///
/// @param A Left vector $\mathbf{a}$.
/// @param B Right vector $\mathbf{b}$.
/// @returns The scalar inner product.
function Dot(const A, B: TVector2): Double;

/// Computes the Euclidean magnitude of a vector.
///
/// $$
/// \lVert\mathbf{v}\rVert_2=\sqrt{v_x^2+v_y^2}.
/// $$
///
/// @param Value Vector $\mathbf{v}$.
/// @returns Its non-negative magnitude.
function Magnitude(const Value: TVector2): Double;

/// Computes the distance between two points.
///
/// $$
/// d(\mathbf{a},\mathbf{b})=\lVert\mathbf{a}-\mathbf{b}\rVert_2.
/// $$
///
/// @param A First point $\mathbf{a}$.
/// @param B Second point $\mathbf{b}$.
/// @returns Their Euclidean distance.
function Distance(const A, B: TVector2): Double;

/// Produces a unit vector with the same direction.
///
/// $$
/// \widehat{\mathbf{v}}=
/// \frac{\mathbf{v}}{\lVert\mathbf{v}\rVert_2}.
/// $$
///
/// The zero vector maps to itself rather than dividing by zero.
///
/// @param Value Vector $\mathbf{v}$ to normalize.
/// @returns $\widehat{\mathbf{v}}$ or $(0,0)$ for a zero input.
function Normalize(const Value: TVector2): TVector2;

/// Rotates a vector counter-clockwise by $\theta$ radians.
///
/// $$
/// R(\theta)=
/// \begin{bmatrix}
/// \cos\theta & -\sin\theta \\
/// \sin\theta &  \cos\theta
/// \end{bmatrix},
/// \qquad \mathbf{v}'=R(\theta)\mathbf{v}.
/// $$
///
/// @param Value Vector $\mathbf{v}$ to rotate.
/// @param Angle Rotation angle $\theta$ in radians.
/// @returns The rotated vector $\mathbf{v}'$.
function Rotate(const Value: TVector2; const Angle: Double): TVector2;

/// Measures the unsigned angle between two non-zero vectors.
///
/// $$
/// \theta=\arccos\!\left(
/// \frac{\mathbf{a}\cdot\mathbf{b}}
/// {\lVert\mathbf{a}\rVert_2\lVert\mathbf{b}\rVert_2}
/// \right).
/// $$
///
/// @param A First vector $\mathbf{a}$.
/// @param B Second vector $\mathbf{b}$.
/// @returns The angle $\theta\in[0,\pi]$, or zero for a zero input.
function AngleBetween(const A, B: TVector2): Double;

implementation

uses
  Math;

function Vector2(const X, Y: Double): TVector2;
begin
  Result.X := X;
  Result.Y := Y;
end;

function Dot(const A, B: TVector2): Double;
begin
  Result := A.X * B.X + A.Y * B.Y;
end;

function Magnitude(const Value: TVector2): Double;
begin
  Result := Sqrt(Sqr(Value.X) + Sqr(Value.Y));
end;

function Distance(const A, B: TVector2): Double;
begin
  Result := Magnitude(Vector2(A.X - B.X, A.Y - B.Y));
end;

function Normalize(const Value: TVector2): TVector2;
var
  LengthValue: Double;
begin
  LengthValue := Magnitude(Value);
  if LengthValue = 0 then
    Exit(Vector2(0, 0));
  Result := Vector2(Value.X / LengthValue, Value.Y / LengthValue);
end;

function Rotate(const Value: TVector2; const Angle: Double): TVector2;
var
  Cosine: Double;
  Sine: Double;
begin
  Cosine := Cos(Angle);
  Sine := Sin(Angle);
  Result := Vector2(
    Cosine * Value.X - Sine * Value.Y,
    Sine * Value.X + Cosine * Value.Y);
end;

function AngleBetween(const A, B: TVector2): Double;
var
  Denominator: Double;
  Ratio: Double;
begin
  Denominator := Magnitude(A) * Magnitude(B);
  if Denominator = 0 then
    Exit(0);
  Ratio := Dot(A, B) / Denominator;
  if Ratio < -1 then
    Ratio := -1
  else if Ratio > 1 then
    Ratio := 1;
  Result := ArcCos(Ratio);
end;

end.
