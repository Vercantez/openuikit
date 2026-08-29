// NSString drawing conveniences supplied by UIKit/Foundation on Apple
// platforms but absent from corelibs Foundation.  Keep this Linux-only so it
// cannot compete with the platform declaration on Darwin.

#if os(Linux)
import Foundation

public struct NSStringDrawingOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let usesLineFragmentOrigin = NSStringDrawingOptions(rawValue: 1 << 0)
    public static let usesFontLeading = NSStringDrawingOptions(rawValue: 1 << 1)
    public static let usesDeviceMetrics = NSStringDrawingOptions(rawValue: 1 << 3)
    public static let truncatesLastVisibleLine = NSStringDrawingOptions(rawValue: 1 << 5)
}

public final class NSStringDrawingContext: @unchecked Sendable {
    public init() {}
}

extension String {
    public func boundingRect(
        with size: CGSize,
        options: NSStringDrawingOptions = [],
        attributes: [NSAttributedString.Key: Any]? = nil,
        context: NSStringDrawingContext? = nil
    ) -> CGRect {
        _ = context
        let font = attributes?[.font] as? UIFont ?? .systemFont(ofSize: 12)
        let maximumWidth = max(0, size.width)
        let lineHeight = FontEngine.labelLineHeight(for: font)

        if options.contains(.usesLineFragmentOrigin), maximumWidth > 0 {
            let lines = TextLayout.wrap(
                self,
                font: font,
                maxWidth: maximumWidth,
                maxLines: 0
            )
            let width = lines.reduce(CGFloat.zero) { max($0, $1.measuredWidth) }
            return CGRect(
                origin: .zero,
                size: CGSize(
                    width: FontEngine.ceilToPixel(width, scale: 1),
                    height: CGFloat(lines.count) * lineHeight
                )
            )
        }

        return CGRect(
            origin: .zero,
            size: CGSize(
                width: FontEngine.ceilToPixel(FontEngine.measure(self, font: font), scale: 1),
                height: isEmpty ? 0 : lineHeight
            )
        )
    }
}
#endif
