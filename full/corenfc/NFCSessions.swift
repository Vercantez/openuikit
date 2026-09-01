import Foundation
import Dispatch

public protocol NFCReaderSessionProtocol: NSObjectProtocol {
    var alertMessage: String { get set }
    var isReady: Bool { get }
    func begin()
    func invalidate()
    func invalidate(errorMessage: String)
}

open class NFCReaderSession: NSObject, NFCReaderSessionProtocol {
    public class var readingAvailable: Bool { false }

    public private(set) weak var delegate: AnyObject?
    public let sessionQueue: DispatchQueue
    public var alertMessage: String = ""
    public private(set) var isReady: Bool = false
    private var invalidated = false

    public init(delegate: AnyObject?, sessionQueue: DispatchQueue) {
        self.delegate = delegate
        self.sessionQueue = sessionQueue
        super.init()
    }

    open func begin() {
        failClosed(code: .readerErrorUnsupportedFeature)
    }

    open func invalidate() {
        invalidated = true
        isReady = false
    }

    open func invalidate(errorMessage: String) {
        alertMessage = errorMessage
        failClosed(code: .readerErrorUnsupportedFeature)
    }

    func failClosed(code: NFCReaderError.Code) {
        invalidated = true
        isReady = false
        let error = NFCReaderError(code)
        let delegate = self.delegate
        if let ndef = self as? NFCNDEFReaderSession,
           let typed = delegate as? any NFCNDEFReaderSessionDelegate
        {
            sessionQueue.async {
                typed.readerSession(ndef, didInvalidateWithError: error)
            }
        } else if let tags = self as? NFCTagReaderSession,
                  let typed = delegate as? any NFCTagReaderSessionDelegate
        {
            sessionQueue.async {
                typed.tagReaderSession(tags, didInvalidateWithError: error)
            }
        } else if let vas = self as? NFCVASReaderSession,
                  let typed = delegate as? any NFCVASReaderSessionDelegate
        {
            sessionQueue.async {
                typed.readerSession(vas, didInvalidateWithError: error)
            }
        }
    }
}

public protocol NFCNDEFReaderSessionDelegate: NSObjectProtocol {
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage])
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag])
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error)
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession)
}

extension NFCNDEFReaderSessionDelegate {
    public func readerSession(
        _ session: NFCNDEFReaderSession,
        didDetect tags: [any NFCNDEFTag]
    ) {
        _ = (session, tags)
    }

    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        _ = session
    }
}

open class NFCNDEFReaderSession: NFCReaderSession {
    public let invalidateAfterFirstRead: Bool

    public init(
        delegate: any NFCNDEFReaderSessionDelegate,
        queue: DispatchQueue?,
        invalidateAfterFirstRead: Bool
    ) {
        self.invalidateAfterFirstRead = invalidateAfterFirstRead
        super.init(delegate: delegate, sessionQueue: _nfcDefaultSessionQueue(queue))
    }

    open func restartPolling() {}

    open func connect(to tag: any NFCNDEFTag) async throws {
        _ = tag
        try _nfcThrowUnsupported()
    }
}

public protocol NFCTagReaderSessionDelegate: NSObjectProtocol {
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error)
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag])
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession)
}

extension NFCTagReaderSessionDelegate {
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        _ = session
    }

    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        _ = (session, tags)
    }
}

open class NFCTagReaderSession: NFCReaderSession {
    public struct PollingOption: OptionSet, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let iso14443 = PollingOption(rawValue: 1 << 0)
        public static let iso15693 = PollingOption(rawValue: 1 << 1)
        public static let iso18092 = PollingOption(rawValue: 1 << 2)
        public static let pace = PollingOption(rawValue: 1 << 3)
    }

    public let pollingOption: PollingOption
    public private(set) var connectedTag: NFCTag?

    public convenience init?(
        pollingOption: PollingOption,
        delegate: any NFCTagReaderSessionDelegate,
        queue: DispatchQueue? = nil
    ) {
        if pollingOption.isEmpty { return nil }
        self.init(
            pollingOption: pollingOption,
            delegate: delegate,
            sessionQueue: _nfcDefaultSessionQueue(queue)
        )
    }

    public init(
        pollingOption: PollingOption,
        delegate: any NFCTagReaderSessionDelegate,
        sessionQueue: DispatchQueue
    ) {
        self.pollingOption = pollingOption
        super.init(delegate: delegate, sessionQueue: sessionQueue)
    }

    open func restartPolling() {}

    open func connect(to tag: NFCTag, completionHandler: @escaping ((any Error)?) -> Void) {
        _ = tag
        _nfcCompleteUnsupported(completionHandler)
    }

    open func connect(to tag: NFCTag) async throws {
        _ = tag
        try _nfcThrowUnsupported()
    }
}

open class NFCPaymentTagReaderSession: NFCTagReaderSession {
    public convenience init(
        delegate: any NFCTagReaderSessionDelegate,
        queue: DispatchQueue? = nil
    ) {
        self.init(
            pollingOption: [.iso14443, .pace],
            delegate: delegate,
            sessionQueue: _nfcDefaultSessionQueue(queue)
        )
    }
}

public protocol NFCVASReaderSessionDelegate: NSObjectProtocol {
    func readerSession(_ session: NFCVASReaderSession, didInvalidateWithError error: any Error)
    func readerSession(_ session: NFCVASReaderSession, didReceive responses: [NFCVASResponse])
    func readerSessionDidBecomeActive(_ session: NFCVASReaderSession)
}

extension NFCVASReaderSessionDelegate {
    public func readerSessionDidBecomeActive(_ session: NFCVASReaderSession) {
        _ = session
    }

    public func readerSession(
        _ session: NFCVASReaderSession,
        didReceive responses: [NFCVASResponse]
    ) {
        _ = (session, responses)
    }
}

open class NFCVASReaderSession: NFCReaderSession {
    public let commandConfigurations: [NFCVASCommandConfiguration]

    public init(
        vasCommandConfigurations commandConfigurations: [NFCVASCommandConfiguration],
        delegate: any NFCVASReaderSessionDelegate,
        queue: DispatchQueue?
    ) {
        self.commandConfigurations = commandConfigurations
        super.init(delegate: delegate, sessionQueue: _nfcDefaultSessionQueue(queue))
    }

    public init(
        VASCommandConfigurations commandConfigurations: [NFCVASCommandConfiguration],
        delegate: any NFCVASReaderSessionDelegate,
        queue: DispatchQueue?
    ) {
        self.commandConfigurations = commandConfigurations
        super.init(delegate: delegate, sessionQueue: _nfcDefaultSessionQueue(queue))
    }
}
