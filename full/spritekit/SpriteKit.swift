import Foundation
#if canImport(Glibc)
import Glibc
#else
import Darwin
#endif
#if canImport(Dispatch)
import Dispatch
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(QuartzCore)
import QuartzCore
#endif
// MARK: - Version / availability macros
// Apple packed `SK_VERSION` is unobserved in the pinned corpus; Linux reports 0.
public let SK_VERSION: Int32 = 0
public let SKVIEW_AVAILABLE: Int32 = 1
public let PHYSICSKIT_MINUS_GL_IMPORTS: Int32 = 1

public typealias SKActionTimingFunction = (Float) -> Float

public typealias vector_float2 = SIMD2<Float>
public typealias vector_float3 = SIMD3<Float>
public typealias vector_float4 = SIMD4<Float>

public struct matrix_float2x2: Equatable, Sendable {
    public var columns: (SIMD2<Float>, SIMD2<Float>)
    public init() { columns = (SIMD2<Float>(1, 0), SIMD2<Float>(0, 1)) }
    public init(columns: (SIMD2<Float>, SIMD2<Float>)) { self.columns = columns }
    public static func == (lhs: matrix_float2x2, rhs: matrix_float2x2) -> Bool {
        lhs.columns.0 == rhs.columns.0 && lhs.columns.1 == rhs.columns.1
    }
}

public struct matrix_float3x3: Equatable, Sendable {
    public var columns: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)
    public init() {
        columns = (SIMD3<Float>(1, 0, 0), SIMD3<Float>(0, 1, 0), SIMD3<Float>(0, 0, 1))
    }
    public init(columns: (SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)) { self.columns = columns }
    public static func == (lhs: matrix_float3x3, rhs: matrix_float3x3) -> Bool {
        lhs.columns.0 == rhs.columns.0 && lhs.columns.1 == rhs.columns.1 && lhs.columns.2 == rhs.columns.2
    }
}

public struct matrix_float4x4: Equatable, Sendable {
    public var columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)
    public init() {
        columns = (
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
    }
    public init(columns: (SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>)) {
        self.columns = columns
    }
    public static func == (lhs: matrix_float4x4, rhs: matrix_float4x4) -> Bool {
        lhs.columns.0 == rhs.columns.0 && lhs.columns.1 == rhs.columns.1
            && lhs.columns.2 == rhs.columns.2 && lhs.columns.3 == rhs.columns.3
    }
}

public struct simd_quatf: Equatable, Sendable {
    public var vector: SIMD4<Float>
    public init(ix: Float, iy: Float, iz: Float, r: Float) {
        vector = SIMD4<Float>(ix, iy, iz, r)
    }
    public init() { vector = SIMD4<Float>(0, 0, 0, 1) }
}

public typealias SKFieldForceEvaluator = (
    vector_float3, vector_float3, Float, Float, TimeInterval
) -> vector_float3

// MARK: - Enums (macios SpriteKit/Enums.cs explicit raw values)

public enum SKActionTimingMode: Int, Sendable, Hashable {
    case linear = 0
    case easeIn = 1
    case easeOut = 2
    case easeInEaseOut = 3
}

public enum SKAttributeType: Int, Sendable, Hashable {
    case none = 0
    case float = 1
    case vectorFloat2 = 2
    case vectorFloat3 = 3
    case vectorFloat4 = 4
    case halfFloat = 5
    case vectorHalfFloat2 = 6
    case vectorHalfFloat3 = 7
    case vectorHalfFloat4 = 8
}

public enum SKBlendMode: Int, Sendable, Hashable {
    case alpha = 0
    case add = 1
    case subtract = 2
    case multiply = 3
    case multiplyX2 = 4
    case screen = 5
    case replace = 6
    case multiplyAlpha = 7
}

public enum SKInterpolationMode: Int, Sendable, Hashable {
    case linear = 1
    case spline = 2
    case step = 3
}

public enum SKLabelHorizontalAlignmentMode: Int, Sendable, Hashable {
    case center = 0
    case left = 1
    case right = 2
}

public enum SKLabelVerticalAlignmentMode: Int, Sendable, Hashable {
    case baseline = 0
    case center = 1
    case top = 2
    case bottom = 3
}

public enum SKNodeFocusBehavior: Int, Sendable, Hashable {
    case none = 0
    case occluding = 1
    case focusable = 2
}

public enum SKParticleRenderOrder: UInt, Sendable, Hashable {
    case oldestLast = 0
    case oldestFirst = 1
    case dontCare = 2
}

public enum SKRepeatMode: Int, Sendable, Hashable {
    case clamp = 1
    case loop = 2
}

public enum SKSceneScaleMode: Int, Sendable, Hashable {
    case fill = 0
    case aspectFill = 1
    case aspectFit = 2
    case resizeFill = 3
}

public enum SKTextureFilteringMode: Int, Sendable, Hashable {
    case nearest = 0
    case linear = 1
}

public enum SKTileDefinitionRotation: UInt, Sendable, Hashable {
    case rotation0 = 0
    case rotation90 = 1
    case rotation180 = 2
    case rotation270 = 3
}

public enum SKTileSetType: UInt, Sendable, Hashable {
    case grid = 0
    case isometric = 1
    case hexagonalFlat = 2
    case hexagonalPointy = 3
}

public enum SKTransitionDirection: Int, Sendable, Hashable {
    case up = 0
    case down = 1
    case right = 2
    case left = 3
}

public enum SKUniformType: Int, Sendable, Hashable {
    case none = 0
    case float = 1
    case floatVector2 = 2
    case floatVector3 = 3
    case floatVector4 = 4
    case floatMatrix2 = 5
    case floatMatrix3 = 6
    case floatMatrix4 = 7
    case texture = 8
}

public struct SKTileAdjacencyMask: OptionSet, Hashable, Sendable {
    public var rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let adjacencyUp = SKTileAdjacencyMask(rawValue: 1 << 0)
    public static let adjacencyUpperRight = SKTileAdjacencyMask(rawValue: 1 << 1)
    public static let adjacencyRight = SKTileAdjacencyMask(rawValue: 1 << 2)
    public static let adjacencyLowerRight = SKTileAdjacencyMask(rawValue: 1 << 3)
    public static let adjacencyDown = SKTileAdjacencyMask(rawValue: 1 << 4)
    public static let adjacencyLowerLeft = SKTileAdjacencyMask(rawValue: 1 << 5)
    public static let adjacencyLeft = SKTileAdjacencyMask(rawValue: 1 << 6)
    public static let adjacencyUpperLeft = SKTileAdjacencyMask(rawValue: 1 << 7)
    public static let adjacencyAll: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpperRight, .adjacencyRight, .adjacencyLowerRight,
        .adjacencyDown, .adjacencyLowerLeft, .adjacencyLeft, .adjacencyUpperLeft,
    ]

    public static let hexFlatAdjacencyUp = SKTileAdjacencyMask(rawValue: 1 << 0)
    public static let hexFlatAdjacencyUpperRight = SKTileAdjacencyMask(rawValue: 1 << 1)
    public static let hexFlatAdjacencyLowerRight = SKTileAdjacencyMask(rawValue: 1 << 2)
    public static let hexFlatAdjacencyDown = SKTileAdjacencyMask(rawValue: 1 << 3)
    public static let hexFlatAdjacencyLowerLeft = SKTileAdjacencyMask(rawValue: 1 << 4)
    public static let hexFlatAdjacencyUpperLeft = SKTileAdjacencyMask(rawValue: 1 << 5)
    public static let hexFlatAdjacencyAll: SKTileAdjacencyMask = [
        .hexFlatAdjacencyUp, .hexFlatAdjacencyUpperRight, .hexFlatAdjacencyLowerRight,
        .hexFlatAdjacencyDown, .hexFlatAdjacencyLowerLeft, .hexFlatAdjacencyUpperLeft,
    ]

    public static let hexPointyAdjacencyUpperLeft = SKTileAdjacencyMask(rawValue: 1 << 0)
    public static let hexPointyAdjacencyUpperRight = SKTileAdjacencyMask(rawValue: 1 << 1)
    public static let hexPointyAdjacencyRight = SKTileAdjacencyMask(rawValue: 1 << 2)
    public static let hexPointyAdjacencyLowerRight = SKTileAdjacencyMask(rawValue: 1 << 3)
    public static let hexPointyAdjacencyLowerLeft = SKTileAdjacencyMask(rawValue: 1 << 4)
    public static let hexPointyAdjacencyLeft = SKTileAdjacencyMask(rawValue: 1 << 5)
    /// Overlay name for the pointy-hex all-neighbors mask (`HexPointyAll`).
    public static let hexPointyAdjacencyAdd: SKTileAdjacencyMask = [
        .hexPointyAdjacencyUpperLeft, .hexPointyAdjacencyUpperRight, .hexPointyAdjacencyRight,
        .hexPointyAdjacencyLowerRight, .hexPointyAdjacencyLowerLeft, .hexPointyAdjacencyLeft,
    ]

    public static let adjacencyUpEdge: SKTileAdjacencyMask = [
        .adjacencyRight, .adjacencyLowerRight, .adjacencyDown, .adjacencyLowerLeft, .adjacencyLeft,
    ]
    public static let adjacencyUpperRightEdge: SKTileAdjacencyMask = [
        .adjacencyDown, .adjacencyLowerLeft, .adjacencyLeft,
    ]
    public static let adjacencyRightEdge: SKTileAdjacencyMask = [
        .adjacencyDown, .adjacencyLowerLeft, .adjacencyLeft, .adjacencyUpperLeft, .adjacencyUp,
    ]
    public static let adjacencyLowerRightEdge: SKTileAdjacencyMask = [
        .adjacencyLeft, .adjacencyUpperLeft, .adjacencyUp,
    ]
    public static let adjacencyDownEdge: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpperRight, .adjacencyRight, .adjacencyLeft, .adjacencyUpperLeft,
    ]
    public static let adjacencyLowerLeftEdge: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpperRight, .adjacencyRight,
    ]
    public static let adjacencyLeftEdge: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpperRight, .adjacencyRight, .adjacencyLowerRight, .adjacencyDown,
    ]
    public static let adjacencyUpperLeftEdge: SKTileAdjacencyMask = [
        .adjacencyRight, .adjacencyLowerRight, .adjacencyDown,
    ]
    public static let adjacencyUpperRightCorner: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpperRight, .adjacencyRight, .adjacencyLowerRight,
        .adjacencyDown, .adjacencyLeft, .adjacencyUpperLeft,
    ]
    public static let adjacencyLowerRightCorner: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpperRight, .adjacencyRight, .adjacencyLowerRight,
        .adjacencyDown, .adjacencyLowerLeft, .adjacencyLeft,
    ]
    public static let adjacencyLowerLeftCorner: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyRight, .adjacencyLowerRight, .adjacencyDown,
        .adjacencyLowerLeft, .adjacencyLeft, .adjacencyUpperLeft,
    ]
    public static let adjacencyUpperLeftCorner: SKTileAdjacencyMask = [
        .adjacencyUp, .adjacencyUpperRight, .adjacencyRight, .adjacencyDown,
        .adjacencyLowerLeft, .adjacencyLeft, .adjacencyUpperLeft,
    ]
}

func sk_clamp<T: Comparable>(_ value: T, _ lo: T, _ hi: T) -> T {
    min(max(value, lo), hi)
}

func sk_timing(_ mode: SKActionTimingMode, _ t: CGFloat) -> CGFloat {
    let x = sk_clamp(t, 0, 1)
    switch mode {
    case .linear:
        return x
    case .easeIn:
        return x * x
    case .easeOut:
        let u = 1 - x
        return 1 - u * u
    case .easeInEaseOut:
        return x * x * (3 - 2 * x)
    }
}

func sk_hypot(_ x: CGFloat, _ y: CGFloat) -> CGFloat {
    CGFloat(sqrt(Double(x * x + y * y)))
}

func sk_lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

func sk_glob(_ pattern: String, _ value: String) -> Bool {
    if pattern == "*" { return true }
    if pattern == value { return true }
    func match(_ p: ArraySlice<Character>, _ v: ArraySlice<Character>) -> Bool {
        if p.isEmpty { return v.isEmpty }
        if p.first == "*" {
            let rest = p.dropFirst()
            if rest.isEmpty { return true }
            var index = v.startIndex
            while true {
                if match(rest, v[index...]) { return true }
                if index == v.endIndex { return false }
                index = v.index(after: index)
            }
        }
        guard let head = v.first, p.first == head else { return false }
        return match(p.dropFirst(), v.dropFirst())
    }
    return match(ArraySlice(pattern), ArraySlice(value))
}

func sk_pngSize(_ data: Data) -> CGSize? {
    guard data.count >= 24 else { return nil }
    let signature: [UInt8] = [137, 80, 78, 71, 13, 10, 26, 10]
    if Array(data.prefix(8)) != signature { return nil }
    let bytes = [UInt8](data)
    func u32(_ offset: Int) -> UInt32 {
        (UInt32(bytes[offset]) << 24)
            | (UInt32(bytes[offset + 1]) << 16)
            | (UInt32(bytes[offset + 2]) << 8)
            | UInt32(bytes[offset + 3])
    }
    let width = u32(16)
    let height = u32(20)
    guard width > 0, height > 0, width < 16_384, height < 16_384 else { return nil }
    return CGSize(width: CGFloat(width), height: CGFloat(height))
}

func sk_polyline(_ path: CGPath) -> [CGPoint] {
#if canImport(CoreGraphics)
    _ = path
    return [.zero]
#else
    var points: [CGPoint] = []
    for command in path.commands {
        switch command {
        case .move(let point), .line(let point):
            points.append(point)
        case .close:
            if let first = points.first {
                points.append(first)
            }
        }
    }
    return points
#endif
}

func sk_pointAlong(_ points: [CGPoint], t: CGFloat) -> CGPoint {
    guard let first = points.first else { return .zero }
    if points.count == 1 { return first }
    var lengths: [CGFloat] = [0]
    var total: CGFloat = 0
    for index in 1..<points.count {
        let delta = sk_hypot(points[index].x - points[index - 1].x, points[index].y - points[index - 1].y)
        total += delta
        lengths.append(total)
    }
    if total <= 0 { return first }
    let target = sk_clamp(t, 0, 1) * total
    for index in 1..<points.count {
        if lengths[index] >= target {
            let span = lengths[index] - lengths[index - 1]
            let local = span <= 0 ? 1 : (target - lengths[index - 1]) / span
            return CGPoint(
                x: sk_lerp(points[index - 1].x, points[index].x, local),
                y: sk_lerp(points[index - 1].y, points[index].y, local)
            )
        }
    }
    return points.last ?? first
}

func sk_rectCorners(_ rect: CGRect) -> [CGPoint] {
    [
        CGPoint(x: rect.minX, y: rect.minY),
        CGPoint(x: rect.maxX, y: rect.minY),
        CGPoint(x: rect.minX, y: rect.maxY),
        CGPoint(x: rect.maxX, y: rect.maxY),
    ]
}

func sk_colorBytes(_ color: SKColor) -> (UInt8, UInt8, UInt8, UInt8) {
#if canImport(UIKit)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 1
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return (
        UInt8(sk_clamp(red, 0, 1) * 255),
        UInt8(sk_clamp(green, 0, 1) * 255),
        UInt8(sk_clamp(blue, 0, 1) * 255),
        UInt8(sk_clamp(alpha, 0, 1) * 255)
    )
#else
    return (
        UInt8(sk_clamp(color.red, 0, 1) * 255),
        UInt8(sk_clamp(color.green, 0, 1) * 255),
        UInt8(sk_clamp(color.blue, 0, 1) * 255),
        UInt8(sk_clamp(color.alpha, 0, 1) * 255)
    )
#endif
}

public enum SKViewport {
    public struct Mapping {
        public var scaleX: CGFloat
        public var scaleY: CGFloat
        public var offsetX: CGFloat
        public var offsetY: CGFloat
    }

    public static func mapping(sceneSize: CGSize, viewSize: CGSize, mode: SKSceneScaleMode) -> Mapping {
        let viewWidth = max(viewSize.width, 0.0001)
        let viewHeight = max(viewSize.height, 0.0001)
        let sceneWidth = max(sceneSize.width, 0.0001)
        let sceneHeight = max(sceneSize.height, 0.0001)
        switch mode {
        case .fill:
            return Mapping(scaleX: viewWidth / sceneWidth, scaleY: viewHeight / sceneHeight, offsetX: 0, offsetY: 0)
        case .aspectFill:
            let scale = max(viewWidth / sceneWidth, viewHeight / sceneHeight)
            return Mapping(
                scaleX: scale,
                scaleY: scale,
                offsetX: (viewWidth - sceneWidth * scale) / 2,
                offsetY: (viewHeight - sceneHeight * scale) / 2
            )
        case .aspectFit:
            let scale = min(viewWidth / sceneWidth, viewHeight / sceneHeight)
            return Mapping(
                scaleX: scale,
                scaleY: scale,
                offsetX: (viewWidth - sceneWidth * scale) / 2,
                offsetY: (viewHeight - sceneHeight * scale) / 2
            )
        case .resizeFill:
            return Mapping(scaleX: 1, scaleY: 1, offsetX: 0, offsetY: 0)
        }
    }
}
