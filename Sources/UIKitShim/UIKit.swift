// A module literally named `UIKit` that re-exports OpenUIKit.
//
// Why this exists: the real-app harness (Sources/RealAppProbe) vendors
// UNMODIFIED source files from a shipping iOS app, and every one of them
// starts with `import UIKit`. Without this shim each vendored file would need
// that line rewritten to `import OpenUIKit`, which would show up in the
// adaptation ledger as noise — a module rename says nothing about API
// coverage, which is what docs/REAL_APP_TEST.md is measuring.
//
// It is safe on both platforms: `import UIKit` does not resolve to anything in
// the macOS SDK (UIKit ships in the iOS / Mac Catalyst SDKs only), and there is
// no UIKit at all on Linux, so this target is the only `UIKit` in scope.
//
// This target is a shim by definition and is labelled as such in the report.
// It re-exports framework API and declares only the local identity aliases
// below, which make unqualified lookup select the canonical family.
//
// M15: it re-exports Foundation as well, because REAL UIKit does
// (`@_exported import Foundation` is in UIKit's own swiftinterface). That is
// what makes an app file whose only import line is `import UIKit` able to name
// `NSCoder` — the corpus's single most common missing type, 344 of 5,099
// files. It became possible only once OpenUIKit's geometry types were
// Foundation's own; before M15 this line would have made every `CGRect` in
// every vendored file ambiguous. Linux-built Mach-O app builds do not yet
// have the complete Foundation umbrella, but they do stage the open-source
// FoundationEssentials module. Re-exporting it on that path preserves real
// UIKit's app-facing contract: an unchanged file with only `import UIKit`
// sees the canonical `IndexPath`, rather than OpenUIKit's old fallback value.
#if canImport(Foundation)
@_exported import Foundation
#elseif canImport(FoundationEssentials)
@_exported import FoundationEssentials
#endif
#if canImport(ObjectiveC)
@_exported import ObjectiveC
#endif
@_exported import OpenUIKit

// These local aliases deliberately win unqualified lookup through the
// re-exporting UIKit module. On Foundation-visible builds OpenUIKit's
// Notification, NSNotification and OperationQueue aliases already have
// Foundation identity, and Foundation+Objective-C also aliases the center;
// importing UIKit plus Foundation therefore names one declaration. Portable
// builds retain OpenUIKit's selector-capable center behind the same spelling.
public typealias Notification = OpenUIKit.Notification
#if canImport(Foundation) || canImport(ObjectiveC)
public typealias NSNotification = OpenUIKit.NSNotification
#endif
public typealias NotificationCenter = OpenUIKit.NotificationCenter
public typealias OperationQueue = OpenUIKit.OperationQueue
