import FoundationEssentials

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("Foundation.Stream requires the ObjectiveC NSObject substrate")
#endif

private enum _FoundationOutputStreamError: Error, Sendable {
    case capacityExceeded
}

/// The stream state shared by Foundation's in-memory request-body stream.
open class Stream: NSObject, @unchecked Sendable {
    public struct PropertyKey: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }

        public static let dataWrittenToMemoryStreamKey = PropertyKey(
            "NSStreamDataWrittenToMemoryStreamKey"
        )
        public static let fileCurrentOffsetKey = PropertyKey(
            "NSStreamFileCurrentOffsetKey"
        )
    }

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

    open func property(forKey key: PropertyKey) -> Any? {
        _ = key
        return nil
    }

    open func setProperty(_ property: Any?, forKey key: PropertyKey) -> Bool {
        _ = (property, key)
        return false
    }
}

/// A byte output stream backed by caller memory or growable in-process Data.
/// File and socket destinations are not silently accepted by this bounded
/// route; the two implemented designated initializers have real write and
/// capacity behavior.
open class OutputStream: Stream, @unchecked Sendable {
    private enum Destination: @unchecked Sendable {
        case memory
        case buffer(UnsafeMutablePointer<UInt8>, capacity: Int)
    }

    private let destination: Destination
    private var memory = Data()
    private var position = 0

    public init(toMemory: ()) {
        _ = toMemory
        destination = .memory
        super.init()
    }

    public init(
        toBuffer buffer: UnsafeMutablePointer<UInt8>,
        capacity: Int
    ) {
        precondition(capacity >= 0, "OutputStream capacity must be nonnegative")
        destination = .buffer(buffer, capacity: capacity)
        super.init()
    }

    open override func open() {
        streamLock.withLock {
            memory.removeAll(keepingCapacity: true)
            position = 0
            mutableError = nil
            mutableStatus = .open
        }
    }

    open override func close() {
        streamLock.withLock { mutableStatus = .closed }
    }

    open var hasSpaceAvailable: Bool {
        streamLock.withLock {
            guard mutableStatus == .open || mutableStatus == .writing
            else { return false }
            switch destination {
            case .memory:
                return true
            case .buffer(_, let capacity):
                return position < capacity
            }
        }
    }

    open func write(
        _ buffer: UnsafePointer<UInt8>,
        maxLength len: Int
    ) -> Int {
        guard len >= 0 else { return -1 }
        if len == 0 { return 0 }
        return streamLock.withLock {
            guard mutableStatus == .open || mutableStatus == .writing
            else { return -1 }
            mutableStatus = .writing
            switch destination {
            case .memory:
                memory.append(buffer, count: len)
                position += len
                mutableStatus = .open
                return len
            case .buffer(let destination, let capacity):
                guard len <= capacity - position else {
                    mutableError = _FoundationOutputStreamError.capacityExceeded
                    mutableStatus = .error
                    return -1
                }
                destination.advanced(by: position).update(
                    from: buffer,
                    count: len
                )
                position += len
                mutableStatus = .open
                return len
            }
        }
    }

    open override func property(forKey key: PropertyKey) -> Any? {
        streamLock.withLock {
            if key == .dataWrittenToMemoryStreamKey,
               case .memory = destination {
                return memory
            }
            if key == .fileCurrentOffsetKey {
                return position
            }
            return nil
        }
    }
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
