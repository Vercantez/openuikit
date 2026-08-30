# Foundation guest NSString

`NSString.swift` replaces the former `typealias NSString = String` with one
immutable `ObjectiveC.NSObject`-backed reference type. It stores a canonical
Swift `String`, reports `length` and `character(at:)` in UTF-16 code units, and
implements the three substring APIs, comparison/equality/hash behavior, stable
UTF-8 access, path conveniences, and immutable copy identity. Swift `String`
conforms to `_ObjectiveCBridgeable` with this exact class as its object type, so
generated signatures such as `INObjectCollection<NSString>` carry a genuine
reference identity instead of a value alias.

The source-level `NSCopying` contract uses ObjectiveC's canonical `NSZone` and
returns the same object for immutable copies. It does not claim a separately
published Objective-C protocol object or mutable-string implementation.

The shared 46-row oracle in `tests/FoundationGuestNSStringOracle.swift` is
compiled against Apple Foundation and against a fresh literal portable module.
Both outputs must equal
`tests/foundation-guest-nsstring-apple-2026-08-30.txt`, SHA-256
`472ce641b97e460a14b19e80a10bb60af3fa532df6d0383799a9e58ba2d87486`.
It covers NSObject identity, composed Unicode/UTF-16 indexing, substring and
comparison behavior, explicit/implicit/generic object-value bridges, NSCopying identity, UTF-8 pointers
and constructors, `Data`, formatting, and path operations. A portable-only
negative executable requires malformed UTF-8, a missing nonempty byte buffer,
and unsupported encodings to return nil.

This slice is deliberately UTF-8-first. Byte/data construction and
`data(using:)` reject other encodings rather than silently applying UTF-8.
Mutable strings, locale-sensitive collation, file-encoding detection, and the
complete NSString API remain future production work. Host differential proof
does not substitute for the serialized ARM64 `libFoundation.dylib` package
gate; that binary/runtime claim remains pending until Docker lane ownership is
granted.
