// Fail-closed stand-in for the `Firebase` umbrella of firebase-ios-sdk
// 11.15.0 (fdc352fa). The real umbrella re-exports FirebaseCore and every
// linked product; ios-oss's AppDelegate imports only `Firebase` and reaches
// FirebaseApp, Analytics.setConsent, Crashlytics and RemoteConfig through it.
// See the individual shim modules for their (non-)behaviour.
@_exported import FirebaseAnalytics
@_exported import FirebaseCore
@_exported import FirebaseCrashlytics
@_exported import FirebaseRemoteConfig
