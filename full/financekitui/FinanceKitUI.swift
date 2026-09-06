@_exported import Foundation

#if canImport(FinanceKit)
@_exported import FinanceKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Linux starting point for Apple's public `FinanceKitUI` module.
///
/// Isolated host compilation has Foundation only. FinanceKit / UIKit /
/// SwiftUI / ExtensionKit types used by the public surface live in
/// `FinanceKitUILookalikes.swift` until those modules are on the link line.
/// Linux has no Wallet, no bank-connection extension host, and no
/// transaction-picker sheet: those paths stay fail-closed.
///
/// Darwin types: https://developer.apple.com/documentation/financekitui

/// Linux host-test control. Hidden from ordinary `import FinanceKitUI`
/// clients and not part of Apple's public FinanceKitUI surface.
@_spi(OpenUIKitHost)
public enum FinanceKitUIHostControl {
    public static func lastWalletArchive() -> Data? {
        FinanceKitUIHostState.shared.lastWalletArchive
    }

    public static func lastWalletStyle() -> AddOrderToWalletButtonStyle? {
        FinanceKitUIHostState.shared.lastWalletStyle
    }

    public static func pendingWalletCompletions() -> Int {
        FinanceKitUIHostState.shared.walletCompletions.count
    }

    /// Invokes every retained Wallet-button completion with
    /// `FinanceKitUIUnavailable.linuxHost` and clears the queue. Darwin calls
    /// the completion after the Wallet save UI; Linux has no Wallet and
    /// never reports `.success`.
    @discardableResult
    public static func failClosedPendingWalletButtons() -> Int {
        FinanceKitUIHostState.shared.failClosedWalletButtons()
    }

    public static func lastTransactionPickerPresented() -> Bool? {
        FinanceKitUIHostState.shared.lastPickerPresented
    }

    public static func lastTransactionPickerSelectionCount() -> Int? {
        FinanceKitUIHostState.shared.lastPickerSelectionCount
    }

    public static func lastAuthorizationDuplicateCompletes() -> Int {
        FinanceKitUIHostState.shared.lastAuthorizationDuplicateCompletes
    }

    public static func lastAuthorizationCompleted() -> Bool {
        FinanceKitUIHostState.shared.lastAuthorizationCompleted
    }

    public static func reset() {
        FinanceKitUIHostState.shared.reset()
    }
}

/// Fail-closed error for Wallet, financial-connection extensions,
/// entitlement, privacy-sheet, or Apple-service paths. Linux never invents a
/// successful Wallet save or bank authorization.
public enum FinanceKitUIUnavailable: Error, Equatable, Sendable {
    case linuxHost(operation: String)
}

final class FinanceKitUIHostState: @unchecked Sendable {
    static let shared = FinanceKitUIHostState()

    private let lock = NSLock()
    var lastWalletArchive: Data?
    var lastWalletStyle: AddOrderToWalletButtonStyle?
    var walletCompletions: [(Result<FinanceStore.SaveOrderResult, any Error>) -> Void] = []
    var lastPickerPresented: Bool?
    var lastPickerSelectionCount: Int?
    var lastAuthorizationDuplicateCompletes: Int = 0
    var lastAuthorizationCompleted: Bool = false

    func reset() {
        lock.lock()
        lastWalletArchive = nil
        lastWalletStyle = nil
        walletCompletions.removeAll()
        lastPickerPresented = nil
        lastPickerSelectionCount = nil
        lastAuthorizationDuplicateCompletes = 0
        lastAuthorizationCompleted = false
        lock.unlock()
    }

    func recordWalletButton(
        archive: Data,
        completion: @escaping (Result<FinanceStore.SaveOrderResult, any Error>) -> Void
    ) {
        lock.lock()
        lastWalletArchive = archive
        walletCompletions.append(completion)
        lock.unlock()
    }

    func recordWalletStyle(_ style: AddOrderToWalletButtonStyle) {
        lock.lock()
        lastWalletStyle = style
        lock.unlock()
    }

    func recordPicker(isPresented: Bool, selectionCount: Int) {
        lock.lock()
        lastPickerPresented = isPresented
        lastPickerSelectionCount = selectionCount
        lock.unlock()
    }

    func noteAuthorizationComplete(duplicate: Bool) {
        lock.lock()
        if duplicate {
            lastAuthorizationDuplicateCompletes += 1
        } else {
            lastAuthorizationCompleted = true
        }
        lock.unlock()
    }

    func failClosedWalletButtons() -> Int {
        lock.lock()
        let pending = walletCompletions
        walletCompletions.removeAll()
        lock.unlock()
        for completion in pending {
            completion(
                .failure(FinanceKitUIUnavailable.linuxHost(operation: "AddOrderToWalletButton"))
            )
        }
        return pending.count
    }
}
