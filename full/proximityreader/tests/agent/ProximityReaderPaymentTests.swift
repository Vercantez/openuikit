import Foundation
import ProximityReader

func testPaymentCardReaderTokensAndOptions() {
    let token = PaymentCardReader.Token(rawValue: "psp-token")
    precondition(token.rawValue == "psp-token")
    precondition(PaymentCardReader.Token.RawValue.self == String.self)
    precondition(token == PaymentCardReader.Token(rawValue: "psp-token"))
    precondition(token != PaymentCardReader.Token(rawValue: "other"))
    _ = token.hashValue
    var hasher = Hasher()
    token.hash(into: &hasher)

    var options = PaymentCardReader.Options()
    precondition(options.vasMerchants.isEmpty)
    precondition(options.includeErrorInReadResult == false)
    precondition(options.returnReadResultImmediately == false)
    let merchant = VASRequest.Merchant(id: "merchant.example")
    options = PaymentCardReader.Options(vasMerchants: [merchant])
    precondition(options.vasMerchants.count == 1)
    options.includeErrorInReadResult = true
    options.returnReadResultImmediately = true
    precondition(options.includeErrorInReadResult)
    precondition(options.returnReadResultImmediately)
}


func testPaymentCardReaderIsUnsupported() {
    precondition(PaymentCardReader.isSupported == false)
    let reader = PaymentCardReader()
    precondition(!reader.id.isEmpty)
    precondition(reader.options.vasMerchants.isEmpty)
    let withOptions = PaymentCardReader(options: PaymentCardReader.Options())
    precondition(withOptions.options.returnReadResultImmediately == false)
    do {
        _ = try reader.fetchPaymentCardReaderStore()
        preconditionFailure("store fetch must fail closed")
    } catch let error as PaymentCardReaderError {
        precondition(error.errorName == "unsupported")
    } catch {
        preconditionFailure("expected PaymentCardReaderError")
    }
}


func testPaymentCardReaderEventNames() {
    let events: [PaymentCardReader.Event] = [
        .removeCard, .readyForTap, .cardDetected, .readCancelled, .readCompleted,
        .updateProgress(40), .readNotCompleted, .pinEntryCompleted, .pinEntryRequested,
        .userInterfaceDismissed, .notReady, .readRetry,
    ]
    let names = events.map(\.name)
    precondition(names.contains("readyForTap"))
    precondition(PaymentCardReader.Event.updateProgress(1).name == "updateProgress")
    precondition(PaymentCardReader.UpdateEvent.notReady.name == "notReady")
    precondition(PaymentCardReader.UpdateEvent.progress(12).name == "progress")
}


func testPaymentCardReaderErrorCases() {
    let cases: [PaymentCardReaderError] = [
        .serviceConnectionError, .networkAuthenticationError, .emptyReaderToken,
        .invalidReaderToken("bad"), .networkError, .notAllowed, .readerBusy,
        .unsupported, .deviceBanned(nil), .tokenExpired, .prepareFailed("x"),
        .prepareExpired, .invalidMerchant, .merchantBlocked, .accountNotLinked,
        .passcodeDisabled, .readerMemoryFull, .modelNotSupported, .accountDeactivated,
        .requestInterrupted, .accountAlreadyLinked, .accountLinkingFailed,
        .osVersionNotSupported, .accountLinkingCancelled, .accountLinkingCheckFailed,
        .storeAndForwardNotAllowed, .backgroundRequestNotAllowed,
        .storeAndForwardSessionExpired, .storeAndForwardSessionInvalidated,
        .storeAndForwardTokenIssuerChanged, .accountLinkingRequiresiCloudSignIn,
        .unknown(code: 99), .notReady,
    ]
    precondition(cases.count == 33)
    precondition(PaymentCardReaderError.unsupported.errorName == "unsupported")
    precondition(PaymentCardReaderError.emptyReaderToken.errorDescription.contains("emptyReaderToken"))
    precondition(PaymentCardReaderError.unknown(code: 7).localizedDescription.contains("unknown"))
    precondition(PaymentCardReaderError.invalidReaderToken(nil).errorName == "invalidReaderToken")
    precondition(PaymentCardReaderError.deviceBanned(Date()).errorName == "deviceBanned")
    precondition(PaymentCardReaderError.prepareFailed(nil).errorName == "prepareFailed")
}


func testPaymentCardReaderStoreErrorCases() {
    let cases: [PaymentCardReaderStore.StoreError] = [
        .networkError, .notAllowed, .passcodeDisabled, .storeAndForwardBatchNotFound,
        .storeAndForwardResultsNotFound, .storeAndForwardBatchSizeInvalid,
        .storeAndForwardBatchAlreadyExists, .storeAndForwardDeletionTokenExpired,
        .storeAndForwardDeletionTokenInvalid, .busy, .unknown(code: 3),
    ]
    precondition(cases.count == 11)
    precondition(PaymentCardReaderStore.StoreError.notAllowed.localizedDescription.contains("notAllowed"))
    precondition(PaymentCardReaderStore.StoreError.unknown(code: 3).localizedDescription.contains("3"))
    _ = PaymentCardReaderStore()
}


func testPaymentCardReaderSessionEventCases() {
    let events: [PaymentCardReaderSession.Event] = [
        .removeCard, .readyForTap, .cardDetected, .readCancelled,
        .readNotCompleted, .retry, .completed,
    ]
    precondition(events[1].name == "readyForTap")
    precondition(PaymentCardReaderSession.Event.retry == .retry)
    precondition(PaymentCardReaderSession.Event.completed != .retry)
    _ = PaymentCardReaderSession.Event.cardDetected.hashValue
    var hasher = Hasher()
    PaymentCardReaderSession.Event.readyForTap.hash(into: &hasher)
}


func testPaymentCardReaderSessionReadErrorCases() {
    let cases: [PaymentCardReaderSession.ReadError] = [
        .readerServiceError, .readFromBackgroundError, .readerServiceConnectionError,
        .noReaderSession, .vasReadFail, .cardReadFailed, .readerSessionBusy,
        .readerSessionExpired, .readerSessionAuthenticationError, .readerSessionNetworkError,
        .paymentCardDeclined, .paymentReadFailed, .nfcDisabled, .pinCancelled,
        .invalidAmount, .pinNotAllowed, .readCancelled, .pinEntryFailed, .readNotAllowed,
        .pinEntryTimeout, .pinTokenInvalid, .cardNotSupported, .passcodeDisabled,
        .readerNotAvailable, .readerTokenExpired, .invalidCurrencyCode, .invalidPreferredAID,
        .invalidVASMerchants("m"), .readNotAllowedDuringCall, .readerInitializationFailed,
        .invalidVASRequestParameters(nil), .storeAndForwardDeclineFailed,
        .storeAndForwardResultNotFound, .unknown(code: 1),
    ]
    precondition(cases.count == 34)
    precondition(PaymentCardReaderSession.ReadError.nfcDisabled.errorName == "nfcDisabled")
    precondition(PaymentCardReaderSession.ReadError.invalidAmount.errorDescription.contains("invalidAmount"))
    precondition(PaymentCardReaderSession.ReadError.readerNotAvailable.localizedDescription.contains("readerNotAvailable"))
}


func testPINToken() {
    let pin = PaymentCardReaderSession.PINToken(rawValue: "pin-1")
    precondition(pin.rawValue == "pin-1")
    precondition(PaymentCardReaderSession.PINToken.RawValue.self == String.self)
    precondition(pin != PaymentCardReaderSession.PINToken(rawValue: "pin-2"))
    _ = pin.hashValue
    var hasher = Hasher()
    pin.hash(into: &hasher)
}


func testVASRequestAndMerchant() {
    let url = URL(string: "https://vas.example/callback")!
    let a = VASRequest.Merchant(id: "m1", url: url, localizedName: "Cafe")
    precondition(a.id == "m1")
    precondition(a.url == url)
    precondition(a.shouldSendURLOnly == false)
    precondition(a.localizedName == "Cafe")
    let b = VASRequest.Merchant(id: "m2", url: nil, shouldSendURLOnly: true, localizedName: "Bar")
    precondition(b.shouldSendURLOnly)
    precondition(VASRequest.Merchant.ID.self == String.self)
    let request = VASRequest(vasMerchants: [a, b], localizedVASType: "loyalty")
    precondition(request.vasMerchants.count == 2)
    precondition(request.localizedVASType == "loyalty")
    precondition(request.userInterfaceLanguage == nil)
    request.userInterfaceLanguage = Locale.Language(identifier: "en")
    precondition(request.userInterfaceLanguage != nil)
}


func testVASReadResultAndStatusRawValues() {
    precondition(VASReadResult.ReadEntry.Status.success.rawValue == 0)
    precondition(VASReadResult.ReadEntry.Status.vasDataNotFound.rawValue == 1)
    precondition(VASReadResult.ReadEntry.Status.vasDataNotActivated.rawValue == 2)
    precondition(VASReadResult.ReadEntry.Status.wrongP1P2.rawValue == 3)
    precondition(VASReadResult.ReadEntry.Status.wrongCommandLength.rawValue == 4)
    precondition(VASReadResult.ReadEntry.Status.userInterventionRequired.rawValue == 5)
    precondition(VASReadResult.ReadEntry.Status.incorrectData.rawValue == 6)
    precondition(VASReadResult.ReadEntry.Status.unsupportedApplicationVersion.rawValue == 7)
    precondition(VASReadResult.ReadEntry.Status(rawValue: 0) == .success)
    precondition(VASReadResult.ReadEntry.Status(rawValue: 99) == nil)
    precondition(VASReadResult.ReadEntry.Status.success != .incorrectData)
    _ = VASReadResult.ReadEntry.Status.success.hashValue
    var hasher = Hasher()
    VASReadResult.ReadEntry.Status.wrongP1P2.hash(into: &hasher)
    let entry = VASReadResult.ReadEntry(
        id: "e1",
        customerVASData: Data([0x01]),
        status: .success
    )
    precondition(entry.id == "e1")
    precondition(entry.customerVASData?.count == 1)
    precondition(entry.status == .success)
    precondition(VASReadResult.ReadEntry.ID.self == String.self)
    let result = VASReadResult(id: "r1", entries: [entry])
    precondition(result.id == "r1")
    precondition(result.entries.count == 1)
    precondition(VASReadResult.ID.self == String.self)
}


func testPaymentCardReadResultEnums() {
    let states: [PaymentCardReadResult.CardEffectiveState] = [.active, .invalid, .unknown, .inactive]
    precondition(states.contains(.active))
    precondition(PaymentCardReadResult.CardEffectiveState.active != .inactive)
    _ = PaymentCardReadResult.CardEffectiveState.active.hashValue
    var hasher = Hasher()
    PaymentCardReadResult.CardEffectiveState.invalid.hash(into: &hasher)

    let exp: [PaymentCardReadResult.CardExpirationState] = [.notExpired, .expired, .invalid, .unknown]
    precondition(exp.contains(.expired))
    precondition(PaymentCardReadResult.CardExpirationState.expired != .notExpired)
    _ = PaymentCardReadResult.CardExpirationState.expired.hashValue
    PaymentCardReadResult.CardExpirationState.unknown.hash(into: &hasher)

    let outcomes: [PaymentCardReadResult.ReadOutcome] = [.cardDeclined, .failure, .success]
    precondition(outcomes.contains(.success))
    precondition(PaymentCardReadResult.ReadOutcome.success != .failure)
    _ = PaymentCardReadResult.ReadOutcome.success.hashValue
    PaymentCardReadResult.ReadOutcome.failure.hash(into: &hasher)
}


func testPaymentCardReadResultFields() {
    let result = PaymentCardReadResult(
        id: "tx-1",
        generalCardData: "gen",
        paymentCardData: "pay",
        pinBypassed: true,
        isPINFallback: false,
        cardEffectiveState: .active,
        cardExpirationState: .notExpired,
        applicationTypeIdentifier: "A000000003",
        outcome: .success
    )
    precondition(result.id == "tx-1")
    precondition(result.generalCardData == "gen")
    precondition(result.paymentCardData == "pay")
    precondition(result.pinBypassed)
    precondition(result.isPINFallback == false)
    precondition(result.cardEffectiveState == .active)
    precondition(result.cardExpirationState == .notExpired)
    precondition(result.applicationTypeIdentifier == "A000000003")
    precondition(result.outcome == .success)
    precondition(PaymentCardReadResult.ID.self == String.self)
}


func testPaymentCardTransactionRequest() {
    let request = PaymentCardTransactionRequest(amount: Decimal(12.50), currencyCode: "USD")
    precondition(request.amount == Decimal(12.50))
    precondition(request.currencyCode == "USD")
    precondition(request.type == .purchase)
    precondition(request.preferredAIDList.isEmpty)
    precondition(request.useISOCurrencySymbol == false)
    precondition(request.userInterfaceLanguage == nil)
    precondition(request.transactionDescription == nil)
    var refund = PaymentCardTransactionRequest(amount: 3, currencyCode: "EUR", for: .refund)
    precondition(refund.type == .refund)
    refund.preferredAIDList = [Data([0xA0])]
    refund.useISOCurrencySymbol = true
    refund.userInterfaceLanguage = Locale.Language(identifier: "fr")
    refund.transactionDescription = .surchargePercent(2.5)
    precondition(refund.preferredAIDList.count == 1)
    precondition(refund.useISOCurrencySymbol)
    switch refund.transactionDescription {
    case .surchargePercent(let value):
        precondition(value == 2.5)
    default:
        preconditionFailure("expected surchargePercent")
    }
}


func testPaymentCycleAndAmountDescription() {
    let cycles: [PaymentCardTransactionRequest.PaymentCycle] = [.weekly, .yearly, .monthly]
    precondition(cycles.contains(.monthly))
    precondition(PaymentCardTransactionRequest.PaymentCycle.weekly != .yearly)
    _ = PaymentCardTransactionRequest.PaymentCycle.monthly.hashValue
    var hasher = Hasher()
    PaymentCardTransactionRequest.PaymentCycle.weekly.hash(into: &hasher)
    precondition(PaymentCardTransactionRequest.TransactionType.purchase != .refund)
    _ = PaymentCardTransactionRequest.TransactionType.purchase.hashValue
    PaymentCardTransactionRequest.TransactionType.refund.hash(into: &hasher)

    let descriptions: [PaymentCardTransactionRequest.TransactionAmountDescription] = [
        .preauthorizationAmount(Decimal(10)),
        .surchargeAmount(Decimal(1)),
        .membership(.monthly),
        .installment(.yearly, amount: Decimal(20), payments: 12),
        .preauthorization,
        .surchargePercent(1.5),
        .preauthorizationRelease,
    ]
    precondition(descriptions.count == 7)
}


func testPaymentCardVerificationRequest() {
    let request = PaymentCardVerificationRequest(currencyCode: "USD")
    precondition(request.currencyCode == "USD")
    precondition(request.verificationReason == .other)
    let lookup = PaymentCardVerificationRequest(currencyCode: "GBP", for: .lookUp)
    precondition(lookup.verificationReason == .lookUp)
    let reasons: [PaymentCardVerificationRequest.Reason] = [.saveCard, .other, .lookUp, .openTab]
    precondition(reasons.count == 4)
    precondition(PaymentCardVerificationRequest.Reason.saveCard != .openTab)
    _ = PaymentCardVerificationRequest.Reason.other.hashValue
    var hasher = Hasher()
    PaymentCardVerificationRequest.Reason.openTab.hash(into: &hasher)
}


func testStoreAndForwardTypes() {
    let token = StoreAndForwardBatchDeletionToken(rawValue: "del-1")
    precondition(token.rawValue == "del-1")
    precondition(StoreAndForwardBatchDeletionToken.RawValue.self == String.self)
    precondition(token != StoreAndForwardBatchDeletionToken(rawValue: "del-2"))
    _ = token.hashValue
    var hasher = Hasher()
    token.hash(into: &hasher)

    let stored = StoreAndForwardBatch.StoredPaymentCardReadResult(
        id: "p1",
        generalCardData: "g",
        paymentCardData: "p",
        signature: "sig"
    )
    precondition(stored.id == "p1")
    precondition(stored.generalCardData == "g")
    precondition(stored.paymentCardData == "p")
    precondition(stored.signature == "sig")
    precondition(StoreAndForwardBatch.StoredPaymentCardReadResult.ID.self == String.self)

    let batch = StoreAndForwardBatch(
        id: "b1",
        payments: [stored],
        signature: "batch-sig",
        leafCertificate: "leaf",
        intermediateCertificate: ["int"]
    )
    precondition(batch.id == "b1")
    precondition(batch.count == 1)
    precondition(batch.payments.count == 1)
    precondition(batch.signature == "batch-sig")
    precondition(batch.leafCertificate == "leaf")
    precondition(batch.intermediateCertificate == ["int"])
    precondition(StoreAndForwardBatch.ID.self == String.self)

    let encoded = try! JSONEncoder().encode(batch)
    precondition(!encoded.isEmpty)
    let storedEncoded = try! JSONEncoder().encode(stored)
    precondition(!storedEncoded.isEmpty)

    let status = StoreAndForwardStatus(expiration: Date(timeIntervalSince1970: 0), readCount: 2)
    precondition(status.readCount == 2)
    precondition(status.expiration.timeIntervalSince1970 == 0)
    precondition(status == StoreAndForwardStatus(expiration: Date(timeIntervalSince1970: 0), readCount: 2))
    precondition(status != StoreAndForwardStatus(expiration: Date(timeIntervalSince1970: 0), readCount: 3))
    _ = status.hashValue
    status.hash(into: &hasher)
}


func testSessionLinuxHostConstruction() {
    let session = PaymentCardReaderSession()
    precondition(!session.id.isEmpty)
    precondition(session.currentOSVersionDeprecationDate == nil)
    _ = StoreAndForwardPaymentCardReaderSession()
    _ = MobileDocumentReaderSession()
}


func testFoundationValuesThroughPublicAPI() {
    let amount = Decimal(string: "19.99")!
    let request = PaymentCardTransactionRequest(amount: amount, currencyCode: "USD")
    precondition(request.amount == amount)
    let data = Data("iso".utf8)
    var withAID = request
    withAID.preferredAIDList = [data]
    precondition(withAID.preferredAIDList.first == data)
    let token = PaymentCardReader.Token(rawValue: UUID().uuidString)
    precondition(!token.rawValue.isEmpty)
    let language = Locale.Language(identifier: "en-US")
    let vas = VASRequest()
    vas.userInterfaceLanguage = language
    precondition(vas.userInterfaceLanguage == language)
}
