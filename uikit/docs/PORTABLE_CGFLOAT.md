# Portable `CGFloat` for Foundation-hidden guests

OpenCoreGraphics uses a nominal `CGFloat` when it is compiled before a
complete `Foundation` umbrella is visible. This matches the Apple SDK's type
identity: `Double` and `CGFloat` are distinct types even on 64-bit platforms,
so an unchanged dependency may legally add separate conformances for both.
SnapKit does exactly that. A `typealias CGFloat = Double` made its 36 pinned
sources impossible to compile without editing vendor code.

The implementation in `Sources/OpenCoreGraphics/PortableCGFloat.swift` is
adapted from the Swift project's `swift-corelibs-foundation` at commit
`761b621da93a856a48995efc29ed11028c283306`, file
`Sources/Foundation/CGFloat.swift` (SHA-256
`de830d499904959b9589a9af4019aa344bd54e0e89138d1a65c6fd5748ec51c0`).
That source is Copyright Apple Inc. and
the Swift project authors and is licensed under Apache License 2.0 with the
Swift Runtime Library Exception. Its license header is retained in the source,
and the complete license is bundled at
`THIRD_PARTY_LICENSES/Swift-Foundation.txt`. The upstream `LICENSE` used for
that copy has SHA-256
`0ca84095d1de77cad1a866ebbad28f8db98a0826c6055d92b0608c5baa1643e2`;
only trailing whitespace is normalized in the bundled copy.

Two deliberate adaptations are documented in the file:

- `init?<T: BinaryInteger>(exactly:)` delegates to the native `Float` or
  `Double` exact initializer instead of the donor revision's placeholder
  `fatalError()`.
- The donor's free `tgmath` overloads are omitted. OpenCoreGraphics' rendering
  paths use their existing deterministic math helpers and the
  `BinaryFloatingPoint` operations supplied by this type. Public `tgmath`
  coverage remains a separate compatibility slice.

`QuartzCGFloatBridge.swift` is the explicit boundary between the Swift value
type and libquartz's C ABI, whose `QZFloat` is `double`. No implicit source or
binary conversion is assumed.

Run `scripts/prove_portable_cgfloat.sh` after building the sibling
`swift-macho-linux` full substrate. It compiles the same contract probe against
Apple CoreGraphics, then compiles the portable implementation for
`arm64-apple-macos15.0`, links a real Mach-O executable, and runs it through
machorun on Linux. The probe checks distinct conformances, 64-bit layout,
numeric conversions (including exact failure), arithmetic, bit patterns,
floating-point classifications, `Strideable`, and hashing.
