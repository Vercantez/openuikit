// Portable Copy/Create registry helpers. These are not the pinned overlay
// signatures: the immutable surface returns Unmanaged CF objects, which staged
// Foundation cannot represent (CFString is String; CFArray is absent).
// Callers that need takeRetainedValue() must wait for a class-typed CF
// universe. Do not import this SPI as proof of Swift source compatibility.

import Foundation

@_spi(OpenUIKitHost)
public enum OpenUIKitHostUTType {
    /// Host-only preferred-tag lookup. Not `Unmanaged<CFString>?`.
    public static func copyPreferredTag(
        for inUTI: String,
        tagClass inTagClass: String
    ) -> String? {
        _UTRegistry.preferredTag(inUTI, tagClass: inTagClass)
    }

    /// Host-only tag list. Not `Unmanaged<CFArray>?`.
    public static func copyAllTags(
        for inUTI: String,
        tagClass inTagClass: String
    ) -> [String]? {
        let tags = _UTRegistry.allTags(inUTI, tagClass: inTagClass)
        return tags.isEmpty ? nil : tags
    }

    /// Host-only declaration dictionary. Not `Unmanaged<CFDictionary>?`.
    public static func copyDeclaration(for inUTI: String) -> [String: Any]? {
        _UTRegistry.declaration(inUTI)
    }

    /// Host-only declaring-bundle lookup. Always nil (no Launch Services).
    public static func copyDeclaringBundleURL(for inUTI: String) -> URL? {
        _ = inUTI
        return nil
    }

    /// Host-only description lookup. Always nil (no Apple localizer).
    public static func copyDescription(for inUTI: String) -> String? {
        _ = inUTI
        return nil
    }

    /// Host-only preferred-identifier lookup. Unknown tags are fail-closed
    /// partial `nil`, not a synthesized Apple `dyn.*` identifier.
    public static func createPreferredIdentifier(
        tagClass: String,
        tag: String,
        conformingTo: String?
    ) -> String? {
        _UTRegistry.preferredIdentifier(
            tagClass: tagClass,
            tag: tag,
            conformingTo: conformingTo
        )
    }

    /// Host-only identifier list. Unknown tags are fail-closed partial `nil`.
    public static func createAllIdentifiers(
        tagClass: String,
        tag: String,
        conformingTo: String?
    ) -> [String]? {
        let identifiers = _UTRegistry.allIdentifiers(
            tagClass: tagClass,
            tag: tag,
            conformingTo: conformingTo
        )
        return identifiers.isEmpty ? nil : identifiers
    }
}
