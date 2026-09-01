// Swift source-compatibility overlay for the iPhoneOS CoreServices UTI surface.
//
// CoreServices owns this iPhone UTI C API. MobileCoreServices is the later
// adapter/reexport, not the owner. This module does not emit `_UTType*` /
// `_kUT*` C ABI exports; central C-shim work owns that before platform merge.
//
// Canonical CF identities come from staged Foundation/CoreFoundation
// (`CFString == String`, `CFURL == URL`, `CFDictionary == [CFString: Any]`).
// This overlay binds signatures to those identities. There is no public
// module-local CF alias and no integration-compatible fallback dylib.
// `CFArray` has no Foundation identity; tag/identifier lists use `[String]`.
// Copy/Create results are optional Swift values, not Unmanaged CF retains.

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
/// Unknown tags currently return `nil` from Create* (fail-closed partial).
/// Apple's exact `dyn.*` encoding is an unanswered oracle question.
public func UTTypeIsDynamic(_ inUTI: String) -> Bool {
    _UTRegistry.isDynamic(inUTI)
}

/// Returns the preferred tag of `inTagClass` for `inUTI`.
/// Returns `nil` when the type is unknown or has no tag of that class.
public func UTTypeCopyPreferredTagWithClass(
    _ inUTI: String,
    _ inTagClass: String
) -> String? {
    _UTRegistry.preferredTag(inUTI, tagClass: inTagClass)
}

/// Returns every tag of `inTagClass` declared for `inUTI`.
/// Returns `nil` when the type is unknown or has no tags of that class.
public func UTTypeCopyAllTagsWithClass(
    _ inUTI: String,
    _ inTagClass: String
) -> [String]? {
    let tags = _UTRegistry.allTags(inUTI, tagClass: inTagClass)
    return tags.isEmpty ? nil : tags
}

/// Returns the portable declaration dictionary for a declared type.
/// Dynamic and unknown identifiers return `nil`.
public func UTTypeCopyDeclaration(_ inUTI: String) -> [String: Any]? {
    _UTRegistry.declaration(inUTI)
}

/// Declaring-bundle lookup is Launch Services state. Linux has no Apple
/// bundle database, so this is fail-closed and always returns `nil`.
public func UTTypeCopyDeclaringBundleURL(_ inUTI: String) -> URL? {
    _ = inUTI
    return nil
}

/// Localized type descriptions are Apple bundle/localizer state. This
/// overlay does not invent those strings and returns `nil`.
public func UTTypeCopyDescription(_ inUTI: String) -> String? {
    _ = inUTI
    return nil
}

/// Returns the preferred declared identifier for `inTag` in `inTagClass`.
/// Unknown tags are fail-closed partial: `nil`, not a synthesized `dyn.*`.
public func UTTypeCreatePreferredIdentifierForTag(
    _ inTagClass: String,
    _ inTag: String,
    _ inConformingToUTI: String?
) -> String? {
    _UTRegistry.preferredIdentifier(
        tagClass: inTagClass,
        tag: inTag,
        conformingTo: inConformingToUTI
    )
}

/// Returns every declared identifier for `inTag` in `inTagClass`.
/// Unknown tags are fail-closed partial: `nil`, not a `dyn.*` array.
public func UTTypeCreateAllIdentifiersForTag(
    _ inTagClass: String,
    _ inTag: String,
    _ inConformingToUTI: String?
) -> [String]? {
    let identifiers = _UTRegistry.allIdentifiers(
        tagClass: inTagClass,
        tag: inTag,
        conformingTo: inConformingToUTI
    )
    return identifiers.isEmpty ? nil : identifiers
}
