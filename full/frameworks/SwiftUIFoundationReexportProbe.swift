// This source intentionally imports only SwiftUI. It proves that the staged
// SwiftUI module was compiled after and publicly re-exports the full
// Foundation facade (including Combine and portable Dispatch), as Apple's
// SwiftUI does for application sources.

import SwiftUI

@main
private enum SwiftUIFoundationReexportProbe {
    @MainActor
    static func main() async {
        let suite = "OpenUIKit.SwiftUIFoundationReexportProbe"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        var notifications = 0
        let publisher: NotificationCenter.Publisher = NotificationCenter.default
            .publisher(
                for: UserDefaults.didChangeNotification,
                object: defaults
            )
        let cancellable: AnyCancellable = publisher.sink { notification in
            precondition(notification.object as AnyObject? === defaults)
            notifications += 1
        }
        defaults.set(true, forKey: "enabled")
        precondition(notifications == 1)
        cancellable.cancel()

        let scheduled = await withCheckedContinuation { continuation in
            DispatchQueue.main.schedule {
                continuation.resume(returning: 43)
            }
        }
        precondition(scheduled == 43)
        defaults.removePersistentDomain(forName: suite)

        print(
            "SWIFTUI_FOUNDATION_REEXPORT_MACHO_OK " +
                "import=swiftui-only notification=publisher " +
                "dispatch=scheduler"
        )
    }
}
