# Unit `Demo.Core`

[Project index](../index.md)

**Source:** `Demo.Core.pas`

Defines the core API for the documented PasWeave example.
Every renderable declaration in this unit uses PasWeave's explicit `///`
documentation marker.

## Interface dependencies

None.

## Types

<a id="symbol-demo-core-tgreeter-fb605899cec8779b"></a>
### `Demo.Core.TGreeter`

**Kind:** `class`; **Visibility:** `public`; **Source:** `Demo.Core.pas:16:11`

```pascal
TGreeter = class
end
```

Creates greetings for callers.

<a id="symbol-demo-core-tgreetingstyle-10cc0ecc6a6635c8"></a>
### `Demo.Core.TGreetingStyle`

**Kind:** `enumeration`; **Visibility:** `public`; **Source:** `Demo.Core.pas:13:17`

```pascal
TGreetingStyle = (gsFriendly,gsExcited)
```

Selects the punctuation used in a generated greeting.

## Routines

<a id="symbol-demo-core-add-ada12614b553c86d"></a>
### `Demo.Core.Add`

**Kind:** `routine`; **Visibility:** `public`; **Source:** `Demo.Core.pas:34:13`

```pascal
function Add(const A: Integer; const B: Integer) : Integer
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

<a id="symbol-demo-core-tgreeter-greetingfor-82c8855e62545192"></a>
### `Demo.Core.TGreeter.GreetingFor`

**Kind:** `method`; **Visibility:** `public`; **Source:** `Demo.Core.pas:23:25`

**Parent:** [`Demo.Core.TGreeter`](#symbol-demo-core-tgreeter-fb605899cec8779b)

```pascal
function GreetingFor(const AName: string; AStyle: TGreetingStyle)
                     : string
```

Builds a greeting for one person.

#### Parameters

| Name | Description |
|---|---|
| `AName` | Name to include in the greeting. |
| `AStyle` | Punctuation style for the result. |

#### Returns

A friendly greeting containing `AName`.
