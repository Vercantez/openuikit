import CFNetwork
import CoreFoundation
import Foundation
#if canImport(Glibc)
import Glibc
#endif

final class CallbackCounter {
    var value = 0
}

func cfDataFromUTF8(_ value: String) -> CFData {
    Array(value.utf8).withUnsafeBufferPointer { buffer in
        CFDataCreate(nil, buffer.baseAddress, CFIndex(buffer.count))!
    }
}

func cfDataBytes(_ data: CFData) -> [UInt8] {
    let length = Int(CFDataGetLength(data))
    guard length > 0, let pointer = CFDataGetBytePtr(data) else { return [] }
    return Array(UnsafeBufferPointer(start: pointer, count: length))
}

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("CFNetworkRuntime: \(message)")
    }
}

func swiftString(_ value: CFString) -> String {
    let length = Int(CFStringGetLength(value))
    var buffer = [CChar](repeating: 0, count: max(16, length * 4 + 1))
    require(
        CFStringGetCString(
            value,
            &buffer,
            CFIndex(buffer.count),
            CFStringBuiltInEncodings.UTF8.rawValue
        ),
        "CFString conversion"
    )
    return String(cString: buffer)
}

func cfString(_ value: String) -> CFString {
    value.withCString { CFStringCreateWithCString(nil, $0, CFStringBuiltInEncodings.UTF8.rawValue)! }
}

func testCFFTPCreateParsedResourceListing() {

    let listing = "-rw-r--r-- 1 user group 1234 Jan 01 12:00 README.txt\r\n"
    var parsed: Unmanaged<CFDictionary>?
    let consumed = listing.withCString { pointer in
        CFFTPCreateParsedResourceListing(
            nil,
            UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
            CFIndex(listing.utf8.count),
            &parsed
        )
    }
    require(consumed == CFIndex(listing.utf8.count), "FTP listing consumed")
    let dictionary = parsed!.takeRetainedValue()
    let namePointer = CFDictionaryGetValue(
        dictionary,
        Unmanaged.passUnretained(kCFFTPResourceName).toOpaque()
    )!
    let name = Unmanaged<CFString>.fromOpaque(namePointer).takeUnretainedValue()
    require(swiftString(name) == "README.txt", "FTP name")
    let datePointer = CFDictionaryGetValue(
        dictionary,
        Unmanaged.passUnretained(kCFFTPResourceModDate).toOpaque()
    )!
    let date = Unmanaged<CFString>.fromOpaque(datePointer).takeUnretainedValue()
    require(swiftString(date) == "Jan 01 12:00", "FTP mod date")
    let linkListing = "lrwxrwxrwx 1 user group 4 Jan 01 12:00 link -> dest\r\n"
    var linkParsed: Unmanaged<CFDictionary>?
    _ = linkListing.withCString { pointer in
        CFFTPCreateParsedResourceListing(
            nil,
            UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
            CFIndex(linkListing.utf8.count),
            &linkParsed
        )
    }
    let linkDictionary = linkParsed!.takeRetainedValue()
    let linkPointer = CFDictionaryGetValue(
        linkDictionary,
        Unmanaged.passUnretained(kCFFTPResourceLink).toOpaque()
    )!
    let link = Unmanaged<CFString>.fromOpaque(linkPointer).takeUnretainedValue()
    require(swiftString(link) == "dest", "FTP link")
}
