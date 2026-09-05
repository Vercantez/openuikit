@_exported import Foundation

#if canImport(CoreGraphics)
@_exported import CoreGraphics
#elseif canImport(OpenCoreGraphics)
@_exported import OpenCoreGraphics
#endif

#if canImport(UIKit)
@_exported import UIKit
#elseif canImport(OpenUIKit)
@_exported import OpenUIKit
#endif

/// Sentinel used when a destination does not specify a point. The magnitude
/// matches Apple's documented "unspecified" usage (`-CGFloat.greatestFiniteMagnitude`);
/// the exact published bit pattern is an oracle question.
public let kPDFDestinationUnspecifiedValue: CGFloat = -CGFloat.greatestFiniteMagnitude

public let PDFDocumentFoundSelectionKey = "PDFDocumentFoundSelection"
public let PDFDocumentPageIndexKey = "PDFDocumentPageIndex"

extension Notification.Name {
    public static let PDFThumbnailViewDocumentEdited = Notification.Name("PDFThumbnailViewDocumentEditedNotification")
    public static let PDFViewAnnotationHit = Notification.Name("PDFViewAnnotationHitNotification")
    public static let PDFViewAnnotationWillHit = Notification.Name("PDFViewAnnotationWillHitNotification")
    public static let PDFViewChangedHistory = Notification.Name("PDFViewChangedHistoryNotification")
    public static let PDFViewCopyPermission = Notification.Name("PDFViewCopyPermissionNotification")
    public static let PDFViewDisplayBoxChanged = Notification.Name("PDFViewDisplayBoxChangedNotification")
    public static let PDFViewDisplayModeChanged = Notification.Name("PDFViewDisplayModeChangedNotification")
    public static let PDFViewDocumentChanged = Notification.Name("PDFViewDocumentChangedNotification")
    public static let PDFViewPageChanged = Notification.Name("PDFViewPageChangedNotification")
    public static let PDFViewPrintPermission = Notification.Name("PDFViewPrintPermissionNotification")
    public static let PDFViewScaleChanged = Notification.Name("PDFViewScaleChangedNotification")
    public static let PDFViewSelectionChanged = Notification.Name("PDFViewSelectionChangedNotification")
    public static let PDFViewVisiblePagesChanged = Notification.Name("PDFViewVisiblePagesChangedNotification")
    public static let PDFDocumentDidUnlock = Notification.Name("PDFDocumentDidUnlockNotification")
    public static let PDFDocumentDidBeginFind = Notification.Name("PDFDocumentDidBeginFindNotification")
    public static let PDFDocumentDidEndFind = Notification.Name("PDFDocumentDidEndFindNotification")
    public static let PDFDocumentDidBeginPageFind = Notification.Name("PDFDocumentDidBeginPageFindNotification")
    public static let PDFDocumentDidEndPageFind = Notification.Name("PDFDocumentDidEndPageFindNotification")
    public static let PDFDocumentDidFindMatch = Notification.Name("PDFDocumentDidFindMatchNotification")
    public static let PDFDocumentDidBeginWrite = Notification.Name("PDFDocumentDidBeginWriteNotification")
    public static let PDFDocumentDidEndWrite = Notification.Name("PDFDocumentDidEndWriteNotification")
    public static let PDFDocumentDidBeginPageWrite = Notification.Name("PDFDocumentDidBeginPageWriteNotification")
    public static let PDFDocumentDidEndPageWrite = Notification.Name("PDFDocumentDidEndPageWriteNotification")
}

@_spi(PDFKitTesting)
public enum PDFKitTesting {
    public static func parseStatus(_ data: Data, password: String? = nil) -> String {
        switch PDFKitIO.parseDetailed(data, password: password) {
        case .success(let document) where document.encrypted && document.pages.isEmpty:
            return "encrypted"
        case .success:
            return "ok"
        case .failure(let failure):
            return failure.rawValue
        }
    }

    public static func flate(_ data: Data) -> Data { PDFKitFilters.encodeFlate(data) }
    public static func asciiHex(_ data: Data) -> Data { PDFKitFilters.encodeASCIIHex(data) }
    public static func ascii85(_ data: Data) -> Data { PDFKitFilters.encodeASCII85(data) }
    public static func runLength(_ data: Data) -> Data { PDFKitFilters.encodeRunLength(data) }
    public static func md5(_ data: Data) -> Data { Data(PDFKitCrypto.md5([UInt8](data))) }

    /// Build a R=2 / V=1 RC4-encrypted hello PDF (ISO 32000-1 §7.6.3 Algorithms 2–4).
    public static func standardEncryptedHello(userPassword: String, ownerPassword: String? = nil) -> Data {
        let fileID: [UInt8] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
        let permissions: Int32 = -4
        let owner = ownerPassword ?? userPassword
        var ownerHash = PDFKitCrypto.md5(PDFKitCrypto.padPassword(owner))
        ownerHash = Array(ownerHash.prefix(5))
        let ownerKey = PDFKitCrypto.rc4(ownerHash, PDFKitCrypto.padPassword(userPassword))
        let info = PDFKitCrypto.EncryptInfo(
            revision: 2,
            version: 1,
            keyLengthBytes: 5,
            permissions: permissions,
            ownerKey: ownerKey,
            userKey: [],
            fileID: fileID,
            encryptMetadata: true,
            useAES: false,
            ownerEncryptionKey: [],
            userEncryptionKey: [],
            perms: []
        )
        let fileKey = PDFKitCrypto.fileKey(password: userPassword, info: info)
        let userKey = PDFKitCrypto.rc4(fileKey, PDFKitCrypto.padding)
        let body = Data("BT /F1 12 Tf 72 720 Td (Hello PDFKit) Tj ET".utf8)
        let encryptedBody = PDFKitCrypto.encryptObject(body, key: fileKey, object: 5, generation: 0, useAES: false)
        let title = PDFKitCrypto.encryptObject(
            Data("Runtime Probe".utf8),
            key: fileKey,
            object: 1,
            generation: 0,
            useAES: false
        )
        func pdfString(_ bytes: [UInt8]) -> String {
            let hex = bytes.map { String(format: "%02X", $0) }.joined()
            return "<\(hex)>"
        }
        let builder = _PDFKitEncryptedBuilder()
        builder.add(1, "<< /Title \(pdfString([UInt8](title))) >>")
        builder.add(2, "<< /Type /Catalog /Pages 3 0 R >>")
        builder.add(3, "<< /Type /Pages /Kids [4 0 R] /Count 1 >>")
        builder.add(
            4,
            "<< /Type /Page /Parent 3 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents 5 0 R >>"
        )
        var stream = Data("<< /Length \(encryptedBody.count) >>\nstream\n".utf8)
        stream.append(encryptedBody)
        stream.append(Data("\nendstream".utf8))
        builder.add(5, stream)
        builder.add(
            6,
            "<< /Filter /Standard /V 1 /R 2 /O \(pdfString(ownerKey)) /U \(pdfString(userKey)) /P \(permissions) >>"
        )
        let idLiteral = pdfString(fileID)
        return builder.finish(root: 2, info: 1, extraTrailer: "/Encrypt 6 0 R /ID [\(idLiteral) \(idLiteral)]")
    }

    public static func resourceKeyCount(for page: PDFPage) -> Int {
        page.resourceKeyCount
    }

    #if canImport(CoreGraphics)
    public static func acceptIdentity(document: CGPDFDocument, page: CGPDFPage, rect: CGRect) -> Bool {
        _ = (document, page)
        return rect.width >= 0 && rect.height >= 0
    }
    #endif

    #if canImport(UIKit)
    public static func acceptIdentity(image: UIImage, view: UIView, controller: UIViewController) -> Bool {
        _ = (image.size, view.bounds, controller)
        return true
    }
    #endif
}

final class _PDFKitEncryptedBuilder {
    private var items: [(Int, Data)] = []

    func add(_ number: Int, _ body: String) { items.append((number, Data(body.utf8))) }
    func add(_ number: Int, _ body: Data) { items.append((number, body)) }

    func finish(root: Int, info: Int?, extraTrailer: String) -> Data {
        var output = Data("%PDF-1.4\n".utf8)
        output.append(contentsOf: [0x25, 0xE2, 0xE3, 0xCF, 0xD3, 0x0A])
        let maxNumber = items.map(\.0).max() ?? 0
        var offsets = Array(repeating: 0, count: maxNumber + 1)
        var inUse = Array(repeating: false, count: maxNumber + 1)
        for (number, body) in items {
            offsets[number] = output.count
            inUse[number] = true
            output.append(Data("\(number) 0 obj\n".utf8))
            output.append(body)
            if body.last != 0x0A { output.append(0x0A) }
            output.append(Data("endobj\n".utf8))
        }
        let xref = output.count
        var table = "xref\n0 \(maxNumber + 1)\n0000000000 65535 f \n"
        for number in 1...maxNumber {
            if inUse[number] {
                table += String(format: "%010d 00000 n \n", offsets[number])
            } else {
                table += "0000000000 00000 f \n"
            }
        }
        output.append(Data(table.utf8))
        var trailer = "trailer\n<< /Size \(maxNumber + 1) /Root \(root) 0 R"
        if let info { trailer += " /Info \(info) 0 R" }
        trailer += " \(extraTrailer) >>\nstartxref\n\(xref)\n%%EOF\n"
        output.append(Data(trailer.utf8))
        return output
    }
}

