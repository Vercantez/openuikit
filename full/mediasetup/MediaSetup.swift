@_exported import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Linux starting point for Apple's public `MediaSetup` module.
///
/// Account records and setup-session object identity are real. Linux has no
/// HomePod / Apple TV media-service daemon, no Apple authentication sheet,
/// and (in the isolated host configuration) no UIKit. `MSSetupSession.start()`
/// always fails closed. Darwin's iPhoneOS graph aliases
/// `MSPresentationAnchor` to `UIWindow`; without UIKit the overlay is
/// `NSObject` so presentation-context protocols compile. That overlay is not
/// a public `UIWindow` substitute.
///
/// Apple graph: 17 exact public identifiers, iOS 14+. Pinned `dotnet/macios`
/// `src/mediasetup.cs` corroborates ObjC selectors and nullability; it names
/// `presentationAnchor` as a property while the graph names a method. The
/// graph wins. Unresolved Darwin errors and defaults are in
/// `oracle-questions.tsv`.

// MARK: - Fail-closed NSError

/// Linux-local domain. Darwin `_MSErrorDomain` / `_MSServiceSetupErrorDomain`
/// string payloads are not on the public Swift surface and are unobserved.
let mediaSetupLinuxUnavailableDomain = "MediaSetup.linux.unavailable"

let mediaSetupLinuxUnavailableCode = 1

func mediaSetupUnavailableError(operation: String) -> NSError {
    NSError(
        domain: mediaSetupLinuxUnavailableDomain,
        code: mediaSetupLinuxUnavailableCode,
        userInfo: [
            NSLocalizedDescriptionKey:
                "Linux has no Apple Media Setup service or HomePod/Apple TV setup UI (\(operation))"
        ]
    )
}

// MARK: - MSPresentationAnchor

#if canImport(UIKit)
/// Darwin and the iPhoneOS 26.1 graph: `typealias MSPresentationAnchor = UIWindow`.
public typealias MSPresentationAnchor = UIWindow
#else
/// Darwin's `MSPresentationAnchor` is `UIWindow`. Isolated Linux has no UIKit;
/// the overlay is `NSObject` so `MSAuthenticationPresentationContext` compiles.
/// Supplying an anchor never presents a sheet.
public typealias MSPresentationAnchor = NSObject
#endif

// MARK: - MSAuthenticationPresentationContext

/// Provides a window for Media Setup authentication UI.
///
/// Apple graph: `protocol MSAuthenticationPresentationContext : NSObjectProtocol`
/// with `func presentationAnchor() -> MSPresentationAnchor?`. Pinned macios
/// exports `presentationAnchor` as a nullable property; the graph's method
/// form is the declaration used here.
public protocol MSAuthenticationPresentationContext: NSObjectProtocol {
    func presentationAnchor() -> MSPresentationAnchor?
}
