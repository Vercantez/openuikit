# AdSupport

Linux starting point for Apple's public `AdSupport` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS Swift symbol graph, API-digester import identity,
TBD class exports, and the pinned `dotnet/macios` binding as a secondary
cross-check. This directory is not wired into the shared guest package. A
passing isolated host gate is not integrated Linux success.

Coverage: **4 implemented / 0 declared / 0 deferred / 4 total** (leaf-full
floor is 4).

## What is real

The public Swift surface compiles to `libAdSupport.dylib` with Foundation only.

- `ASIdentifierManager` is an `open` `NSObject` subclass.
- `ASIdentifierManager.shared()` overlays ObjC `+sharedManager` and returns one
  process-wide instance.
- `advertisingIdentifier` is a Foundation `UUID` (ObjC `NSUUID`). Linux always
  returns `00000000-0000-0000-0000-000000000000`, the identifier Apple documents
  when tracking is not authorized. It is never a random or persisted IDFA.
- `isAdvertisingTrackingEnabled` is always `false`. The graph marks it
  deprecated in iOS 14 with the ATT replacement message.

Pinned `dotnet/macios` corroborates the ObjC selectors, `NSObject` base,
`DisableDefaultCtor` binding, `NSUuid` identifier type, and the iOS 14
deprecation. It also lists `clearAdvertisingIdentifier` as unavailable on iOS;
that method is absent from the sealed public Swift census and is not declared.

## Fail-closed boundaries

Linux has no IDFA hardware, advertising identifier daemon, ATT prompt, or
Settings advertising toggle.

- `advertisingIdentifier` never returns a non-zero UUID. Returning `UUID()`
  would fabricate a tracking identifier.
- `isAdvertisingTrackingEnabled` never reports `true`.
- `clearAdvertisingIdentifier` is not part of the iPhoneOS Swift graph and is
  not declared.
- Darwin IDFA format, rotation after Reset Advertising Identifier, ATT status
  mapping, and whether `alloc/init` aliases `sharedManager` are unobserved.

## Tests

`tests/agent/AdSupportLoadSmoke.swift` is the schema-v2 load marker.
`tests/agent/ASIdentifierManagerTests.swift` holds the sealed focused tests.
`tests/agent/AdSupportDependencyIdentity.swift` is prepared for a future clean
EC2 run that builds guest Foundation first and prints
`ADSUPPORT_DEPENDENCY_IDENTITY_OK` only after assertions pass. Compiling that
file against toolchain Foundation is not guest-Foundation success.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

## Depth pass 2026-09

Fresh seed: no prior implemented/declared split. After this pass:
**4 implemented / 0 declared / 0 deferred**. Every public precise identifier
has a dedicated synchronous test. There are no enum/option-set members.

Corpus ranking used `reference/corpus-summary.json` (one `ios-oss` occurrence
in `AppTrackingTransparency.swift`). `scratch/ladder-corpus` was not present
in this environment. The documented ATT relationship is fail-closed here:
AdSupport never claims tracking authorization.

Top-5 evidence distribution among 4 implemented rows:

| Citations | Evidence |
| ---: | --- |
| 1 | `ASIdentifierManagerTests.swift#testASIdentifierManagerClassIdentity` |
| 1 | `ASIdentifierManagerTests.swift#testSharedReturnsProcessWideSingleton` |
| 1 | `ASIdentifierManagerTests.swift#testAdvertisingIdentifierIsZeroUUID` |
| 1 | `ASIdentifierManagerTests.swift#testAdvertisingTrackingEnabledIsFalse` |

No test cites more than 1 of 4 implemented rows (40% cap is 2).
