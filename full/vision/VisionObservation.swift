import Foundation

open class VNObservation: NSObject, NSCopying, NSSecureCoding, VNRequestRevisionProviding {
    public static var supportsSecureCoding: Bool { true }

    public let uuid: UUID
    public let confidence: VNConfidence
    public var timeRange: CMTimeRange = .zero
    public var requestRevision: Int

    public init(
        uuid: UUID = UUID(),
        confidence: VNConfidence = 1,
        requestRevision: Int = VNRequestRevisionUnspecified
    ) {
        self.uuid = uuid
        self.confidence = max(0, min(1, confidence))
        self.requestRevision = requestRevision
        super.init()
    }

    public required init?(coder: NSCoder) {
        let uuidString = coder.decodeObject(of: NSString.self, forKey: "uuid") as String?
        uuid = UUID(uuidString: uuidString ?? "") ?? UUID()
        confidence = Float(coder.decodeDouble(forKey: "confidence"))
        requestRevision = coder.decodeInteger(forKey: "requestRevision")
        super.init()
    }

    open func encode(with coder: NSCoder) {
        coder.encode(uuid.uuidString as NSString, forKey: "uuid")
        coder.encode(Double(confidence), forKey: "confidence")
        coder.encode(requestRevision, forKey: "requestRevision")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        VNObservation(uuid: uuid, confidence: confidence, requestRevision: requestRevision)
    }
}

open class VNDetectedObjectObservation: VNObservation {
    public let boundingBox: CGRect
    public var globalSegmentationMask: VNPixelBufferObservation?

    public convenience init(boundingBox: CGRect) {
        self.init(requestRevision: VNRequestRevisionUnspecified, boundingBox: boundingBox)
    }

    public init(requestRevision: Int, boundingBox: CGRect, confidence: VNConfidence = 1, uuid: UUID = UUID()) {
        self.boundingBox = boundingBox
        super.init(uuid: uuid, confidence: confidence, requestRevision: requestRevision)
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
    public let landmarks: VNFaceLandmarks2D?

    public convenience init(
        requestRevision: Int,
        boundingBox: CGRect,
        roll: NSNumber?,
        yaw: NSNumber?
    ) {
        self.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            roll: roll,
            yaw: yaw,
            pitch: nil
        )
    }

    public convenience init(
        requestRevision: Int,
        boundingBox: CGRect,
        roll: NSNumber?,
        yaw: NSNumber?,
        pitch: NSNumber?
    ) {
        self.init(
            requestRevision: requestRevision,
            boundingBox: boundingBox,
            roll: roll,
            yaw: yaw,
            pitch: pitch,
            faceCaptureQuality: nil,
            landmarks: nil
        )
    }

    public init(
        requestRevision: Int = VNRequestRevisionUnspecified,
        boundingBox: CGRect,
        roll: NSNumber? = nil,
        yaw: NSNumber? = nil,
        pitch: NSNumber? = nil,
        faceCaptureQuality: NSNumber? = nil,
        landmarks: VNFaceLandmarks2D? = nil,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.roll = roll
        self.yaw = yaw
        self.pitch = pitch
        self.faceCaptureQuality = faceCaptureQuality
        self.landmarks = landmarks
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
        landmarks = nil
        super.init(coder: coder)
    }
}

open class VNContoursObservation: VNObservation {
    public let topLevelContours: [VNContour]

    public var topLevelContourCount: Int { topLevelContours.count }

    public var contourCount: Int {
        topLevelContours.reduce(0) { $0 + 1 + countContours($1.childContours) }
    }

    public var normalizedPath: CGPath {
        let path = CGPath()
        for contour in topLevelContours {
            appendContour(contour, to: path)
        }
        return path
    }

    public init(topLevelContours: [VNContour], confidence: VNConfidence = 1, uuid: UUID = UUID()) {
        self.topLevelContours = topLevelContours
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        topLevelContours = []
        super.init(coder: coder)
    }

    public func contour(at contourIndex: Int) throws -> VNContour {
        let flat = flatten(topLevelContours)
        guard flat.indices.contains(contourIndex) else {
            throw vnMakeError(.outOfBoundsError, description: "contourIndex")
        }
        return flat[contourIndex]
    }

    public func contour(at indexPath: IndexPath) throws -> VNContour {
        guard let first = indexPath.first else {
            throw vnMakeError(.invalidArgument, description: "empty indexPath")
        }
        var current = try topLevelIndex(first)
        for component in indexPath.dropFirst() {
            current = try current.childContour(at: component)
        }
        return current
    }

    private func topLevelIndex(_ index: Int) throws -> VNContour {
        guard topLevelContours.indices.contains(index) else {
            throw vnMakeError(.outOfBoundsError, description: "indexPath")
        }
        return topLevelContours[index]
    }
}

open class VNFeaturePrintObservation: VNObservation {
    public let elementType: VNElementType
    public let data: Data

    public var elementCount: Int {
        let size = max(1, VNElementTypeSize(elementType))
        return data.count / size
    }

    public init(
        elementType: VNElementType,
        data: Data,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.elementType = elementType
        self.data = data
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        elementType = .float
        data = Data()
        super.init(coder: coder)
    }

    public func computeDistance(
        _ outDistance: UnsafeMutablePointer<Float>,
        to featurePrint: VNFeaturePrintObservation
    ) throws {
        guard elementType == featurePrint.elementType else {
            throw vnMakeError(.invalidArgument, description: "feature print element type")
        }
        guard elementCount == featurePrint.elementCount else {
            throw vnMakeError(.invalidArgument, description: "feature print length")
        }
        if elementType == .float {
            let lhs = data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
            let rhs = featurePrint.data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
            var sum: Float = 0
            for index in 0..<min(lhs.count, rhs.count) {
                let delta = lhs[index] - rhs[index]
                sum += delta * delta
            }
            outDistance.pointee = sum.squareRoot()
            return
        }
        throw vnMakeError(.notImplemented, description: "non-float feature print distance")
    }
}

open class VNImageAlignmentObservation: VNObservation {}

open class VNImageTranslationAlignmentObservation: VNImageAlignmentObservation {
    public let alignmentTransform: CGAffineTransform

    public init(alignmentTransform: CGAffineTransform, confidence: VNConfidence = 1, uuid: UUID = UUID()) {
        self.alignmentTransform = alignmentTransform
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        alignmentTransform = .identity
        super.init(coder: coder)
    }
}

open class VNImageHomographicAlignmentObservation: VNImageAlignmentObservation {
    public var warpTransform: matrix_float3x3 = .identity
}

open class VNPixelBufferObservation: VNObservation {
    public let pixelBuffer: CVPixelBuffer
    public let featureName: String?

    public init(
        pixelBuffer: CVPixelBuffer,
        featureName: String? = nil,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.pixelBuffer = pixelBuffer
        self.featureName = featureName
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        pixelBuffer = CVPixelBuffer(width: 0, height: 0)
        featureName = nil
        super.init(coder: coder)
    }
}

open class VNClassificationObservation: VNObservation {
    public let identifier: String
    public var hasPrecisionRecallCurve: Bool { false }

    public init(identifier: String, confidence: VNConfidence, uuid: UUID = UUID()) {
        self.identifier = identifier
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        identifier = ""
        super.init(coder: coder)
    }

    public func hasMinimumPrecision(_ minimumPrecision: Float, forRecall recall: Float) -> Bool {
        _ = minimumPrecision
        _ = recall
        return false
    }

    public func hasMinimumRecall(_ minimumRecall: Float, forPrecision precision: Float) -> Bool {
        _ = minimumRecall
        _ = precision
        return false
    }
}

open class VNHorizonObservation: VNObservation {
    public var angle: Double

    public var transform: CGAffineTransform {
        CGAffineTransform(rotationAngle: -CGFloat(angle))
    }

    public init(angle: Double, confidence: VNConfidence = 1, uuid: UUID = UUID()) {
        self.angle = angle
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        angle = 0
        super.init(coder: coder)
    }

    public func transform(forImageWidth width: Int, height: Int) -> CGAffineTransform {
        visionHorizonCenteredTransform(angle: angle, width: width, height: height)
    }
}

func visionHorizonCenteredTransform(angle: Double, width: Int, height: Int) -> CGAffineTransform {
    let cosine = Foundation.cos(-angle)
    let sine = Foundation.sin(-angle)
    let cx = CGFloat(width) / 2
    let cy = CGFloat(height) / 2
    return CGAffineTransform(
        a: cosine,
        b: sine,
        c: -sine,
        d: cosine,
        tx: cx - cosine * cx + sine * cy,
        ty: cy - sine * cx - cosine * cy
    )
}

open class VNHumanObservation: VNDetectedObjectObservation {
    public var upperBodyOnly: Bool = false

    public init(boundingBox: CGRect, upperBodyOnly: Bool = false, confidence: VNConfidence = 1, uuid: UUID = UUID()) {
        self.upperBodyOnly = upperBodyOnly
        super.init(requestRevision: VNRequestRevisionUnspecified, boundingBox: boundingBox, confidence: confidence, uuid: uuid)
    }

    public required init?(coder: NSCoder) {
        upperBodyOnly = coder.decodeBool(forKey: "upperBodyOnly")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(upperBodyOnly, forKey: "upperBodyOnly")
    }
}

open class VNInstanceMaskObservation: VNObservation {
    public let instanceMask: CVPixelBuffer

    public var allInstances: IndexSet {
        visionInstanceLabels(in: instanceMask)
    }

    public init(
        instanceMask: CVPixelBuffer,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.instanceMask = instanceMask
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        instanceMask = CVPixelBuffer(width: 0, height: 0)
        super.init(coder: coder)
    }

    public func generateMask(forInstances instances: IndexSet) throws -> CVPixelBuffer {
        try visionGenerateInstanceMask(instanceMask, instances: instances)
    }

    public func generateMaskedImage(
        ofInstances instances: IndexSet,
        from requestHandler: VNImageRequestHandler,
        croppedToInstancesExtent cropResult: Bool
    ) throws -> CVPixelBuffer {
        let mask = try generateMask(forInstances: instances)
        return try visionApplyInstanceMask(
            mask,
            to: requestHandler.raster.makePixelBuffer(),
            croppedToInstancesExtent: cropResult
        )
    }

    public func generateScaledMaskForImage(
        forInstances instances: IndexSet,
        from requestHandler: VNImageRequestHandler
    ) throws -> CVPixelBuffer {
        let mask = try generateMask(forInstances: instances)
        let target = requestHandler.raster
        return visionScaleMask(mask, width: target.width, height: target.height)
    }
}

open class VNSaliencyImageObservation: VNPixelBufferObservation {
    public var salientObjects: [VNRectangleObservation]?

    public init(
        pixelBuffer: CVPixelBuffer,
        salientObjects: [VNRectangleObservation]? = nil,
        featureName: String? = "saliency",
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.salientObjects = salientObjects
        super.init(pixelBuffer: pixelBuffer, featureName: featureName, confidence: confidence, uuid: uuid)
    }

    public required init?(coder: NSCoder) {
        salientObjects = nil
        super.init(coder: coder)
    }
}

open class VNRecognizedObjectObservation: VNDetectedObjectObservation {}

open class VNImageAestheticsScoresObservation: VNObservation {
    public let isUtility: Bool
    public let overallScore: Float

    public init(
        overallScore: Float,
        isUtility: Bool = false,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.overallScore = max(-1, min(1, overallScore))
        self.isUtility = isUtility
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        isUtility = coder.decodeBool(forKey: "isUtility")
        overallScore = coder.decodeFloat(forKey: "overallScore")
        super.init(coder: coder)
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(isUtility, forKey: "isUtility")
        coder.encode(overallScore, forKey: "overallScore")
    }
}

open class VNTrajectoryObservation: VNObservation {
    public var detectedPoints: [VNPoint]
    public var projectedPoints: [VNPoint]
    public var equationCoefficients: SIMD3<Float>
    public var movingAverageRadius: CGFloat

    public init(
        detectedPoints: [VNPoint],
        projectedPoints: [VNPoint] = [],
        equationCoefficients: SIMD3<Float> = SIMD3<Float>(0, 0, 0),
        movingAverageRadius: CGFloat = 0,
        confidence: VNConfidence = 1,
        uuid: UUID = UUID()
    ) {
        self.detectedPoints = detectedPoints
        self.projectedPoints = projectedPoints
        self.equationCoefficients = equationCoefficients
        self.movingAverageRadius = movingAverageRadius
        super.init(uuid: uuid, confidence: confidence)
    }

    public required init?(coder: NSCoder) {
        detectedPoints = []
        projectedPoints = []
        equationCoefficients = SIMD3<Float>(0, 0, 0)
        movingAverageRadius = 0
        super.init(coder: coder)
    }
}

private func countContours(_ contours: [VNContour]) -> Int {
    contours.reduce(0) { $0 + 1 + countContours($1.childContours) }
}

private func flatten(_ contours: [VNContour]) -> [VNContour] {
    var output: [VNContour] = []
    for contour in contours {
        output.append(contour)
        output.append(contentsOf: flatten(contour.childContours))
    }
    return output
}

private func appendContour(_ contour: VNContour, to path: CGPath) {
    guard let first = contour.normalizedPoints.first else { return }
    path.move(to: CGPoint(x: Double(first.x), y: Double(first.y)))
    for point in contour.normalizedPoints.dropFirst() {
        path.addLine(to: CGPoint(x: Double(point.x), y: Double(point.y)))
    }
    path.closeSubpath()
    for child in contour.childContours {
        appendContour(child, to: path)
    }
}

func visionInstanceLabels(in buffer: CVPixelBuffer) -> IndexSet {
    var labels = IndexSet()
    let width = buffer.width
    let height = buffer.height
    guard width > 0, height > 0 else { return labels }
    for y in 0..<height {
        for x in 0..<width {
            let offset = (y * width + x) * 4
            let label = Int(buffer.pixels[offset])
            if label > 0 {
                labels.insert(label)
            }
        }
    }
    return labels
}

func visionGenerateInstanceMask(_ buffer: CVPixelBuffer, instances: IndexSet) throws -> CVPixelBuffer {
    let width = buffer.width
    let height = buffer.height
    guard width > 0, height > 0 else {
        throw vnMakeError(.invalidImage, description: "instance mask is empty")
    }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        for x in 0..<width {
            let offset = (y * width + x) * 4
            let label = Int(buffer.pixels[offset])
            if instances.contains(label) {
                pixels[offset] = 255
                pixels[offset + 1] = 255
                pixels[offset + 2] = 255
                pixels[offset + 3] = 255
            } else {
                pixels[offset + 3] = 255
            }
        }
    }
    return CVPixelBuffer(width: width, height: height, pixels: pixels)
}

func visionApplyInstanceMask(
    _ mask: CVPixelBuffer,
    to image: CVPixelBuffer,
    croppedToInstancesExtent cropResult: Bool
) throws -> CVPixelBuffer {
    let width = image.width
    let height = image.height
    guard width > 0, height > 0 else {
        throw vnMakeError(.invalidImage, description: "masked image source is empty")
    }
    let scaledMask = visionScaleMask(mask, width: width, height: height)
    var minX = width
    var minY = height
    var maxX = 0
    var maxY = 0
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    for y in 0..<height {
        for x in 0..<width {
            let offset = (y * width + x) * 4
            let keep = scaledMask.pixels[offset] > 0
            if keep {
                pixels[offset] = image.pixels[offset]
                pixels[offset + 1] = image.pixels[offset + 1]
                pixels[offset + 2] = image.pixels[offset + 2]
                pixels[offset + 3] = image.pixels[offset + 3]
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            } else {
                pixels[offset + 3] = 255
            }
        }
    }
    if cropResult, maxX >= minX, maxY >= minY {
        let cropWidth = maxX - minX + 1
        let cropHeight = maxY - minY + 1
        var cropped = [UInt8](repeating: 0, count: cropWidth * cropHeight * 4)
        for y in 0..<cropHeight {
            for x in 0..<cropWidth {
                let src = ((y + minY) * width + (x + minX)) * 4
                let dst = (y * cropWidth + x) * 4
                cropped[dst] = pixels[src]
                cropped[dst + 1] = pixels[src + 1]
                cropped[dst + 2] = pixels[src + 2]
                cropped[dst + 3] = pixels[src + 3]
            }
        }
        return CVPixelBuffer(width: cropWidth, height: cropHeight, pixels: cropped)
    }
    return CVPixelBuffer(width: width, height: height, pixels: pixels)
}

func visionScaleMask(_ mask: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer {
    let srcW = max(1, mask.width)
    let srcH = max(1, mask.height)
    let dstW = max(1, width)
    let dstH = max(1, height)
    var pixels = [UInt8](repeating: 0, count: dstW * dstH * 4)
    for y in 0..<dstH {
        let srcY = min(srcH - 1, y * srcH / dstH)
        for x in 0..<dstW {
            let srcX = min(srcW - 1, x * srcW / dstW)
            let src = (srcY * srcW + srcX) * 4
            let dst = (y * dstW + x) * 4
            pixels[dst] = mask.pixels[src]
            pixels[dst + 1] = mask.pixels[src + 1]
            pixels[dst + 2] = mask.pixels[src + 2]
            pixels[dst + 3] = mask.pixels[src + 3]
        }
    }
    return CVPixelBuffer(width: dstW, height: dstH, pixels: pixels)
}
