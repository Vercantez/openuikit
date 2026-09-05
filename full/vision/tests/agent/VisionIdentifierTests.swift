#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testBarcodeSymbologyCatalog() {
    let catalog = VNBarcodeSymbology.knownSymbologies
    visionExpectEqual(catalog.count, 24, "symbology catalog")
    visionExpectEqual(Set(catalog.map(\.rawValue)).count, 24, "symbology unique")
    visionExpectEqual(VNBarcodeSymbology.qr, .QR, "qr alias")
    visionExpectEqual(VNBarcodeSymbology.aztec, .Aztec, "aztec alias")
    visionExpectEqual(VNBarcodeSymbology.codabar, .Codabar, "codabar alias")
    visionExpectEqual(VNBarcodeSymbology.code128, .Code128, "code128 alias")
    visionExpectEqual(VNBarcodeSymbology.code39, .Code39, "code39 alias")
    visionExpectEqual(VNBarcodeSymbology.code39Checksum, .Code39Checksum, "code39 checksum alias")
    visionExpectEqual(VNBarcodeSymbology.code39FullASCII, .Code39FullASCII, "code39 full alias")
    visionExpectEqual(VNBarcodeSymbology.code39FullASCIIChecksum, .Code39FullASCIIChecksum, "code39 full checksum")
    visionExpectEqual(VNBarcodeSymbology.code93, .Code93, "code93 alias")
    visionExpectEqual(VNBarcodeSymbology.code93i, .Code93i, "code93i alias")
    visionExpectEqual(VNBarcodeSymbology.dataMatrix, .DataMatrix, "datamatrix alias")
    visionExpectEqual(VNBarcodeSymbology.ean13, .EAN13, "ean13 alias")
    visionExpectEqual(VNBarcodeSymbology.ean8, .EAN8, "ean8 alias")
    visionExpectEqual(VNBarcodeSymbology.i2of5, .I2of5, "i2of5 alias")
    visionExpectEqual(VNBarcodeSymbology.i2of5Checksum, .I2of5Checksum, "i2of5 checksum alias")
    visionExpectEqual(VNBarcodeSymbology.itf14, .ITF14, "itf14 alias")
    visionExpectEqual(VNBarcodeSymbology.pdf417, .PDF417, "pdf417 alias")
    visionExpectEqual(VNBarcodeSymbology.upce, .UPCE, "upce alias")
    visionExpect(VNBarcodeSymbology.qr != .pdf417, "qr != pdf417")
    visionExpectEqual(
        VNBarcodeSymbology(rawValue: VNBarcodeSymbology.ean13.rawValue),
        .ean13,
        "symbology roundtrip"
    )
    visionExpect(catalog.contains(.gs1DataBar), "gs1")
    visionExpect(catalog.contains(.gs1DataBarExpanded), "gs1 expanded")
    visionExpect(catalog.contains(.gs1DataBarLimited), "gs1 limited")
    visionExpect(catalog.contains(.msiPlessey), "msi")
    visionExpect(catalog.contains(.microPDF417), "micropdf")
    visionExpect(catalog.contains(.microQR), "microqr")
}

func testImageOptionAndComputeStage() {
    visionExpect(VNImageOption.ciContext != .properties, "image option distinct")
    visionExpect(VNImageOption.cameraIntrinsics != .ciContext, "intrinsics")
    visionExpect(VNComputeStage.main != .postProcessing, "compute stage distinct")
    visionExpect(VNComputeStage.main.hashValue == VNComputeStage.main.hashValue, "compute hash stable")
    visionExpectEqual(VNImageOption(rawValue: VNImageOption.properties.rawValue), .properties, "option roundtrip")
}
