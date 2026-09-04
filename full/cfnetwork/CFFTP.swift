import CoreFoundation
import Foundation

public func CFFTPCreateParsedResourceListing(
    _ alloc: CFAllocator?,
    _ buffer: UnsafePointer<UInt8>,
    _ bufferLength: CFIndex,
    _ parsed: UnsafeMutablePointer<Unmanaged<CFDictionary>?>?
) -> CFIndex {
    _ = alloc
    guard bufferLength > 0 else { return 0 }
    let bytes = Array(UnsafeBufferPointer(start: buffer, count: Int(bufferLength)))
    guard let newline = bytes.firstIndex(of: 10) else { return 0 }
    var lineBytes = Array(bytes[0...newline])
    let consumed = CFIndex(lineBytes.count)
    if lineBytes.last == 10 { lineBytes.removeLast() }
    if lineBytes.last == 13 { lineBytes.removeLast() }
    guard let line = String(bytes: lineBytes, encoding: .utf8) else { return -1 }
    guard let listing = cfParseFTPListLine(line) else {
        parsed?.pointee = nil
        return -1
    }
    parsed?.pointee = cfRetain(listing)
    return consumed
}

private func cfParseFTPListLine(_ line: String) -> CFMutableDictionary? {
    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    if trimmed.hasPrefix("total ") { return nil }
    let tokens = trimmed.split(whereSeparator: { $0.isWhitespace }).map(String.init)
    guard tokens.count >= 9 else { return nil }
    let modeText = tokens[0]
    guard let first = modeText.first else { return nil }
    let type: Int32
    switch first {
    case "d": type = 4
    case "l": type = 10
    case "b": type = 6
    case "c": type = 2
    case "p": type = 1
    case "s": type = 12
    default: type = 8
    }
    let owner = tokens[2]
    let group = tokens[3]
    let size = Int(tokens[4]) ?? 0
    let nameTokens: [String]
    let linkTarget: String?
    if type == 10, let arrow = tokens.firstIndex(of: "->"), arrow > 8 {
        nameTokens = Array(tokens[8..<arrow])
        linkTarget = tokens[(arrow + 1)...].joined(separator: " ")
    } else {
        nameTokens = Array(tokens[8...])
        linkTarget = nil
    }
    let name = nameTokens.joined(separator: " ")
    guard !name.isEmpty else { return nil }
    let dictionary = cfMutableDictionary()
    cfDictionarySet(dictionary, key: kCFFTPResourceName, value: cfString(name))
    cfDictionarySet(dictionary, key: kCFFTPResourceSize, value: cfNumber(size))
    cfDictionarySet(dictionary, key: kCFFTPResourceType, value: cfNumberInt32(type))
    cfDictionarySet(dictionary, key: kCFFTPResourceOwner, value: cfString(owner))
    cfDictionarySet(dictionary, key: kCFFTPResourceGroup, value: cfString(group))
    cfDictionarySet(dictionary, key: kCFFTPResourceMode, value: cfString(modeText))
    if let linkTarget {
        cfDictionarySet(dictionary, key: kCFFTPResourceLink, value: cfString(linkTarget))
    }
    return dictionary
}
