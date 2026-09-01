# Portable SwiftData

This directory supplies a standalone `SwiftData.swiftmodule`,
`libSwiftData.dylib`, and native `libSwiftDataMacros.so` for the Linux-hosted
ARM64 Mach-O platform package. It is intentionally a working volatile object
store, not a declaration-only shim.

Implemented behavior includes:

- attached `@Model` identity and `PersistentModel` conformance;
- schema-checked `ModelContainer` and `ModelContext`;
- insert, delete, save, rollback, identity lookup, and change sets;
- Foundation `#Predicate` evaluation, multiple sort descriptors, offset, limit,
  and fetch counts;
- live `@Query` reads and the SwiftUI `modelContext` environment value;
- SwiftUI `.modelContainer(for:)` using a process-lifetime in-memory store.

The SwiftUI convenience modifier reports its volatile fallback once to standard
error so an unchanged application can launch even though Linux durability is
not available. Explicit durable `ModelConfiguration` construction still throws
`SwiftDataError.unsupportedPersistentStore`; CloudKit, migrations, undo, and
disk-backed storage are never reported as successful.

The pinned swift-foundation revision predates upstream's final-class Predicate
key-path correction. The core build applies
`FoundationEssentials-PredicateFinalClassKeyPath.patch` to a derived build copy
only, after checking both the exact upstream source hash and patch hash. The
pinned upstream checkout remains untouched.

Run the semantic and exact-source gates with:

```sh
bash full/swiftdata/tests/test_swiftdata_host.sh
python3 -B full/swiftdata/tests/test_predicate_keypath_backport.py
```

The host gate hashes all 27 untouched IceCubes SwiftData import sites, all 54
sources in its Models target, and the exact 60-source SwiftSoup dependency. The
production package additionally builds and executes
`SwiftDataGuestRuntime.swift` as an ARM64 Mach-O process under the Linux loader.
