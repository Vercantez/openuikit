import Foundation

public protocol CXCallDirectoryExtensionContextDelegate: NSObjectProtocol {
    func requestFailed(
        for extensionContext: CXCallDirectoryExtensionContext,
        withError error: any Error
    )
}

open class CXCallDirectoryExtensionContext: NSObject, @unchecked Sendable {
    public weak var delegate: (any CXCallDirectoryExtensionContextDelegate)?
    public private(set) var isIncremental: Bool = false

    private var blocking: [CXCallDirectoryPhoneNumber] = []
    private var identification: [(CXCallDirectoryPhoneNumber, String)] = []
    private var pendingError: CXErrorCodeCallDirectoryManagerError?

    public override init() {
        super.init()
    }

    @_spi(OpenUIKitHost)
    public func _portableSetIncremental(_ isIncremental: Bool) {
        self.isIncremental = isIncremental
    }

    @_spi(OpenUIKitHost)
    public var _portableBlockingEntries: [CXCallDirectoryPhoneNumber] { blocking }

    @_spi(OpenUIKitHost)
    public var _portableIdentificationEntries: [(CXCallDirectoryPhoneNumber, String)] {
        identification
    }

    open func addBlockingEntry(withNextSequentialPhoneNumber phoneNumber: CXCallDirectoryPhoneNumber) {
        record(phoneNumber, into: &blocking, label: nil)
    }

    open func addIdentificationEntry(
        withNextSequentialPhoneNumber phoneNumber: CXCallDirectoryPhoneNumber,
        label: String
    ) {
        record(phoneNumber, intoIdentification: label)
    }

    open func removeBlockingEntry(withPhoneNumber phoneNumber: CXCallDirectoryPhoneNumber) {
        guard isIncremental else {
            pendingError = CXErrorCodeCallDirectoryManagerError(.unexpectedIncrementalRemoval)
            return
        }
        blocking.removeAll { $0 == phoneNumber }
    }

    open func removeIdentificationEntry(withPhoneNumber phoneNumber: CXCallDirectoryPhoneNumber) {
        guard isIncremental else {
            pendingError = CXErrorCodeCallDirectoryManagerError(.unexpectedIncrementalRemoval)
            return
        }
        identification.removeAll { $0.0 == phoneNumber }
    }

    open func removeAllBlockingEntries() {
        guard isIncremental else {
            pendingError = CXErrorCodeCallDirectoryManagerError(.unexpectedIncrementalRemoval)
            return
        }
        blocking.removeAll()
    }

    open func removeAllIdentificationEntries() {
        guard isIncremental else {
            pendingError = CXErrorCodeCallDirectoryManagerError(.unexpectedIncrementalRemoval)
            return
        }
        identification.removeAll()
    }

    /// Completing a request cannot install entries into an Apple Call Directory
    /// host that does not exist. Local validation still runs; the completion
    /// reports failure.
    open func completeRequest(completionHandler completion: ((Bool) -> Void)? = nil) {
        if let pendingError {
            delegate?.requestFailed(for: self, withError: pendingError)
            completion?(false)
            return
        }
        let unavailable = CXErrorCodeCallDirectoryManagerError(.noExtensionFound)
        delegate?.requestFailed(for: self, withError: unavailable)
        completion?(false)
    }

    private func record(
        _ phoneNumber: CXCallDirectoryPhoneNumber,
        into numbers: inout [CXCallDirectoryPhoneNumber],
        label: String?
    ) {
        _ = label
        if let last = numbers.last {
            if phoneNumber == last {
                pendingError = CXErrorCodeCallDirectoryManagerError(.duplicateEntries)
                return
            }
            if phoneNumber < last {
                pendingError = CXErrorCodeCallDirectoryManagerError(.entriesOutOfOrder)
                return
            }
        }
        numbers.append(phoneNumber)
    }

    private func record(
        _ phoneNumber: CXCallDirectoryPhoneNumber,
        intoIdentification label: String
    ) {
        if let last = identification.last {
            if phoneNumber == last.0 {
                pendingError = CXErrorCodeCallDirectoryManagerError(.duplicateEntries)
                return
            }
            if phoneNumber < last.0 {
                pendingError = CXErrorCodeCallDirectoryManagerError(.entriesOutOfOrder)
                return
            }
        }
        identification.append((phoneNumber, label))
    }
}

open class CXCallDirectoryProvider: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }

    open func beginRequest(with context: CXCallDirectoryExtensionContext) {
        _ = context
    }
}

open class CXCallDirectoryManager: NSObject, @unchecked Sendable {
    public enum EnabledStatus: Int, Equatable, Hashable, Sendable {
        case unknown = 0
        case disabled = 1
        case enabled = 2
    }

    public static let sharedInstance = CXCallDirectoryManager()

    private override init() {
        super.init()
    }

    open func reloadExtension(
        withIdentifier identifier: String,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        _ = identifier
        completion(CXErrorCodeCallDirectoryManagerError(.noExtensionFound))
    }

    open func reloadExtension(withIdentifier identifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reloadExtension(withIdentifier: identifier) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    open func enabledStatusForExtension(
        withIdentifier identifier: String,
        completionHandler completion: @escaping (EnabledStatus, (any Error)?) -> Void
    ) {
        _ = identifier
        completion(.unknown, CXErrorCodeCallDirectoryManagerError(.noExtensionFound))
    }

    open func enabledStatusForExtension(withIdentifier identifier: String) async throws -> EnabledStatus {
        try await withCheckedThrowingContinuation { continuation in
            enabledStatusForExtension(withIdentifier: identifier) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: .unknown)
                }
            }
        }
    }

    /// Linux has no Settings app or Call Directory UI.
    open func openSettings(completionHandler completion: (((any Error)?) -> Void)? = nil) {
        completion?(CXError(.unentitled))
    }
}
