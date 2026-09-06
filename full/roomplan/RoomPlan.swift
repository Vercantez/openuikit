import Foundation

// Linux starting point for Apple's RoomPlan. LiDAR room scanning, ARKit
// world tracking, RoomCaptureView rendering, and USD export are fail-closed:
// Linux has no RoomPlan daemon, LiDAR scanner, or Apple USD pipeline.
// Value types, attribute enums, option sets, URL validation, model-provider
// bookkeeping, and the capture-session state machine are implemented here.

// MARK: - SIMD aliases (Darwin `simd` is not a declared dependency)

public typealias simd_float2 = SIMD2<Float>
public typealias simd_float3 = SIMD3<Float>

/// Column-major 4x4 transform matching Darwin `simd_float4x4`.
public struct simd_float4x4: Equatable, Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)

    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }

    public static func == (lhs: simd_float4x4, rhs: simd_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0
            && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2
            && lhs.columns.3 == rhs.columns.3
    }

    public static let identity = simd_float4x4(
        columns: (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    )

    public var scalars: [Float] {
        [
            columns.0.x, columns.0.y, columns.0.z, columns.0.w,
            columns.1.x, columns.1.y, columns.1.z, columns.1.w,
            columns.2.x, columns.2.y, columns.2.z, columns.2.w,
            columns.3.x, columns.3.y, columns.3.z, columns.3.w,
        ]
    }

    public init(scalars: [Float]) {
        let values = scalars.count == 16 ? scalars : Array(repeating: Float(0), count: 16)
        self.columns = (
            SIMD4<Float>(values[0], values[1], values[2], values[3]),
            SIMD4<Float>(values[4], values[5], values[6], values[7]),
            SIMD4<Float>(values[8], values[9], values[10], values[11]),
            SIMD4<Float>(values[12], values[13], values[14], values[15])
        )
    }
}

// MARK: - Host stand-ins for undeclared UIKit / ARKit / CoreGraphics types

/// ARKit is not a declared dependency. Session and view APIs accept `NSObject`.
public typealias ARSession = NSObject

/// UIKit is not a declared dependency. `RoomCaptureView.subviews` is empty.
public typealias UIView = NSObject

/// UIKit is not a declared dependency. Trait callbacks are no-ops on Linux.
public typealias UITraitCollection = NSObject

func roomPlanEncodeVector3(_ value: simd_float3, to encoder: Encoder, key: String) throws {
    var container = encoder.container(keyedBy: RoomPlanStringKey.self)
    try container.encode([value.x, value.y, value.z], forKey: RoomPlanStringKey(key))
}

func roomPlanDecodeVector3(from decoder: Decoder, key: String) throws -> simd_float3 {
    let container = try decoder.container(keyedBy: RoomPlanStringKey.self)
    let values = try container.decode([Float].self, forKey: RoomPlanStringKey(key))
    guard values.count == 3 else {
        throw DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "simd_float3")
        )
    }
    return simd_float3(values[0], values[1], values[2])
}

struct RoomPlanStringKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init(_ string: String) {
        self.stringValue = string
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}
