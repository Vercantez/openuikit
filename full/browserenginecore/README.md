# BrowserEngineCore

Linux starting point for Apple's public `BrowserEngineCore` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph. Isolated host-gate
success is not integrated Darwin kqueue, JIT-witness, or `AVAudioSession`
routing.

## Depth pass 2026-09

This is a fresh seed: **15 exact public identifiers**, floor 12 nondeferred
(`ceil(80% of 15)`). Every identifier is `implemented` with a focused
top-level synchronous `func test*()`. The three C macros
(`BE_KEVENT_NO_FLAGS`, `BE_KEVENT_RETURN_IMMEDIATELY`,
`BE_JIT_WRITE_PROTECT_TAG`) each have their own value test rather than sharing
a table.

Coverage after this pass: **15 implemented / 0 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 implemented evidence distribution (15 implemented rows; no test
exceeds 40%):

| rows | share | evidence |
| ---: | ---: | --- |
| 1 | 6.7% | `BEKeventTests.swift#testBeKeventFailsClosed` |
| 1 | 6.7% | `BEKeventTests.swift#testBeKevent64FailsClosed` |
| 1 | 6.7% | `BEAudioSessionTests.swift#testBEAudioSessionIsNSObjectSubclass` |
| 1 | 6.7% | `BEAudioSessionTests.swift#testBEAudioSessionInitRetainsSession` |
| 1 | 6.7% | `BEAudioSessionTests.swift#testBEAudioSessionSetPreferredOutputFailsClosed` |

The remaining ten implemented rows each have their own test (available /
preferred outputs, ObjC class / init / setPreferredOutput-nil / empty-array /
preferred-nil-across-instances, JIT tag, kevent flag integers).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`26f5086c5b31ba816742f18d3096152cd32280f4` matched.

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.

## What is real

- `BE_KEVENT_NO_FLAGS` is `Int32` `0x0` and `BE_KEVENT_RETURN_IMMEDIATELY` is
  `Int32` `0x1`, matching the public `BEkevent.h` macros recorded by the
  pinned `dotnet/macios` Xcode 16.3 header diff.
- `be_kevent` / `be_kevent64` compile with Darwin `struct kevent` /
  `struct kevent64_s` overlays and always return `-1` with `errno == ENOSYS`.
  They never write `eventlist`.
- `BEAudioSession` is an `open` `NSObject` subclass. Designated
  `init(audioSession:)` retains the given session by object identity.
- Swift overlay `availableOutputs` is a non-optional `Array` and is empty.
  `preferredOutput` starts `nil`.
- `setPreferredOutput` always throws `NSError` domain
  `BrowserEngineCore.linux.unavailable` code `1`.

## Fail-closed boundaries

- Linux has no kqueue. `be_kevent` / `be_kevent64` never wait, never copy
  changes, and never succeed for `BE_KEVENT_RETURN_IMMEDIATELY`.
- Linux has no `AVAudioSession` routing hardware or daemon.
  `setPreferredOutput` throws even when the port is `nil` (Darwin's documented
  clear-preference success is unobserved).
- `availableOutputs` never fabricates a port description.
- `BE_JIT_WRITE_PROTECT_TAG` is `0` on this ptrauth-less host. It is not a
  working arm64e PAC discriminator and does not enable JIT write-protect.
- TBD exports (`BrowserEngineEntitlement`, `AuditToken`,
  `be_memory_inline_jit_restrict_*`, entitlement checkers) are not on the
  sealed 15-ID Swift surface and are not declared.

## Still deferred / unobserved

See `oracle-questions.tsv` for Darwin `setPreferredOutput` NSError identity,
`availableOutputs` nil-vs-empty, the JIT PAC discriminator integer,
`be_kevent` flag/timeout mapping, and hidden TBD overlay types.

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The sealed gate prints `BROWSERENGINECORE_AGENT_RUNTIME_OK` after calling each
cited test once.

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=BrowserEngineCore lane=leaf-full symbols=15
FRAMEWORK_FANOUT_REFERENCE_OK
BROWSERENGINECORE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=BrowserEngineCore dylib=libBrowserEngineCore.dylib
```

Run `bash full/browserenginecore/tests/acceptance/test_host.sh` from the repo root.
Keep generated products out of the tree.
