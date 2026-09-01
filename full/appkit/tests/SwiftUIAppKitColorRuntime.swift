import AppKit
import SwiftUI

@main
private enum SwiftUIAppKitColorRuntime {
    static func main() {
        let source = NSColor(red: 0.125, green: 0.25, blue: 0.5, alpha: 0.75)
        let color = Color(nsColor: source)
        let roundTrip = NSColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        roundTrip.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        precondition(red == 0.125)
        precondition(green == 0.25)
        precondition(blue == 0.5)
        precondition(alpha == 0.75)

        print(
            "APPKIT_SWIFTUI_COLOR_MACHO_OK rgba=" +
            "\(red),\(green),\(blue),\(alpha) identity=AppKit.NSColor"
        )
    }
}
