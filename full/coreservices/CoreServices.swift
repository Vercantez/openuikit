// Swift overlay for the iPhoneOS CoreServices UTI surface.
//
// CoreServices owns this iPhone UTI C API. MobileCoreServices is the later
// adapter/reexport, not the owner. This module does not emit `_UTType*` /
// `_kUT*` C ABI exports; central C-shim work owns that before platform merge.
//
// Staged Foundation/CoreFoundation currently aliases CFString to String and
// has no ownership-capable CFArray. The pinned Copy/Create signatures return
// Unmanaged<CFString|CFArray|CFDictionary|CFURL> and therefore cannot be
// published without a CoreServices-local CF lookalike. Those seven APIs are
// deferred on that central dependency blocker. Direct-optional String/URL
// substitutes are not the public surface.
//
// Bool queries and constants bind to String, which is the staged CFString
// identity. Portable Copy/Create registry behavior lives under
// @_spi(OpenUIKitHost) and must not be treated as the pinned overlay.

import Foundation

#if CORESERVICES_EMIT_C_ABI
#error("C ABI _UTType*/_kUT* exports are deferred to central C-shim work; this Swift overlay must not emit them")
#endif

/// Returns whether two uniform type identifiers name the same type.
///
/// Comparison is case-insensitive on the identifier string. This does not
/// consult Launch Services aliases beyond the portable registry.
public func UTTypeEqual(_ inUTI1: String, _ inUTI2: String) -> Bool {
    _UTRegistry.identifiersEqual(inUTI1, inUTI2)
}

/// Returns whether `inUTI` is equal to or conforms to `inConformsToUTI`.
///
/// An identifier always conforms to itself. Additional conformance is the
/// portable parent graph in `_UTRegistry`; unknown identifiers do not invent
/// a Launch Services pedigree.
public func UTTypeConformsTo(_ inUTI: String, _ inConformsToUTI: String) -> Bool {
    _UTRegistry.conforms(inUTI, to: inConformsToUTI)
}

/// Returns whether `inUTI` is a declared type in the portable registry.
public func UTTypeIsDeclared(_ inUTI: String) -> Bool {
    _UTRegistry.isDeclared(inUTI)
}

/// Returns whether `inUTI` uses the documented dynamic-UTI prefix `dyn.`.
///
/// Unknown tags currently return `nil` from the host SPI Create* helpers
/// (fail-closed partial). Apple's exact `dyn.*` encoding is unanswered.
public func UTTypeIsDynamic(_ inUTI: String) -> Bool {
    _UTRegistry.isDynamic(inUTI)
}
