# Unit `Demo.Core`

[Project index](../index.md)

**Source:** [`Demo.Core.pas`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Core.pas#L5)

Defines the core API for the documented PasWeave example.
Every renderable declaration in this unit uses PasWeave's explicit `///`
documentation marker.

## Interface dependencies

None.

## Types

<a id="symbol-demo-core-tgreeter-fb605899cec8779b"></a>
### `Demo.Core.TGreeter`

**Kind:** `class`; **Visibility:** `public`; **Source:** [`Demo.Core.pas:16:11`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Core.pas#L16)

```pascal
TGreeter = class
end
```

Creates greetings for callers.

<a id="symbol-demo-core-tgreetingstyle-10cc0ecc6a6635c8"></a>
### `Demo.Core.TGreetingStyle`

**Kind:** `enumeration`; **Visibility:** `public`; **Source:** [`Demo.Core.pas:13:17`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Core.pas#L13)

```pascal
TGreetingStyle = (gsFriendly,gsExcited)
```

Selects the punctuation used in a generated greeting.

## Routines

<a id="symbol-demo-core-add-ce92e6099fa0d067"></a>
### `Demo.Core.Add`

**Kind:** `routine`; **Visibility:** `public`; **Source:** [`Demo.Core.pas:34:13`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Core.pas#L34)

```pascal
function Add(const A: Integer; const B: Integer): Integer
```

Adds two integer values.
The operation is $A + B$.

#### Parameters

| Name | Description |
|---|---|
| `A` | Left operand. |
| `B` | Right operand. |

#### Returns

The sum of `A` and `B`.

## Members

<a id="symbol-demo-core-tgreeter-greetingfor-26da7ea6d7daae6a"></a>
### `Demo.Core.TGreeter.GreetingFor`

**Kind:** `method`; **Visibility:** `public`; **Source:** [`Demo.Core.pas:23:25`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Core.pas#L23)

**Parent:** [`Demo.Core.TGreeter`](#symbol-demo-core-tgreeter-fb605899cec8779b)

```pascal
function GreetingFor(
  const AName: string;
  AStyle: TGreetingStyle = gsFriendly
): string
```

Builds a greeting for one person.

#### Parameters

| Name | Description |
|---|---|
| `AName` | Name to include in the greeting. |
| `AStyle` | Punctuation style for the result. |

#### Returns

A friendly greeting containing `AName`.
