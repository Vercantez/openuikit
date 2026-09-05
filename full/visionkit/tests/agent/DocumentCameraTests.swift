@_spi(OpenUIKitHost) import VisionKit
import Foundation

func testDocumentCameraScan() {
    let scan = VNDocumentCameraScan.hostFixture(title: "Scan", pageCount: 2)
    precondition(scan.title == "Scan")
    precondition(scan.pageCount == 2)
    let empty = VNDocumentCameraScan.hostFixture(title: "", pageCount: 0)
    precondition(empty.title.isEmpty)
    precondition(empty.pageCount == 0)
}

func testDocumentCameraViewController() {
    precondition(VNDocumentCameraViewController.isSupported == false)
    let camera = VNDocumentCameraViewController()
    precondition(camera.delegate == nil)
    final class CameraSink: NSObject, VNDocumentCameraViewControllerDelegate {}
    let sink = CameraSink()
    camera.delegate = sink
    precondition(camera.delegate === sink)
    camera.delegate = nil
    precondition(camera.delegate == nil)
}

func testDocumentCameraDelegate() {
    final class CameraSink: NSObject, VNDocumentCameraViewControllerDelegate {}
    let camera = VNDocumentCameraViewController()
    let sink = CameraSink()
    let scan = VNDocumentCameraScan.hostFixture(title: "Scan", pageCount: 1)
    sink.documentCameraViewControllerDidCancel(camera)
    sink.documentCameraViewController(camera, didFinishWith: scan)
    sink.documentCameraViewController(
        camera,
        didFailWithError: DataScannerViewController.ScanningUnavailable.unsupported
    )
}
