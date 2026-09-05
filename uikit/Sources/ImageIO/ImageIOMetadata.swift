import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

private let imageioTypeIDMetadata: CFTypeID = 0x4949_4d01
private let imageioTypeIDMetadataTag: CFTypeID = 0x4949_5401

public class CGImageMetadata: @unchecked Sendable {
    var tags: [CGImageMetadataTag] = []
    var namespaces: [String: String] = [:]
}

public final class CGMutableImageMetadata: CGImageMetadata, @unchecked Sendable {}

public final class CGImageMetadataTag: @unchecked Sendable {
    let xmlns: String
    let prefix: String?
    let name: String
    var path: String
    let value: Any

    init(xmlns: String, prefix: String?, name: String, path: String, value: Any) {
        self.xmlns = xmlns
        self.prefix = prefix
        self.name = name
        self.path = path
        self.value = value
    }
}

public func CGImageMetadataGetTypeID() -> CFTypeID { imageioTypeIDMetadata }
public func CGImageMetadataTagGetTypeID() -> CFTypeID { imageioTypeIDMetadataTag }

public func CGImageMetadataCreateMutable() -> CGMutableImageMetadata {
    CGMutableImageMetadata()
}

public func CGImageMetadataCopyTagWithPath(
    _ metadata: CGImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: CFString
) -> CGImageMetadataTag? {
    _ = parent
    let key = path as String
    return metadata.tags.first { $0.path == key }
}

public func CGImageMetadataSetValueWithPath(
    _ metadata: CGMutableImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: CFString,
    _ value: Any
) -> Bool {
    _ = parent
    let key = path as String
    let tag = CGImageMetadataTag(xmlns: "", prefix: nil, name: key, path: key, value: value)
    if let index = metadata.tags.firstIndex(where: { $0.path == key }) {
        metadata.tags[index] = tag
    } else {
        metadata.tags.append(tag)
    }
    return true
}

public func CGImageMetadataCopyStringValueWithPath(
    _ metadata: CGImageMetadata,
    _ parent: CGImageMetadataTag?,
    _ path: CFString
) -> CFString? {
    guard let tag = CGImageMetadataCopyTagWithPath(metadata, parent, path) else { return nil }
    if let string = tag.value as? String { return string as CFString }
    return nil
}

public func CGImageMetadataRegisterNamespaceForPrefix(
    _ metadata: CGMutableImageMetadata,
    _ xmlns: CFString,
    _ prefix: CFString,
    _ err: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    _ = err
    metadata.namespaces[prefix as String] = xmlns as String
    return true
}

public func CGImageMetadataCreateXMPData(
    _ metadata: CGImageMetadata,
    _ options: CFDictionary?
) -> CFData? {
    _ = options
    guard !metadata.tags.isEmpty else { return nil }
    var body = "<x:xmpmeta xmlns:x=\"adobe:ns:meta/\"><rdf:RDF xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"><rdf:Description rdf:about=\"\">"
    for tag in metadata.tags {
        body += "<\(tag.path)>\(tag.value)</\(tag.path)>"
    }
    body += "</rdf:Description></rdf:RDF></x:xmpmeta>"
    return Data(body.utf8) as CFData
}

public func CGImageMetadataCreateFromXMPData(_ data: CFData) -> CGImageMetadata? {
    guard let xml = String(data: data as Data, encoding: .utf8), !xml.isEmpty else { return nil }
    let metadata = CGMutableImageMetadata()
    var cursor = xml.startIndex
    while cursor < xml.endIndex {
        guard xml[cursor] == "<",
              let gt = imageioFind(xml, ">", from: cursor) else {
            cursor = xml.index(after: cursor)
            continue
        }
        let tag = String(xml[xml.index(after: cursor)..<gt])
        if tag.hasPrefix("/") || tag.hasPrefix("?") || tag.hasPrefix("!")
            || tag.hasPrefix("rdf:") || tag.hasPrefix("x:") {
            cursor = xml.index(after: gt)
            continue
        }
        let name: String
        if let space = tag.firstIndex(of: " ") {
            name = String(tag[tag.startIndex..<space])
        } else {
            name = tag
        }
        if name.isEmpty || name.hasPrefix("/") {
            cursor = xml.index(after: gt)
            continue
        }
        let close = "</" + name + ">"
        let innerStart = xml.index(after: gt)
        guard let end = imageioFind(xml, close, from: innerStart) else {
            cursor = xml.index(after: gt)
            continue
        }
        let inner = String(xml[innerStart..<end])
        if inner.hasPrefix("<") {
            cursor = xml.index(after: gt)
            continue
        }
        _ = CGImageMetadataSetValueWithPath(metadata, nil, name as CFString, inner)
        cursor = xml.index(end, offsetBy: close.count, limitedBy: xml.endIndex) ?? xml.endIndex
    }
    return metadata.tags.isEmpty ? nil : metadata
}

/// Index scan so the guest does not link `_StringProcessing` (`String.range(of:)`).
private func imageioFind(_ haystack: String, _ needle: String, from: String.Index) -> String.Index? {
    var index = from
    while index < haystack.endIndex {
        if haystack[index...].hasPrefix(needle) { return index }
        index = haystack.index(after: index)
    }
    return nil
}
