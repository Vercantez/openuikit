// FreestandingShims.swift -- NOT part of ~/uikit.
// Provenance: added by swift-macho-linux to build a vendored OpenUIKit slice
// for arm64-apple-macos under machorun, where canImport(Foundation) is FALSE
// (the staged sysroot has no Foundation module). Post-M15, OpenUIKit declares
// IndexPath / NSRange / TimeInterval only under `#if canImport(Foundation)`
// (Sources/OpenUIKit/FoundationTypes.swift); the pre-M15 build declared its
// own. This restores just the names the minimal render slice needs, matching
// the pre-M15 freestanding semantics.

public typealias TimeInterval = Double
