@_exported import Foundation

// Linux has no CoreFoundation overlay. The Darwin Swift importer spells these
// C types as CFString / CFArray / CFDictionary / CFURL; NS* classes are the
// toll-free-bridged stand-ins used by this isolated host module.

public typealias CFString = NSString
public typealias CFArray = NSArray
public typealias CFDictionary = NSDictionary
public typealias CFURL = NSURL

// MARK: - Info.plist / tag-class keys
//
// Raw values match the public UTType.h / UTCoreTypes.h names.

public let kUTExportedTypeDeclarationsKey: CFString = "UTExportedTypeDeclarations"
public let kUTImportedTypeDeclarationsKey: CFString = "UTImportedTypeDeclarations"
public let kUTTypeIdentifierKey: CFString = "UTTypeIdentifier"
public let kUTTypeTagSpecificationKey: CFString = "UTTypeTagSpecification"
public let kUTTypeConformsToKey: CFString = "UTTypeConformsTo"
public let kUTTypeDescriptionKey: CFString = "UTTypeDescription"
public let kUTTypeIconFileKey: CFString = "UTTypeIconFile"
public let kUTTypeReferenceURLKey: CFString = "UTTypeReferenceURL"
public let kUTTypeVersionKey: CFString = "UTTypeVersion"
public let kUTTagClassFilenameExtension: CFString = "public.filename-extension"
public let kUTTagClassMIMEType: CFString = "public.mime-type"

// MARK: - Query API
//
// Create/Copy functions return a +1 Unmanaged, matching the Darwin importer.
// Unknown tags do not mint `dyn.*` identifiers (encoding unobserved).
// Declaring-bundle lookup is always nil: Linux has no Apple framework bundle.

public func UTTypeEqual(_ inUTI1: CFString, _ inUTI2: CFString) -> Bool {
    (inUTI1 as String) == (inUTI2 as String)
}

public func UTTypeConformsTo(_ inUTI: CFString, _ inConformsToUTI: CFString) -> Bool {
    UTTypeDatabase.conforms(inUTI as String, to: inConformsToUTI as String)
}

public func UTTypeIsDeclared(_ inUTI: CFString) -> Bool {
    UTTypeDatabase.record(for: inUTI as String) != nil
}

public func UTTypeIsDynamic(_ inUTI: CFString) -> Bool {
    (inUTI as String).hasPrefix("dyn.")
}

public func UTTypeCopyDescription(_ inUTI: CFString) -> Unmanaged<CFString>? {
    guard let description = UTTypeDatabase.record(for: inUTI as String)?.description else {
        return nil
    }
    return Unmanaged.passRetained(description as NSString)
}

public func UTTypeCopyDeclaringBundleURL(_ inUTI: CFString) -> Unmanaged<CFURL>? {
    _ = inUTI
    return nil
}

public func UTTypeCopyDeclaration(_ inUTI: CFString) -> Unmanaged<CFDictionary>? {
    guard let record = UTTypeDatabase.record(for: inUTI as String) else {
        return nil
    }
    var declaration: [NSString: Any] = [
        kUTTypeIdentifierKey: record.identifier as NSString,
        kUTTypeDescriptionKey: record.description as NSString,
    ]
    if !record.parents.isEmpty {
        declaration[kUTTypeConformsToKey] = record.parents as NSArray
    }
    var tags: [NSString: Any] = [:]
    if !record.filenameExtensions.isEmpty {
        tags[kUTTagClassFilenameExtension] = record.filenameExtensions as NSArray
    }
    if !record.mimeTypes.isEmpty {
        tags[kUTTagClassMIMEType] = record.mimeTypes as NSArray
    }
    if !tags.isEmpty {
        declaration[kUTTypeTagSpecificationKey] = tags as NSDictionary
    }
    return Unmanaged.passRetained(declaration as NSDictionary)
}

public func UTTypeCopyPreferredTagWithClass(
    _ inUTI: CFString,
    _ inTagClass: CFString
) -> Unmanaged<CFString>? {
    let tags = UTTypeDatabase.tags(for: inUTI as String, tagClass: inTagClass as String)
    guard let preferred = tags.first else {
        return nil
    }
    return Unmanaged.passRetained(preferred as NSString)
}

public func UTTypeCopyAllTagsWithClass(
    _ inUTI: CFString,
    _ inTagClass: CFString
) -> Unmanaged<CFArray>? {
    let tags = UTTypeDatabase.tags(for: inUTI as String, tagClass: inTagClass as String)
    guard !tags.isEmpty else {
        return nil
    }
    return Unmanaged.passRetained(tags as NSArray)
}

public func UTTypeCreatePreferredIdentifierForTag(
    _ inTagClass: CFString,
    _ inTag: CFString,
    _ inConformingToUTI: CFString?
) -> Unmanaged<CFString>? {
    let matches = UTTypeDatabase.identifiers(
        tagClass: inTagClass as String,
        tag: inTag as String,
        conformingTo: inConformingToUTI.map { $0 as String }
    )
    guard let preferred = matches.first else {
        return nil
    }
    return Unmanaged.passRetained(preferred as NSString)
}

public func UTTypeCreateAllIdentifiersForTag(
    _ inTagClass: CFString,
    _ inTag: CFString,
    _ inConformingToUTI: CFString?
) -> Unmanaged<CFArray>? {
    let matches = UTTypeDatabase.identifiers(
        tagClass: inTagClass as String,
        tag: inTag as String,
        conformingTo: inConformingToUTI.map { $0 as String }
    )
    guard !matches.isEmpty else {
        return nil
    }
    return Unmanaged.passRetained(matches as NSArray)
}
