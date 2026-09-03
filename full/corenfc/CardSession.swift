import Foundation

public final class NFCPresentmentIntentAssertion: Sendable {
    public enum Error: Swift.Error, Hashable, Sendable {
        case systemNotAvailable
        case systemEligibilityFailed

        public var localizedDescription: String {
            switch self {
            case .systemNotAvailable:
                return "NFC presentment is unavailable on this Linux host"
            case .systemEligibilityFailed:
                return "NFC presentment eligibility cannot be established on this Linux host"
            }
        }
    }

    public let isValid: Bool = false

    public static func acquire() async throws -> NFCPresentmentIntentAssertion {
        throw Error.systemNotAvailable
    }
}

public final class CardSession: @unchecked Sendable {
    public enum EmulationUIStatus: Sendable, Hashable {
        case failure
        case success
    }

    public enum Error: Swift.Error, Hashable, Sendable {
        case transmissionError
        case maxSessionDurationReached
        case invalidated
        case radioDisabled
        case userInvalidated
        case emulationStopped
        case accessNotAccepted
        case systemNotAvailable
        case systemEligibilityFailed

        public var localizedDescription: String {
            "CardSession.\(self) is fail-closed on this Linux host"
        }
    }

    public enum Event: Sendable {
        case readerDetected
        case sessionStarted
        case readerDeselected
        case sessionInvalidated(reason: Error)
        case received(APDU)
    }

    public final class APDU: @unchecked Sendable, Equatable, CustomDebugStringConvertible {
        public let payload: Data

        public init(payload: Data) {
            self.payload = payload
        }

        public var debugDescription: String {
            "CardSession.APDU(payload: \(payload.count) bytes)"
        }

        public static func == (lhs: APDU, rhs: APDU) -> Bool {
            lhs.payload == rhs.payload
        }

        public func respond(response: Data) async throws {
            _ = response
            throw CardSession.Error.systemNotAvailable
        }
    }

    public final class EventStream: AsyncSequence, Sendable {
        public typealias Element = CardSession.Event
        public typealias AsyncIterator = Iterator

        public init() {}

        public final class Iterator: AsyncIteratorProtocol {
            public typealias Element = CardSession.Event
            private let lock = NSLock()
            private var consumed = false

            public init() {}

            public func next() async throws -> CardSession.Event? {
                let first: Bool = {
                    lock.lock()
                    defer { lock.unlock() }
                    if consumed {
                        return false
                    }
                    consumed = true
                    return true
                }()
                if first {
                    throw CardSession.Error.systemNotAvailable
                }
                return nil
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }
    }

    public static var isSupported: Bool { false }

    public static var isEligible: Bool {
        get async { false }
    }

    public var alertMessage: String = ""
    public var eventStream: EventStream { EventStream() }

    public var isEmulationInProgress: Bool {
        get async { false }
    }

    public init() async throws {
        throw Error.systemNotAvailable
    }

    public func invalidate() {}

    public func stopEmulation(status: EmulationUIStatus) async {
        _ = status
    }

    public func startEmulation() async throws {
        throw Error.systemNotAvailable
    }
}
