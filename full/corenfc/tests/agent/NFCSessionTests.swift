import Dispatch
import Foundation
@_spi(OpenUIKitHost) import CoreNFC

func testReadingAvailableIsFalse() {
    precondition(NFCReaderSession.readingAvailable == false)
}

func testNDEFReaderSessionFailClosed() {
    let delegate = NFCRecordingNDEFDelegate()
    let session = NFCNDEFReaderSession(
        delegate: delegate,
        queue: CoreNFCHostControl.sessionQueue,
        invalidateAfterFirstRead: true
    )
    precondition(session.isReady == false)
    precondition(session.invalidateAfterFirstRead)
    precondition(session.delegate === delegate)
    precondition(session.sessionQueue === CoreNFCHostControl.sessionQueue)
    session.alertMessage = "hold near tag"
    precondition(session.alertMessage == "hold near tag")
    session.begin()
    nfcSpinUntil {
        delegate.lock.lock()
        defer { delegate.lock.unlock() }
        return delegate.invalidation != nil
    }
    delegate.lock.lock()
    let error = delegate.invalidation
    delegate.lock.unlock()
    precondition(nfcReaderError(error!).code == .readerErrorUnsupportedFeature)
}

func testNDEFReaderSessionConnectFails() {
    let delegate = NFCRecordingNDEFDelegate()
    let session = NFCNDEFReaderSession(
        delegate: delegate,
        queue: nil,
        invalidateAfterFirstRead: false
    )
    let tag = nfcHostTag()
    nfcExpectReaderCode(
        nfcAwait { try await session.connect(to: tag) },
        .readerTransceiveErrorTagNotConnected
    )
    session.restartPolling()
    precondition(session.isReady == false)
}

func testTagReaderSessionInitNil() {
    let delegate = NFCRecordingTagDelegate()
    precondition(
        NFCTagReaderSession(pollingOption: .iso14443, delegate: delegate, queue: nil) == nil
    )
}

func testTagReaderSessionHostConnectFails() {
    let delegate = NFCRecordingTagDelegate()
    let session = NFCTagReaderSession.hostMakeSession(
        pollingOption: [.iso14443, .iso15693],
        delegate: delegate
    )
    precondition(session.connectedTag == nil)
    precondition(session.pollingOption.contains(.iso15693))
    precondition(session.delegate === delegate)
    let tag = NFCTag.iso15693(nfcHostTag())
    let connectError = nfcWait { finish in
        session.connect(to: tag, completionHandler: finish)
    }
    precondition(nfcReaderError(connectError!).code == .readerTransceiveErrorTagNotConnected)
    nfcExpectReaderCode(
        nfcAwait { try await session.connect(to: tag) },
        .readerTransceiveErrorTagNotConnected
    )
    session.restartPolling()
}

func testPaymentTagReaderSession() {
    let delegate = NFCRecordingTagDelegate()
    let payment = NFCPaymentTagReaderSession(delegate: delegate, queue: nil)
    precondition(payment.delegate === delegate)
    precondition(payment.pollingOption.contains(.iso14443))
    payment.begin()
    nfcSpinUntil {
        delegate.lock.lock()
        defer { delegate.lock.unlock() }
        return delegate.invalidation != nil
    }
    delegate.lock.lock()
    let error = delegate.invalidation
    delegate.lock.unlock()
    precondition(nfcReaderError(error!).code == .readerErrorUnsupportedFeature)
}

func testVASReaderSession() {
    let delegate = NFCRecordingVASDelegate()
    let vas = NFCVASReaderSession(
        vasCommandConfigurations: [],
        delegate: delegate,
        queue: nil
    )
    precondition(vas.commandConfigurations.isEmpty)
    let queue = DispatchQueue(label: "CoreNFC.tests.vas")
    let labeled = NFCVASReaderSession(
        VASCommandConfigurations: [],
        delegate: delegate,
        queue: queue
    )
    precondition(labeled.sessionQueue === queue)
    vas.begin()
}

func testReaderSessionInvalidate() {
    let delegate = NFCRecordingNDEFDelegate()
    let session = NFCNDEFReaderSession(
        delegate: delegate,
        queue: DispatchQueue.global(),
        invalidateAfterFirstRead: false
    )
    session.invalidate()
    nfcSpinUntil {
        delegate.lock.lock()
        defer { delegate.lock.unlock() }
        return delegate.invalidation != nil
    }
    delegate.lock.lock()
    let canceled = delegate.invalidation
    delegate.lock.unlock()
    precondition(nfcReaderError(canceled!).code == .readerSessionInvalidationErrorUserCanceled)

    let second = NFCRecordingNDEFDelegate()
    let other = NFCNDEFReaderSession(
        delegate: second,
        queue: nil,
        invalidateAfterFirstRead: false
    )
    other.invalidate(errorMessage: "done")
    precondition(other.alertMessage == "done")
}

func testNDEFDelegateDefaults() {
    let delegate = NFCDefaultNDEFDelegate()
    let session = NFCNDEFReaderSession(
        delegate: delegate,
        queue: nil,
        invalidateAfterFirstRead: true
    )
    delegate.readerSession(session, didDetect: [nfcHostTag()])
    delegate.readerSessionDidBecomeActive(session)
}

func testVASDelegateDefault() {
    let delegate = NFCDefaultVASDelegate()
    let session = NFCVASReaderSession(
        vasCommandConfigurations: [],
        delegate: delegate,
        queue: nil
    )
    delegate.readerSessionDidBecomeActive(session)
    delegate.readerSession(session, didReceive: [])
    delegate.readerSession(session, didInvalidateWithError: NFCReaderError(.readerErrorUnsupportedFeature))
}

func testTagReaderSessionDelegateDidBecomeActive() {
    let delegate = NFCRecordingTagDelegate()
    let session = NFCTagReaderSession.hostMakeSession(
        pollingOption: .iso14443,
        delegate: delegate
    )
    delegate.tagReaderSessionDidBecomeActive(session)
    delegate.lock.lock()
    let active = delegate.becameActive
    delegate.lock.unlock()
    precondition(active)
    delegate.tagReaderSession(session, didDetect: [])
}
