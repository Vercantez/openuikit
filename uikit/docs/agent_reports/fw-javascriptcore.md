# JavaScriptCore SDK depth (agent/fw-javascriptcore)

Wave-1 starting point in `full/javascriptcore/`: **240 implemented / 115
declared / 2 deferred** of 357 public precise IDs. Wave-2: **357 implemented /
0 deferred**. No UIKit pixel rule; the Catalyst goldens and iOS suite are
untouched.

## What backs `JSContext.evaluateScript`

A real embedded recursive-descent interpreter in `JSEngine.swift` (not
fail-closed-as-undefined). Wave-1 already evaluated `40 + 2`, object
literals, arrays, functions, `JSON.parse` / `JSON.stringify`, and `throw`.
Wave-2 measured the remaining corpus-shaped subset against that engine and
filled the holes:

| script | result |
|---|---|
| `typeof 1` | `"number"` |
| `1 + '2'` | `"12"` (ECMA-262 13.8; string wins `+`) |
| `'2' * '3'` | `6` (ECMA-262 7.1.3 `ToNumber`) |
| `null == undefined` | `true` (ECMA-262 7.2.14) |
| `'12' == 12` / `'12' === 12` | `true` / `false` |
| `if (1) { 8 } else { 9 }` | `8` |
| `for (var i=0; i<3; i=i+1) s=s+i` | `3` |
| `Math.floor(1.9)` / `Math.pow(2,3)` | `1` / `8` |
| `'hello'.charAt(1)` / `'hello'.length` | `"e"` / `5` (UTF-16) |
| `[1,2].push(3)` then `join('-')` | `"1-2-3"` |
| `({a:1}) instanceof Object` | `true` |
| `"40+2".description` | `"42"` |

Unsupported syntax throws `SyntaxError` with `line` / `column` rather than
returning `undefined`. Measured:

| script | `exception.name` | `message` contains | `line` |
|---|---|---|---|
| `class Foo {}` | `SyntaxError` | `class` | 1 |
| `async function f(){}` | `SyntaxError` | `async` | 1 |
| `/a+/` | `SyntaxError` | `regular expression` | 1 |
| `x => x` | `SyntaxError` | `arrow` | 1 |
| `` `hi` `` | `SyntaxError` | `template` | 1 |
| `\nclass Foo {}` | `SyntaxError` | `class` | **2** |

## API surface exercised

The runtime probe now calls the previously-declared C and overlay IDs:
typed-array types (Int16 through BigUint64), `JSClassCreate` plus callback
dispatch (initialize, get/set/has/delete property, getPropertyNames,
callAsFunction, callAsConstructor, hasInstance, convertToType, finalize,
null-terminated staticValues/staticFunctions), `JSObjectMakeFunction` body
evaluation (was returning the declaration's undefined), `JSObjectMakeFunctionWithCallback`,
`JSObjectMakeConstructor`, `*PropertyForKey`, prototype get/set,
`JSValueCompare*`, `JSValue` `toDate`/`toDictionary`/`toObject`/`toObjectOf`/
`toInt64`/`toUInt64`/`toNumber`/`defineProperty`/subscripts/`compare`/
`isEqual`/`isInstance`, Hashable `hash(into:)` / `hashValue`, Equatable `!=`,
memberwise `JSClassDefinition` / `JSStaticValue` / `JSStaticFunction` inits.

Host functions: `setObject` with `([Any]) -> Any` (`hostAdd(2,3)→5`) and
`() -> Any` (`hostPing()→"pong"`). `JSExport` remains a marker protocol;
Swift class export is listed OPEN. `JSGarbageCollect` is invoked and is an
inert collector (no reclamation claimed). `JSVirtualMachine.addManagedReference`
keeps an owner/object pair and does not implement Apple GC.

`JSValue.toObject()`: `undefined`/`null` → `nil`; booleans/numbers →
`NSNumber`; strings → `NSString`; dates → `NSDate`; arrays/objects →
`NSArray`/`NSDictionary`. Date `ToNumber` is milliseconds since epoch
(`Date(timeIntervalSince1970: 1)` → `toInt64()==1000`).

## Coverage

| | implemented | declared | deferred | total |
|---|---|---|---|---|
| before | 240 | 115 | 2 | 357 |
| after | 357 | 0 | 0 | 357 |

Target was fully nondeferred and implemented ≥ 330.

## Listed gaps (not silent)

Regex literals, classes, async/await, generators, arrow functions, template
literals, modules. Also: no microtask Promise queue, no Web Inspector, no
JSExport class export, no JIT/strict-mode/full built-in library (`try`/`catch`,
`Map`/`Set`/`Proxy`, `Promise.then` jobs). `JSObjectMakeRegExp` still builds
a data-only object whose `toString` is `/pattern/flags`.

## Verification

- `bash tests/acceptance/test_host.sh` from `full/javascriptcore/` →
  `JAVASCRIPTCORE_AGENT_RUNTIME_OK` / `FRAMEWORK_FANOUT_HOST_OK`.
- Linux: `swift:6.2-noble` compile of the five guest sources (see commit).
- No uikit render change: Catalyst / iOS suite / real-app floors are the
  operator's existing numbers; this branch does not edit scenes, quartz, or
  goldens.

## Files

- `full/javascriptcore/JSEngine.swift` — interpreter, builtins, JSClass tables
- `full/javascriptcore/JSContext.swift` — closure bridge, `description`, `toObject`
- `full/javascriptcore/JSCAPI.swift` — `JSObjectMakeFunction` returns the function
- `full/javascriptcore/JSTypes.swift` — JSExport documented as a marker
- `full/javascriptcore/tests/agent/JavaScriptCoreRuntime.swift` — probe
- `full/javascriptcore/coverage.tsv` / `README.md`
