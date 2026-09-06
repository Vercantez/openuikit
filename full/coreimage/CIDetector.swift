import Foundation

public class CIFeature: NSObject, @unchecked Sendable {
    public var bounds: CGRect
    public var type: String

    public init(bounds: CGRect = .zero, type: String = "") {
        self.bounds = bounds
        self.type = type
        super.init()
    }
}

public class CIFaceFeature: CIFeature, @unchecked Sendable {
    public var hasLeftEyePosition = false
    public var hasRightEyePosition = false
    public var hasMouthPosition = false
    public var hasFaceAngle = false
    public var hasSmile = false
    public var hasTrackingID = false
    public var hasTrackingFrameCount = false
    public var leftEyeClosed = false
    public var rightEyeClosed = false
    public var leftEyePosition: CGPoint = .zero
    public var rightEyePosition: CGPoint = .zero
    public var mouthPosition: CGPoint = .zero
    public var faceAngle: Float = 0
    public var trackingID: Int32 = 0
    public var trackingFrameCount: Int32 = 0

    public init(bounds: CGRect = .zero) {
        super.init(bounds: bounds, type: CIFeatureTypeFace)
    }
}

public class CIRectangleFeature: CIFeature, @unchecked Sendable {
    public var topLeft: CGPoint = .zero
    public var topRight: CGPoint = .zero
    public var bottomLeft: CGPoint = .zero
    public var bottomRight: CGPoint = .zero

    public init(bounds: CGRect = .zero) {
        super.init(bounds: bounds, type: CIFeatureTypeRectangle)
        topLeft = CGPoint(x: bounds.minX, y: bounds.maxY)
        topRight = CGPoint(x: bounds.maxX, y: bounds.maxY)
        bottomLeft = CGPoint(x: bounds.minX, y: bounds.minY)
        bottomRight = CGPoint(x: bounds.maxX, y: bounds.minY)
    }
}

public class CITextFeature: CIFeature, @unchecked Sendable {
    public var topLeft: CGPoint = .zero
    public var topRight: CGPoint = .zero
    public var bottomLeft: CGPoint = .zero
    public var bottomRight: CGPoint = .zero
    public var subFeatures: [Any]?

    public init(bounds: CGRect = .zero) {
        super.init(bounds: bounds, type: CIFeatureTypeText)
        topLeft = CGPoint(x: bounds.minX, y: bounds.maxY)
        topRight = CGPoint(x: bounds.maxX, y: bounds.maxY)
        bottomLeft = CGPoint(x: bounds.minX, y: bounds.minY)
        bottomRight = CGPoint(x: bounds.maxX, y: bounds.minY)
    }
}

public class CIQRCodeFeature: CIFeature, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public var topLeft: CGPoint = .zero
    public var topRight: CGPoint = .zero
    public var bottomLeft: CGPoint = .zero
    public var bottomRight: CGPoint = .zero
    public var messageString: String?
    public var symbolDescriptor: CIQRCodeDescriptor?

    public init(bounds: CGRect = .zero) {
        super.init(bounds: bounds, type: CIFeatureTypeQRCode)
        topLeft = CGPoint(x: bounds.minX, y: bounds.maxY)
        topRight = CGPoint(x: bounds.maxX, y: bounds.maxY)
        bottomLeft = CGPoint(x: bounds.minX, y: bounds.minY)
        bottomRight = CGPoint(x: bounds.maxX, y: bounds.minY)
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }
}

public class CIBarcodeDescriptor: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }

    public func encode(with coder: NSCoder) {
        _ = coder
    }
}

public class CIQRCodeDescriptor: CIBarcodeDescriptor, @unchecked Sendable {
    public enum ErrorCorrectionLevel: Int, Hashable, Sendable {
        case levelL = 76
        case levelM = 77
        case levelQ = 81
        case levelH = 72
    }

    public let errorCorrectedPayload: Data
    public let symbolVersion: Int
    public let maskPattern: UInt8
    public let errorCorrectionLevel: ErrorCorrectionLevel

    public init?(
        payload errorCorrectedPayload: Data,
        symbolVersion: Int,
        maskPattern: UInt8,
        errorCorrectionLevel: ErrorCorrectionLevel
    ) {
        guard symbolVersion >= 1, symbolVersion <= 40 else { return nil }
        self.errorCorrectedPayload = errorCorrectedPayload
        self.symbolVersion = symbolVersion
        self.maskPattern = maskPattern
        self.errorCorrectionLevel = errorCorrectionLevel
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

public class CIAztecCodeDescriptor: CIBarcodeDescriptor, @unchecked Sendable {
    public let errorCorrectedPayload: Data
    public let isCompact: Bool
    public let layerCount: Int
    public let dataCodewordCount: Int

    public init?(
        payload errorCorrectedPayload: Data,
        isCompact: Bool,
        layerCount: Int,
        dataCodewordCount: Int
    ) {
        guard layerCount > 0, dataCodewordCount > 0 else { return nil }
        self.errorCorrectedPayload = errorCorrectedPayload
        self.isCompact = isCompact
        self.layerCount = layerCount
        self.dataCodewordCount = dataCodewordCount
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

public class CIPDF417CodeDescriptor: CIBarcodeDescriptor, @unchecked Sendable {
    public let errorCorrectedPayload: Data
    public let isCompact: Bool
    public let rowCount: Int
    public let columnCount: Int

    public init?(
        payload errorCorrectedPayload: Data,
        isCompact: Bool,
        rowCount: Int,
        columnCount: Int
    ) {
        guard rowCount > 0, columnCount > 0 else { return nil }
        self.errorCorrectedPayload = errorCorrectedPayload
        self.isCompact = isCompact
        self.rowCount = rowCount
        self.columnCount = columnCount
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

public class CIDataMatrixCodeDescriptor: CIBarcodeDescriptor, @unchecked Sendable {
    public enum ECCVersion: Int, Hashable, Sendable {
        case v000 = 0
        case v050 = 50
        case v080 = 80
        case v100 = 100
        case v140 = 140
        case v200 = 200
    }

    public let errorCorrectedPayload: Data
    public let rowCount: Int
    public let columnCount: Int
    public let eccVersion: ECCVersion

    public init?(
        payload errorCorrectedPayload: Data,
        rowCount: Int,
        columnCount: Int,
        eccVersion: ECCVersion
    ) {
        guard rowCount > 0, columnCount > 0 else { return nil }
        self.errorCorrectedPayload = errorCorrectedPayload
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.eccVersion = eccVersion
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        return nil
    }
}

/// Face / QR / rectangle / text detectors. Isolated Linux has no Vision
/// models; `features(in:)` is fail-closed and returns an empty array.
public class CIDetector: @unchecked Sendable {
    public let type: String
    public let context: CIContext?
    public let options: [String: Any]

    public init?(ofType type: String, context: CIContext?, options: [String: Any]? = nil) {
        let known = [
            CIDetectorTypeFace,
            CIDetectorTypeQRCode,
            CIDetectorTypeRectangle,
            CIDetectorTypeText,
        ]
        guard known.contains(type) else { return nil }
        self.type = type
        self.context = context
        self.options = options ?? [:]
    }

    public func features(in image: CIImage) -> [CIFeature] {
        features(in: image, options: nil)
    }

    public func features(in image: CIImage, options: [String: Any]? = nil) -> [CIFeature] {
        _ = (image, options)
        return []
    }
}
