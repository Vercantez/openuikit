# VisualIntelligence (Linux starting point)

This directory is a fail-closed portable `VisualIntelligence` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift
surface from the sealed symbol graph. It is not wired into the shared guest
package; a passing isolated host gate is not integrated Linux success and is
not Apple Visual Intelligence behavior.

## Depth pass 2026-09

This is a fresh seed: 13 exact public identifiers, floor 11 nondeferred.

Coverage after this pass: **13 implemented** / 0 declared / 0 deferred
(floor 11 nondeferred). Implemented rows are the `SemanticContentDescriptor`
value type, stored `labels`, Linux-host `description` / identity / display
tokens, fail-closed `pixelBuffer`, and the App Intents typealias overlays.

Top-5 evidence distribution among 13 implemented rows (13 focused tests;
each identifier has its own test, 7.7% each):

- `SemanticContentDescriptorTests.swift#testSemanticContentDescriptorValueType` — 1 (7.7%)
- `SemanticContentDescriptorTests.swift#testLabelsStored` — 1 (7.7%)
- `SemanticContentDescriptorTests.swift#testDescriptionFormat` — 1 (7.7%)
- `SemanticContentDescriptorPixelBufferTests.swift#testPixelBufferFailClosed` — 1 (7.7%)
- `SemanticContentDescriptorIdentityTests.swift#testPersistentIdentifier` — 1 (7.7%)

## What is real

- `SemanticContentDescriptor` stores `labels: [String]`. Equality and hashing
  use labels. Linux constructs values with `init(labels:)`. Apple's TBD inits
  that take `IntentItemCollection` and a pixel buffer or image-frame UUID are
  not in the compact 13-identifier surface.
- `description` / `String(describing:)` emit `SemanticContentDescriptor()` or
  `SemanticContentDescriptor(a, b)`. Darwin formatting is unobserved.
- `persistentIdentifier` is the Linux-host token
  `VisualIntelligence.SemanticContentDescriptor`.
- `typeDisplayRepresentation.name` is `Semantic Content Descriptor`.
- `displayRepresentation.title` is the labels joined with `", "`, or the type
  name when labels is empty.
- `localizedStringResource` maps that display title onto a Linux-host
  `LocalizedStringResource` (swift-corelibs Foundation does not provide the
  Darwin type).
- `UnwrappedType` and `ValueType` alias `SemanticContentDescriptor`.
- `Specification` aliases the unavailable resolver type. Apple's opaque
  `typealias Specification = some ResolverSpecification` is not accepted by
  this Swift toolchain in typealias position.

## Fail-closed boundaries

Linux has no Visual Intelligence camera session, on-device ML scene, or App
Intents resolver.

- `pixelBuffer` is always `nil`.
- `defaultResolverSpecification` is `VisualIntelligenceUnavailableResolverSpecification`
  and never resolves entities.
- `VisualIntelligenceLinuxUnavailableError` (`VisualIntelligence.LinuxUnavailable`,
  code `1`) is a Linux overlay for operations that would require Apple ML /
  App Intents / camera services. It is not one of the 13 public identifiers.
- AppIntents (`DisplayRepresentation`, `TypeDisplayRepresentation`,
  `ResolverSpecification`) and CoreVideo (`CVReadOnlyPixelBuffer`) types are
  lookalikes compiled only when those modules are absent. They are not Linux
  ports of those frameworks and are not declared dependencies of this seed
  (Foundation only).

## Still open

See `oracle-questions.tsv` for Darwin persistent-identifier strings, description
format, display-representation image/subtitle payloads, when `pixelBuffer` is
non-nil, the concrete resolver type, and TBD-only `convertToEntity` /
`imageFrameResourceID` behavior.

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The sealed gate prints `VISUALINTELLIGENCE_AGENT_RUNTIME_OK` after calling
each cited test once.

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=VisualIntelligence lane=leaf-full symbols=13
FRAMEWORK_FANOUT_REFERENCE_OK
VISUALINTELLIGENCE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=VisualIntelligence dylib=libVisualIntelligence.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiled with a clean product tree (`products=clean`). Starting commit `26f5086c5b31ba816742f18d3096152cd32280f4` matched.

Run `bash full/visualintelligence/tests/acceptance/test_host.sh` from the
repo root. Keep generated products out of the tree.
