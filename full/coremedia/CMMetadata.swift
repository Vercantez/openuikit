import CoreFoundation
import Foundation

/// Metadata identifier services. Apple's CMMetadata.h: identifiers encode a
/// four-byte keyspace and an n-byte key into a CFString and back.

public func CMMetadataCreateIdentifierForKeyAndKeySpace(
    allocator: CFAllocator?,
    key: CFTypeRef,
    keySpace: CFString,
    identifierOut: UnsafeMutablePointer<CFString?>
) -> OSStatus {
    _ = allocator
    let space = unsafeBitCast(keySpace, to: NSString.self) as String
    let keyString: String
    if let ns = key as? NSString {
        keyString = ns as String
    } else {
        identifierOut.pointee = nil
        return kCMMetadataIdentifierError_BadKeyType
    }
    if space.isEmpty { return kCMMetadataIdentifierError_BadKeySpace }
    if keyString.isEmpty { return kCMMetadataIdentifierError_BadKey }
    identifierOut.pointee = cmMakeCFString(space + "/" + keyString)
    return 0
}

public func CMMetadataCreateKeyFromIdentifier(
    allocator: CFAllocator?,
    identifier: CFString,
    keyOut: UnsafeMutablePointer<CFTypeRef?>
) -> OSStatus {
    _ = allocator
    let text = unsafeBitCast(identifier, to: NSString.self) as String
    guard let slash = cmFirstIndex(of: "/", in: text) else {
        keyOut.pointee = nil
        return kCMMetadataIdentifierError_BadIdentifier
    }
    let key = String(text[text.index(after: slash)...])
    if key.isEmpty {
        keyOut.pointee = nil
        return kCMMetadataIdentifierError_BadIdentifier
    }
    keyOut.pointee = cmMakeCFString(key)
    return 0
}

public func CMMetadataCreateKeyFromIdentifierAsCFData(
    allocator: CFAllocator?,
    identifier: CFString,
    keyOut: UnsafeMutablePointer<CFData?>
) -> OSStatus {
    var key: CFTypeRef?
    let status = CMMetadataCreateKeyFromIdentifier(
        allocator: allocator,
        identifier: identifier,
        keyOut: &key
    )
    guard status == 0, let key else {
        keyOut.pointee = nil
        return status
    }
    let text = unsafeBitCast(key, to: NSString.self) as String
    keyOut.pointee = text.withCString { pointer in
        CFDataCreate(kCFAllocatorDefault, UnsafePointer<UInt8>(OpaquePointer(pointer)), CFIndex(text.utf8.count))
    }
    return 0
}

public func CMMetadataCreateKeySpaceFromIdentifier(
    allocator: CFAllocator?,
    identifier: CFString,
    keySpaceOut: UnsafeMutablePointer<CFString?>
) -> OSStatus {
    _ = allocator
    let text = unsafeBitCast(identifier, to: NSString.self) as String
    guard let slash = cmFirstIndex(of: "/", in: text) else {
        keySpaceOut.pointee = nil
        return kCMMetadataIdentifierError_BadIdentifier
    }
    let space = String(text[..<slash])
    if space.isEmpty {
        keySpaceOut.pointee = nil
        return kCMMetadataIdentifierError_BadKeySpace
    }
    keySpaceOut.pointee = cmMakeCFString(space)
    return 0
}

private final class CMMetadataTypeRecord {
    var description: CFString
    var conforming: [CFString]
    init(description: CFString, conforming: [CFString]) {
        self.description = description
        self.conforming = conforming
    }
}

private let cmMetadataRegistryLock = CMUnfairLock()
private var cmMetadataRegistry: [String: CMMetadataTypeRecord] = [:]

private func cmMetadataKey(_ type: CFString) -> String {
    unsafeBitCast(type, to: NSString.self) as String
}

public func CMMetadataDataTypeRegistryRegisterDataType(
    _ dataType: CFString,
    description: CFString,
    conformingDataTypes: CFArray
) -> OSStatus {
    let name = cmMetadataKey(dataType)
    if name.isEmpty { return kCMMetadataDataTypeRegistryError_BadDataTypeIdentifier }
    return cmMetadataRegistryLock.locked {
        if cmMetadataRegistry[name] != nil {
            return kCMMetadataDataTypeRegistryError_DataTypeAlreadyRegistered
        }
        let count = Int(CFArrayGetCount(conformingDataTypes))
        var conforming: [CFString] = []
        for index in 0..<count {
            let value = CFArrayGetValueAtIndex(conformingDataTypes, CFIndex(index))
            conforming.append(unsafeBitCast(value, to: CFString.self))
        }
        cmMetadataRegistry[name] = CMMetadataTypeRecord(
            description: description,
            conforming: conforming
        )
        return 0
    }
}

public func CMMetadataDataTypeRegistryDataTypeIsRegistered(_ dataType: CFString) -> Bool {
    cmMetadataRegistryLock.locked { cmMetadataRegistry[cmMetadataKey(dataType)] != nil }
}

public func CMMetadataDataTypeRegistryGetDataTypeDescription(_ dataType: CFString) -> CFString {
    cmMetadataRegistryLock.locked {
        cmMetadataRegistry[cmMetadataKey(dataType)]?.description ?? dataType
    }
}

public func CMMetadataDataTypeRegistryGetConformingDataTypes(_ dataType: CFString) -> CFArray {
    let types = cmMetadataRegistryLock.locked { cmMetadataRegistry[cmMetadataKey(dataType)]?.conforming ?? [] }
    let mutable = CFArrayCreateMutable(kCFAllocatorDefault, CFIndex(types.count), nil)
    if mutable == nil {
        return CFArrayCreate(kCFAllocatorDefault, nil, 0, nil)!
    }
    for item in types {
        CFArrayAppendValue(mutable, unsafeBitCast(item, to: UnsafeRawPointer.self))
    }
    return mutable!
}

public func CMMetadataDataTypeRegistryDataTypeConformsToDataType(
    _ dataType: CFString,
    conformsTo conformsToDataType: CFString
) -> Bool {
    let name = cmMetadataKey(dataType)
    let target = cmMetadataKey(conformsToDataType)
    if name == target { return true }
    return cmMetadataRegistryLock.locked {
        guard let record = cmMetadataRegistry[name] else { return false }
        return record.conforming.contains { cmMetadataKey($0) == target }
    }
}

public func CMMetadataDataTypeRegistryGetBaseDataTypes() -> CFArray? {
    nil
}

public func CMMetadataDataTypeRegistryDataTypeIsBaseDataType(_ dataType: CFString) -> Bool {
    _ = dataType
    return false
}

public func CMMetadataDataTypeRegistryGetBaseDataTypeForConformingDataType(
    _ dataType: CFString
) -> CFString {
    dataType
}

public func CMMetadataFormatDescriptionCreateWithKeys(
    allocator: CFAllocator?,
    metadataType: CMMetadataFormatType,
    keys: CFArray?,
    formatDescriptionOut: UnsafeMutablePointer<CMMetadataFormatDescription?>
) -> OSStatus {
    _ = allocator
    do {
        let desc = try CMFormatDescription(
            metadataFormatType: CMFormatDescription.MediaSubType(rawValue: metadataType)
        )
        if let keys {
            desc.metadataIdentifiers = cmMetadataIdentifiers(from: keys)
        }
        formatDescriptionOut.pointee = desc
        return 0
    } catch {
        formatDescriptionOut.pointee = nil
        return kCMFormatDescriptionError_InvalidParameter
    }
}

public func CMMetadataFormatDescriptionGetIdentifiers(
    _ desc: CMMetadataFormatDescription
) -> CFArray? {
    if desc.metadataIdentifiers.isEmpty { return nil }
    let mutable = CFArrayCreateMutable(
        kCFAllocatorDefault,
        CFIndex(desc.metadataIdentifiers.count),
        nil
    )!
    for identifier in desc.metadataIdentifiers {
        CFArrayAppendValue(mutable, unsafeBitCast(identifier, to: UnsafeRawPointer.self))
    }
    return mutable
}

private func cmMetadataIdentifiers(from keys: CFArray) -> [CFString] {
    var identifiers: [CFString] = []
    let count = CFArrayGetCount(keys)
    var index: CFIndex = 0
    while index < count {
        defer { index += 1 }
        guard let raw = CFArrayGetValueAtIndex(keys, index) else { continue }
        let object = unsafeBitCast(raw, to: CFTypeRef.self)
        if CFGetTypeID(object) == CFStringGetTypeID() {
            identifiers.append(unsafeBitCast(object, to: CFString.self))
        } else if CFGetTypeID(object) == CFDictionaryGetTypeID() {
            let dict = unsafeBitCast(object, to: CFDictionary.self)
            if let ident = cmCFDictionaryValue(
                dict,
                key: kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier
            ) {
                identifiers.append(unsafeBitCast(ident, to: CFString.self))
            }
        }
    }
    return identifiers
}

private func cmFirstIndex(of needle: Character, in text: String) -> String.Index? {
    var index = text.startIndex
    while index < text.endIndex {
        if text[index] == needle { return index }
        index = text.index(after: index)
    }
    return nil
}
