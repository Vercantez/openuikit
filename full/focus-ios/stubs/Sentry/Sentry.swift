// A no-op Sentry. Crash reporting is write-only, like Glean: measured surface is
// SentSDK.start / capture(message:) / capture(exception:) / capture(error:) /
// crash(), and nothing reads a value back. Silence changes no screen.
//
// `crash()` is the exception and it is NOT a no-op: it exists to deliberately
// crash the app from an internal debug screen, so a no-op would make a button
// labelled "SentrySDK.crash()" do nothing. That is the "succeeds and does
// nothing" shape, so it traps and says why.

import Foundation

public final class Options {
    public var dsn: String?
    public var releaseName: String?
    public var environment: String?
    public var debug = false
    public var enableCrashHandler = true
    public init() {}
}

public enum SentrySDK {
    public static func start(_ configure: (Options) -> Void) { configure(Options()) }
    public static func capture(message: String) {}
    public static func capture(error: Error) {}
    public static func capture(exception: NSException) {}
    public static func crash() -> Never {
        fatalError("Sentry stub: crash() is a DELIBERATE crash trigger from the "
                 + "internal debug screen. A no-op would make that button lie.")
    }
}
