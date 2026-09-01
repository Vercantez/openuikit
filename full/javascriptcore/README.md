# JavaScriptCore (Linux starting point)

This directory is a clean-room Linux implementation of Apple's public
`JavaScriptCore` Swift/C surface from the iPhoneOS 26.1 SDK seed. It builds
module `JavaScriptCore` and `libJavaScriptCore.dylib` from the Swift sources
listed in `javascriptcore_guest_sources.txt`.

## What is real

- **JSContext / JSValue / JSVirtualMachine / JSManagedValue.** Contexts evaluate
  a local JavaScript subset (literals, objects/arrays, functions, control flow,
  arithmetic, JSON, Date, Error, RegExp via `NSRegularExpression`, typed arrays,
  and a synchronous Promise executor). Values convert to and from common
  Foundation types (`String`, `NSNumber`, `Date`, arrays, dictionaries).
- **C API.** `JSGlobalContextCreate`, `JSEvaluateScript`, `JSString*`,
  `JSValueMake*` / `JSValueTo*`, object property access, classes, typed arrays,
  and CFString copy/create are implemented against the same in-process heap.
  Opaque pointers use Swift `Unmanaged` retain/release for the CF-style types
  (`JSString`, `JSClass`, `JSContext`, `JSContextGroup`, property-name arrays).
- **Types and constants.** `JSType`, `JSTypedArrayType`, `JSRelationCondition`,
  property/class attributes, `JSClassDefinition`, and `JSC_OBJC_API_ENABLED`
  match the pinned Swift interface.

The interpreter is original to this port. It is not Apple's JSC parser, JIT, or
garbage collector.

## Fail-closed boundaries

- **Inspector / remote debugging.** `isInspectable` is a stored flag only. No
  WebKit inspector, sampling profiler, or debugger run loop is created.
- **JSExport.** The protocol exists so types can conform. Linux has no ObjC
  runtime, so conforming classes are not automatically projected into JavaScript.
  Unknown Swift objects become inert host wrappers.
- **Promises.** `then` / `catch` run immediately. There is no JSC microtask
  queue.
- **Garbage collection.** `JSGarbageCollect` is a no-op. Values are kept by
  Swift ARC and the owning virtual machine heap until the context is released.
- **Language coverage.** `class`, `async`/`await`, `import`/`export`, `yield`,
  and template interpolation throw a syntax error instead of pretending to work.
- **RegExp.** Patterns compile through `NSRegularExpression`. This is not a
  claim of ECMAScript `lastIndex` / `exec` parity.

## Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: JSExport projection,
inspector attach behavior, Promise scheduling, exception object shape,
`JSManagedValue` collection, CFString allocator details, and which extra ES
features the 20-app corpus actually evaluates.

Coverage for every precise identifier is in `coverage.tsv`. Run the host gate
with:

```sh
bash full/javascriptcore/tests/acceptance/test_host.sh
```
