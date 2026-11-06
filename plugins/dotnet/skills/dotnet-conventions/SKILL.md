---
name: dotnet-conventions
description: Baseline C#/.NET conventions, patterns, and idioms, including logging (Microsoft.Extensions.Logging + NLog), testing (xUnit, NSubstitute, AAA), object mapping (Riok.Mapperly), asynchronous programming, concurrency and thread safety, nullable reference types, dependency injection lifetimes, HttpClient usage, time abstraction (TimeProvider), and querying official Microsoft/.NET documentation, best practices, conventions, patterns, configuration options, templates, usage examples and working code samples. Use whenever writing, reviewing or modifying any C#/.NET code.
---

# .NET / C#

This skill contains opinionated C#/.NET conventions, patterns, and idioms, meant to complement (not replace) official Microsoft documentation, which remains the primary reference. Use the `microsoft-learn` MCP server (`microsoft_docs_search`, `microsoft_code_sample_search`, `microsoft_docs_fetch`; see the server's own tool instructions for the basic workflow) for authoritative details, templates, patterns, mechanisms, and best practices on Microsoft technologies.

- Be specific: include the namespace/package and version (`BlobClient UploadAsync Azure.Storage.Blobs`, not `Azure Functions`).
- Verify before trusting generated code when a method name seems "too convenient", when SDK major versions might be mixed, or when using an API for the first time.

The sections below name the right mechanisms, and the pitfalls worth never repeating, not every detail. For platform specifics (API signatures, defaults, version-dependent behavior), look up current Microsoft Learn through the MCP by the section's topic instead of relying on memory. Where the docs and this skill disagree on platform behavior, the docs win; this skill wins on library choices and style conventions.

Third-party libraries (NLog, Mapperly, xUnit, NSubstitute) aren't on Microsoft Learn: their sections end with `Docs:` URLs to fetch with a web fetch tool.

## Logging

* Use structured logging with `Microsoft.Extensions.Logging` abstractions (`ILogger<T>`) throughout all layers, with **NLog** as the provider/sink, configured via `NLog.config`.
* Do not prefix log messages with the class or service name: `ILogger<T>` already captures the source type, so it would duplicate it in structured logs.
* Use constant message templates with named placeholders, never string interpolation or concatenation (CA2254): those lose the placeholder names and values that make logs searchable. Prefer `[LoggerMessage]` source-generated methods (strongly typed, template parsed once).

Docs: <https://github.com/NLog/NLog/wiki/Configuration-file>, <https://github.com/NLog/NLog.Extensions.Logging/wiki>

## Mapping

* Use **Riok.Mapperly** for object-to-object mapping (e.g. between DTOs and domain models/entities), through static mapper classes with static methods; avoid instance-based or DI-injected mappers.
* For deep cloning, use Mapperly with `[Mapper(UseDeepCloning = true)]`, exposed as an extension method on the concrete type, e.g. `public static partial Foo DeepClone(this Foo foo);`.

Docs: <https://mapperly.riok.app/docs/configuration/static-mappers/>, <https://mapperly.riok.app/docs/configuration/mapper/>

## Testing

* Use **xUnit v3** with its built-in assertions (`Assert.*`) and **NSubstitute** for mocking.
* Follow the AAA pattern (Arrange, Act, Assert).
* Test both success and failure scenarios, including null parameter validation.

Docs: <https://xunit.net/docs/getting-started/v3/getting-started>, <https://nsubstitute.github.io/help/getting-started/>

## Async/Await

* Suffix async methods with `Async`, and mirror the synchronous name where one exists (`GetDataAsync()` for `GetData()`).
* Return `Task<T>` when there is a result and `Task` when there is none. Use `async void` only for event handlers: callers cannot await it or catch its exceptions, so a failure goes unhandled and is likely to crash the application.
* Use async/await for all I/O and long-running work, await every Task-returning call (a dropped task hides its exceptions and outlives its caller), and use `IAsyncEnumerable<T>` for sequences produced asynchronously.
* Never block on async code (`.Wait()`, `.Result`, `.GetAwaiter().GetResult()`) or mix blocking and async calls: it risks deadlocks and thread-pool starvation.
* Accept a `CancellationToken` as the last parameter of every public async API and pass it to every awaited call that takes one, so callers can cancel and shut down cleanly.
* Use `ConfigureAwait(false)` in library code, where a synchronization context may be captured, to prevent deadlocks. Omit it in application code without one (ASP.NET Core request handling, console apps) and in Blazor components, whose renderer context must be preserved.
* Let exceptions propagate to a caller that can act on them: catch only to recover, add context, or translate (rethrow with `throw;`), and never swallow. In an `async` method just `throw` (the Task captures it); use `Task.FromException()` only in non-`async` Task-returning methods. Validate arguments eagerly so usage errors throw synchronously (a non-`async` wrapper over an `async` implementation).
* Use `Task.WhenAll()` for independent parallel operations and `Task.WhenAny()` for the first completed task. For timeouts, use `Task.WaitAsync()` with a `CancellationTokenSource` instead: a timeout alone abandons the wait but doesn't stop the operation.
* Skip `async`/`await` for pure pass-through methods, except inside `using` or `try` scopes, which would end before the task completes.

## Concurrency and Thread Safety

* Prefer immutable types, concurrent/immutable collections, and message passing (`Channel<T>`) over shared mutable state guarded by `lock`.
* For unavoidable shared mutable state, prefer `Interlocked` and high-level primitives (e.g. `ReaderWriterLockSlim` for synchronous read-heavy access) over hand-rolled coordination. Use `volatile` only for the visibility of a single flag or an immutable-snapshot reference, never for compound operations (`x++` isn't atomic), and `lock`/`Monitor` only for short critical sections nothing higher-level covers. Avoid nesting locks: inconsistent ordering deadlocks.
* `lock`, `Monitor`, and `ReaderWriterLockSlim` are thread-affine (the acquiring thread must release), so they can't span an `await`; in async code use `SemaphoreSlim` with `WaitAsync()`.

## Nullable Reference Types

* Keep `<Nullable>enable</Nullable>` on in every project and treat warnings as defects: annotate, check, or annotate the producing API. Use the null-forgiving `!` sparingly (each is a place the compiler can no longer protect you), and prefer `required` members or constructors over `= null!`, reserving it for cases like EF Core navigation properties.

## Dependency Injection

* Use constructor injection; avoid the service locator pattern and `BuildServiceProvider` during registration (use the overload that receives an `IServiceProvider`).
* Pick lifetimes deliberately: singleton only for expensive or shared, thread-safe state. Never inject a scoped service into a singleton (it silently becomes one; use `IServiceScopeFactory`), keep `ValidateScopes` enabled (on by default only in Development), and don't resolve disposable transients from the root provider (the container holds them until shutdown).

## HTTP Clients

* Never create an `HttpClient` per request: it exhausts sockets. Use `IHttpClientFactory` (typed clients) or a shared long-lived client with `SocketsHttpHandler.PooledConnectionLifetime` set. Factory clients are short-lived by design: don't cache them or inject typed clients into singletons, or they miss DNS changes.

## Time

* Inject `TimeProvider` instead of reading `DateTime.UtcNow`/`DateTimeOffset.UtcNow` directly, and work in UTC. In tests use `FakeTimeProvider`, advance time explicitly, and don't mix it with `TimeProvider.System`.
