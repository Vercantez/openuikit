// NSTextContainer. Owner: text module (TextKit-1).
//
// The box TextKit lays glyphs into. `UITextView.textContainer` is one of
// these. Defaults MEASURED iPhone SE 2x / iOS 26.1, attach_probe UITextView
// path 7: `lineFragmentPadding` 5 (same constant UITextView already used
// for its plain path).

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#endif

open class NSTextContainer: NSObject {

    public override convenience init() {
        self.init(size: CGSize(width: 0, height: 0))
    }

    public init(size: CGSize) {
        self.size = size
        super.init()
    }

    open weak var layoutManager: NSLayoutManager?

    open var size: CGSize {
        didSet { layoutManager?.invalidateContainer() }
    }

    /// UIBezierPath holes. A line strip that intersects a path's bounds is
    /// shrunk by that intersection; non-rect paths use their bounds (the
    /// samples we have are rectangles).
    open var exclusionPaths: [UIBezierPath] = [] {
        didSet { layoutManager?.invalidateContainer() }
    }

    /// MEASURED attach_probe UITextView: 5.
    open var lineFragmentPadding: CGFloat = 5 {
        didSet { layoutManager?.invalidateContainer() }
    }

    open var maximumNumberOfLines: Int = 0 {
        didSet { layoutManager?.invalidateContainer() }
    }

    open var lineBreakMode: NSLineBreakMode = .byWordWrapping {
        didSet { layoutManager?.invalidateContainer() }
    }

    open var widthTracksTextView: Bool = false
    open var heightTracksTextView: Bool = false

    open var isSimpleRectangularTextContainer: Bool { exclusionPaths.isEmpty }

    /// Remaining width of a proposed strip after padding and exclusion.
    open func lineFragmentRect(forProposedRect proposedRect: CGRect,
                               at characterIndex: Int,
                               writingDirection: NSWritingDirection,
                               remaining remainingRect: UnsafeMutablePointer<CGRect>?) -> CGRect {
        remainingRect?.pointee = CGRect(x: 0, y: 0, width: 0, height: 0)
        var r = proposedRect
        r.origin.x += lineFragmentPadding
        r.size.width = Swift.max(0, Swift.min(r.size.width, size.width) - 2 * lineFragmentPadding)
        if r.origin.x + r.size.width > size.width - lineFragmentPadding {
            r.size.width = Swift.max(0, size.width - lineFragmentPadding - r.origin.x)
        }
        for path in exclusionPaths {
            let b = path.bounds
            let strip = CGRect(x: r.origin.x, y: r.origin.y, width: r.size.width, height: r.size.height)
            if strip.intersects(b) {
                // Shrink from the intersecting side: a hole on the right
                // clips width; a hole on the left shifts origin.
                if b.minX > strip.minX {
                    r.size.width = Swift.max(0, b.minX - r.origin.x)
                } else if b.maxX < strip.maxX {
                    let newX = b.maxX
                    r.size.width = Swift.max(0, r.maxX - newX)
                    r.origin.x = newX
                } else {
                    r.size.width = 0
                }
            }
        }
        return r
    }
}
