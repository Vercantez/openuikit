import Foundation

/// System action button used by marketplace product pages.
///
/// Darwin subclasses a UIKit control. Linux stores the documented properties
/// on a `UIControl` stand-in and never presents Apple chrome.
public final class ActionButton: UIControl, @unchecked Sendable {
    public enum Action {
        case batchInstall(BatchInstallConfiguration)
        case delete(AppleItemID)
        case launch(AppleItemID)
        case install(InstallConfiguration)
    }

    /// Overlay graph child order: `top`, `leading`, `bottom`, `trailing`.
    public enum ButtonImagePlacement: Int, Hashable, Sendable {
        case top = 0
        case leading = 1
        case bottom = 2
        case trailing = 3
    }

    public let action: Action
    public var label: String = ""
    public var imageName: String?
    public var imagePlacement: ButtonImagePlacement = .leading
    public var size: CGSize = .zero
    public var fontSize: CGFloat = 0
    public var cornerRadius: CGFloat = 0
    public var borderWidth: CGFloat = 0
    public var borderColor: UIColor = .black

    public init(action: Action) {
        self.action = action
        super.init()
        isEnabled = true
        isHighlighted = false
        backgroundColor = nil
        tintColor = UIColor.black
    }
}

/// Scene display request decoded from a marketplace URL or notification.
public enum MarketplaceDisplayOption: Sendable, Codable, Equatable {
    case productPage(appleItemID: AppleItemID, appleVersionID: AppleVersionID?)
    case searchResults(query: String)
    case authentication(account: String)
}

/// Delegate informed when a marketplace scene should show a display option.
public protocol MarketplaceSceneDelegate {
    func scene(_ scene: UIWindowScene, askedToDisplay option: MarketplaceDisplayOption)
}

/// Result of confirming a single install.
public enum InstallConfirmationResult {
    case cancel
    case confirmed(installVerificationToken: String, authenticationContext: LAContext?)
}

/// Result of confirming a batch install.
public enum BatchInstallConfirmationResult: Equatable {
    case cancel
    case confirmed(installVerificationTokens: [AppleItemID: String], authenticationContext: LAContext?)

    public static func == (a: BatchInstallConfirmationResult, b: BatchInstallConfirmationResult) -> Bool {
        switch (a, b) {
        case (.cancel, .cancel):
            return true
        case (
            .confirmed(let tokensA, let contextA),
            .confirmed(let tokensB, let contextB)
        ):
            return tokensA == tokensB && contextA === contextB
        default:
            return false
        }
    }
}

/// Metadata describing one alternative-distribution install.
public struct InstallMetadata: Sendable {
    public let account: String
    public let appleItemID: AppleItemID
    public let alternativeDistributionPackage: URL
    public let isUpdate: Bool
    public var appShareURL: URL?
    public var requestAgeException: Bool

    public init(
        account: String,
        appleItemID: AppleItemID,
        alternativeDistributionPackage: URL,
        isUpdate: Bool
    ) {
        self.account = account
        self.appleItemID = appleItemID
        self.alternativeDistributionPackage = alternativeDistributionPackage
        self.isUpdate = isUpdate
        self.appShareURL = nil
        self.requestAgeException = false
    }

    public init(
        account: String,
        appleItemID: AppleItemID,
        alternativeDistributionPackage: URL,
        isUpdate: Bool,
        appShareURL: URL?,
        requestAgeException: Bool = false
    ) {
        self.account = account
        self.appleItemID = appleItemID
        self.alternativeDistributionPackage = alternativeDistributionPackage
        self.isUpdate = isUpdate
        self.appShareURL = appShareURL
        self.requestAgeException = requestAgeException
    }
}

/// Configuration for a single `ActionButton` install action.
public struct InstallConfiguration {
    public let install: InstallMetadata
    public let confirmInstall: () async -> InstallConfirmationResult

    public init(
        install: InstallMetadata,
        confirmInstall: @escaping () async -> InstallConfirmationResult
    ) {
        self.install = install
        self.confirmInstall = confirmInstall
    }
}

/// Configuration for a batch `ActionButton` install action.
public struct BatchInstallConfiguration {
    public let installs: [InstallMetadata]
    public let confirmInstall: () async -> BatchInstallConfirmationResult

    public init(
        installs: [InstallMetadata],
        confirmInstall: @escaping () async -> BatchInstallConfirmationResult
    ) {
        self.installs = installs
        self.confirmInstall = confirmInstall
    }
}
