import Foundation

public struct VNBarcodeSymbology: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let aztec = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyAztec")
    public static let codabar = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyCodabar")
    public static let code128 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyCode128")
    public static let code39 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyCode39")
    public static let code39Checksum = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyCode39Checksum")
    public static let code39FullASCII = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyCode39FullASCII")
    public static let code39FullASCIIChecksum = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyCode39FullASCIIChecksum")
    public static let code93 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyCode93")
    public static let code93i = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyCode93i")
    public static let dataMatrix = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyDataMatrix")
    public static let ean13 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyEAN13")
    public static let ean8 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyEAN8")
    public static let gs1DataBar = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyGS1DataBar")
    public static let gs1DataBarExpanded = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyGS1DataBarExpanded")
    public static let gs1DataBarLimited = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyGS1DataBarLimited")
    public static let i2of5 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyI2of5")
    public static let i2of5Checksum = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyI2of5Checksum")
    public static let itf14 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyITF14")
    public static let msiPlessey = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyMSIPlessey")
    public static let microPDF417 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyMicroPDF417")
    public static let microQR = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyMicroQR")
    public static let pdf417 = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyPDF417")
    public static let qr = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyQR")
    public static let upce = VNBarcodeSymbology(rawValue: "VNBarcodeSymbologyUPCE")

    public static var Aztec: VNBarcodeSymbology { aztec }
    public static var Codabar: VNBarcodeSymbology { codabar }
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

    public static let knownSymbologies: [VNBarcodeSymbology] = [
        .aztec, .codabar, .code128, .code39, .code39Checksum, .code39FullASCII,
        .code39FullASCIIChecksum, .code93, .code93i, .dataMatrix, .ean13, .ean8,
        .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited, .i2of5, .i2of5Checksum,
        .itf14, .msiPlessey, .microPDF417, .microQR, .pdf417, .qr, .upce,
    ]
}

public struct VNImageOption: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let ciContext = VNImageOption(rawValue: "VNImageOptionCIContext")
    public static let cameraIntrinsics = VNImageOption(rawValue: "VNImageOptionCameraIntrinsics")
    public static let properties = VNImageOption(rawValue: "VNImageOptionProperties")
}

public struct VNComputeStage: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let main = VNComputeStage(rawValue: "VNComputeStageMain")
    public static let postProcessing = VNComputeStage(rawValue: "VNComputeStagePostProcessing")
}
