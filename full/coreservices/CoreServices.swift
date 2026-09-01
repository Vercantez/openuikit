// Linux starting point for Apple's public CoreServices UTI C API.
//
// On iPhoneOS this module is a legacy umbrella over MobileCoreServices
// (Uniform Type Identifiers). The pinned public surface is that C API:
// `kUTType*` / `kUTTag*` constants plus the `UTType*` query functions.
// Linux Foundation does not ship CoreFoundation CFString/CFArray types, so
// the public CF names are NSString/NSArray/NSDictionary/NSURL class aliases
// that make the documented `Unmanaged` Copy/Create retain convention compile.

import Foundation

/// CoreFoundation string spelling used by the public UTI C API.
/// Bridged to `NSString` on Linux because `Unmanaged` requires a class type.
public typealias CFString = NSString
/// CoreFoundation array spelling used by Copy/Create tag and identifier APIs.
public typealias CFArray = NSArray
/// CoreFoundation dictionary spelling used by `UTTypeCopyDeclaration`.
public typealias CFDictionary = NSDictionary
/// CoreFoundation URL spelling used by `UTTypeCopyDeclaringBundleURL`.
public typealias CFURL = NSURL

/// Returns whether two uniform type identifiers name the same type.
///
/// Comparison is case-insensitive on the identifier string. This does not
/// consult Launch Services aliases beyond the portable registry.
public func UTTypeEqual(_ inUTI1: CFString, _ inUTI2: CFString) -> Bool {
    _UTRegistry.identifiersEqual(inUTI1 as String, inUTI2 as String)
}

/// Returns whether `inUTI` is equal to or conforms to `inConformsToUTI`.
///
/// An identifier always conforms to itself. Additional conformance is the
/// portable parent graph in `_UTRegistry`; unknown identifiers do not invent
/// a Launch Services pedigree.
public func UTTypeConformsTo(_ inUTI: CFString, _ inConformsToUTI: CFString) -> Bool {
    _UTRegistry.conforms(inUTI as String, to: inConformsToUTI as String)
}

/// Returns whether `inUTI` is a declared type in the portable registry.
public func UTTypeIsDeclared(_ inUTI: CFString) -> Bool {
    _UTRegistry.isDeclared(inUTI as String)
}

/// Returns whether `inUTI` uses the documented dynamic-UTI prefix `dyn.`.
///
/// This Linux starting point does not synthesize Apple's compact `dyn.*`
/// encoding for unknown tags; see `oracle-questions.tsv`.
public func UTTypeIsDynamic(_ inUTI: CFString) -> Bool {
    _UTRegistry.isDynamic(inUTI as String)
}

/// Returns the preferred tag of `inTagClass` for `inUTI`, following the
/// Create/Copy +1 retain rule. Returns `nil` when the type is unknown or
/// has no tag of that class.
public func UTTypeCopyPreferredTagWithClass(
    _ inUTI: CFString,
    _ inTagClass: CFString
) -> Unmanaged<CFString>? {
    guard let tag = _UTRegistry.preferredTag(
        inUTI as String,
        tagClass: inTagClass as String
    ) else {
        return nil
    }
    return _retainCFString(tag)
}

/// Returns every tag of `inTagClass` declared for `inUTI`. Returns `nil`
/// when the type is unknown or has no tags of that class.
public func UTTypeCopyAllTagsWithClass(
    _ inUTI: CFString,
    _ inTagClass: CFString
) -> Unmanaged<CFArray>? {
    let tags = _UTRegistry.allTags(inUTI as String, tagClass: inTagClass as String)
    guard !tags.isEmpty else { return nil }
    return _retainCFArray(tags)
}

/// Returns the portable declaration dictionary for a declared type.
/// Dynamic and unknown identifiers return `nil`.
public func UTTypeCopyDeclaration(_ inUTI: CFString) -> Unmanaged<CFDictionary>? {
    guard let declaration = _UTRegistry.declaration(inUTI as String) else {
        return nil
    }
    return Unmanaged.passRetained(declaration)
}

/// Declaring-bundle lookup is Launch Services state. Linux has no Apple
/// bundle database, so this is fail-closed and always returns `nil`.
public func UTTypeCopyDeclaringBundleURL(_ inUTI: CFString) -> Unmanaged<CFURL>? {
    _ = inUTI
    return nil
}

/// Localized type descriptions are Apple bundle/localizer state. This
/// starting point does not invent those strings and returns `nil`.
public func UTTypeCopyDescription(_ inUTI: CFString) -> Unmanaged<CFString>? {
    _ = inUTI
    return nil
}

/// Returns the preferred declared identifier for `inTag` in `inTagClass`.
/// Unknown tags do not synthesize an Apple `dyn.*` identifier.
public func UTTypeCreatePreferredIdentifierForTag(
    _ inTagClass: CFString,
    _ inTag: CFString,
    _ inConformingToUTI: CFString?
) -> Unmanaged<CFString>? {
    guard let identifier = _UTRegistry.preferredIdentifier(
        tagClass: inTagClass as String,
        tag: inTag as String,
        conformingTo: inConformingToUTI.map { $0 as String }
    ) else {
        return nil
    }
    return _retainCFString(identifier)
}

/// Returns every declared identifier for `inTag` in `inTagClass`.
/// Unknown tags return `nil` rather than a dynamic-UTI array.
public func UTTypeCreateAllIdentifiersForTag(
    _ inTagClass: CFString,
    _ inTag: CFString,
    _ inConformingToUTI: CFString?
) -> Unmanaged<CFArray>? {
    let identifiers = _UTRegistry.allIdentifiers(
        tagClass: inTagClass as String,
        tag: inTag as String,
        conformingTo: inConformingToUTI.map { $0 as String }
    )
    guard !identifiers.isEmpty else { return nil }
    return _retainCFArray(identifiers)
}

private func _retainCFString(_ value: String) -> Unmanaged<CFString> {
    Unmanaged.passRetained(value as NSString)
}

private func _retainCFArray(_ values: [String]) -> Unmanaged<CFArray> {
    Unmanaged.passRetained(values.map { $0 as NSString } as NSArray)
}
