import Foundation
import Dispatch

/// Linux starting point for Apple's public `MetalPerformanceShadersGraph` overlay.
/// Graph construction, host tensor buffers, descriptors, and documented enum
/// raw values are real. GPU compile/encode and Metal/MPS interop stay fail-closed.
public enum MetalPerformanceShadersGraphModule {
    public static let name = "MetalPerformanceShadersGraph"
}

/// C dispatch queue name used by the Apple overlay. Linux maps it to Dispatch.
public typealias dispatch_queue_t = DispatchQueue

/// Bridging `MPSDataType` until `MetalPerformanceShaders` is imported by the
/// guest integration. Encoding matches the documented MPS bit-field
/// (`floatBit`, `signedBit`, size in the low bits). Replace with the
/// dependency-owned type at integration; do not treat this as a second ABI.
public enum MPSDataType: UInt32, Sendable, Hashable {
    case invalid = 0
    case uInt8 = 8
    case uInt16 = 16
    case uInt32 = 32
    case uInt64 = 64
    case floatBit = 0x1000_0000
    case float16 = 0x1000_0010
    case float32 = 0x1000_0020
    case signedBit = 0x2000_0000
    case int8 = 0x2000_0008
    case int16 = 0x2000_0010
    case int32 = 0x2000_0020
    case int64 = 0x2000_0040
    case normalizedBit = 0x4000_0000
    case unorm8 = 0x4000_0008
    case alternateEncodingBit = 0x8000_0000
    case bFloat16 = 0x8000_0010
    case complexBit = 0x0100_0000
    case complexFloat16 = 0x1100_0010
    case complexFloat32 = 0x1100_0020
    case bool = 0x0800_0000

    public var byteSize: Int {
        let low = Int(rawValue & 0xFF)
        if self == .bool { return 1 }
        if low == 0 { return 0 }
        return max(low / 8, 1)
    }
}

/// Fail-closed host boundary. GPU/Metal/package APIs record the refused
/// selector here instead of inventing Apple-device success.
public enum MPSGraphHostBoundary {
    public private(set) static var lastRefusedAPI: String?
    public private(set) static var lastReason: String?

    public static func reset() {
        lastRefusedAPI = nil
        lastReason = nil
    }

    public static func refuse(_ api: String, reason: String) {
        lastRefusedAPI = api
        lastReason = reason
    }
}

public func MPSGraphSizeOfDataType(_ dataType: MPSDataType) -> Int {
    dataType.byteSize
}
