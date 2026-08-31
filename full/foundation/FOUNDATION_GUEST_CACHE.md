# Foundation URL Reference and Cache Compatibility

The standalone guest `Foundation` module owns the reference side of `URL`
bridging and a real `NSCache` implementation. These APIs are platform code:
unchanged applications can use `URL as NSURL`, `NSURL as URL`, and
`NSCache<NSURL, Object>` without an application shim or source rewrite.

## URL reference identity

`NSURL.swift` supplies the Foundation `ReferenceConvertible` contract, an
`NSObject`-backed `NSURL`, and `URL`'s `_ObjectiveCBridgeable` conformance.
The bridge preserves relative URL text and its base URL, while equality and
hashing follow the underlying FoundationEssentials `URL` value. The common
file, data-representation, component, and description surfaces are exposed on
the reference object.

## Cache semantics

`NSCache.swift` is a lock-protected, equality-keyed LRU cache. It strongly
retains keys and values, weakly retains its delegate, updates recency on a
successful lookup, trims immediately when count or total-cost limits change,
and reports replacement, explicit removal, bulk removal, and limit eviction
to the delegate after releasing its storage lock. Delegate generic erasure
preserves the original cache object's identity.

Apple accounts a negative item cost as a value exceeding every positive
limit, rather than clamping it to zero. The guest follows that observed edge.
Apple also raises an Objective-C reentrancy exception when a delegate mutates
the same cache during an eviction callback; the callback is consequently a
notification boundary, not a mutation hook.

## Oracle and cold gate

`tests/FoundationCacheOracle.swift` is compiled once with Apple's Foundation
and again as an ARM64 Mach-O executable against the project-owned Foundation.
Its checked-in 43-line Apple transcript is
`tests/foundation-cache-apple-2026-08-31.txt` (SHA-256
`0dd1fab4b09c76dfe6ab6fc07ac93d9350cf3bb19d31c7d8524c2df8e59e441c`).
The production core-package build refuses a changed oracle or golden file,
runs the guest executable in a cold Linux process, and requires an exact byte
comparison before publication.

The oracle covers absolute and relative URL bridges, component access,
round-trips, equality and hashing, cache defaults, equality-key lookup,
replacement, delegate identity and ordering, count/cost/late-limit eviction,
negative costs, lookup recency, key/value lifetime, and weak delegate lifetime.
