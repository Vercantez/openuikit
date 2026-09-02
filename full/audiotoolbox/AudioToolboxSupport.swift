#if canImport(CoreFoundation)
import CoreFoundation
#endif
import Foundation

/// Isolated overlay return type for C `OSStatus`. Darwin/CoreAudioTypes own
/// the `OSStatus` name; this module must not redeclare it.
internal typealias ATStatus = Int32

internal let atParamError: ATStatus = -50
internal let atUnimplementedError: ATStatus = -4

internal func atFourCC(_ a: UInt8, _ b: UInt8, _ c: UInt8, _ d: UInt8) -> UInt32 {
    (UInt32(a) << 24) | (UInt32(b) << 16) | (UInt32(c) << 8) | UInt32(d)
}

internal func atFourCC(_ s: StaticString) -> UInt32 {
    precondition(s.utf8CodeUnitCount == 4, "FourCC must be exactly 4 bytes")
    return s.withUTF8Buffer { buffer in
        atFourCC(buffer[0], buffer[1], buffer[2], buffer[3])
    }
}

internal func atSignedFourCC(_ s: StaticString) -> ATStatus {
    Int32(bitPattern: atFourCC(s))
}

internal class ATObject {
    fileprivate(set) var disposed = false
}

internal final class ATRegistry {
    static let shared = ATRegistry()

    private let lock = NSLock()
    private var live: Set<UInt> = []

    private init() {}

    func retain(_ object: ATObject) -> OpaquePointer {
        let raw = Unmanaged.passRetained(object).toOpaque()
        lock.lock()
        live.insert(UInt(bitPattern: raw))
        lock.unlock()
        return OpaquePointer(raw)
    }

    func lookup(_ pointer: OpaquePointer?) -> ATObject? {
        guard let pointer else { return nil }
        let raw = UnsafeRawPointer(pointer)
        let key = UInt(bitPattern: raw)
        lock.lock()
        let present = live.contains(key)
        lock.unlock()
        guard present else { return nil }
        return Unmanaged<ATObject>.fromOpaque(raw).takeUnretainedValue()
    }

    func lookup<T: ATObject>(_ pointer: OpaquePointer?, as type: T.Type) -> T? {
        lookup(pointer) as? T
    }

    /// Safe against double-dispose and unknown pointers. Does not crash.
    func release(_ pointer: OpaquePointer?) -> ATStatus {
        guard let pointer else { return atParamError }
        let raw = UnsafeRawPointer(pointer)
        let key = UInt(bitPattern: raw)
        lock.lock()
        guard live.contains(key) else {
            lock.unlock()
            return atParamError
        }
        live.remove(key)
        lock.unlock()
        let object = Unmanaged<ATObject>.fromOpaque(raw).takeUnretainedValue()
        object.disposed = true
        Unmanaged<ATObject>.fromOpaque(raw).release()
        return 0
    }
}

@discardableResult
internal func atWithLock<T>(_ lock: NSLock, _ body: () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return body()
}

#if canImport(CoreFoundation)
internal func atCFURLIsLikelyMalformed(_ url: CFURL) -> Bool {
    let pathMax = 4096
    var buffer = [UInt8](repeating: 0, count: pathMax)
    let ok = buffer.withUnsafeMutableBufferPointer { ptr in
        CFURLGetFileSystemRepresentation(url, true, ptr.baseAddress, pathMax)
    }
    if !ok {
        return true
    }
    if buffer[0] == 0 {
        return true
    }
    return false
}
#endif
