import AppKit
import Foundation

let color = NSColor(red: 0.125, green: 0.25, blue: 0.5, alpha: 0.75)
var red: CGFloat = 0
var green: CGFloat = 0
var blue: CGFloat = 0
var alpha: CGFloat = 0
color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

let openSignature: (NSWorkspace, URL) -> Bool = { workspace, url in
    workspace.open(url)
}
let selectSignature: (NSWorkspace, String?, String) -> Bool = {
    workspace, path, root in
    workspace.selectFile(path, inFileViewerRootedAtPath: root)
}
_ = openSignature
_ = selectSignature
_ = NSWindow.self

print("notification.willBecome=\(NSApplication.willBecomeActiveNotification.rawValue)")
print("notification.willResign=\(NSApplication.willResignActiveNotification.rawValue)")
print("notification.didResign=\(NSApplication.didResignActiveNotification.rawValue)")
print("notification.didBecome=\(NSApplication.didBecomeActiveNotification.rawValue)")
print(
    "modal=stop:\(NSApplication.ModalResponse.stop.rawValue)," +
    "abort:\(NSApplication.ModalResponse.abort.rawValue)," +
    "continue:\(NSApplication.ModalResponse.continue.rawValue)"
)
print(
    "buttons=first:\(NSApplication.ModalResponse.alertFirstButtonReturn.rawValue)," +
    "second:\(NSApplication.ModalResponse.alertSecondButtonReturn.rawValue)," +
    "third:\(NSApplication.ModalResponse.alertThirdButtonReturn.rawValue)"
)
print("alert.informational=\(NSAlert.Style.informational.rawValue)")
print("color=\(red),\(green),\(blue),\(alpha)")
print("unknown-font=\(NSFont(name: "__OpenAppKitMissingFont__", size: 1) == nil)")
print("signatures=workspace.open,workspace.selectFile,window")
