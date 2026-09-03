# JavaScriptCore (Linux starting point)

This directory is a host-local starting implementation of Apple's public
`JavaScriptCore` Swift surface, reconstructed from the sealed Xcode 26.1
iPhoneOS 26.1 symbol graph. Isolated `test_host.sh` success is not Apple JSC
parity and is not an integrated guest-package claim.

The legacy fan-out repository `github.com/Vercantez/openuikit-linux-platform`
was not readable from this environment (`git fetch` returned 404). This lane
is therefore a content-level promotion of a Linux deliverable onto the
monorepo seed: `full/javascriptcore/reference/` is the monorepo dossier
(generator SHA `2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`).

## What is real

- A Swift module named `JavaScriptCore` and a loadable `libJavaScriptCore.dylib`.
- The C overlay (`JSEvaluateScript`, `JSString*`, `JSObject*`, typed arrays,
  BigInt constructors, property names) as Swift functions over a retainable
  heap. Pointer identity is stable for the same object while it is retained.
- `JSContext` / `JSValue` / `JSVirtualMachine` / `JSManagedValue` overlay
  types, including keyed/indexed subscripts, `call` / `construct` /
  `invokeMethod`, geometry bridges (`CGPoint` / `CGSize` / `CGRect` /
  `NSRange`), and a small recursive-descent interpreter for the scripts the
  runtime probe exercises (`40 + 2`, object literals, arrays, functions,
  `JSON.parse` / `JSON.stringify`, `throw`).
- Typed-array views intern the backing `ArrayBuffer` object so
  `JSObjectGetTypedArrayBuffer` returns the same pointer twice.
- `this` inside JS functions follows the call/construct receiver, so
  `function Box(v){ this.v = v }` assigns onto the constructed object.

## Fail-closed / host-local boundaries

- `JSGarbageCollect` is an inert entry: it does not reclaim values.
- `isInspectable` / `JSGlobalContextSetInspectable` store a boolean. They do
  not attach a Web Inspector or remote debugging backend.
- Promises are ordinary objects with resolve/reject functions. There is no
  microtask queue and no unhandled-rejection plumbing.
- `JSExport` is an empty marker protocol. Swift classes are not exported into
  the JS global object.
- JSClass callback tables compile and `getProperty` can invoke a class
  getter when present; the host probe does not exercise custom JSClass
  callbacks, static values, or `finalize`.
- The interpreter is a subset. Apple parser/bytecode/JIT behavior, strict
  mode, and the full built-in library are unobserved.

## Deferred

See `coverage.tsv` (`deferred` rows) and `oracle-questions.tsv`. Facts that
cannot be established from the sealed public inputs stay `deferred` or
`unavailable`; they are never invented.
