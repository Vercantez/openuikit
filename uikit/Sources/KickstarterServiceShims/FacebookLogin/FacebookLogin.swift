// Fail-closed stand-in for FacebookLogin / FBSDKLoginKit from facebook-ios-sdk
// 12.3.2 (e14f3499). Surface = what ios-oss touches:
//   Kickstarter-Framework LoginToutViewController.swift:29-31,79,453-462 and
//     FindFriendsFacebookConnectCell.swift:27-29,119-126:
//     LoginManager(), .defaultAudience = .friends,
//     logIn(permissions:from:handler:) with `result.isCancelled`, logOut()
//   Library LoginToutViewModel.swift / FindFriendsFacebookConnectCellViewModel
//     .swift: LoginManagerLoginResult, `result.token?.tokenString`
//   Library UIAlertController.swift: the FacebookCore error keys (re-exported)
//
// Behaviour: login always FAILS — the handler is called once, on the main
// queue, with a nil result and an NSError in `LoginManager.shimErrorDomain`
// that carries no FBSDK localized title/description keys, so the app shows
// its own "Facebook login unavailable" strings. No token is ever produced.
// `LoginManagerLoginResult` has no public initializer, so no caller can
// construct a success.
@_exported import FacebookCore
import Foundation
import UIKit

public enum DefaultAudience: UInt {
    case friends
    case onlyMe
    case everyone
}

public final class LoginManagerLoginResult {
    public let token: AccessToken?
    public let isCancelled: Bool
    public let grantedPermissions: Set<String>
    public let declinedPermissions: Set<String>

    init(token: AccessToken?, isCancelled: Bool, grantedPermissions: Set<String>, declinedPermissions: Set<String>) {
        self.token = token
        self.isCancelled = isCancelled
        self.grantedPermissions = grantedPermissions
        self.declinedPermissions = declinedPermissions
    }
}

public typealias LoginManagerLoginResultBlock = (LoginManagerLoginResult?, Error?) -> Void

public final class LoginManager {
    /// Not SDK API: the domain of the error every login reports.
    public static let shimErrorDomain = "OpenUIKit.FacebookLoginShim"

    public var defaultAudience: DefaultAudience = .friends

    public init() {}

    public func logIn(
        permissions: [String],
        from fromViewController: UIViewController?,
        handler: LoginManagerLoginResultBlock? = nil
    ) {
        guard let handler else { return }
        let error = NSError(domain: Self.shimErrorDomain, code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Facebook Login is not available on OpenUIKit (fail-closed shim)",
        ])
        DispatchQueue.main.async { handler(nil, error) }
    }

    public func logOut() {}
}
