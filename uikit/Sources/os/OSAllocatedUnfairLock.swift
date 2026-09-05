// OSAllocatedUnfairLock — a real mutex with Apple's iOS 16 surface.
//
// Measured scratch/ladder-corpus 2026-09-05:
//   * OSAllocatedUnfairLock(initialState:) — NetNewsWire Cache.swift:24,
//     NewsBlurAPICaller.swift:20/26, Hackers Shared DependencyContainer.swift:85,
//     WordPress UploadFilenameAllocator.swift:17, pocket-casts FileLog.swift:119
//   * OSAllocatedUnfairLock() (State == Void) — nextcloud NotificationService.swift:31
//     then `withLock { … }` with a no-argument closure (line 127)
//   * withLock { $0 } / withLock { $0 = newValue } (Hackers DependencyContainer)
//   * withLock { state in … } (NetNewsWire Cache)
//   * withLockUnchecked is Apple's unchecked sibling of withLock; the corpus
//     does not call it, but the brief names the same three-entry API.
// pthread_mutex (not a no-op): two threads incrementing 1000 times each
// observe 2000 (OSAllocatedUnfairLockTests).

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

public struct OSAllocatedUnfairLock<State>: @unchecked Sendable {
    private final class Storage: @unchecked Sendable {
        var state: State
        private var mutex = pthread_mutex_t()

        init(_ state: State) {
            self.state = state
            pthread_mutex_init(&mutex, nil)
        }

        deinit {
            pthread_mutex_destroy(&mutex)
        }

        func lock() {
            pthread_mutex_lock(&mutex)
        }

        func unlock() {
            pthread_mutex_unlock(&mutex)
        }
    }

    private let storage: Storage

    public init(initialState: State) {
        storage = Storage(initialState)
    }

    public init(uncheckedState initialState: State) {
        storage = Storage(initialState)
    }

    public func withLock<R>(_ body: (inout State) throws -> R) rethrows -> R {
        try locked(body)
    }

    public func withLockUnchecked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        try locked(body)
    }

    fileprivate func locked<R>(_ body: (inout State) throws -> R) rethrows -> R {
        storage.lock()
        defer { storage.unlock() }
        return try body(&storage.state)
    }
}

extension OSAllocatedUnfairLock where State == Void {
    public init() {
        self.init(initialState: ())
    }

    public func withLock<R>(_ body: () throws -> R) rethrows -> R {
        try locked { (_: inout Void) in
            try body()
        }
    }

    public func withLockUnchecked<R>(_ body: () throws -> R) rethrows -> R {
        try locked { (_: inout Void) in
            try body()
        }
    }
}
