import AppKit
import OpenUIKit

private func appKitComponents(
    of storage: _OpenColor.Storage
) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
    switch storage {
    case .resolved(let color):
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard color.getRed(
            &red,
            green: &green,
            blue: &blue,
            alpha: &alpha
        ) else {
            return (0, 0, 0, 0)
        }
        return (red, green, blue, alpha)
    case .named:
        // Named asset resolution needs the UI host's bundle/trait context.
        // The bridge has neither, so it must not fabricate a component color.
        return (0, 0, 0, 0)
    case .opacity(let nested, let opacity):
        let components = appKitComponents(of: nested)
        return (
            components.red,
            components.green,
            components.blue,
            components.alpha * opacity
        )
    }
}

public extension _OpenColor {
    init(nsColor: NSColor) {
        self.init(
            red: Double(nsColor.redComponent),
            green: Double(nsColor.greenComponent),
            blue: Double(nsColor.blueComponent),
            opacity: Double(nsColor.alphaComponent)
        )
    }

    @_disfavoredOverload
    init(_ color: NSColor) {
        self.init(nsColor: color)
    }
}

public extension NSColor {
    convenience init(_ color: _OpenColor) {
        let components = appKitComponents(of: color.storage)
        self.init(
            red: components.red,
            green: components.green,
            blue: components.blue,
            alpha: components.alpha
        )
    }
}
