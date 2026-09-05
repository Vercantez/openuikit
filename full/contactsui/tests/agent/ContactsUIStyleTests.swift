@_spi(OpenUIKitHost) import ContactsUI
import Foundation

@MainActor
func testStyleAutomatic() {
    let automatic = ContactAccessButton.Style.automatic
    precondition(automatic.imageTrailingEdgePadding == nil)
    precondition(automatic.imageWidth == nil)
    precondition(automatic.imageColor == nil)
    let other = ContactAccessButton.Style()
    precondition(automatic == other)
}

@MainActor
func testStyleInitializer() {
    let custom = ContactAccessButton.Style(
        imageTrailingEdgePadding: 8,
        imageWidth: 30,
        imageColor: .accentColor
    )
    precondition(custom.imageTrailingEdgePadding == 8)
    precondition(custom.imageWidth == 30)
    precondition(custom.imageColor == .accentColor)
    precondition(custom != ContactAccessButton.Style.automatic)
}
