//===----------------------------------------------------------------------===//
// Public enums, newtype wrappers, and identifier constants.
//===----------------------------------------------------------------------===//

@frozen public enum VNBarcodeCompositeType: Int, Sendable, Hashable {
    case none
    case linked
    case gs1TypeA
    case gs1TypeB
    case gs1TypeC
}

@frozen public enum VNChirality: Int, Sendable, Hashable {
    case unknown
    case left
    case right
}

public enum VNElementType: UInt, Sendable, Hashable {
    case unknown
    case float
    case double
}

public enum VNImageCropAndScaleOption: UInt, Sendable, Hashable {
    case centerCrop
    case scaleFit
    case scaleFill
    case scaleFitRotate90CCW
    case scaleFillRotate90CCW
}

@frozen public enum VNPointsClassification: Int, Sendable, Hashable {
    case disconnected
    case openPath
    case closedPath
}

public enum VNRequestFaceLandmarksConstellation: UInt, Sendable, Hashable {
    case constellationNotDefined
    case constellation65Points
    case constellation76Points
}

public enum VNRequestTextRecognitionLevel: Int, Sendable, Hashable {
    case accurate
    case fast
}

public enum VNRequestTrackingLevel: UInt, Sendable, Hashable {
    case accurate
    case fast
}

public struct VNBarcodeSymbology: RawRepresentable, Hashable, Sendable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let aztec = Self(rawValue: "VNBarcodeSymbologyAztec")
    public static let codabar = Self(rawValue: "VNBarcodeSymbologyCodabar")
    public static let code128 = Self(rawValue: "VNBarcodeSymbologyCode128")
    public static let code39 = Self(rawValue: "VNBarcodeSymbologyCode39")
    public static let code39Checksum = Self(rawValue: "VNBarcodeSymbologyCode39Checksum")
    public static let code39FullASCII = Self(rawValue: "VNBarcodeSymbologyCode39FullASCII")
    public static let code39FullASCIIChecksum = Self(
        rawValue: "VNBarcodeSymbologyCode39FullASCIIChecksum"
    )
    public static let code93 = Self(rawValue: "VNBarcodeSymbologyCode93")
    public static let code93i = Self(rawValue: "VNBarcodeSymbologyCode93i")
    public static let dataMatrix = Self(rawValue: "VNBarcodeSymbologyDataMatrix")
    public static let ean13 = Self(rawValue: "VNBarcodeSymbologyEAN13")
    public static let ean8 = Self(rawValue: "VNBarcodeSymbologyEAN8")
    public static let gs1DataBar = Self(rawValue: "VNBarcodeSymbologyGS1DataBar")
    public static let gs1DataBarExpanded = Self(
        rawValue: "VNBarcodeSymbologyGS1DataBarExpanded"
    )
    public static let gs1DataBarLimited = Self(
        rawValue: "VNBarcodeSymbologyGS1DataBarLimited"
    )
    public static let i2of5 = Self(rawValue: "VNBarcodeSymbologyI2of5")
    public static let i2of5Checksum = Self(rawValue: "VNBarcodeSymbologyI2of5Checksum")
    public static let itf14 = Self(rawValue: "VNBarcodeSymbologyITF14")
    public static let msiPlessey = Self(rawValue: "VNBarcodeSymbologyMSIPlessey")
    public static let microPDF417 = Self(rawValue: "VNBarcodeSymbologyMicroPDF417")
    public static let microQR = Self(rawValue: "VNBarcodeSymbologyMicroQR")
    public static let pdf417 = Self(rawValue: "VNBarcodeSymbologyPDF417")
    public static let qr = Self(rawValue: "VNBarcodeSymbologyQR")
    public static let upce = Self(rawValue: "VNBarcodeSymbologyUPCE")

    public static var Aztec: VNBarcodeSymbology { aztec }
    public static var Code128: VNBarcodeSymbology { code128 }
    public static var Code39: VNBarcodeSymbology { code39 }
    public static var Code39Checksum: VNBarcodeSymbology { code39Checksum }
    public static var Code39FullASCII: VNBarcodeSymbology { code39FullASCII }
    public static var Code39FullASCIIChecksum: VNBarcodeSymbology { code39FullASCIIChecksum }
    public static var Code93: VNBarcodeSymbology { code93 }
    public static var Code93i: VNBarcodeSymbology { code93i }
    public static var DataMatrix: VNBarcodeSymbology { dataMatrix }
    public static var EAN13: VNBarcodeSymbology { ean13 }
    public static var EAN8: VNBarcodeSymbology { ean8 }
    public static var I2of5: VNBarcodeSymbology { i2of5 }
    public static var I2of5Checksum: VNBarcodeSymbology { i2of5Checksum }
    public static var ITF14: VNBarcodeSymbology { itf14 }
    public static var PDF417: VNBarcodeSymbology { pdf417 }
    public static var QR: VNBarcodeSymbology { qr }
    public static var UPCE: VNBarcodeSymbology { upce }

    public static let allCases: [VNBarcodeSymbology] = [
        .aztec, .codabar, .code128, .code39, .code39Checksum, .code39FullASCII,
        .code39FullASCIIChecksum, .code93, .code93i, .dataMatrix, .ean13, .ean8,
        .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited, .i2of5, .i2of5Checksum,
        .itf14, .msiPlessey, .microPDF417, .microQR, .pdf417, .qr, .upce,
    ]
}

public struct VNImageOption: RawRepresentable, Hashable, Sendable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let ciContext = Self(rawValue: "VNImageOptionCIContext")
    public static let cameraIntrinsics = Self(rawValue: "VNImageOptionCameraIntrinsics")
    public static let properties = Self(rawValue: "VNImageOptionProperties")
}

public struct VNComputeStage: RawRepresentable, Hashable, Sendable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let main = Self(rawValue: "VNComputeStageMain")
    public static let postProcessing = Self(rawValue: "VNComputeStagePostProcessing")
}

public struct VNAnimalIdentifier: RawRepresentable, Hashable, Sendable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let cat = Self(rawValue: "VNAnimalIdentifierCat")
    public static let dog = Self(rawValue: "VNAnimalIdentifierDog")
}

public struct VNRecognizedPointKey: RawRepresentable, Hashable, Sendable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct VNRecognizedPointGroupKey: RawRepresentable, Hashable, Sendable, Equatable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
