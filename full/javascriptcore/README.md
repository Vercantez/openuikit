# JavaScriptCore (Linux starting point)

This directory is a clean-room Linux implementation of Apple's public
`JavaScriptCore` Swift/C surface from the iPhoneOS 26.1 SDK seed. It builds
module `JavaScriptCore` and `libJavaScriptCore.dylib` from the Swift sources
listed in `javascriptcore_guest_sources.txt`. Canonical C headers and a
`module.modulemap` live in `include/`.

The isolated host gate only compiles those Swift sources and runs
`tests/agent/JavaScriptCoreRuntime.swift`. It is not an integrated Linux/EC2
result. Independent C and Swift clients are prepared under `tests/agent/` for
a future clean EC2 run that first builds guest Foundation, the guest Swift
runtime, and this dylib.

## What is real

- **C ABI.** Public `JS*` functions are exported unmangled (`@_cdecl`) to match
  the public-surface C inventory. Overlay functions that cannot appear in
  `@_cdecl` (Swift `JSType`, `JSTypedArrayType`, `JSRelationCondition`,
  `JSClassDefinition`) keep typed Swift entry points; `JSCExports.swift`
  thunks the C names with `UInt32` / `UnsafeRawPointer`. Headers define the
  C structs, enums, and `@convention(c)` callback typedefs. Isolated Swift
  cannot `import CJavaScriptCore` (the host gate has no `-I include`); layout
  is matched in Swift. `tests/agent/JavaScriptCoreCABI.c` plus
  `check_javascriptcore_exports.sh` are the C compile-link-run and nm/readelf
  gates for a future installed dylib.
- **JSClassDefinition.** `staticValues`, `staticFunctions`, has/get/set/delete
  property, `getPropertyNames`, `hasInstance`, `convertToType`,
  `callAsFunction`, `callAsConstructor`, `initialize` (parent first), and
  `finalize` (derived first, exactly once) are invoked from the C client.
- **Typed arrays.** `JSObjectGetTypedArrayBuffer` returns the context-interned
  backing `ArrayBuffer` object (stable identity, shared bytes) rather than a
  temporary unretained box.
- **Protect / GC.** `JSValueProtect` increments a protect count that is a GC
  root. `JSGarbageCollect` mark-sweeps from the global object and protected
  boxes; unreachable interned objects are dropped and class finalizers run.
  This is not Apple's JSC collector.
- **JSContext / JSValue / JSVirtualMachine / JSManagedValue.** A local
  JavaScript subset (literals, objects/arrays, functions, control flow,
  arithmetic, JSON, Date, Error, `NSRegularExpression`, typed arrays, and a
  synchronous Promise executor). Foundation `Date`, `CGPoint`, and `NSString`
  are used from the guest module (see
  `tests/agent/JavaScriptCoreDependencyIdentity.swift`).

## Fail-closed boundaries

- **`JSC_OBJC_API_ENABLED` is 0.** There is no Objective-C `JSExport`
  projection. The `JSExport` protocol is a marker only.
- **Inspector / remote debugging.** `isInspectable` is a stored flag. No
  WebKit inspector, sampling profiler, or debugger run loop is created.
- **Promises.** `then` / `catch` / executor callbacks run immediately. There
  is no JSC microtask queue.
- **`kJSClassDefinitionEmpty`.** Swift has a zero `JSClassDefinition` value.
  The C `extern const` data symbol is not emitted from Swift; C clients should
  zero-initialize a local struct.
- **Language coverage.** `class`, `async`/`await`, `import`/`export`, `yield`,
  and template interpolation throw a syntax error instead of pretending to
  work.
- **RegExp.** Patterns compile through `NSRegularExpression`. This is not
  ECMAScript `lastIndex` / `exec` parity.

The interpreter is original to this port. It is not Apple's JSC parser, JIT,
or garbage collector.

## Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes. Coverage for every precise
identifier is in `coverage.tsv`. Run the isolated host gate with:

```sh
bash full/javascriptcore/tests/acceptance/test_host.sh
```

A future clean EC2 run should install `include/` and `libJavaScriptCore.dylib`,
then:

```sh
export JSC_INCLUDE=.../include JSC_LIB=...
export LD_LIBRARY_PATH="$JSC_LIB:/usr/lib/swift/linux"
bash full/javascriptcore/tests/agent/run_javascriptcore_cabi_probe.sh
```
