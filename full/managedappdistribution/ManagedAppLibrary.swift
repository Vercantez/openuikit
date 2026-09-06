import Foundation

/// A representation of a library of managed apps.
///
/// Linux has no MDM client. `currentDistributor` is a process-local
/// singleton. `availableApps` yields one fail-closed
/// `.failure(.deviceNotManaged)` snapshot and then ends. Apple catalog
/// refresh, install, and metadata download never run.
public final class ManagedAppLibrary: @unchecked Sendable {
    /// The library provider for managed apps on this device.
    ///
    /// This is a singleton object.
    public static let currentDistributor = ManagedAppLibrary()

    /// The current managed apps available to this device.
    public var availableApps: ManagedApps {
        ManagedApps()
    }

    private init() {}

    /// Host-observable fail-closed catalog. Linux is not an MDM device.
    @_spi(OpenUIKitHost)
    public func _catalogSnapshot() -> Result<[ManagedApp], ManagedAppDistributionError> {
        .failure(.deviceNotManaged)
    }

    /// An array of managed apps that updates as apps become available or unavailable.
    public struct ManagedApps: AsyncSequence, Sendable {
        /// The type of element this asynchronous sequence produces.
        public typealias Element = Result<[ManagedApp], ManagedAppDistributionError>

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator()
        }

        /// The iterator for managed apps.
        public struct AsyncIterator: AsyncIteratorProtocol, Sendable {
            /// The type of element this asynchronous sequence produces.
            public typealias Element = Result<[ManagedApp], ManagedAppDistributionError>
            /// The type of failure produced by iteration.
            public typealias Failure = Never

            private var emitted = false

            /// Asynchronously advances to the next element and returns it, or ends the sequence if there is no next element.
            public mutating func next() async throws -> Element? {
                await next(isolation: nil)
            }

            /// Asynchronously advances to the next element and returns it, or ends the sequence if there is no next element.
            public mutating func next(isolation actor: isolated (any Actor)?) async throws(Failure) -> Element? {
                _ = actor
                if emitted {
                    return nil
                }
                emitted = true
                return .failure(.deviceNotManaged)
            }
        }
    }
}
