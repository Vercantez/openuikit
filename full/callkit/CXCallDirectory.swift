import Foundation

public protocol CXCallDirectoryExtensionContextDelegate: NSObjectProtocol {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: any Error)
}

open class CXCallDirectoryManager: NSObject, @unchecked Sendable {
    public enum EnabledStatus: Int, Hashable, Sendable {
        case unknown = 0
        case disabled = 1
        case enabled = 2
    }

    public static let sharedInstance = CXCallDirectoryManager()

    private override init() {
        super.init()
    }

    public func enabledStatusForExtension(
        withIdentifier identifier: String,
        completionHandler: @escaping (EnabledStatus, (any Error)?) -> Void
    ) {
        _ = identifier
        completionHandler(.unknown, CXErrorCodeCallDirectoryManagerError(.noExtensionFound))
    }

    public func enabledStatusForExtension(withIdentifier identifier: String) async throws -> EnabledStatus {
        try await withCheckedThrowingContinuation { continuation in
            self.enabledStatusForExtension(withIdentifier: identifier) { status, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: status)
                }
            }
        }
    }

    public func reloadExtension(
        withIdentifier identifier: String,
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _ = identifier
        completionHandler?(CXErrorCodeCallDirectoryManagerError(.noExtensionFound))
    }

    public func reloadExtension(withIdentifier identifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.reloadExtension(withIdentifier: identifier) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func openSettings(completionHandler completion: (((any Error)?) -> Void)? = nil) {
        let error = CXErrorCodeCallDirectoryManagerError(.noExtensionFound)
        completion?(error)
    }
}

open class CXCallDirectoryExtensionContext: NSObject, @unchecked Sendable {
    public weak var delegate: (any CXCallDirectoryExtensionContextDelegate)?
    public private(set) var isIncremental = false

    private let lock = NSLock()
    private var blocking: [CXCallDirectoryPhoneNumber] = []
    private var identification: [(CXCallDirectoryPhoneNumber, String)] = []

    public override init() {
        super.init()
    }

    @_spi(OpenUIKitHost)
    public convenience init(incremental: Bool) {
        self.init()
        self.isIncremental = incremental
    }

    public func addBlockingEntry(withNextSequentialPhoneNumber phoneNumber: CXCallDirectoryPhoneNumber) {
        lock.lock()
        defer { lock.unlock() }
        if let last = blocking.last, phoneNumber <= last {
            return
        }
        if phoneNumber < 0 {
            return
        }
        blocking.append(phoneNumber)
    }

    public func addIdentificationEntry(
        withNextSequentialPhoneNumber phoneNumber: CXCallDirectoryPhoneNumber,
        label: String
    ) {
        lock.lock()
        defer { lock.unlock() }
        if let last = identification.last?.0, phoneNumber <= last {
            return
        }
        identification.append((phoneNumber, label))
    }

    public func removeBlockingEntry(withPhoneNumber phoneNumber: CXCallDirectoryPhoneNumber) {
        lock.lock()
        defer { lock.unlock() }
        if !isIncremental {
            return
        }
        blocking.removeAll { $0 == phoneNumber }
    }

    public func removeAllBlockingEntries() {
        lock.lock()
        defer { lock.unlock() }
        if !isIncremental {
            return
        }
        blocking.removeAll()
    }

    public func removeIdentificationEntry(withPhoneNumber phoneNumber: CXCallDirectoryPhoneNumber) {
        lock.lock()
        defer { lock.unlock() }
        if !isIncremental {
            return
        }
        identification.removeAll { $0.0 == phoneNumber }
    }

    public func removeAllIdentificationEntries() {
        lock.lock()
        defer { lock.unlock() }
        if !isIncremental {
            return
        }
        identification.removeAll()
    }

    @_spi(OpenUIKitHost)
    public func hostBlockingEntries() -> [CXCallDirectoryPhoneNumber] {
        lock.lock()
        defer { lock.unlock() }
        return blocking
    }

    @_spi(OpenUIKitHost)
    public func hostIdentificationEntries() -> [(CXCallDirectoryPhoneNumber, String)] {
        lock.lock()
        defer { lock.unlock() }
        return identification
    }

    public func completeRequest(completionHandler completion: ((Bool) -> Void)? = nil) {
        let error = CXErrorCodeCallDirectoryManagerError(.noExtensionFound)
        let delegate = self.delegate
        if let delegate {
            delegate.requestFailed(for: self, withError: error)
        }
        completion?(false)
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
