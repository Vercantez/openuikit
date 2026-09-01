import AppKit
import Foundation

@main
private enum AppKitGuestRuntime {
    static func main() {
        precondition(
            NSApplication.willBecomeActiveNotification.rawValue ==
                "NSApplicationWillBecomeActiveNotification"
        )
        precondition(
            NSApplication.willResignActiveNotification.rawValue ==
                "NSApplicationWillResignActiveNotification"
        )
        precondition(
            NSApplication.didResignActiveNotification.rawValue ==
                "NSApplicationDidResignActiveNotification"
        )
        precondition(
            NSApplication.didBecomeActiveNotification.rawValue ==
                "NSApplicationDidBecomeActiveNotification"
        )
        precondition(NSApplication.ModalResponse.stop.rawValue == -1000)
        precondition(NSApplication.ModalResponse.abort.rawValue == -1001)
        precondition(NSApplication.ModalResponse.continue.rawValue == -1002)
        precondition(
            NSApplication.ModalResponse.alertFirstButtonReturn.rawValue == 1000
        )
        precondition(
            NSApplication.ModalResponse.alertSecondButtonReturn.rawValue == 1001
        )
        precondition(
            NSApplication.ModalResponse.alertThirdButtonReturn.rawValue == 1002
        )

        let alert = NSAlert()
        alert.messageText = "Test Store Purchase"
        alert.informativeText = "No WindowServer is connected"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Purchase")
        alert.addButton(withTitle: "Fail")
        alert.addButton(withTitle: "Cancel")
        precondition(alert.buttons.map(\.title) == ["Purchase", "Fail", "Cancel"])
        precondition(alert.runModal() == .alertThirdButtonReturn)

        let noCancel = NSAlert()
        noCancel.addButton(withTitle: "Continue")
        precondition(noCancel.runModal() == .abort)

        let workspace = NSWorkspace.shared
        let url = URL(string: "https://example.invalid")!
        precondition(!workspace.open(url))
        precondition(!workspace.selectFile(nil, inFileViewerRootedAtPath: "/"))

        precondition(NSFont(name: "__OpenAppKitMissingFont__", size: 1) == nil)
        precondition(NSFontManager.shared.availableFonts.isEmpty)
        precondition(NSFontManager.shared.availableFontFamilies.isEmpty)
        precondition(
            NSFontManager.shared.availableMembers(ofFontFamily: "Missing") == nil
        )

        let color = NSColor(red: 0.125, green: 0.25, blue: 0.5, alpha: 0.75)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        precondition(red == 0.125)
        precondition(green == 0.25)
        precondition(blue == 0.5)
        precondition(alpha == 0.75)
        _ = NSWindow()

        print(
            "APPKIT_GUEST_MACHO_OK surface=application,alert,workspace," +
            "window,font,color ui=headless workspace=fail-closed " +
            "alert=cancel-or-abort fonts=unavailable"
        )
    }
}
