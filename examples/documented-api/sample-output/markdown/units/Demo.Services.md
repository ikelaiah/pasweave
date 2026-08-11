# Unit `Demo.Services`

[Project index](../index.md)

**Source:** [`Demo.Services.pas`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Services.pas#L2)

Demonstrates documented APIs that depend on another project unit.

## Interface dependencies

- [`Demo.Core`](Demo.Core.md)

## Types

<a id="symbol-demo-services-tnamedgreeter-36c4f0e191f7812d"></a>
### `Demo.Services.TNamedGreeter`

**Kind:** `class`; **Visibility:** `public`; **Source:** [`Demo.Services.pas:13:16`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Services.pas#L13)

**Relationships:**

- Inherits from [`TGreeter`](Demo.Core.md#symbol-demo-core-tgreeter-fb605899cec8779b)

```pascal
TNamedGreeter = class(TGreeter)
end
```

Associates a reusable greeter with one name.

## Members

<a id="symbol-demo-services-tnamedgreeter-create-495e8336f5e7fef9"></a>
### `Demo.Services.TNamedGreeter.Create`

**Kind:** `constructor`; **Visibility:** `public`; **Source:** [`Demo.Services.pas:20:23`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Services.pas#L20)

**Parent:** [`Demo.Services.TNamedGreeter`](#symbol-demo-services-tnamedgreeter-36c4f0e191f7812d)

```pascal
constructor Create(const AName: string)
```

Creates a greeter for `AName`.

#### Parameters

| Name | Description |
|---|---|
| `AName` | Name retained by this instance. |

<a id="symbol-demo-services-tnamedgreeter-name-65470d0c8492e87a"></a>
### `Demo.Services.TNamedGreeter.Name`

**Kind:** `property`; **Visibility:** `public`; **Source:** [`Demo.Services.pas:28:18`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Services.pas#L28)

**Parent:** [`Demo.Services.TNamedGreeter`](#symbol-demo-services-tnamedgreeter-36c4f0e191f7812d)

```pascal
Name : string
```

Name included by `Welcome`.

<a id="symbol-demo-services-tnamedgreeter-welcome-39c026d5b69e81c2"></a>
### `Demo.Services.TNamedGreeter.Welcome`

**Kind:** `method`; **Visibility:** `public`; **Source:** [`Demo.Services.pas:25:21`](https://github.com/ikelaiah/pasweave/blob/main/examples/documented-api/Demo.Services.pas#L25)

**Parent:** [`Demo.Services.TNamedGreeter`](#symbol-demo-services-tnamedgreeter-36c4f0e191f7812d)

```pascal
function Welcome: string
```

Builds an excited greeting for the retained name.

#### Returns

A greeting produced by the inherited API.
