# JavaScriptCore (Linux starting point)

This directory is a host-local implementation of Apple's public
`JavaScriptCore` Swift surface, reconstructed from the sealed Xcode 26.1
iPhoneOS 26.1 symbol graph. Isolated `test_host.sh` success is not Apple JSC
parity and is not an integrated guest-package claim.

SDK depth (wave 2): 357/357 precise IDs `implemented`, 0 deferred. The
sealed host probe is `tests/agent/JavaScriptCoreRuntime.swift`; family
tests live under `tests/agent/*Tests.swift` and are cited from
`coverage.tsv`.

## What is real

- A Swift module named `JavaScriptCore` and a loadable `libJavaScriptCore.dylib`.
- The C overlay (`JSEvaluateScript`, `JSString*`, `JSObject*`, typed arrays,
  BigInt constructors, property names, JSClass create/retain/release) as
  Swift functions over a retainable heap. Pointer identity is stable for the
  same object while it is retained.
- `JSContext` / `JSValue` / `JSVirtualMachine` / `JSManagedValue`, including
  keyed/indexed subscripts, `call` / `construct` / `invokeMethod`,
  `defineProperty`, geometry bridges (`CGPoint` / `CGSize` / `CGRect` /
  `NSRange`), and `JSValue.description` (the engine's `ToString`).
- A recursive-descent interpreter sufficient for expression evaluation,
  function calls, JSON-shaped object access, and simple scripts:
  numbers, strings, booleans, null/undefined, objects, arrays,
  functions/closures, `if` / `for` / `while` / `return`, `JSON.parse` /
  `JSON.stringify`, `Math` (`abs`, `floor`, `ceil`, `round`, `sqrt`,
  `sin`/`cos`/`tan`, `log`, `exp`, `max`, `min`, `pow`, `PI`, `E`),
  `String` prototype (`charAt`, `charCodeAt`, `substring`, `slice`,
  `indexOf`, `toLowerCase`, `toUpperCase`, `concat`, `trim`, `split`,
  `length` as UTF-16), `Array` prototype (`push`, `pop`, `shift`,
  `unshift`, `slice`, `concat`, `join`, `indexOf`).
- JS coercion used by the probe: `+` concatenates when either side is a
  string (ECMA-262 13.8); other arithmetic uses `ToNumber` (7.1.3);
  `==` is abstract equality including null/undefined and string/number
  (7.2.14); `===` is strict; `typeof null === "object"`.
- Syntax errors are `SyntaxError` objects with `line` / `column` (and
  `sourceURL` when `evaluateScript(_:withSourceURL:)` provided one).
- JSClass `getProperty` / `setProperty` / `hasProperty` / `deleteProperty` /
  `getPropertyNames` / `initialize` / `finalize` / `hasInstance` /
  `convertToType` / `callAsFunction` / `callAsConstructor`, plus
  null-terminated `staticValues` / `staticFunctions` tables copied at
  `JSClassCreate`.
- Host functions: `JSContext.setObject` with a Swift closure of
  `() -> Any`, `(Any) -> Any`, `(Any, Any) -> Any`, `(Any, Any, Any) -> Any`,
  or `([Any]) -> Any`.
- Typed-array views intern the backing `ArrayBuffer` object so
  `JSObjectGetTypedArrayBuffer` returns the same pointer twice.
- `this` inside JS functions follows the call/construct receiver.

## Listed gaps (fail-closed, not silent undefined)

These produce a `SyntaxError` (or a named runtime error) rather than
returning `undefined`:

- Regular expression literals (`/a+/`) — `JSObjectMakeRegExp` still builds
  a data-only regexp object; there is no `test` / `exec` engine.
- `class` declarations.
- `async` / `await`.
- Generators (`yield`).
- Arrow functions (`=>`).
- Template literals (backticks).
- `import` / `export` modules.

Also unclaimed, and not silently treated as Apple parity:

- `JSGarbageCollect` is an inert entry: it does not reclaim values.
- `isInspectable` / `JSGlobalContextSetInspectable` store a boolean. They do
  not attach a Web Inspector or remote debugging backend.
- Promises are ordinary objects with resolve/reject functions. There is no
  microtask queue and no unhandled-rejection plumbing.
- `JSExport` is an empty marker protocol. Swift classes are not exported into
  the JS global object (no ObjC JSExport runtime on this port). Use the
  Swift closure bridge above.
- No JIT, no strict-mode semantics beyond the operators above, no full
  built-in library (no `Map`/`Set`/`Proxy`/`Reflect`/`Promise.then` jobs,
  no `try`/`catch`/`finally`, no destructuring, no spread).

## Coverage

See `coverage.tsv`. Wave-1 starting point was 240 implemented / 115 declared
/ 2 deferred. Wave-2 is 357 implemented / 0 deferred. Open questions that
need an Apple-oracle probe remain in `oracle-questions.tsv` (GC reclamation,
Apple JSExport class export, inspector backend, Promise job queue, C ABI).

## Depth pass 2026-09

Second SDK-depth pass on `origin/agent/fw-javascriptcore`. Central review
refused wave 2 because every `implemented` row cited the file
`tests/agent/JavaScriptCoreRuntime.swift` rather than a focused test.

This pass keeps the interpreter and the fail-closed ECMAScript gaps
above. It splits behavioral checks into family tests and recites each of
the 357 precise IDs as
`test:full/javascriptcore/tests/agent/<File>Tests.swift#testName`:

- `JSContextTests` — `evaluateScript`, exceptions, `globalObject`, TLS
  `current*`, name / inspectable / VM wrapping
- `JSValueConstructionTests` — every `JSValue` constructor plus every
  `to*()` coercion, type queries, and `compare` / `isEqual`
- `JSValueCallTests` — `call`, `construct`, `invokeMethod`
- `JSValuePropertyTests` — properties, subscripts, `defineProperty`,
  `deleteProperty`, descriptor keys
- `JSValueConversionTests` — nested dictionary and array conversion
- `JSClosureTests` — `() -> Any`, `(Any) -> Any`, `(Any, Any) -> Any`,
  `(Any, Any, Any) -> Any`, `([Any]) -> Any`
- `JSVirtualMachineTests` — `JSVirtualMachine` / `JSManagedValue`
- C overlay / JSClass / typed-array / interpreter-subset files cover the
  remaining identifiers

The sealed `test_host.sh` still compiles only
`JavaScriptCoreRuntime.swift`, so that file defines the same `test*`
functions and invokes them before printing
`JAVASCRIPTCORE_AGENT_RUNTIME_OK`. Family files exist so the ledger can
name the test that exercises each row.

`testJSUnsupportedECMAScriptGaps` is an extra probe (no unique public
precise ID): `class`, `async`/`await`, `yield`, regexp literals, arrow
functions, template literals, and `import`/`export` all throw
`SyntaxError` instead of succeeding as undefined.

Sealed host gate on this Linux host (Swift 6.2.4, `x86_64-unknown-linux-gnu`):

```
FRAMEWORK_FANOUT_REFERENCE_OK
JAVASCRIPTCORE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=JavaScriptCore dylib=libJavaScriptCore.dylib
```

`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
because the scratch corpus pin `scratch/ladder-corpus/focus-ios` is
missing. `swiftc --version` is Swift 6.2.4 targeting linux. The sealed
schema-v1 `test_host.sh` does not print that environment marker.
