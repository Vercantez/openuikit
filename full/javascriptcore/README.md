# JavaScriptCore (Linux starting point)

This directory is a host-local implementation of Apple's public
`JavaScriptCore` Swift surface, reconstructed from the sealed Xcode 26.1
iPhoneOS 26.1 symbol graph. Isolated `test_host.sh` success is not Apple JSC
parity and is not an integrated guest-package claim.

SDK depth (wave 2): 357/357 precise IDs `implemented`, 0 deferred. The
runtime probe in `tests/agent/JavaScriptCoreRuntime.swift` exercises the C
overlay, the ObjC-shaped Swift types, JSClass callback dispatch, and the
embedded ECMAScript subset interpreter.

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
