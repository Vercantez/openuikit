import Foundation

/// A button that adds a signed order archive to Apple Wallet.
///
/// Darwin talks to Wallet. Linux stores the archive and completion, never
/// invokes the completion on construction, and never reports `.success`.
public struct AddOrderToWalletButton: View {
    public typealias Body = EmptyView

    let signedArchive: Data
    let onCompletion: (Result<FinanceStore.SaveOrderResult, any Error>) -> Void

    /// Creates an Add to Wallet button for a signed order archive.
    ///
    /// The completion is retained. Linux does not call it until
    /// `FinanceKitUIHostControl.failClosedPendingWalletButtons()`.
    public init(
        signedArchive: Data,
        onCompletion: @escaping (Result<FinanceStore.SaveOrderResult, any Error>) -> Void
    ) {
        self.signedArchive = signedArchive
        self.onCompletion = onCompletion
        FinanceKitUIHostState.shared.recordWalletButton(
            archive: signedArchive,
            completion: onCompletion
        )
    }

    /// Linux returns an empty view. The button is never drawn.
    public var body: EmptyView {
        EmptyView()
    }

    @_spi(OpenUIKitHost)
    public var hostArchive: Data {
        signedArchive
    }
}

/// Visual style for `AddOrderToWalletButton`.
///
/// Apple documents `black` and `blackOutline`. Linux stores the discriminator
/// and does not rasterize Wallet badge artwork.
public struct AddOrderToWalletButtonStyle: Equatable, Hashable, Sendable {
    enum Kind: UInt8, Sendable {
        case black = 0
        case blackOutline = 1
    }

    let kind: Kind

    public static let black = AddOrderToWalletButtonStyle(kind: .black)
    public static let blackOutline = AddOrderToWalletButtonStyle(kind: .blackOutline)
}

extension View {
    /// Sets the button's style.
    ///
    /// Linux records the style for host tests and returns `self`. Appearance
    /// does not change because there is no Wallet badge renderer.
    public func addOrderToWalletButtonStyle(_ style: AddOrderToWalletButtonStyle) -> Self {
        FinanceKitUIHostState.shared.recordWalletStyle(style)
        return self
    }
}
