# Unit `Scientific.Core`

[Project index](../index.md)

**Source:** `Scientific.Core.pas`

Defines geometric primitives and scalar-function abstractions.
Vectors use Cartesian coordinates:
$$
\mathbf{v} = \begin{bmatrix}v_x \\ v_y\end{bmatrix} \in \mathbb{R}^2.
$$

## Interface dependencies

None.

## Types

<a id="symbol-scientific-core-irealfunction-7542e455abe9e55d"></a>
### `Scientific.Core.IRealFunction`

**Kind:** `interface`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:16:16`

```pascal
IRealFunction = interface
end
```

Represents a real-valued function $f\colon\mathbb{R}\to\mathbb{R}$.

<a id="symbol-scientific-core-trealfunction-58d841dcd63cc0c9"></a>
### `Scientific.Core.TRealFunction`

**Kind:** `class`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:26:16`

```pascal
TRealFunction = class(TInterfacedObject, IRealFunction)
end
```

Supplies reference counting for concrete real-valued functions.

<a id="symbol-scientific-core-tvector2-75d9385235314a7d"></a>
### `Scientific.Core.TVector2`

**Kind:** `record`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:36:11`

```pascal
TVector2 = record
end
```

Stores a vector $\mathbf{v}=(v_x,v_y)$ in the Euclidean plane.

## Routines

<a id="symbol-scientific-core-anglebetween-b9e1c2e554d472b6"></a>
### `Scientific.Core.AngleBetween`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:123:22`

```pascal
function AngleBetween(const A: TVector2; const B: TVector2): Double
```

Measures the unsigned angle between two non-zero vectors.
$$
\theta=\arccos\!\left(
\frac{\mathbf{a}\cdot\mathbf{b}}
{\lVert\mathbf{a}\rVert_2\lVert\mathbf{b}\rVert_2}
\right).
$$

#### Parameters

| Name | Description |
|---|---|
| `A` | First vector $\mathbf{a}$. |
| `B` | Second vector $\mathbf{b}$. |

#### Returns

The angle $\theta\in[0,\pi]$, or zero for a zero input.

<a id="symbol-scientific-core-distance-b680cb2a8a7a51be"></a>
### `Scientific.Core.Distance`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:80:18`

```pascal
function Distance(const A: TVector2; const B: TVector2): Double
```

Computes the distance between two points.
$$
d(\mathbf{a},\mathbf{b})=\lVert\mathbf{a}-\mathbf{b}\rVert_2.
$$

#### Parameters

| Name | Description |
|---|---|
| `A` | First point $\mathbf{a}$. |
| `B` | Second point $\mathbf{b}$. |

#### Returns

Their Euclidean distance.

<a id="symbol-scientific-core-dot-8ee6776b6c79d1ca"></a>
### `Scientific.Core.Dot`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:59:13`

```pascal
function Dot(const A: TVector2; const B: TVector2): Double
```

Computes the Euclidean inner product.
$$
\mathbf{a}\cdot\mathbf{b}=a_xb_x+a_yb_y.
$$

#### Parameters

| Name | Description |
|---|---|
| `A` | Left vector $\mathbf{a}$. |
| `B` | Right vector $\mathbf{b}$. |

#### Returns

The scalar inner product.

<a id="symbol-scientific-core-magnitude-29282b0347b7cb87"></a>
### `Scientific.Core.Magnitude`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:69:19`

```pascal
function Magnitude(const Value: TVector2): Double
```

Computes the Euclidean magnitude of a vector.
$$
\lVert\mathbf{v}\rVert_2=\sqrt{v_x^2+v_y^2}.
$$

#### Parameters

| Name | Description |
|---|---|
| `Value` | Vector $\mathbf{v}$. |

#### Returns

Its non-negative magnitude.

<a id="symbol-scientific-core-normalize-8422b95fea32ee9b"></a>
### `Scientific.Core.Normalize`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:93:19`

```pascal
function Normalize(const Value: TVector2): TVector2
```

Produces a unit vector with the same direction.
$$
\widehat{\mathbf{v}}=
\frac{\mathbf{v}}{\lVert\mathbf{v}\rVert_2}.
$$
The zero vector maps to itself rather than dividing by zero.

#### Parameters

| Name | Description |
|---|---|
| `Value` | Vector $\mathbf{v}$ to normalize. |

#### Returns

$\widehat{\mathbf{v}}$ or $(0,0)$ for a zero input.

<a id="symbol-scientific-core-rotate-55b28a27294a60c3"></a>
### `Scientific.Core.Rotate`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:109:16`

```pascal
function Rotate(const Value: TVector2; const Angle: Double): TVector2
```

Rotates a vector counter-clockwise by $\theta$ radians.
$$
R(\theta)=
\begin{bmatrix}
\cos\theta & -\sin\theta \\
\sin\theta &  \cos\theta
\end{bmatrix},
\qquad \mathbf{v}'=R(\theta)\mathbf{v}.
$$

#### Parameters

| Name | Description |
|---|---|
| `Value` | Vector $\mathbf{v}$ to rotate. |
| `Angle` | Rotation angle $\theta$ in radians. |

#### Returns

The rotated vector $\mathbf{v}'$.

<a id="symbol-scientific-core-vector2-21cc96d192844bf4"></a>
### `Scientific.Core.Vector2`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:48:17`

```pascal
function Vector2(const X: Double; const Y: Double): TVector2
```

Constructs the vector $\mathbf{v}=(x,y)$.

#### Parameters

| Name | Description |
|---|---|
| `X` | Horizontal component $v_x$. |
| `Y` | Vertical component $v_y$. |

#### Returns

A vector containing both components.

## Members

<a id="symbol-scientific-core-irealfunction-evaluate-1d445661aa025b6e"></a>
### `Scientific.Core.IRealFunction.Evaluate`

**Kind:** `method`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:22:22`

**Parent:** [`Scientific.Core.IRealFunction`](#symbol-scientific-core-irealfunction-7542e455abe9e55d)

```pascal
function Evaluate(const X: Double): Double
```

Evaluates $f(x)$ at one real argument.

#### Parameters

| Name | Description |
|---|---|
| `X` | Argument supplied to the function. |

#### Returns

The scalar value $f(X)$.

<a id="symbol-scientific-core-trealfunction-evaluate-93e4b8afef78467c"></a>
### `Scientific.Core.TRealFunction.Evaluate`

**Kind:** `method`; **Visibility:** `public`; **Source:** `Scientific.Core.pas:32:22`

**Parent:** [`Scientific.Core.TRealFunction`](#symbol-scientific-core-trealfunction-58d841dcd63cc0c9)

```pascal
function Evaluate(const X: Double): Double; virtual; abstract
```

Evaluates the concrete function at $x$.

#### Parameters

| Name | Description |
|---|---|
| `X` | Argument supplied to the function. |

#### Returns

The scalar value $f(X)$.

<a id="symbol-scientific-core-tvector2-x-06c946e523114366"></a>
### `Scientific.Core.TVector2.X`

**Kind:** `field`; **Visibility:** `default`; **Source:** `Scientific.Core.pas:38:5`

**Parent:** [`Scientific.Core.TVector2`](#symbol-scientific-core-tvector2-75d9385235314a7d)

```pascal
X : Double
```

Horizontal component $v_x$.

<a id="symbol-scientific-core-tvector2-y-06c947e523114519"></a>
### `Scientific.Core.TVector2.Y`

**Kind:** `field`; **Visibility:** `default`; **Source:** `Scientific.Core.pas:40:5`

**Parent:** [`Scientific.Core.TVector2`](#symbol-scientific-core-tvector2-75d9385235314a7d)

```pascal
Y : Double
```

Vertical component $v_y$.
