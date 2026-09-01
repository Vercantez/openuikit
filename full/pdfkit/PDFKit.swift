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
    public static func parseStatus(_ data: Data) -> String {
        switch PDFKitIO.parseDetailed(data) {
        case .success(let document) where document.encrypted:
            return "encrypted"
        case .success:
            return "ok"
        case .failure(let failure):
            return failure.rawValue
        }
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
