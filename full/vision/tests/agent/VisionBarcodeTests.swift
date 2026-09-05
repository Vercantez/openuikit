#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testQRBarcodeDecode() {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 6, quietZone: 4)
    let qrHandler = VNImageRequestHandler(cgImage: qrImage, orientation: .up, options: [:])
    let qrRequest = VNDetectBarcodesRequest()
    qrRequest.symbologies = [.qr]
    try! qrHandler.perform([qrRequest])
    let qrHits = (qrRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    visionExpect(qrHits.contains(where: { $0.payloadStringValue == "HELLO" && $0.symbology == .qr }), "QR payload")
    visionExpect(qrHits.first!.boundingBox.width > 0, "QR bounding box")
}

func testCode128BarcodeDecode() {
    let codeImage = try! VisionHost.makeCode128Image(payload: "ABC123")
    let codeHandler = VNImageRequestHandler(cgImage: codeImage)
    let codeRequest = VNDetectBarcodesRequest()
    codeRequest.symbologies = [.code128]
    try! codeHandler.perform([codeRequest])
    let codeHits = (codeRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    visionExpect(codeHits.contains(where: { $0.payloadStringValue == "ABC123" && $0.symbology == .code128 }), "Code128 payload")
}

func testEAN13BarcodeDecode() {
    let eanImage = try! VisionHost.makeEAN13Image(payload: "5901234123457")
    let eanData = VisionHost.encodeNetpbm(eanImage)
    let eanHandler = VNImageRequestHandler(data: eanData, orientation: .up)
    let eanRequest = VNDetectBarcodesRequest()
    eanRequest.symbologies = [.ean13]
    try! eanHandler.perform([eanRequest])
    let eanHits = (eanRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    visionExpect(eanHits.contains(where: { $0.payloadStringValue == "5901234123457" }), "EAN-13 payload")
}

func testBarcodeURLHandler() {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 6, quietZone: 4)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("vision-qr.ppm")
    try! VisionHost.encodeNetpbm(qrImage).write(to: url)
    let urlHandler = VNImageRequestHandler(URL: url, orientation: .up, options: [:])
    let urlRequest = VNDetectBarcodesRequest()
    urlRequest.symbologies = [.qr]
    try! urlHandler.perform([urlRequest])
    visionExpect(urlHandler.source == .url(url), "url source")
    let hits = (urlRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    visionExpect(hits.contains(where: { $0.payloadStringValue == "HELLO" }), "url QR")
}
