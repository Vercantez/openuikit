import Foundation

public protocol ARAnchorCopying: NSCopying {
    init(anchor: ARAnchor)
}

public protocol ARTrackable: AnyObject {
    var isTracked: Bool { get }
}

open class ARAnchor: NSObject, ARAnchorCopying, NSSecureCoding {
    public private(set) var identifier: UUID
    public private(set) var name: String?
    public private(set) var sessionIdentifier: UUID?
    public private(set) var transform: simd_float4x4

    public static var supportsSecureCoding: Bool { true }

    public init(transform: simd_float4x4) {
        self.identifier = UUID()
        self.name = nil
        self.sessionIdentifier = nil
        self.transform = transform
        super.init()
    }

    public init(name: String, transform: simd_float4x4) {
        self.identifier = UUID()
        self.name = name
        self.sessionIdentifier = nil
        self.transform = transform
        super.init()
    }

    public required init(anchor: ARAnchor) {
        self.identifier = anchor.identifier
        self.name = anchor.name
        self.sessionIdentifier = anchor.sessionIdentifier
        self.transform = anchor.transform
        super.init()
    }

    init(identifier: UUID, name: String?, sessionIdentifier: UUID?, transform: simd_float4x4) {
        self.identifier = identifier
        self.name = name
        self.sessionIdentifier = sessionIdentifier
        self.transform = transform
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return type(of: self).init(anchor: self)
    }

    func applySessionIdentifier(_ identifier: UUID) {
        sessionIdentifier = identifier
    }

    public func encode(with coder: NSCoder) {
        coder.encode(1, forKey: "version")
        coder.encode(identifier.uuidString, forKey: "identifier")
        coder.encode(name, forKey: "name")
        coder.encode(sessionIdentifier?.uuidString, forKey: "sessionIdentifier")
        coder.encode(arkitEncodeMatrix(transform).map { NSNumber(value: $0) }, forKey: "transform")
    }

    public required init?(coder: NSCoder) {
        guard let identifierString = coder.decodeObject(of: NSString.self, forKey: "identifier") as String?,
              let identifier = UUID(uuidString: identifierString),
              let numbers = coder.decodeObject(of: [NSArray.self, NSNumber.self], forKey: "transform") as? [NSNumber],
              let transform = arkitDecodeMatrix(numbers.map { $0.floatValue })
        else { return nil }
        self.identifier = identifier
        self.name = coder.decodeObject(of: NSString.self, forKey: "name") as String?
        if let sessionString = coder.decodeObject(of: NSString.self, forKey: "sessionIdentifier") as String? {
            self.sessionIdentifier = UUID(uuidString: sessionString)
        } else {
            self.sessionIdentifier = nil
        }
        self.transform = transform
        super.init()
    }
}

open class ARPlaneAnchor: ARAnchor, ARTrackable {
    public enum Alignment: Int, Hashable, Sendable {
        case horizontal = 0
        case vertical = 1
    }

    public enum Classification: Equatable, Sendable {
        case none(Status)
        case wall
        case floor
        case ceiling
        case table
        case seat
        case window
        case door

        public enum Status: Equatable, Hashable, Sendable {
            case notAvailable
            case undetermined
            case unknown
        }
    }

    public class var isClassificationSupported: Bool { false }

    public var alignment: Alignment { _alignment }
    public var center: simd_float3 { _center }
    public var extent: simd_float3 { _extent }
    public var geometry: ARPlaneGeometry { _geometry }
    public var planeExtent: ARPlaneExtent { _planeExtent }
    public var classification: Classification { _classification }
    public var isTracked: Bool { _isTracked }

    private let _alignment: Alignment
    private let _center: simd_float3
    private let _extent: simd_float3
    private let _geometry: ARPlaneGeometry
    private let _planeExtent: ARPlaneExtent
    private let _classification: Classification
    private let _isTracked: Bool

    public init(
        transform: simd_float4x4,
        alignment: Alignment,
        center: simd_float3,
        extent: simd_float3,
        classification: Classification,
        isTracked: Bool,
        identifier: UUID,
        sessionIdentifier: UUID?
    ) {
        self._alignment = alignment
        self._center = center
        self._extent = extent
        self._geometry = ARPlaneGeometry.rectangle(center: center, extent: extent)
        self._planeExtent = ARPlaneExtent(width: extent.x, height: extent.z, rotationOnYAxis: 0)
        self._classification = classification
        self._isTracked = isTracked
        super.init(identifier: identifier, name: nil, sessionIdentifier: sessionIdentifier, transform: transform)
    }

    public required init(anchor: ARAnchor) {
        if let plane = anchor as? ARPlaneAnchor {
            self._alignment = plane._alignment
            self._center = plane._center
            self._extent = plane._extent
            self._geometry = plane._geometry
            self._planeExtent = plane._planeExtent
            self._classification = plane._classification
            self._isTracked = plane._isTracked
        } else {
            self._alignment = .horizontal
            self._center = simd_float3(repeating: 0)
            self._extent = simd_float3(repeating: 0)
            self._geometry = ARPlaneGeometry()
            self._planeExtent = ARPlaneExtent()
            self._classification = .none(.notAvailable)
            self._isTracked = false
        }
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        self._alignment = .horizontal
        self._center = simd_float3(repeating: 0)
        self._extent = simd_float3(repeating: 0)
        self._geometry = ARPlaneGeometry()
        self._planeExtent = ARPlaneExtent()
        self._classification = .none(.notAvailable)
        self._isTracked = false
        super.init(coder: coder)
    }
}

open class ARPlaneExtent: NSObject, NSSecureCoding {
    public var width: Float { _width }
    public var height: Float { _height }
    public var rotationOnYAxis: Float { _rotationOnYAxis }

    private let _width: Float
    private let _height: Float
    private let _rotationOnYAxis: Float

    public static var supportsSecureCoding: Bool { true }

    init(width: Float = 0, height: Float = 0, rotationOnYAxis: Float = 0) {
        self._width = width
        self._height = height
        self._rotationOnYAxis = rotationOnYAxis
        super.init()
    }

    public required init?(coder: NSCoder) {
        self._width = coder.decodeFloat(forKey: "width")
        self._height = coder.decodeFloat(forKey: "height")
        self._rotationOnYAxis = coder.decodeFloat(forKey: "rotation")
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(width, forKey: "width")
        coder.encode(height, forKey: "height")
        coder.encode(rotationOnYAxis, forKey: "rotation")
    }
}

open class ARFaceAnchor: ARAnchor, ARTrackable {
    public struct BlendShapeLocation: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let browDownLeft = BlendShapeLocation(rawValue: "browDown_L")
        public static let browDownRight = BlendShapeLocation(rawValue: "browDown_R")
        public static let browInnerUp = BlendShapeLocation(rawValue: "browInnerUp")
        public static let browOuterUpLeft = BlendShapeLocation(rawValue: "browOuterUp_L")
        public static let browOuterUpRight = BlendShapeLocation(rawValue: "browOuterUp_R")
        public static let cheekPuff = BlendShapeLocation(rawValue: "cheekPuff")
        public static let cheekSquintLeft = BlendShapeLocation(rawValue: "cheekSquint_L")
        public static let cheekSquintRight = BlendShapeLocation(rawValue: "cheekSquint_R")
        public static let eyeBlinkLeft = BlendShapeLocation(rawValue: "eyeBlink_L")
        public static let eyeBlinkRight = BlendShapeLocation(rawValue: "eyeBlink_R")
        public static let eyeLookDownLeft = BlendShapeLocation(rawValue: "eyeLookDown_L")
        public static let eyeLookDownRight = BlendShapeLocation(rawValue: "eyeLookDown_R")
        public static let eyeLookInLeft = BlendShapeLocation(rawValue: "eyeLookIn_L")
        public static let eyeLookInRight = BlendShapeLocation(rawValue: "eyeLookIn_R")
        public static let eyeLookOutLeft = BlendShapeLocation(rawValue: "eyeLookOut_L")
        public static let eyeLookOutRight = BlendShapeLocation(rawValue: "eyeLookOut_R")
        public static let eyeLookUpLeft = BlendShapeLocation(rawValue: "eyeLookUp_L")
        public static let eyeLookUpRight = BlendShapeLocation(rawValue: "eyeLookUp_R")
        public static let eyeSquintLeft = BlendShapeLocation(rawValue: "eyeSquint_L")
        public static let eyeSquintRight = BlendShapeLocation(rawValue: "eyeSquint_R")
        public static let eyeWideLeft = BlendShapeLocation(rawValue: "eyeWide_L")
        public static let eyeWideRight = BlendShapeLocation(rawValue: "eyeWide_R")
        public static let jawForward = BlendShapeLocation(rawValue: "jawForward")
        public static let jawLeft = BlendShapeLocation(rawValue: "jawLeft")
        public static let jawOpen = BlendShapeLocation(rawValue: "jawOpen")
        public static let jawRight = BlendShapeLocation(rawValue: "jawRight")
        public static let mouthClose = BlendShapeLocation(rawValue: "mouthClose")
        public static let mouthDimpleLeft = BlendShapeLocation(rawValue: "mouthDimple_L")
        public static let mouthDimpleRight = BlendShapeLocation(rawValue: "mouthDimple_R")
        public static let mouthFrownLeft = BlendShapeLocation(rawValue: "mouthFrown_L")
        public static let mouthFrownRight = BlendShapeLocation(rawValue: "mouthFrown_R")
        public static let mouthFunnel = BlendShapeLocation(rawValue: "mouthFunnel")
        public static let mouthLeft = BlendShapeLocation(rawValue: "mouthLeft")
        public static let mouthLowerDownLeft = BlendShapeLocation(rawValue: "mouthLowerDown_L")
        public static let mouthLowerDownRight = BlendShapeLocation(rawValue: "mouthLowerDown_R")
        public static let mouthPressLeft = BlendShapeLocation(rawValue: "mouthPress_L")
        public static let mouthPressRight = BlendShapeLocation(rawValue: "mouthPress_R")
        public static let mouthPucker = BlendShapeLocation(rawValue: "mouthPucker")
        public static let mouthRight = BlendShapeLocation(rawValue: "mouthRight")
        public static let mouthRollLower = BlendShapeLocation(rawValue: "mouthRollLower")
        public static let mouthRollUpper = BlendShapeLocation(rawValue: "mouthRollUpper")
        public static let mouthShrugLower = BlendShapeLocation(rawValue: "mouthShrugLower")
        public static let mouthShrugUpper = BlendShapeLocation(rawValue: "mouthShrugUpper")
        public static let mouthSmileLeft = BlendShapeLocation(rawValue: "mouthSmile_L")
        public static let mouthSmileRight = BlendShapeLocation(rawValue: "mouthSmile_R")
        public static let mouthStretchLeft = BlendShapeLocation(rawValue: "mouthStretch_L")
        public static let mouthStretchRight = BlendShapeLocation(rawValue: "mouthStretch_R")
        public static let mouthUpperUpLeft = BlendShapeLocation(rawValue: "mouthUpperUp_L")
        public static let mouthUpperUpRight = BlendShapeLocation(rawValue: "mouthUpperUp_R")
        public static let noseSneerLeft = BlendShapeLocation(rawValue: "noseSneer_L")
        public static let noseSneerRight = BlendShapeLocation(rawValue: "noseSneer_R")
        public static let tongueOut = BlendShapeLocation(rawValue: "tongueOut")
    }

    public var blendShapes: [BlendShapeLocation: NSNumber] { [:] }
    public var geometry: ARFaceGeometry { _geometry }
    public var leftEyeTransform: simd_float4x4 { .identity }
    public var rightEyeTransform: simd_float4x4 { .identity }
    public var lookAtPoint: simd_float3 { simd_float3(repeating: 0) }
    public var isTracked: Bool { false }

    private let _geometry: ARFaceGeometry

    public required init(anchor: ARAnchor) {
        if let face = anchor as? ARFaceAnchor {
            self._geometry = face._geometry
        } else {
            self._geometry = ARFaceGeometry()
        }
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class ARImageAnchor: ARAnchor, ARTrackable {
    public var estimatedScaleFactor: CGFloat { 1 }
    public var referenceImage: ARReferenceImage { _referenceImage }
    public var isTracked: Bool { false }

    private let _referenceImage: ARReferenceImage

    public required init(anchor: ARAnchor) {
        if let image = anchor as? ARImageAnchor {
            self._referenceImage = image._referenceImage
        } else {
            self._referenceImage = ARReferenceImage(physicalSize: .zero)
        }
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class ARObjectAnchor: ARAnchor {
    public var referenceObject: ARReferenceObject { _referenceObject }
    private let _referenceObject: ARReferenceObject

    public required init(anchor: ARAnchor) {
        if let object = anchor as? ARObjectAnchor {
            self._referenceObject = object._referenceObject
        } else {
            self._referenceObject = ARReferenceObject()
        }
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class ARBodyAnchor: ARAnchor, ARTrackable {
    public var estimatedScaleFactor: CGFloat { 1 }
    public var skeleton: ARSkeleton3D { _skeleton }
    public var isTracked: Bool { false }

    private let _skeleton: ARSkeleton3D

    public required init(anchor: ARAnchor) {
        if let body = anchor as? ARBodyAnchor {
            self._skeleton = body._skeleton
        } else {
            self._skeleton = ARSkeleton3D()
        }
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class AREnvironmentProbeAnchor: ARAnchor {
    public var extent: simd_float3 { _extent }
    public var environmentTexture: (any MTLTexture)? { nil }
    private let _extent: simd_float3

    public init(transform: simd_float4x4, extent: simd_float3) {
        self._extent = extent
        super.init(transform: transform)
    }

    public init(name: String, transform: simd_float4x4, extent: simd_float3) {
        self._extent = extent
        super.init(name: name, transform: transform)
    }

    public required init(anchor: ARAnchor) {
        if let probe = anchor as? AREnvironmentProbeAnchor {
            self._extent = probe._extent
        } else {
            self._extent = simd_float3(repeating: 0)
        }
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class ARParticipantAnchor: ARAnchor {
    public required init(anchor: ARAnchor) {
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class ARMeshAnchor: ARAnchor {
    public var geometry: ARMeshGeometry { _geometry }
    private let _geometry: ARMeshGeometry

    public required init(anchor: ARAnchor) {
        if let mesh = anchor as? ARMeshAnchor {
            self._geometry = mesh._geometry
        } else {
            self._geometry = ARMeshGeometry()
        }
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class ARAppClipCodeAnchor: ARAnchor, ARTrackable {
    public enum URLDecodingState: Int, Hashable, Sendable {
        case decoding = 0
        case decoded = 1
        case failed = 2
    }

    public var radius: Float { 0 }
    public var url: URL? { nil }
    public var urlDecodingState: URLDecodingState { .failed }
    public var isTracked: Bool { false }

    public required init(anchor: ARAnchor) {
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

open class ARGeoAnchor: ARAnchor, ARTrackable {
    public enum AltitudeSource: Int, Hashable, Sendable {
        case unknown = 0
        case coarse = 1
        case precise = 2
        case userDefined = 3
    }

    public var altitudeSource: AltitudeSource { _altitudeSource }
    public var isTracked: Bool { false }
    public var coordinate: CLLocationCoordinate2D { _coordinate }
    public var altitude: CLLocationDistance? { _altitude }

    private let _coordinate: CLLocationCoordinate2D
    private let _altitude: CLLocationDistance?
    private let _altitudeSource: AltitudeSource

    public init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance? = nil) {
        self._coordinate = coordinate
        self._altitude = altitude
        self._altitudeSource = altitude == nil ? .unknown : .userDefined
        super.init(transform: .identity)
    }

    public init(name: String, coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance? = nil) {
        self._coordinate = coordinate
        self._altitude = altitude
        self._altitudeSource = altitude == nil ? .unknown : .userDefined
        super.init(name: name, transform: .identity)
    }

    public required init(anchor: ARAnchor) {
        if let geo = anchor as? ARGeoAnchor {
            self._coordinate = geo._coordinate
            self._altitude = geo._altitude
            self._altitudeSource = geo._altitudeSource
        } else {
            self._coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            self._altitude = nil
            self._altitudeSource = .unknown
        }
        super.init(anchor: anchor)
    }

    public required init?(coder: NSCoder) {
        self._coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self._altitude = nil
        self._altitudeSource = .unknown
        super.init(coder: coder)
    }
}
