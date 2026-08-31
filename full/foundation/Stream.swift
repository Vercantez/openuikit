import FoundationEssentials

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("Foundation.Stream requires the ObjectiveC NSObject substrate")
#endif

/// The stream state shared by Foundation's in-memory request-body stream.
open class Stream: NSObject, @unchecked Sendable {
    public enum Status: UInt, Sendable {
        case notOpen = 0
        case opening = 1
        case open = 2
        case reading = 3
        case writing = 4
        case atEnd = 5
        case closed = 6
        case error = 7
    }

    internal let streamLock = NSLock()
    internal var mutableStatus: Status = .notOpen
    internal var mutableError: (any Error)?

    open var streamStatus: Status { streamLock.withLock { mutableStatus } }
    open var streamError: (any Error)? { streamLock.withLock { mutableError } }

    open func open() { streamLock.withLock { mutableStatus = .open } }
    open func close() { streamLock.withLock { mutableStatus = .closed } }
}

/// A byte input stream. The first production route is intentionally concrete:
/// an immutable Data value with deterministic cursor and EOF behavior.
open class InputStream: Stream, @unchecked Sendable {
    private let storage: Data
    private var position = 0

    public init(data: Data) {
        self.storage = data
        super.init()
    }

    open override func open() {
        streamLock.withLock {
            position = 0
            mutableError = nil
            mutableStatus = storage.isEmpty ? .atEnd : .open
        }
    }

    open override func close() {
        streamLock.withLock { mutableStatus = .closed }
    }

    open var hasBytesAvailable: Bool {
        streamLock.withLock {
            mutableStatus != .closed && position < storage.count
        }
    }

    open func read(
        _ buffer: UnsafeMutablePointer<UInt8>,
        maxLength len: Int
    ) -> Int {
        guard len >= 0 else { return -1 }
        if len == 0 { return 0 }
        return streamLock.withLock {
            guard mutableStatus != .closed else { return -1 }
            guard position < storage.count else {
                mutableStatus = .atEnd
                return 0
            }
            mutableStatus = .reading
            let count = min(len, storage.count - position)
            storage.copyBytes(to: buffer, from: position ..< position + count)
            position += count
            mutableStatus = position == storage.count ? .atEnd : .open
            return count
        }
    }
}
