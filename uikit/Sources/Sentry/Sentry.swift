// Fail-closed Sentry for mozilla-mobile/focus-ios a2832521.
// AppDelegate.swift:333 SentrySDK.start { options.dsn }; InternalSettings
// crash buttons (focus-e2e.md: 5 SentrySDK diagnostics). There is no
// Sentry service: start records the DSN and every capture is a no-op.
// SentrySDK.crash() is also a no-op (a real crash would be inventing a
// fatal). Not the Cocoa Sentry SDK.

public enum SentrySDK {
    public static func start(_ configure: (SentryOptions) -> Void) {
        let options = SentryOptions()
        configure(options)
        _ = options.dsn
    }

    public static func crash() {}
    public static func capture(message: String) { _ = message }
    public static func capture(exception: Any) { _ = exception }
    public static func capture(error: Error) { _ = error }
}

public final class SentryOptions {
    public var dsn: String?
    public init() {}
}
