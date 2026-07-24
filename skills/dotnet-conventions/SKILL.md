---
name: dotnet-conventions
description: C#/.NET conventions, best practices, and patterns for logging (Microsoft.Extensions.Logging + NLog), testing (xUnit, NSubstitute, AAA), and object mapping (Riok.Mapperly). Use whenever writing, reviewing or modifying C#/.NET code, tests, logging, or mapping code.
---

# .NET / C#

## Logging

* Use structured logging with `Microsoft.Extensions.Logging` abstractions (`ILogger<T>`) throughout all layers.
* Use **NLog** as the logging provider/sink — configure via `NLog.config`.
* Do not prefix log messages with the class or service name — `ILogger<T>` already captures the source type, avoiding duplication in structured logs.

## Mapping

* Use **Riok.Mapperly** for object-to-object mapping (e.g. between DTOs and domain models/entities).
* Use static mapper classes with static methods for mapping; avoid instance-based mappers or dependency injection for mappers.
* For deep cloning needs, also use **Riok.Mapperly** with `[Mapper(UseDeepCloning = true)]` and expose it as a `public static partial T DeepClone(this T t);` extension method.

## Testing

* Use **xUnit** as the unit test framework.
* Use built-in xUnit assertions (`Assert.*`).
* Use **NSubstitute** for mocking.
* Follow the AAA pattern (Arrange, Act, Assert).
* Test both success and failure scenarios.
* Include null parameter validation tests.