// Native source oracle for the public SwiftUI app-lifecycle shape mirrored by
// Sources/SwiftUI/AppLifecycle.swift. This file is typechecked against the
// iOS simulator SDK; it is never compiled into OpenUIKit.

import SwiftUI
import UIKit

@MainActor
final class NativeLifecycleDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        true
    }
}

@main
struct NativeLifecycleApp: App {
    @UIApplicationDelegateAdaptor(NativeLifecycleDelegate.self)
    private var delegate

    var body: some Scene {
        WindowGroup {
            Text("Primary")
        }
        WindowGroup("Secondary") {
            Text("Secondary")
        }
    }
}
