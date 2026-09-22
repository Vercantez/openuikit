// Fail-closed stand-in for FirebaseCore from firebase-ios-sdk 11.15.0
// (fdc352fa), the one call ios-oss makes: `FirebaseApp.configure()`
// (Kickstarter-iOS/AppDelegate.swift:215, inside `#if RELEASE ||
// INTERNAL_BUILD`). There is no GoogleService-Info.plist and no Firebase
// backend on OpenUIKit, so configuring creates no default app: `app()` stays
// nil and nothing is recorded or sent. (The real SDK raises an Objective-C
// exception when the plist is missing; the shim does not pretend to succeed
// and does not crash.)
import Foundation

public final class FirebaseApp {
    private init() {}

    /// Records nothing and creates no app.
    public static func configure() {}

    /// Always nil: no default app is ever configured.
    public static func app() -> FirebaseApp? { nil }
}
