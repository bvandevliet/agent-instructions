---
name: dotnet-conventions
description: C#/.NET conventions, best practices, and patterns for logging (Microsoft.Extensions.Logging + NLog), testing (xUnit, NSubstitute, AAA), object mapping (Riok.Mapperly), and asyncronous programming. Use whenever writing, reviewing or modifying any C#/.NET code.
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

## Async/Await Patterns

### Naming Conventions
* Use the 'Async' suffix for all async methods.
* Match method names with their synchronous counterparts when applicable (e.g., `GetDataAsync()` for `GetData()`).

### Return Types
* Return `Task<T>` when the method returns a value; return `Task` when the method does not return a value.
* Use ConfigureAwait(false) where appropriate.
* Handle async exceptions properly.

### Exception Handling
* Use try/catch blocks around await expressions.
* Avoid swallowing exceptions in async methods.
* Use `ConfigureAwait(false)` when appropriate to prevent deadlocks in library code.
* Propagate exceptions with `Task.FromException()` instead of throwing in async Task returning methods.

### Performance
* Use `Task.WhenAll()` for parallel execution of multiple tasks.
* Use `Task.WhenAny()` for implementing timeouts or taking the first completed task.
* Avoid unnecessary async/await when simply passing through task results.
* Consider cancellation tokens for long-running operations.

### Common Pitfalls
* Never use `.Wait()`, `.Result`, or `.GetAwaiter().GetResult()` in async code.
* Avoid mixing blocking and async code.
* Don't create async void methods (except for event handlers).
* Always await Task-returning methods.

### Implementation Patterns
* Use async/await for all I/O operations and long-running tasks.
* Use async streams (`IAsyncEnumerable<T>`) for processing sequences asynchronously.
* Consider the task-based asynchronous pattern (TAP) for public APIs.