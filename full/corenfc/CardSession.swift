import Foundation

/// Host card emulation. Linux has no NFC controller or presentment entitlement,
/// so construction and emulation fail closed.
open class CardSession: @unchecked Sendable {
    public enum Error: Swift.Error, Hashable, Sendable {
        case invalidated
        case userInvalidated
        case maxSessionDurationReached
        case transmissionError
        case systemNotAvailable
        case accessNotAccepted
        case systemEligibilityFailed
        case emulationStopped
        case radioDisabled

        public var localizedDescription: String {
            "CardSession is unavailable on this host (\(String(describing: self)))"
        }
    }

    public enum Event: Sendable {
        case sessionStarted
        case readerDetected
        case received(CardSession.APDU)
        case readerDeselected
        case sessionInvalidated(reason: CardSession.Error)
    }

    public enum EmulationUIStatus: Hashable, Sendable {
        case success
        case failure
    }

    public final class APDU: Equatable, CustomDebugStringConvertible, @unchecked Sendable {
        public let payload: Data

        init(payload: Data) {
            self.payload = payload
        }

        public static func == (lhs: APDU, rhs: APDU) -> Bool {
            lhs.payload == rhs.payload
        }

        public var debugDescription: String {
            "CardSession.APDU(payloadByteCount: \(payload.count))"
        }

        public func respond(response: Data) async throws {
            _ = response
            throw CardSession.Error.systemNotAvailable
        }
    }

    public final class EventStream: AsyncSequence, @unchecked Sendable {
        public typealias Element = CardSession.Event
        public typealias AsyncIterator = Iterator

        public class Iterator: AsyncIteratorProtocol, @unchecked Sendable {
            public typealias Element = CardSession.Event

            public func next() async throws -> CardSession.Event? {
                nil
            }
        }

        public func makeAsyncIterator() -> Iterator {
            Iterator()
        }
    }

    public class var isSupported: Bool { false }

    public static var isEligible: Bool {
        get async { false }
    }

    public var alertMessage: String = ""
    public let eventStream = EventStream()

    public var isEmulationInProgress: Bool {
        get async { false }
    }

    public init() async throws {
        throw Error.systemNotAvailable
    }

    public func startEmulation() async throws {
        throw Error.systemNotAvailable
    }

    public func stopEmulation(status: EmulationUIStatus) async {
        _ = status
    }

    public func invalidate() {}
}

public final class NFCPresentmentIntentAssertion: @unchecked Sendable {
    public enum Error: Swift.Error, Hashable, Sendable {
        case systemNotAvailable
        case systemEligibilityFailed

        public var localizedDescription: String {
            "NFC presentment intent is unavailable on this host"
        }
    }

    public var isValid: Bool { false }

    public static func acquire() async throws -> NFCPresentmentIntentAssertion {
        throw Error.systemNotAvailable
    }
}
