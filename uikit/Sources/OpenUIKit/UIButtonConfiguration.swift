// UIButton.Configuration (minimal subset for scene fixtures).
// Owner: button module.
//
// This mirrors the UIKit API shape used by fixtures/scenes. Only the
// measured styles used by the oracle scenes are modeled here.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
#elseif canImport(Foundation)
import Foundation
#endif

public extension UIButton {
    struct Configuration {
        public enum Style {
            case plain
            case bordered
            case tinted
            case filled
        }

        public var style: Style
        public var title: String?
        public var image: UIImage?
        public var imagePadding: CGFloat

        public init(style: Style) {
            self.style = style
            title = nil
            image = nil
            imagePadding = 6
        }

        public static func plain() -> Configuration {
            Configuration(style: .plain)
        }

        public static func bordered() -> Configuration {
            Configuration(style: .bordered)
        }

        public static func tinted() -> Configuration {
            Configuration(style: .tinted)
        }

        public static func filled() -> Configuration {
            Configuration(style: .filled)
        }
    }
}
