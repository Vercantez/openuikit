import Foundation
import ProximityReader

func testAsyncAccountLinking() async {
    let reader = PaymentCardReader()
    let token = PaymentCardReader.Token(rawValue: "link-token")
    do {
        try await reader.linkAccount(using: token)
        preconditionFailure("linkAccount must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "unsupported")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
    do {
        try await reader.relinkAccount(using: token)
        preconditionFailure("relinkAccount must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "unsupported")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
    do {
        _ = try await reader.isAccountLinked(using: token)
        preconditionFailure("isAccountLinked must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "unsupported")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
}

func testAsyncPrepareSessions() async {
    let reader = PaymentCardReader()
    let token = PaymentCardReader.Token(rawValue: "prepare-token")
    do {
        _ = try await reader.prepare(using: token)
        preconditionFailure("prepare must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "unsupported")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
    do {
        _ = try await reader.prepare(using: PaymentCardReader.Token(rawValue: ""))
        preconditionFailure("empty token must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "emptyReaderToken")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
    var sawUpdate = false
    do {
        _ = try await reader.prepare(using: token, updateHandler: { _ in sawUpdate = true })
        preconditionFailure("prepare with updateHandler must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "unsupported")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
    precondition(sawUpdate)
    do {
        _ = try await reader.prepareStoreAndForward()
        preconditionFailure("prepareStoreAndForward must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "storeAndForwardNotAllowed")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
}

func testAsyncStoreBatchRequests() async {
    let store = PaymentCardReaderStore()
    do {
        _ = try await store.fetchStoredPaymentCardReadResultBatch(size: 4)
        preconditionFailure("fetchStoredPaymentCardReadResultBatch must fail closed")
    } catch let error as PaymentCardReaderStore.StoreError {
        guard case .notAllowed = error else { preconditionFailure("expected notAllowed") }
    } catch {
        preconditionFailure("expected StoreError")
    }
    do {
        _ = try await store.fetchStoredPaymentCardReadResultCount()
        preconditionFailure("fetchStoredPaymentCardReadResultCount must fail closed")
    } catch let error as PaymentCardReaderStore.StoreError {
        guard case .notAllowed = error else { preconditionFailure("expected notAllowed") }
    } catch {
        preconditionFailure("expected StoreError")
    }
    do {
        _ = try await store.resolveBatch(
            batchDeletionToken: StoreAndForwardBatchDeletionToken(rawValue: "del-1")
        )
        preconditionFailure("resolveBatch must fail closed")
    } catch let error as PaymentCardReaderStore.StoreError {
        guard case .notAllowed = error else { preconditionFailure("expected notAllowed") }
    } catch {
        preconditionFailure("expected StoreError")
    }
    do {
        try await store.resetBatchState()
        preconditionFailure("resetBatchState must fail closed")
    } catch let error as PaymentCardReaderStore.StoreError {
        guard case .notAllowed = error else { preconditionFailure("expected notAllowed") }
    } catch {
        preconditionFailure("expected StoreError")
    }
}

func testAsyncSessionCardReads() async {
    let session = PaymentCardReaderSession()
    let transaction = PaymentCardTransactionRequest(amount: Decimal(9), currencyCode: "USD")
    let verification = PaymentCardVerificationRequest(currencyCode: "USD")
    let vas = VASRequest()
    do {
        _ = try await session.readPaymentCard(
            transaction, vasRequest: vas, stopOnVASResult: false, eventHandler: nil
        )
        preconditionFailure("readPaymentCard with VAS handler must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "readerNotAvailable")
    } catch {
        preconditionFailure("expected ReadError")
    }
    do {
        _ = try await session.readPaymentCard(
            transaction, vasRequest: vas, stopOnVASResult: true
        )
        preconditionFailure("readPaymentCard with VAS must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "readerNotAvailable")
    } catch {
        preconditionFailure("expected ReadError")
    }
    do {
        _ = try await session.readPaymentCard(transaction, eventHandler: nil)
        preconditionFailure("readPaymentCard transaction with handler must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "readerNotAvailable")
    } catch {
        preconditionFailure("expected ReadError")
    }
    do {
        _ = try await session.readPaymentCard(verification, eventHandler: nil)
        preconditionFailure("readPaymentCard verification with handler must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "readerNotAvailable")
    } catch {
        preconditionFailure("expected ReadError")
    }
    do {
        _ = try await session.readPaymentCard(transaction)
        preconditionFailure("readPaymentCard transaction must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "readerNotAvailable")
    } catch {
        preconditionFailure("expected ReadError")
    }
    do {
        _ = try await session.readPaymentCard(verification)
        preconditionFailure("readPaymentCard verification must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "readerNotAvailable")
    } catch {
        preconditionFailure("expected ReadError")
    }
}

func testAsyncSessionVASAndPIN() async {
    let session = PaymentCardReaderSession()
    let vas = VASRequest()
    do {
        _ = try await session.readVAS(vas, eventHandler: nil)
        preconditionFailure("readVAS with handler must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "vasReadFail")
    } catch {
        preconditionFailure("expected ReadError")
    }
    do {
        _ = try await session.readVAS(vas)
        preconditionFailure("readVAS must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "vasReadFail")
    } catch {
        preconditionFailure("expected ReadError")
    }
    do {
        _ = try await session.capturePIN(
            using: PaymentCardReaderSession.PINToken(rawValue: "pin"),
            cardReaderTransactionID: "txn-1"
        )
        preconditionFailure("capturePIN must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "pinNotAllowed")
    } catch {
        preconditionFailure("expected ReadError")
    }
    do {
        _ = try await session.cancelRead()
        preconditionFailure("cancelRead must fail closed")
    } catch let error as PaymentCardReaderSession.ReadError {
        precondition(error.errorName == "noReaderSession")
    } catch {
        preconditionFailure("expected ReadError")
    }
}

func testAsyncDiscoveryAndDocuments() async {
    let discovery = ProximityReaderDiscovery()
    do {
        _ = try await discovery.content(for: .payment(.howToTap))
        preconditionFailure("content must fail closed")
    } catch let error as ProximityReaderDiscovery.ContentError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected ContentError")
    }
    do {
        try await discovery.presentContent(
            ProximityReaderDiscovery.Content(id: "c1", description: "How to tap"),
            from: UIViewController()
        )
        preconditionFailure("presentContent must fail closed")
    } catch let error as ProximityReaderDiscovery.ContentError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected ContentError")
    }
    let documentReader = MobileDocumentReader()
    do {
        _ = try await documentReader.prepare(using: MobileDocumentReader.Token("doc-token"))
        preconditionFailure("MobileDocumentReader.prepare must fail closed")
    } catch let error as MobileDocumentReaderError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected MobileDocumentReaderError")
    }
    let documentSession = MobileDocumentReaderSession()
    let photoRequest = MobilePhotoIDDataRequest(
        retainedElements: [.givenName],
        nonRetainedElements: [.portrait]
    )
    do {
        let _: MobilePhotoIDDataRequest.Response = try await documentSession.requestDocument(photoRequest)
        preconditionFailure("requestDocument must fail closed")
    } catch let error as MobileDocumentReaderError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected MobileDocumentReaderError")
    }
    let forwardSession = StoreAndForwardPaymentCardReaderSession()
    do {
        _ = try await forwardSession.status()
        preconditionFailure("status must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "storeAndForwardNotAllowed")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
    do {
        try await forwardSession.decline()
        preconditionFailure("decline must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "storeAndForwardNotAllowed")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
}
