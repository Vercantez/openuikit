# Foundation canonical framework contracts

This slice supplies the canonical Foundation identities that unchanged
first-party framework sources require at their package boundary. It is one
coherent platform layer, not per-framework compatibility aliases.

## Module ownership

`corefoundation_guest_sources.txt` builds `CoreFoundationCompatibility.swift`
as module `CoreFoundation` and `libCoreFoundation.dylib` before Foundation.
`FoundationCoreFoundationExports.swift` then reexports that module. The source
must not also be compiled into Foundation: doing so would create distinct
`Foundation.CFUUID` and `CoreFoundation.CFUUID` nominal identities.

The CoreFoundation boundary currently includes default-allocator URL creation,
Booleans, `CFAbsoluteTime`, and the exact sixteen-byte `CFUUIDBytes` carrier
with UUID creation/extraction. Custom allocators and a general CF object model
remain unsupported.

## Reference values and coding

`NSArray`/`NSMutableArray` and `NSData`/`NSMutableData` own synchronized
in-process storage, copying and mutation. Swift `Array` and `Data` conform to
the compiler's Objective-C bridge protocol, so both directions work without
application or framework source changes. `NSDictionary`/`NSMutableDictionary`
copy keys, retain values, synchronize individual mutations, and provide the
canonical empty/capacity/remove-all contracts.

The Foundation module declares `NSCoding`, `NSSecureCoding`, and
`NSMutableCopying` against OpenUIKit's existing `NSCoder`, `NSObject`, and
`NSCopying` identities. `NSCopying.copy()` and `NSMutableCopying.mutableCopy()`
forward to their nil-zone requirements. Keyed coder storage is a bounded,
thread-safe, 64-coder process-local transport supporting object/class-filtered
decode and the Bool, floating-point, and integer primitives required by the
framework package. It is not an `NSKeyedArchiver` byte format: missing,
evicted, or class-disallowed values fail closed.

## Predicate and streams

`NSPredicate(value:)`, block predicates, both evaluation overloads, copying,
and secure coding of constant predicates are implemented. Format parsing is
not guessed and block predicates do not claim archival support.

`OutputStream` implements real growable-memory and caller-buffer destinations.
It follows the measured Apple rule that a buffer write larger than remaining
capacity returns `-1` without a partial write. File and socket destinations are
outside this bounded route.

## Evidence

`test_foundation_canonical_contracts_host.sh` compiles declaration and behavior
probes against Xcode 26.1 Foundation.
`test_foundation_extension_guest_ec2.sh` rebuilds literal ARM64 modules named
`CoreFoundation` and `Foundation`, links both dylibs, runs the result through
machorun, and checks module-qualified CF identity plus live Array/NSArray and
Data/NSData bridges. Every run uses a fresh module cache and temporary tree.
