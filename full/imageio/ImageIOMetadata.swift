import Foundation

private let imageioTypeIDMetadata: CFTypeID = 0x4949_4d01
private let imageioTypeIDMetadataTag: CFTypeID = 0x4949_5401

public class CGImageMetadata: @unchecked Sendable {
    var tags: [CGImageMetadataTag]
    var namespaces: [CFString: CFString]

    init(tags: [CGImageMetadataTag] = [], namespaces: [CFString: CFString] = [:]) {
        self.tags = tags
        self.namespaces = namespaces
    }

    public static func == (left: CGImageMetadata, right: CGImageMetadata) -> Bool {
        left === right
    }

    public static func != (left: CGImageMetadata, right: CGImageMetadata) -> Bool {
        left !== right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public var hashValue: Int {
        ObjectIdentifier(self).hashValue
    }
}

public final class CGMutableImageMetadata: CGImageMetadata, @unchecked Sendable {}

public final class CGImageMetadataTag: @unchecked Sendable {
    let xmlns: CFString
    let prefix: CFString?
    let name: CFString
    let type: CGImageMetadataType
    let value: CFTypeRef
    let qualifiers: CFArray?
    var path: CFString

    init(
        xmlns: CFString,
        prefix: CFString?,
        name: CFString,
        type: CGImageMetadataType,
        value: CFTypeRef,
        qualifiers: CFArray? = nil,
        path: CFString? = nil
    ) {
        self.xmlns = xmlns
        self.prefix = prefix
        self.name = name
        self.type = type
        self.value = value
        self.qualifiers = qualifiers
        if let path {
            self.path = path
        } else if let prefix, !prefix.isEmpty {
            self.path = "\(prefix):\(name)"
        } else {
            self.path = name
        }
    }

    public static func == (left: CGImageMetadataTag, right: CGImageMetadataTag) -> Bool {
        left === right
    }

    public static func != (left: CGImageMetadataTag, right: CGImageMetadataTag) -> Bool {
        left !== right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    public var hashValue: Int {
        ObjectIdentifier(self).hashValue
    }
}

public typealias CGImageMetadataTagBlock = (CFString, CGImageMetadataTag) -> Bool

public func CGImageMetadataGetTypeID() -> CFTypeID {
    imageioTypeIDMetadata
}

public func CGImageMetadataTagGetTypeID() -> CFTypeID {
    imageioTypeIDMetadataTag
}

public func CGImageMetadataCreateMutable() -> CGMutableImageMetadata {
    CGMutableImageMetadata()
}

public func CGImageMetadataCreateMutableCopy(_ metadata: CGImageMetadata) -> CGMutableImageMetadata? {
    let copy = CGMutableImageMetadata()
    copy.namespaces = metadata.namespaces
    copy.tags = metadata.tags.map { tag in
        CGImageMetadataTag(
            xmlns: tag.xmlns,
            prefix: tag.prefix,
            name: tag.name,
            type: tag.type,
            value: tag.value,
            qualifiers: tag.qualifiers,
            path: tag.path
        )
    }
    return copy
}

public func CGImageMetadataCreateFromXMPData(_ data: CFData) -> CGImageMetadata? {
    _ = data
    return nil
}

public func CGImageMetadataCreateXMPData(
    _ metadata: CGImageMetadata,
    _ options: CFDictionary?
) -> CFData? {
    _ = metadata
    _ = options
    return nil
}

public func CGImageMetadataCopyTags(_ metadata: CGImageMetadata) -> CFArray? {
    metadata.tags.isEmpty ? nil : metadata.tags
}

public func CGImageMetadataCopyTagWithPath(
    _ metadata: CGImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: CFString
) -> CGImageMetadataTag? {
    _ = parent
    return metadata.tags.first { $0.path == path }
}

public func CGImageMetadataCopyStringValueWithPath(
    _ metadata: CGImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: CFString
) -> CFString? {
    guard let tag = CGImageMetadataCopyTagWithPath(metadata, parent, path) else { return nil }
    return tag.value as? CFString
}

public func CGImageMetadataEnumerateTagsUsingBlock(
    _ metadata: CGImageMetadata,
    _ rootPath: CFString?,
    _ options: CFDictionary?,
    _ block: @escaping CGImageMetadataTagBlock
) {
    _ = options
    for tag in metadata.tags {
        if let rootPath, !rootPath.isEmpty, !tag.path.hasPrefix(rootPath) {
            continue
        }
        if !block(tag.path, tag) {
            return
        }
    }
}

public func CGImageMetadataCopyTagMatchingImageProperty(
    _ metadata: CGImageMetadata,
    _ dictionaryName: CFString,
    _ propertyName: CFString
) -> CGImageMetadataTag? {
    let expected = "\(dictionaryName)/\(propertyName)"
    return metadata.tags.first { $0.path == expected || $0.name == propertyName }
}

public func CGImageMetadataRegisterNamespaceForPrefix(
    _ metadata: CGMutableImageMetadata,
    _ xmlns: CFString,
    _ prefix: CFString,
    _ err: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    if let existing = metadata.namespaces[prefix], existing != xmlns {
        imageioWriteError(
            err,
            code: Int(CGImageMetadataErrors.prefixConflict.rawValue),
            message: "prefix already registered to a different namespace"
        )
        return false
    }
    metadata.namespaces[prefix] = xmlns
    return true
}

public func CGImageMetadataSetTagWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: CFString,
    _ tag: CGImageMetadataTag
) -> Bool {
    _ = parent
    tag.path = path
    if let index = metadata.tags.firstIndex(where: { $0.path == path }) {
        metadata.tags[index] = tag
    } else {
        metadata.tags.append(tag)
    }
    return true
}

public func CGImageMetadataRemoveTagWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: CFString
) -> Bool {
    _ = parent
    let before = metadata.tags.count
    metadata.tags.removeAll { $0.path == path }
    return metadata.tags.count < before
}

public func CGImageMetadataSetValueWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: CFString,
    _ value: CFTypeRef
) -> Bool {
    let tag = CGImageMetadataTag(
        xmlns: "",
        prefix: nil,
        name: path,
        type: .string,
        value: value,
        path: path
    )
    return CGImageMetadataSetTagWithPath(metadata, parent, path, tag)
}

public func CGImageMetadataSetValueMatchingImageProperty(
    _ metadata: CGMutableImageMetadata,
    _ dictionaryName: CFString,
    _ propertyName: CFString,
    _ value: CFTypeRef
) -> Bool {
    let path = "\(dictionaryName)/\(propertyName)"
    let tag = CGImageMetadataTag(
        xmlns: dictionaryName,
        prefix: nil,
        name: propertyName,
        type: .string,
        value: value,
        path: path
    )
    return CGImageMetadataSetTagWithPath(metadata, nil, path, tag)
}

public func CGImageMetadataTagCreate(
    _ xmlns: CFString,
    _ prefix: CFString?,
    _ name: CFString,
    _ type: CGImageMetadataType,
    _ value: CFTypeRef
) -> CGImageMetadataTag? {
    guard type != .invalid, !name.isEmpty else { return nil }
    return CGImageMetadataTag(
        xmlns: xmlns,
        prefix: prefix,
        name: name,
        type: type,
        value: value
    )
}

public func CGImageMetadataTagCopyName(_ tag: CGImageMetadataTag) -> CFString? {
    tag.name
}

public func CGImageMetadataTagCopyNamespace(_ tag: CGImageMetadataTag) -> CFString? {
    tag.xmlns
}

public func CGImageMetadataTagCopyPrefix(_ tag: CGImageMetadataTag) -> CFString? {
    tag.prefix
}

public func CGImageMetadataTagCopyQualifiers(_ tag: CGImageMetadataTag) -> CFArray? {
    tag.qualifiers
}

public func CGImageMetadataTagCopyValue(_ tag: CGImageMetadataTag) -> CFTypeRef? {
    tag.value
}

public func CGImageMetadataTagGetType(_ tag: CGImageMetadataTag) -> CGImageMetadataType {
    tag.type
}
