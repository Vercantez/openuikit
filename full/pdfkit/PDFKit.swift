@_exported import Foundation
#if canImport(CoreGraphics)
@_exported import CoreGraphics
#endif
#if canImport(UIKit)
@_exported import UIKit
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
