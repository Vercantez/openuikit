// NSTextAttachment + TextKit-1 attachment container. Owner: text module.
//
// An inline image (or hosted view) box that the attributed layout engine
// treats as a glyph of width `attachmentBounds.width`. Every geometric
// constant below was read off iPhone SE 2x / iOS 26.1 captures
// (`/tmp/probe-uikit-textkit`, SIM_DEVICE=2x, 2026-09-06):
//
//   17 pt SFUI regular: ascender 16.187, descender −4.101, lineHeight 20.287.
//   Default `bounds == .zero` → attachmentBounds is (0, 0, image.w, image.h).
//   origin.y is CoreText's (positive UP from the baseline), even on UIKit.
//   Line ascent  = max(font.ascender, max(0, origin.y + height))
//   Line descent = max(−font.descender, max(0, −origin.y))
//   UILabel 2x then ceils that sum to the device pixel (24×24 default → 28.5;
//   origin.y = −24 → 40.5; origin.y = −6 → 24.0).
//   Dark frames identical to light. 23 pt / 28 pt follow the same max().
//
// `NSAttributedString(attachment:)` inserts U+FFFC with `.attachment`.

#if canImport(Foundation)
import class Foundation.NSObject
import struct Foundation.Data
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#endif

/// UTF-16 value of the object-replacement character (`U+FFFC`) that
/// `NSAttributedString(attachment:)` inserts.
public let NSAttachmentCharacter: UInt16 = 0xFFFC

/// The attachment character as a String. Apps and the layout engine use this
/// rather than a String-algorithm search for U+FFFC.
public let NSAttachmentCharacterString = "\u{FFFC}"

// MARK: - Container protocol

/// UIKit's `NSTextAttachmentContainer`. The two queries are how TextKit asks
/// an attachment for its image and its box.
public protocol NSTextAttachmentContainer: AnyObject {
    func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?,
               characterIndex charIndex: Int) -> UIImage?
    func attachmentBounds(for textContainer: NSTextContainer?,
                          proposedLineFragment lineFrag: CGRect,
                          glyphPosition position: CGPoint,
                          characterIndex charIndex: Int) -> CGRect
}

// MARK: - NSTextAttachment

open class NSTextAttachment: NSObject, NSTextAttachmentContainer {

    /// File contents. When `image` is nil the layout engine tries to decode
    /// this as a bitmap via `UIImage(data:)`.
    open var contents: Data?

    /// UTI of `contents` (e.g. `"public.png"`). Also the key for the view
    /// provider registry.
    open var fileType: String?

    /// Displayed image. Takes precedence over `contents`.
    open var image: UIImage?

    /// Explicit box in CoreText coordinates (origin.y positive UP from the
    /// baseline). `.zero` means "use `image.size` at origin (0, 0)".
    /// MEASURED attach_probe path 0 vs path 1, SE 2x / iOS 26.1: both 46×28.5
    /// with a 24×24 image.
    open var bounds: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)

    /// Extra gap drawn on the leading side of the image. MEASURED
    /// attach_probe path 5, 17 pt, padding 4: UILabel sizeThatFits stayed
    /// 46×28.5 (the same as padding 0) while the red box origin shifted
    /// +4 pt (x 19 → 23). Padding is a drawing inset, not an advance.
    open var lineLayoutPadding: CGFloat = 0

    /// When true (the iOS 15+ default) a UITextView may host a
    /// `NSTextAttachmentViewProvider` view instead of painting `image`.
    /// MEASURED attach_probe: `allowsTextAttachmentView` is true and
    /// `usesTextAttachmentView` is true for a plain image attachment.
    open var allowsTextAttachmentView: Bool = true

    open var usesTextAttachmentView: Bool {
        guard allowsTextAttachmentView else { return false }
        if let fileType, Self.textAttachmentViewProviderClass(forFileType: fileType) != nil {
            return true
        }
        // Image attachments host a view in UITextView even without a
        // registered UTI — MEASURED attach_probe UITextView path 7.
        return image != nil
    }

    public override init() {
        super.init()
    }

    public init(data contentData: Data?, ofType uti: String?) {
        self.contents = contentData
        self.fileType = uti
        super.init()
    }

    // MARK: View-provider registry

    private static var _providers: [String: NSTextAttachmentViewProvider.Type] = [:]

    open class func textAttachmentViewProviderClass(forFileType fileType: String)
        -> NSTextAttachmentViewProvider.Type? {
        _providers[fileType]
    }

    open class func registerViewProviderClass(
        _ textAttachmentViewProviderClass: NSTextAttachmentViewProvider.Type,
        forFileType fileType: String
    ) {
        _providers[fileType] = textAttachmentViewProviderClass
    }

    // MARK: NSTextAttachmentContainer

    /// Default: `image`, else decode `contents`.
    open func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?,
                    characterIndex charIndex: Int) -> UIImage? {
        if let image { return image }
        if let contents {
            return UIImage(data: [UInt8](contents))
        }
        return nil
    }

    /// Default: `bounds` when it has a non-zero size, else the image size
    /// at origin (0, 0). MEASURED attach_probe path 0 (`bounds == .zero`)
    /// and path 1 (`bounds = (0,0,24,24)`): both report attachmentBounds
    /// (0, 0, 24, 24) and both sizeToFit 46×28.5.
    open func attachmentBounds(for textContainer: NSTextContainer?,
                               proposedLineFragment lineFrag: CGRect,
                               glyphPosition position: CGPoint,
                               characterIndex charIndex: Int) -> CGRect {
        if bounds.width != 0 || bounds.height != 0 { return bounds }
        if let img = image(forBounds: bounds, textContainer: textContainer,
                           characterIndex: charIndex) {
            return CGRect(x: 0, y: 0, width: img.size.width, height: img.size.height)
        }
        return CGRect(x: 0, y: 0, width: 0, height: 0)
    }
}

// MARK: - NSAttributedString(attachment:)

extension NSAttributedString {
    /// Inserts U+FFFC with `.attachment` set to `attachment`.
    public convenience init(attachment: NSTextAttachment) {
        self.init(string: NSAttachmentCharacterString,
                  attributes: [.attachment: attachment])
    }
}

// MARK: - View provider (TextKit-1 hosting in UITextView)

/// Hosts a `UIView` inline in a `UITextView` for one attachment. The default
/// `loadView` builds a `UIImageView` from `textAttachment.image`.
@preconcurrency @MainActor
open class NSTextAttachmentViewProvider: NSObject {
    open private(set) var textAttachment: NSTextAttachment
    open weak var parentView: UIView?
    /// UTF-16 character index of the attachment in the text storage.
    open private(set) var location: Int
    open var view: UIView?
    /// When true, `attachmentBounds` is taken from `view.bounds` after layout.
    open var tracksTextAttachmentViewBounds: Bool = false

    public required init(textAttachment: NSTextAttachment, parentView: UIView?,
                         textLayoutManager: AnyObject?, location: Int) {
        self.textAttachment = textAttachment
        self.parentView = parentView
        self.location = location
        super.init()
    }

    open func loadView() {
        if view != nil { return }
        let iv = UIImageView()
        iv.image = textAttachment.image
        iv.contentMode = .scaleToFill
        iv.isUserInteractionEnabled = false
        view = iv
    }

    open func attachmentBounds(
        for attributes: [NSAttributedString.Key: Any],
        location: Int,
        textContainer: NSTextContainer?,
        proposedLineFragment: CGRect,
        position: CGPoint
    ) -> CGRect {
        if tracksTextAttachmentViewBounds, let view, view.bounds.width > 0 {
            return view.bounds
        }
        return textAttachment.attachmentBounds(
            for: textContainer, proposedLineFragment: proposedLineFragment,
            glyphPosition: position, characterIndex: location)
    }
}

// MARK: - NSAdaptiveImageGlyph (iOS 18 stickers — compiling surface)

/// iOS 18 adaptive image glyph (Genmoji / stickers). The type compiles and
/// round-trips `imageContent`; layout treats it as a regular attachment
/// once the app wraps it in `NSTextAttachment`.
open class NSAdaptiveImageGlyph: NSObject {
    open private(set) var imageContent: Data
    open var contentIdentifier: String = ""
    open var contentDescription: String = ""

    public init(imageContent: Data) {
        self.imageContent = imageContent
        super.init()
    }
}
