# CoreServices

Linux starting point for Apple's public `CoreServices` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. The iPhoneOS Swift surface
in this seed is the legacy Uniform Type Identifier C API (`UTType.h` /
`UTCoreTypes.h`), not Launch Services, FSEvents, or identity services.

This directory is not wired into the shared guest package. A passing isolated
host gate is not integrated Linux success.

The GitHub App installation for this promotion can read `Vercantez/openuikit`
only. `git fetch platform cursor/port-coreservices-to-linux-88cd` returned 404,
so this is a **fresh isolated-host implementation from the current monorepo
seed**, not a byte-copy of fan-out PR #8's claimed 1088 Swift lines.

**Reference dossier kept:** monorepo `full/coreservices/reference/` (generator
`scripts/framework-fanout/generate_seed.py`, SHA-256
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`). The
platform branch dossier was unavailable to compare, so the current seed on
main is the one retained.

## What is real

The public Swift surface compiles to `libCoreServices.dylib`.

- CF stand-ins: `CFString` / `CFArray` / `CFDictionary` / `CFURL` are
  typealiases to `NSString` / `NSArray` / `NSDictionary` / `NSURL`.
- All `kUTType*` constants use Apple's stable public UTI strings
  (`public.jpeg`, `com.adobe.pdf`, …).
- Declaration and tag-class keys use the public Info.plist names
  (`UTTypeIdentifier`, `public.filename-extension`, …).
- Query functions walk a local declared-type registry:
  conformance, equality, declared vs `dyn.*`, descriptions, tag lookup,
  and declaration dictionaries.
- Create/Copy functions return `Unmanaged` with +1 retain, matching the
  Darwin importer.

`tests/agent/CoreServicesRuntime.swift` exercises those paths and prints
`CORESERVICES_AGENT_RUNTIME_OK`.

## Fail-closed boundaries

- `UTTypeCopyDeclaringBundleURL` always returns `nil`. Linux has no Apple
  CoreServices/MobileCoreServices bundle to name as the declaring bundle.
- Unknown filename-extension or MIME tags do **not** mint `dyn.*`
  identifiers. `UTTypeCreatePreferredIdentifierForTag` /
  `UTTypeCreateAllIdentifiersForTag` return `nil` until the dynamic-UTI
  encoding is observed.
- `UTTypeIsDynamic` is prefix-only (`dyn.`). This module never produces
  those identifiers.
- Launch Services, FSEvents, and CSIdentity remain out of the public Swift
  surface in this seed and are not stubbed as success.

## Still open

See `oracle-questions.tsv` for dynamic-UTI encoding, preferred-identifier
choice when several types share a tag, declaring-bundle URLs on Darwin, and
the exact Info.plist shape of `UTTypeCopyDeclaration`.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
