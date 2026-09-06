// TextKit — a CONFORMANCE APP for NSTextAttachment layout
// (docs/HILLCLIMB.md, full/ladder/APP_LADDER.md §8).
//
// A UILabel and a UITextView each hold "A" + a 24×24 red attachment + "B"
// at 17 pt regular, plus a hanging attachment (bounds.origin.y = −24) and
// a custom NSTextAttachmentViewProvider host. The same source compiles
// against real UIKit (Tools/oracle2/confprobe) and OpenUIKit
// (`openhost --app TextKit`).
//
// Window: 375 x 667 at scale 2 — iPhone SE (3rd generation), status bar
// hidden, window safe area [0, 0, 0, 0].
import UIKit

@MainActor
public enum TextKitApp {
    public static let windowSize = CGSize(width: 375, height: 667)

    static var root: TextKitRootViewController?

    public static func makeRoot() -> UIViewController {
        let root = TextKitRootViewController()
        self.root = root
        return root
    }

    public static func perform(_ action: String) {
        guard let root else {
            print("TextKit: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "hang":
            root.showHanging()
        case "provider":
            root.showProvider()
        default:
            print("TextKit: unknown action \"\(action)\"")
        }
    }
}

extension ConformanceApps {
    static let _registerTextKit: Void = register(
        "TextKit",
        windowSize: TextKitApp.windowSize,
        makeRoot: TextKitApp.makeRoot,
        perform: TextKitApp.perform,
        scriptPath: "Sources/ConformanceApps/TextKit/script.json")
}
