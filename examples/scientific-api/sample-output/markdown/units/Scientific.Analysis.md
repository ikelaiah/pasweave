# Unit `Scientific.Analysis`

[Project index](../index.md)

**Source:** `Scientific.Analysis.pas`

Provides numerical methods and elementary statistical transforms.
The routines illustrate documentation ranging from short inline symbols
such as $\mu$ and $\sigma$ to complete display equations.

## Interface dependencies

- [`Scientific.Core`](Scientific.Core.md)

## Types

<a id="symbol-scientific-analysis-tdoublearray-62038572069cc187"></a>
### `Scientific.Analysis.TDoubleArray`

**Kind:** `type-alias`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:16:15`

```pascal
TDoubleArray = Array of Double
```

Owns a finite sequence $(x_1,\ldots,x_n)$ of real values.

<a id="symbol-scientific-analysis-tgaussianfunction-e84b5f2e25221487"></a>
### `Scientific.Analysis.TGaussianFunction`

**Kind:** `class`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:25:20`

```pascal
TGaussianFunction = class(TRealFunction)
end
```

Represents a Gaussian density with mean $\mu$ and deviation $\sigma$.
$$
\mathcal{N}(x\mid\mu,\sigma^2)=
\frac{1}{\sigma\sqrt{2\pi}}
\exp\!\left[-\frac{(x-\mu)^2}{2\sigma^2}\right].
$$

## Routines

<a id="symbol-scientific-analysis-arithmeticmean-32bb31d6362baf9d"></a>
### `Scientific.Analysis.ArithmeticMean`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:113:24`

```pascal
function ArithmeticMean(const Values: Array of Double): Double
```

Computes the arithmetic mean of $n$ observations.
$$
\bar{x}=\frac{1}{n}\sum_{i=1}^{n}x_i.
$$

#### Parameters

| Name | Description |
|---|---|
| `Values` | Observations $(x_1,\ldots,x_n)$. |

#### Returns

Their arithmetic mean $\bar{x}$.

#### Raises

| Exception | Condition |
|---|---|
| `Exception` | When the sequence is empty. |

<a id="symbol-scientific-analysis-entropy-d5b13cab52c688ec"></a>
### `Scientific.Analysis.Entropy`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:151:17`

```pascal
function Entropy(const Probabilities: Array of Double): Double
```

Computes Shannon entropy in bits.
$$
H(P)=-\sum_{i=1}^{n}p_i\log_2 p_i,
\qquad 0\log_2 0:=0.
$$

#### Parameters

| Name | Description |
|---|---|
| `Probabilities` | Values $p_i\in[0,1]$. |

#### Returns

The information entropy $H(P)$ in bits.

#### Raises

| Exception | Condition |
|---|---|
| `Exception` | When a probability lies outside $[0,1]$. |

<a id="symbol-scientific-analysis-logistic-82af6173e9041dc9"></a>
### `Scientific.Analysis.Logistic`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:58:18`

```pascal
function Logistic(const X: Double): Double
```

Evaluates the logistic sigmoid.
$$
\operatorname{sigmoid}(x)=\frac{1}{1+e^{-x}}.
$$

#### Parameters

| Name | Description |
|---|---|
| `X` | Real argument $x$. |

#### Returns

A value strictly between zero and one.

<a id="symbol-scientific-analysis-newtonstep-06f8729a1729c0f4"></a>
### `Scientific.Analysis.NewtonStep`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:85:20`

```pascal
function NewtonStep(
  const F: IRealFunction;
  const Derivative: IRealFunction;
  const X: Double
): Double
```

Performs one Newton-Raphson root update.
$$
x_{k+1}=x_k-\frac{f(x_k)}{f'(x_k)}.
$$

#### Parameters

| Name | Description |
|---|---|
| `F` | Function $f$ whose root is sought. |
| `Derivative` | Derivative function $f'$. |
| `X` | Current approximation $x_k$. |

#### Returns

The next approximation $x_{k+1}$.

#### Raises

| Exception | Condition |
|---|---|
| `Exception` | When $f'(x_k)$ is numerically zero. |

<a id="symbol-scientific-analysis-normalpdf-e5fe8f59d32c3ffa"></a>
### `Scientific.Analysis.NormalPDF`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:72:19`

```pascal
function NormalPDF(
  const X: Double;
  const Mean: Double;
  const StandardDeviation: Double
): Double
```

Evaluates a normal probability density without constructing an object.
$$
p(x)=\frac{e^{-z^2/2}}{\sigma\sqrt{2\pi}},
\qquad z=\frac{x-\mu}{\sigma}.
$$

#### Parameters

| Name | Description |
|---|---|
| `X` | Observation $x$. |
| `Mean` | Distribution mean $\mu$. |
| `StandardDeviation` | Positive standard deviation $\sigma$. |

#### Returns

The normal density $p(x)$.

#### Raises

| Exception | Condition |
|---|---|
| `Exception` | When $\sigma\leq 0$. |

<a id="symbol-scientific-analysis-populationvariance-58d817a56398aab5"></a>
### `Scientific.Analysis.PopulationVariance`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:124:28`

```pascal
function PopulationVariance(const Values: Array of Double): Double
```

Computes population variance around the arithmetic mean.
$$
\sigma^2=\frac{1}{n}\sum_{i=1}^{n}(x_i-\bar{x})^2.
$$

#### Parameters

| Name | Description |
|---|---|
| `Values` | Observations $(x_1,\ldots,x_n)$. |

#### Returns

Their population variance $\sigma^2$.

#### Raises

| Exception | Condition |
|---|---|
| `Exception` | When the sequence is empty. |

<a id="symbol-scientific-analysis-simpsonestimate-49bedd72e6d0699c"></a>
### `Scientific.Analysis.SimpsonEstimate`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:101:25`

```pascal
function SimpsonEstimate(
  const F: IRealFunction;
  const A: Double;
  const B: Double
): Double
```

Estimates an integral with one Simpson panel.
$$
\int_a^b f(x)\,dx \approx
\frac{b-a}{6}\left[
f(a)+4f\!\left(\frac{a+b}{2}\right)+f(b)
\right].
$$

#### Parameters

| Name | Description |
|---|---|
| `F` | Integrand $f$. |
| `A` | Lower bound $a$. |
| `B` | Upper bound $b$. |

#### Returns

The Simpson estimate of the definite integral.

<a id="symbol-scientific-analysis-softmax-9058366060f8b88c"></a>
### `Scientific.Analysis.Softmax`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:139:17`

```pascal
function Softmax(const Values: Array of Double): TDoubleArray
```

Converts arbitrary scores into a categorical probability distribution.
$$
\operatorname{softmax}(z_i)=
\frac{e^{z_i-m}}{\sum_{j=1}^{n}e^{z_j-m}},
\qquad m=\max_j z_j.
$$
Subtracting $m$ leaves the result unchanged while improving numerical
stability.

#### Parameters

| Name | Description |
|---|---|
| `Values` | Scores $(z_1,\ldots,z_n)$. |

#### Returns

Probabilities whose sum is one, or an empty sequence.

## Members

<a id="symbol-scientific-analysis-tgaussianfunction-create-1444eec387cfd1a5"></a>
### `Scientific.Analysis.TGaussianFunction.Create`

**Kind:** `constructor`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:35:23`

**Parent:** [`Scientific.Analysis.TGaussianFunction`](#symbol-scientific-analysis-tgaussianfunction-e84b5f2e25221487)

```pascal
constructor Create(const AMean: Double; const AStandardDeviation: Double)
```

Creates $\mathcal{N}(\mu,\sigma^2)$ for a positive $\sigma$.

#### Parameters

| Name | Description |
|---|---|
| `AMean` | Distribution mean $\mu$. |
| `AStandardDeviation` | Standard deviation $\sigma>0$. |

#### Raises

| Exception | Condition |
|---|---|
| `Exception` | When $\sigma\leq 0$. |

<a id="symbol-scientific-analysis-tgaussianfunction-evaluate-bf9e752cc02b5d70"></a>
### `Scientific.Analysis.TGaussianFunction.Evaluate`

**Kind:** `method`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:41:22`

**Parent:** [`Scientific.Analysis.TGaussianFunction`](#symbol-scientific-analysis-tgaussianfunction-e84b5f2e25221487)

```pascal
function Evaluate(const X: Double): Double; override
```

Evaluates the Gaussian probability density at $x$.

#### Parameters

| Name | Description |
|---|---|
| `X` | Observation $x$. |

#### Returns

The density $\mathcal{N}(x\mid\mu,\sigma^2)$.

<a id="symbol-scientific-analysis-tgaussianfunction-mean-0a1055396fe14598"></a>
### `Scientific.Analysis.TGaussianFunction.Mean`

**Kind:** `property`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:44:18`

**Parent:** [`Scientific.Analysis.TGaussianFunction`](#symbol-scientific-analysis-tgaussianfunction-e84b5f2e25221487)

```pascal
Mean : Double
```

Distribution mean $\mu=\mathbb{E}[X]$.

<a id="symbol-scientific-analysis-tgaussianfunction-standarddeviation-8f4e58e1f2de6bd0"></a>
### `Scientific.Analysis.TGaussianFunction.StandardDeviation`

**Kind:** `property`; **Visibility:** `public`; **Source:** `Scientific.Analysis.pas:47:31`

**Parent:** [`Scientific.Analysis.TGaussianFunction`](#symbol-scientific-analysis-tgaussianfunction-e84b5f2e25221487)

```pascal
StandardDeviation : Double
```

Standard deviation $\sigma=\sqrt{\operatorname{Var}(X)}$.
