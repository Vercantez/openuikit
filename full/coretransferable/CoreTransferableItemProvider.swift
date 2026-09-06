@_exported import Foundation

// Isolated Linux Foundation (swift-corelibs-foundation) does not vend
// Darwin's NSItemProvider. PhotosUI / SharedWithYou use the same host
// stand-in. The later guest Foundation port owns the real type; this
// class is compiled only when that type is absent. Register/load here
// is in-process typed storage plus Transferable export/import. It is
// not a pasteboard, share sheet, or NSItemProviderReading daemon.

#if os(Linux)

private final class _HostItemProviderStorage: @unchecked Sendable {
    let lock = NSLock()
    var values: [ObjectIdentifier: Any] = [:]
}

open class NSItemProvider: NSObject, @unchecked Sendable {
    fileprivate let _hostStorage = _HostItemProviderStorage()

    public override init() {
        super.init()
    }
}

#endif

extension NSItemProvider {
    /// Stores `transferable` for later `loadTransferable`. Linux evaluates
    /// the autoclosure immediately and keeps the value in-process. Apple's
    /// NSItemProvider re-encodes through registered UTIs on a pasteboard
    /// queue; that timing is unobserved here (oracle-questions.tsv).
    public func register<T>(_ transferable: @autoclosure @escaping () -> T)
    where T: Transferable {
        let value = transferable()
        #if os(Linux)
        _hostStorage.lock.lock()
        _hostStorage.values[ObjectIdentifier(T.self)] = value
        _hostStorage.lock.unlock()
        #else
        _ = value
        #endif
    }

    /// Completes the handler inline on this host. Apple's method returns
    /// Progress and may invoke the handler on another queue; that identity
    /// is unobserved (oracle-questions.tsv).
    @discardableResult
    public func loadTransferable<T>(
        type transferableType: T.Type,
        completionHandler: @escaping (Result<T, any Error>) -> Void
    ) -> Progress where T: Transferable {
        let progress = Progress(totalUnitCount: 1)
        #if os(Linux)
        _hostStorage.lock.lock()
        let stored = _hostStorage.values[ObjectIdentifier(transferableType)]
        _hostStorage.lock.unlock()
        if let value = stored as? T {
            completionHandler(.success(value))
        } else {
            completionHandler(
                .failure(
                    TransferableError.importNotSupported(contentType: "item-provider")
                )
            )
        }
        #else
        completionHandler(
            .failure(
                TransferableError.importNotSupported(contentType: "item-provider")
            )
        )
        #endif
        progress.completedUnitCount = 1
        return progress
    }
}
