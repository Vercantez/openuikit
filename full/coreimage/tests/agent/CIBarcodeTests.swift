import CoreImage
import Foundation

func testCIQRCodeISO18004Codewords() {
    let message = Data("HELLO WORLD".utf8)
    let qr = CIFilter.qrCodeGenerator()
    qr.message = message
    qr.correctionLevel = "M"
    guard let codewords = qr.iso18004DataCodewords() else {
        preconditionFailure("QR data codewords")
    }
    // ISO/IEC 18004 alphanumeric, version 1-M (16 data codewords):
    // mode 0010, count 000001011, pairs HE/LL/O /WO/RL + leftover D, terminator,
    // then pad EC/11. Hand-computed:
    let expected: [UInt8] = [32, 91, 11, 120, 209, 114, 220, 77, 67, 64, 236, 17, 236, 17, 236, 17]
    precondition(codewords == expected)

    guard let image = qr.outputImage, let bitmap = image.cgImage else {
        preconditionFailure("QR output")
    }
    precondition(bitmap.width == 23 && bitmap.height == 23)
    precondition(image.extent.width == 23 && image.extent.height == 23)
    func dark(_ x: Int, _ y: Int) -> Bool {
        bitmap.pixels[(y * 23 + x) * 4] == 0
    }
    // Finder at (1,1) after 1-module quiet.
    precondition(dark(1, 1) && dark(7, 1) && dark(1, 7) && dark(7, 7))
    precondition(!dark(2, 2))
    precondition(dark(4, 4))

    let named = CIFilter(name: "CIQRCodeGenerator", withInputParameters: [
        "inputMessage": message,
        "inputCorrectionLevel": "M",
    ])
    precondition(named?.outputImage?.extent.width == 23)
    precondition((named?.value(forKey: "inputCorrectionLevel") as? String) == "M")
}

func testCICode128BarcodeGenerator() {
    let code128 = CIFilter.code128BarcodeGenerator()
    code128.message = Data("ABC-123".utf8)
    guard let bar = code128.outputImage, let barBitmap = bar.cgImage else {
        preconditionFailure("Code128")
    }
    // ISO 15417 set B: Start B, payload, checksum, Stop; quiet 10, height 32.
    precondition(barBitmap.width == 132)
    precondition(bar.extent.width == 132)
    precondition(bar.extent.height == 52)
    precondition(CIFilter(name: "CIAztecCodeGenerator")?.outputImage == nil)
    precondition(CIFilter(name: "CIPDF417BarcodeGenerator")?.outputImage == nil)
    precondition(CIFilter.localizedReferenceDocumentation(forFilterName: "CICode128BarcodeGenerator") == nil)
}
