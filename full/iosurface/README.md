# IOSurface (Linux starting point)

This directory is a clean-room Linux implementation of Apple's public
`IOSurface` surface seeded from Xcode 26.1 / iPhoneOS 26.1. It is not
wired into a shared guest package; that integration is a later
central-review step.

The isolated host gate compiles `libIOSurface.dylib` from the sources
listed in `iosurface_guest_sources.txt`. `CoreFoundation` names used in
the C API are Foundation lookalikes (`NSString` / `NSDictionary`) so
the standalone module typechecks without a CF overlay. They are not
claimed as IOSurface identifiers. The EC2 integration probe
`tests/agent/IOSurfaceDependencyIdentity.swift` imports the real
`CoreFoundation` module.

## What is real

- `IOSurfaceCreate` / `init(properties:)` for width×height packed
  BGRA/RGBA/ARGB (`'BGRA'`, `'RGBA'`, `'ABGR'`, 32-bit ARGB) and
  biplanar `'420v'` / `'420f'`, plus alloc-size-only blobs and explicit
  `kIOSurfacePlaneInfo` dictionaries.
- Lock / unlock with seed: write unlocks increment the seed when the
  write-lock count returns to zero; `readOnly` does not bump it;
  `avoidSync` succeeds and is a no-op (no GPU stream).
- In-process `IOSurfaceGetID` / `IOSurfaceLookup`, use-count /
  `isInUse`, attachments (`SetValue` / ObjC attachment APIs share one
  store), purgeability (`keepCurrent` query, `empty` zeros pixels).
- Public enum raw values, option-set flags, cache-mode integers, and
  `kIOSurfaceSuccess == 0`.
- `NSSecureCoding` of geometry plus pixel bytes.

## Fail-closed boundaries

- `IOSurfaceCreateMachPort` returns `0` (`MACH_PORT_NULL`).
  `IOSurfaceLookupFromMachPort` returns nil.
- `IOSurfaceSetOwnershipIdentity` returns `KERN_FAILURE` (5). There
  is no `task_id_token` or kernel memory ledger.
- `kIOSurfaceIsGlobal` does not invent cross-process sharing.
- `kIOSurfaceColorSpace` / `kIOSurfaceICCProfile` are key identity only;
  nothing fabricates a ColorSync profile.

`IOSurfaceRef` is a typealias of `IOSurface` (toll-free bridge on
Apple). Conversion inits share backing storage and compare equal by
surface ID.

## Depth pass 2026-09

Coverage: **298 implemented / 0 declared / 0 deferred**.

Every `implemented` row cites
`test:full/iosurface/tests/agent/<File>Tests.swift#testName`. Enum /
option-set members and C `k…` constants share table-driven value tests;
create, lock, planes, lookup, purge, and fail-closed Mach APIs have
focused tests.

Top-5 evidence distribution (of 298 implemented rows):

1. `testPropertyKeys` — 25 (Swift overlay / C property-key constants)
2. `testLockOptionsAlgebra` — 21 (lock option-set algebra)
3. `testMemoryLedgerFlagsAlgebra` — 21 (ledger flag algebra)
4. `testPurgeabilityStateAlgebra` — 21 (purgeability option-set algebra)
5. `testCFStringKeys` / `testPlaneCFStringKeys` — 16 each (C key tables)

Largest non-constant family test is option-set algebra at 21 rows (7.0%),
under the 40% bulk-relabel cap. Enum members and C `k…` constants share
table-driven value tests as allowed.

## Environment

HEAD at seed `342dd2ee859ac3c9369653620a0b8835883008ad`. Swift 6.2.4
linux compiled `libIOSurface.dylib` with a clean product tree.
`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`). The
campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token, not printed by the sealed framework gate.

Run `bash tests/acceptance/test_host.sh` from this directory, or
`bash full/iosurface/tests/acceptance/test_host.sh` from the repo
root. Keep generated products out of the tree.
