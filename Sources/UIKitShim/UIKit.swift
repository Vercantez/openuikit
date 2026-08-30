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
// It contains no API of its own — framework re-exports only.
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
@_exported import OpenUIKit
