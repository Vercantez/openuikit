@_spi(PDFKitTesting) import PDFKit
import CoreGraphics
import Foundation
import UIKit

#if os(Linux)
import Glibc
#endif

func identityFail(_ message: String) -> Never {
    fputs("PDFKIT_DEPENDENCY_IDENTITY_FAIL \(message)\n", stderr)
    exit(1)
}

func identityExpect(_ condition: Bool, _ message: String) {
    if !condition { identityFail(message) }
}

let rect = CGRect(x: 12, y: 24, width: 320, height: 480)
let page = PDFPage()
page.setBounds(rect, for: .mediaBox)
identityExpect(page.bounds(for: .mediaBox) == rect, "CGRect passed through PDFPage.setBounds")

let renderer = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 48))
let image = renderer.image { _ in }
let imagePage = PDFPage(image: image)
identityExpect(imagePage != nil, "UIImage passed through PDFPage.init(image:)")
identityExpect(imagePage?.bounds(for: .mediaBox).width == 64, "UIImage size became media box")
_ = imagePage?.thumbnail(of: CGSize(width: 32, height: 24), for: .mediaBox)

let view = PDFView(frame: rect)
identityExpect(view.frame.size.width == rect.size.width, "CGRect passed through PDFView.frame")
let hostedView: UIView = view
let controller = UIViewController()
identityExpect(
    PDFKitTesting.acceptIdentity(image: image, view: hostedView, controller: controller),
    "UIImage/UIView/UIViewController passed through PDFKit testing SPI"
)

final class IdentityDelegate: NSObject, PDFViewDelegate {
    let controller = UIViewController()
    func pdfViewParentViewController() -> UIViewController { controller }
}

let delegate = IdentityDelegate()
view.delegate = delegate
identityExpect(
    view.delegate?.pdfViewParentViewController() === delegate.controller,
    "UIViewController passed through PDFViewDelegate"
)
_ = view.findInteraction
_ = view.documentView

#if canImport(CoreGraphics)
let temp = FileManager.default.temporaryDirectory.appendingPathComponent("pdfkit-identity-\(UUID().uuidString)")
try? FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: temp) }
let document = PDFDocument()
document.insert(page, at: 0)
let pdfURL = temp.appendingPathComponent("identity.pdf")
identityExpect(document.write(to: pdfURL), "write fixture for CGPDFDocument")
if let cgDocument = CGPDFDocument(pdfURL as CFURL), let cgPage = cgDocument.page(at: 1) {
    identityExpect(
        PDFKitTesting.acceptIdentity(document: cgDocument, page: cgPage, rect: rect),
        "CGPDFDocument/Page passed through PDFKit testing SPI"
    )
    _ = document.documentRef
    _ = page.pageRef
} else {
    identityFail("CGPDFDocument/Page could not be constructed from written PDF")
}
#endif

#if os(Linux)
let handle = dlopen("libPDFKit.dylib", Int32(RTLD_NOW | RTLD_NOLOAD))
identityExpect(handle != nil, "dlopen RTLD_NOLOAD found libPDFKit.dylib")
if let maps = try? String(contentsOfFile: "/proc/self/maps", encoding: .utf8) {
    identityExpect(maps.contains("libPDFKit.dylib"), "/proc/self/maps lists libPDFKit.dylib")
}
#endif

print("PDFKIT_DEPENDENCY_IDENTITY_OK")
