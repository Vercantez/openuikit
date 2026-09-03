import Foundation

open class VNObservation: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let uuid: UUID
    public let confidence: VNConfidence

    public init(uuid: UUID = UUID(), confidence: VNConfidence = 1) {
        self.uuid = uuid
        self.confidence = max(0, min(1, confidence))
        super.init()
    }

    public required init?(coder: NSCoder) {
        let uuidString = coder.decodeObject(of: NSString.self, forKey: "uuid") as String?
        uuid = UUID(uuidString: uuidString ?? "") ?? UUID()
        confidence = Float(coder.decodeDouble(forKey: "confidence"))
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(uuid.uuidString as NSString, forKey: "uuid")
        coder.encode(Double(confidence), forKey: "confidence")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        VNObservation(uuid: uuid, confidence: confidence)
    }
}

open class VNDetectedObjectObservation: VNObservation {
    public let boundingBox: CGRect

    public convenience init(boundingBox: CGRect) {
        self.init(requestRevision: VNRequestRevisionUnspecified, boundingBox: boundingBox)
    }

    public init(requestRevision: Int, boundingBox: CGRect, confidence: VNConfidence = 1, uuid: UUID = UUID()) {
        self.boundingBox = boundingBox
        _ = requestRevision
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        let x = coder.decodeDouble(forKey: "bx")
        let y = coder.decodeDouble(forKey: "by")
        let w = coder.decodeDouble(forKey: "bw")
        let h = coder.decodeDouble(forKey: "bh")
        boundingBox = CGRect(x: x, y: y, width: w, height: h)
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(Double(boundingBox.origin.x), forKey: "bx")
        coder.encode(Double(boundingBox.origin.y), forKey: "by")
        coder.encode(Double(boundingBox.size.width), forKey: "bw")
        coder.encode(Double(boundingBox.size.height), forKey: "bh")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        VNDetectedObjectObservation(
            requestRevision: VNRequestRevisionUnspecified,
            boundingBox: boundingBox,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNRectangleObservation: VNDetectedObjectObservation {
    public let topLeft: CGPoint
    public let topRight: CGPoint
    public let bottomRight: CGPoint
    public let bottomLeft: CGPoint

    public convenience init(
        requestRevision: Int,
        topLeft: CGPoint,
        bottomLeft: CGPoint,
        bottomRight: CGPoint,
        topRight: CGPoint
    ) {
        self.init(
            requestRevision: requestRevision,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft
        )
    }

    public init(
        requestRevision: Int,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.topLeft = topLeft
        self.topRight = topRight
        self.bottomRight = bottomRight
        self.bottomLeft = bottomLeft
        let minX = min(topLeft.x, min(topRight.x, min(bottomLeft.x, bottomRight.x)))
        let maxX = max(topLeft.x, max(topRight.x, max(bottomLeft.x, bottomRight.x)))
        let minY = min(topLeft.y, min(topRight.y, min(bottomLeft.y, bottomRight.y)))
        let maxY = max(topLeft.y, max(topRight.y, max(bottomLeft.y, bottomRight.y)))
        super.init(
            requestRevision: requestRevision,
            boundingBox: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY),
            confidence: confidence,
            uuid: uuid
        )
    }

    public required init?(coder: NSCoder) {
        func point(_ prefix: String) -> CGPoint {
            CGPoint(
                x: coder.decodeDouble(forKey: prefix + "x"),
                y: coder.decodeDouble(forKey: prefix + "y")
            )
        }
        topLeft = point("tl")
        topRight = point("tr")
        bottomRight = point("br")
        bottomLeft = point("bl")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        func encodePoint(_ point: CGPoint, _ prefix: String) {
            coder.encode(Double(point.x), forKey: prefix + "x")
            coder.encode(Double(point.y), forKey: prefix + "y")
        }
        encodePoint(topLeft, "tl")
        encodePoint(topRight, "tr")
        encodePoint(bottomRight, "br")
        encodePoint(bottomLeft, "bl")
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        VNRectangleObservation(
            requestRevision: VNRequestRevisionUnspecified,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: confidence,
            uuid: uuid
        )
    }
}

open class VNBarcodeObservation: VNRectangleObservation {
    public let symbology: VNBarcodeSymbology
    public let payloadStringValue: String?
    public let payloadData: Data?
    public let isGS1DataCarrier: Bool
    public let isColorInverted: Bool
    public let supplementalCompositeType: VNBarcodeCompositeType
    public let supplementalPayloadString: String?
    public let supplementalPayloadData: Data?

    public init(
        requestRevision: Int = VNRequestRevisionUnspecified,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        symbology: VNBarcodeSymbology,
        payloadStringValue: String? = nil,
        payloadData: Data? = nil,
        isGS1DataCarrier: Bool = false,
        isColorInverted: Bool = false,
        supplementalCompositeType: VNBarcodeCompositeType = .none,
        supplementalPayloadString: String? = nil,
        supplementalPayloadData: Data? = nil,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.symbology = symbology
        self.payloadStringValue = payloadStringValue
        self.payloadData = payloadData
        self.isGS1DataCarrier = isGS1DataCarrier
        self.isColorInverted = isColorInverted
        self.supplementalCompositeType = supplementalCompositeType
        self.supplementalPayloadString = supplementalPayloadString
        self.supplementalPayloadData = supplementalPayloadData
        super.init(
            requestRevision: requestRevision,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: confidence,
            uuid: uuid
        )
    }

    public required init?(coder: NSCoder) {
        let raw = coder.decodeObject(of: NSString.self, forKey: "symbology") as String? ?? ""
        symbology = VNBarcodeSymbology(rawValue: raw)
        payloadStringValue = coder.decodeObject(of: NSString.self, forKey: "payload") as String?
        payloadData = coder.decodeObject(of: NSData.self, forKey: "payloadData") as Data?
        isGS1DataCarrier = coder.decodeBool(forKey: "gs1")
        isColorInverted = coder.decodeBool(forKey: "inverted")
        supplementalCompositeType = VNBarcodeCompositeType(
            rawValue: coder.decodeInteger(forKey: "composite")
        ) ?? .none
        supplementalPayloadString = coder.decodeObject(of: NSString.self, forKey: "supp") as String?
        supplementalPayloadData = coder.decodeObject(of: NSData.self, forKey: "suppData") as Data?
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(symbology.rawValue as NSString, forKey: "symbology")
        coder.encode(payloadStringValue as NSString?, forKey: "payload")
        coder.encode(payloadData as NSData?, forKey: "payloadData")
        coder.encode(isGS1DataCarrier, forKey: "gs1")
        coder.encode(isColorInverted, forKey: "inverted")
        coder.encode(supplementalCompositeType.rawValue, forKey: "composite")
        coder.encode(supplementalPayloadString as NSString?, forKey: "supp")
        coder.encode(supplementalPayloadData as NSData?, forKey: "suppData")
    }
}

open class VNTextObservation: VNRectangleObservation {
    public let characterBoxes: [VNRectangleObservation]?

    public init(
        requestRevision: Int = VNRequestRevisionUnspecified,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        characterBoxes: [VNRectangleObservation]? = nil,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.characterBoxes = characterBoxes
        super.init(
            requestRevision: requestRevision,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: confidence,
            uuid: uuid
        )
    }

    public required init?(coder: NSCoder) {
        characterBoxes = nil
        super.init(coder: coder)
    }
}

open class VNRecognizedText: NSObject {
    public let string: String
    public let confidence: VNConfidence

    public init(string: String, confidence: VNConfidence) {
        self.string = string
        self.confidence = max(0, min(1, confidence))
        super.init()
    }

    public func boundingBox(for range: Range<String.Index>) throws -> VNRectangleObservation {
        _ = range
        throw vnMakeError(.notImplemented, description: "boundingBox(for:) needs layout metrics")
    }
}

open class VNRecognizedTextObservation: VNRectangleObservation {
    private let candidates: [VNRecognizedText]

    public init(
        requestRevision: Int = VNRequestRevisionUnspecified,
        topLeft: CGPoint,
        topRight: CGPoint,
        bottomRight: CGPoint,
        bottomLeft: CGPoint,
        candidates: [VNRecognizedText],
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.candidates = candidates
        super.init(
            requestRevision: requestRevision,
            topLeft: topLeft,
            topRight: topRight,
            bottomRight: bottomRight,
            bottomLeft: bottomLeft,
            confidence: confidence,
            uuid: uuid
        )
    }

    public required init?(coder: NSCoder) {
        candidates = []
        super.init(coder: coder)
    }

    public func topCandidates(_ maxCandidateCount: Int) -> [VNRecognizedText] {
        Array(candidates.prefix(max(0, maxCandidateCount)))
    }
}

open class VNFaceObservation: VNDetectedObjectObservation {
    public let roll: NSNumber?
    public let yaw: NSNumber?
    public let pitch: NSNumber?
    public let faceCaptureQuality: NSNumber?

    public init(
        requestRevision: Int = VNRequestRevisionUnspecified,
        boundingBox: CGRect,
        roll: NSNumber? = nil,
        yaw: NSNumber? = nil,
        pitch: NSNumber? = nil,
        faceCaptureQuality: NSNumber? = nil,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.roll = roll
        self.yaw = yaw
        self.pitch = pitch
        self.faceCaptureQuality = faceCaptureQuality
        super.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            confidence: confidence,
            uuid: uuid
        )
    }

    public required init?(coder: NSCoder) {
        roll = nil
        yaw = nil
        pitch = nil
        faceCaptureQuality = nil
        super.init(coder: coder)
    }
}

open class VNHumanBodyPose3DObservation: VNObservation {
    public enum HeightEstimation: Int, CaseIterable, Sendable {
        case reference = 0
        case measured = 1
    }
}
