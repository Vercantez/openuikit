import Foundation

/// A style applied by ``View/managedContentStyle(_:)``.
public struct ManagedContentStyle: Hashable, Sendable {
    private let name: String

    private init(name: String) {
        self.name = name
    }

    public static let header = ManagedContentStyle(name: "header")
    public static let compact = ManagedContentStyle(name: "compact")
    public static let automatic = ManagedContentStyle(name: "automatic")

    @_spi(OpenUIKitHost)
    public var _linuxName: String { name }
}

/// Offer chrome state for ``ManagedContentView``.
///
/// Linux stores the documented cases and never talks to an install daemon.
public struct ManagedContentOfferState: Hashable, Sendable {
    private enum Kind: Hashable, Sendable {
        case installing(Double?)
        case notInstalled
        case neverInstalled
        case noninteractive
        case custom(String)
        case installed
    }

    private let kind: Kind

    private init(kind: Kind) {
        self.kind = kind
    }

    public static func installing(progress: Double?) -> ManagedContentOfferState {
        ManagedContentOfferState(kind: .installing(progress))
    }

    public static let notInstalled = ManagedContentOfferState(kind: .notInstalled)
    public static let neverInstalled = ManagedContentOfferState(kind: .neverInstalled)
    public static let noninteractive = ManagedContentOfferState(kind: .noninteractive)
    public static let installed = ManagedContentOfferState(kind: .installed)

    public static func custom(title: String) -> ManagedContentOfferState {
        ManagedContentOfferState(kind: .custom(title))
    }

    @_spi(OpenUIKitHost)
    public var _linuxProgress: Double? {
        if case .installing(let progress) = kind {
            return progress
        }
        return nil
    }

    @_spi(OpenUIKitHost)
    public var _linuxCustomTitle: String? {
        if case .custom(let title) = kind {
            return title
        }
        return nil
    }
}

/// Linux-only observation of the last ``managedContentStyle(_:)`` argument.
@_spi(OpenUIKitHost)
public enum ManagedContentStyleStorage {
    private static let lock = NSLock()
    private static var stored: ManagedContentStyle?

    public static var last: ManagedContentStyle? {
        get { lock.withLock { stored } }
        set { lock.withLock { stored = newValue } }
    }
}

extension View {
    /// Applies a managed content style to the view.
    ///
    /// Linux records the style and returns `self`. There is no Apple chrome.
    public func managedContentStyle(_ style: ManagedContentStyle) -> Self {
        ManagedContentStyleStorage.last = style
        return self
    }
}

/// A SwiftUI view that presents a managed app.
///
/// Linux stores the ``ManagedApp`` and renders its name as ``Text``. It does
/// not present App Store / MDM product chrome.
public struct ManagedAppView: View {
    public let app: ManagedApp

    public typealias Body = Text

    public nonisolated init(app: ManagedApp) {
        self.app = app
    }

    public var body: Text {
        Text(app.name)
    }
}

/// A SwiftUI view that presents managed content with an icon slot.
///
/// Linux stores labels, offer state, and the supplied icon. `body` is the
/// icon; there is no Apple offer button chrome.
public struct ManagedContentView<Icon: View>: View {
    public let primaryLabel: String
    public let secondaryLabel: String
    public let tertiaryLabel: String
    public let quaternaryLabel: String
    public let offerState: ManagedContentOfferState
    public let offerAction: (() -> Void)?
    public let icon: Icon

    public typealias Body = Icon

    public nonisolated init(
        primaryLabel: LocalizedStringKey,
        secondaryLabel: LocalizedStringKey = "",
        tertiaryLabel: LocalizedStringKey = "",
        quaternaryLabel: LocalizedStringKey = "",
        offerState: ManagedContentOfferState,
        offerAction: (() -> Void)? = nil,
        @ViewBuilder icon: () -> Icon
    ) {
        self.primaryLabel = primaryLabel.rawValue
        self.secondaryLabel = secondaryLabel.rawValue
        self.tertiaryLabel = tertiaryLabel.rawValue
        self.quaternaryLabel = quaternaryLabel.rawValue
        self.offerState = offerState
        self.offerAction = offerAction
        self.icon = icon()
    }

    public nonisolated init(
        primaryLabel: any StringProtocol,
        secondaryLabel: any StringProtocol = "",
        tertiaryLabel: any StringProtocol = "",
        quaternaryLabel: any StringProtocol = "",
        offerState: ManagedContentOfferState,
        offerAction: (() -> Void)? = nil,
        @ViewBuilder icon: () -> Icon
    ) {
        self.primaryLabel = String(primaryLabel)
        self.secondaryLabel = String(secondaryLabel)
        self.tertiaryLabel = String(tertiaryLabel)
        self.quaternaryLabel = String(quaternaryLabel)
        self.offerState = offerState
        self.offerAction = offerAction
        self.icon = icon()
    }

    public var body: Icon { icon }
}
