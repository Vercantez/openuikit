// Fast startup proof; the screen proof still uses render_full's realapp path.
import Foundation
import Blockzilla
import OpenUIKit

@main
struct FocusGuestLaunchProbe {
    @MainActor static func main() {
        OpenUIKitRuntime.imageSearchPaths = [FileManager.default.currentDirectoryPath + "/fixtures/realapp/assets"]
        let root = FocusBrowserLaunch.makeRoot()
        precondition(String(describing: type(of: root)).contains("BrowserViewController"))
        print("FOCUS_REAL_APPDELEGATE_LAUNCHED root=\(type(of: root))")
    }
}
