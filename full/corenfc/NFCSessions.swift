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

    private let stateLock = NSLock()
    private var invalidated = false
    private var began = false

    public init(delegate: AnyObject?, queue: DispatchQueue?) {
        self.delegate = delegate
        self.sessionQueue = queue ?? coreNFCSessionQueue
        super.init()
    }

    public func begin() {
        let already: Bool = {
            stateLock.lock()
            defer { stateLock.unlock() }
            if began || invalidated {
                return true
            }
            began = true
            return false
        }()
        if already {
            return
        }
        let error = coreNFCUnsupportedError()
        sessionQueue.async { [weak self] in
            self?.finishInvalidation(error)
        }
    }

    public func invalidate() {
        finishInvalidation(coreNFCUnsupportedError(.readerSessionInvalidationErrorUserCanceled))
    }

    public func invalidate(errorMessage: String) {
        alertMessage = errorMessage
        finishInvalidation(
            NFCReaderError(
                .readerSessionInvalidationErrorUserCanceled,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        )
    }

    func restartPolling() {}

    func finishInvalidation(_ error: NFCReaderError) {
        let shouldNotify: Bool = {
            stateLock.lock()
            defer { stateLock.unlock() }
            if invalidated {
                return false
            }
            invalidated = true
            isReady = false
            return true
        }()
        guard shouldNotify else {
            return
        }
        notifyInvalidated(error)
    }

    func notifyInvalidated(_ error: NFCReaderError) {
        if let ndef = self as? NFCNDEFReaderSession,
           let delegate = delegate as? NFCNDEFReaderSessionDelegate {
            delegate.readerSession(ndef, didInvalidateWithError: error)
        } else if let tags = self as? NFCTagReaderSession,
                  let delegate = delegate as? NFCTagReaderSessionDelegate {
            delegate.tagReaderSession(tags, didInvalidateWithError: error)
        } else if let vas = self as? NFCVASReaderSession,
                  let delegate = delegate as? NFCVASReaderSessionDelegate {
            delegate.readerSession(vas, didInvalidateWithError: error)
        }
    }
}

public protocol NFCNDEFReaderSessionDelegate: NSObjectProtocol {
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error)
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage])
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag])
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession)
}

extension NFCNDEFReaderSessionDelegate {
    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {}
    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}
}

public class NFCNDEFReaderSession: NFCReaderSession {
    public let invalidateAfterFirstRead: Bool

    public init(
        delegate: any NFCNDEFReaderSessionDelegate,
        queue: DispatchQueue?,
        invalidateAfterFirstRead: Bool
    ) {
        self.invalidateAfterFirstRead = invalidateAfterFirstRead
        super.init(delegate: delegate, queue: queue)
    }

    public func connect(to tag: any NFCNDEFTag) async throws {
        throw coreNFCUnsupportedError(.readerTransceiveErrorTagNotConnected)
    }

    public override func restartPolling() {}
}

public protocol NFCTagReaderSessionDelegate: NSObjectProtocol {
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error)
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag])
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession)
}

public class NFCTagReaderSession: NFCReaderSession {
    public struct PollingOption: OptionSet, Sendable, Hashable {
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
        if !NFCReaderSession.readingAvailable {
            return nil
        }
        self.init(pollingOption: pollingOption, delegate: delegate, queue: queue, hostBypass: true)
    }

    init(
        pollingOption: PollingOption,
        delegate: any NFCTagReaderSessionDelegate,
        queue: DispatchQueue?,
        hostBypass: Bool
    ) {
        self.pollingOption = pollingOption
        super.init(delegate: delegate, queue: queue)
        _ = hostBypass
    }

    public override func restartPolling() {}

    public func connect(to tag: NFCTag, completionHandler: @escaping ((any Error)?) -> Void) {
        let error = coreNFCUnsupportedError(.readerTransceiveErrorTagNotConnected)
        sessionQueue.async {
            completionHandler(error)
        }
    }

    public func connect(to tag: NFCTag) async throws {
        throw coreNFCUnsupportedError(.readerTransceiveErrorTagNotConnected)
    }
}

public class NFCPaymentTagReaderSession: NFCTagReaderSession {
    public init(delegate: any NFCTagReaderSessionDelegate, queue: DispatchQueue? = nil) {
        super.init(
            pollingOption: [.iso14443],
            delegate: delegate,
            queue: queue,
            hostBypass: true
        )
    }
}

public protocol NFCVASReaderSessionDelegate: NSObjectProtocol {
    func readerSession(_ session: NFCVASReaderSession, didInvalidateWithError error: any Error)
    func readerSession(_ session: NFCVASReaderSession, didReceive responses: [NFCVASResponse])
    func readerSessionDidBecomeActive(_ session: NFCVASReaderSession)
}

extension NFCVASReaderSessionDelegate {
    public func readerSessionDidBecomeActive(_ session: NFCVASReaderSession) {}
}

public class NFCVASReaderSession: NFCReaderSession {
    public let commandConfigurations: [NFCVASCommandConfiguration]

    public init(
        vasCommandConfigurations commandConfigurations: [NFCVASCommandConfiguration],
        delegate: any NFCVASReaderSessionDelegate,
        queue: DispatchQueue?
    ) {
        self.commandConfigurations = commandConfigurations
        super.init(delegate: delegate, queue: queue)
    }

    public convenience init(
        VASCommandConfigurations commandConfigurations: [NFCVASCommandConfiguration],
        delegate: any NFCVASReaderSessionDelegate,
        queue: DispatchQueue?
    ) {
        self.init(
            vasCommandConfigurations: commandConfigurations,
            delegate: delegate,
            queue: queue
        )
    }
}

@_spi(OpenUIKitHost)
extension NFCTagReaderSession {
    public static func hostMakeSession(
        pollingOption: PollingOption,
        delegate: any NFCTagReaderSessionDelegate,
        queue: DispatchQueue? = nil
    ) -> NFCTagReaderSession {
        NFCTagReaderSession(
            pollingOption: pollingOption,
            delegate: delegate,
            queue: queue,
            hostBypass: true
        )
    }
}
