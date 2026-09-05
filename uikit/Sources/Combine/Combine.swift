// Literal Combine import bridge backed by one OpenCombine identity.
//
// This target is a package *product* so an ingested SwiftPM package can
// `import Combine` on Linux. MEASURED focus-ios a2832521 Blockzilla ingest:
// 15 files import Combine (AppDelegate.swift:8). Darwin dependents keep
// the SDK module: they list
// `.product(name: "Combine", condition: .when(platforms: [.linux]))` and
// never compile this file. OpenCombine products are already Linux-only
// on the target; `#if os(Linux)` matches that so a Darwin `swift build`
// of this product (empty module) does not look for OpenCombine.
//
// Keep implementation out of this module. These aliases make diagnostics and
// qualified source spellings (`Combine.Published`) match the first-party
// framework name while preserving OpenCombine's nominal types.

#if os(Linux)
@_exported import OpenCombine
#if canImport(OpenCombineDispatch)
@_exported import OpenCombineDispatch
#endif
#if canImport(OpenCombineFoundation)
@_exported import OpenCombineFoundation
#endif

public typealias ObservableObject = OpenCombine.ObservableObject
public typealias ObservableObjectPublisher = OpenCombine.ObservableObjectPublisher
public typealias Published<Value> = OpenCombine.Published<Value>
#else
// Darwin `swift build --product Combine` still compiles this file. An empty
// `#if os(Linux)` body would leave the module with no types; the SDK's
// Combine is what Darwin dependents import.
enum _OpenUIKitCombineProduct {}
#endif
