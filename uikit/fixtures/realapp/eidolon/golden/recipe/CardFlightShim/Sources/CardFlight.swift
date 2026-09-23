import Foundation

// CardFlight-v4 4.3.1 FAIL-CLOSED SHIM -- "call-site-derived".
//
// The locked pod (CardFlight-v4 4.3.1, a closed binary framework from
// https://github.com/CardFlight/cardflight-v4-ios.git tag v4.3.1) is not
// retrievable ("Repository not found"), and no public headers exist. Every
// declaration below is derived ONLY from how artsy/eidolon 44486ed uses the
// SDK: Kiosk/App/CardHandler.swift (all CFT* types, the delegate protocol and
// every enum case the app switches over), Kiosk/Admin/AdminCardTestingViewController.swift
// and Kiosk/Bid Fulfillment/SwipeCreditCardViewController.swift (CFTCardInfo
// fields), and KioskTests/CardHandlerTests.swift (default initializers and the
// overridable beginTokenizing). Nothing here reflects the real SDK's internals.
//
// Fail-closed contract: no card reader is ever reported, no credentials are
// ever accepted, no tokenization/transaction ever completes, and no card data
// or token is ever produced. The only delegate traffic is "zero readers" and
// an .unknown state carrying CFTShimError.serviceUnavailable.

public enum CFTShimError: Error {
    case serviceUnavailable
}

// CardHandler.swift:66-83 switches exhaustively over exactly these cases.
@objc public enum CFTTransactionState: Int {
    case unknown
    case pendingTransactionParameters
    case pendingCardInput
    case pendingProcessOption
    case processing
    case deferred
    case completed
}

// CardHandler.swift:62,114.
@objc public enum CFTProcessOption: Int {
    case abort
    case process
}

// CardHandler.swift:78 (`cardReader?.cardReaderModel ?? .unknown`).
@objc public enum CFTCardReaderModel: Int {
    case unknown
}

// CardHandler.swift:135.
@objc public enum CFTCVM: Int {
    case signature
}

// CardHandler.swift:142-180 switches exhaustively over exactly these cases.
@objc public enum CFTCardReaderEvent: Int {
    case unknown
    case disconnected
    case connected
    case connectionErrored
    case cardSwiped
    case cardSwipeErrored
    case cardInserted
    case cardInsertErrored
    case cardRemoved
    case cardTapped
    case cardTapErrored
    case updateStarted
    case updateCompleted
    case audioRecordingPermissionNotGranted
    case fatalError
    case connecting
    case batteryStatusUpdated
}

// CardHandler.swift:9,78,105.
open class CFTCardReaderInfo: NSObject {
    open var cardReaderModel: CFTCardReaderModel { return .unknown }
}

// AdminCardTestingViewController.swift:41, SwipeCreditCardViewController.swift:78-84.
open class CFTCardInfo: NSObject {
    open var cardholderName: String? { return nil }
    open var lastFour: String? { return nil }
}

// CardHandler.swift:87-92.
open class CFTHistoricalTransaction: NSObject {
    open var cardInfo: CFTCardInfo? { return nil }
    open var cardToken: String? { return nil }
    open var error: Error? { return CFTShimError.serviceUnavailable }
}

// CardHandler.swift:119.
open class CFTMessage: NSObject {
    open var primary: String? { return nil }
    open var secondary: String? { return nil }
}

// CardHandler.swift:30-34. Keys are not retained; setup always fails.
open class CFTCredentials: NSObject {
    open func setup(apiKey: String, accountToken: String, completion: ((Error?) -> Void)?) {
        completion?(CFTShimError.serviceUnavailable)
    }
}

// CardHandler.swift:57.
open class CFTTokenizationParameters: NSObject {
    public init(customerId: String?, credentials: CFTCredentials) {
        super.init()
    }
}

// CardHandler.swift:5,66-138 (method shapes the app implements).
@objc public protocol CFTTransactionDelegate: NSObjectProtocol {
    func transaction(_ transaction: CFTTransaction, didUpdate state: CFTTransactionState, error: Error?)
    func transaction(_ transaction: CFTTransaction, didComplete historicalTransaction: CFTHistoricalTransaction)
    func transaction(_ transaction: CFTTransaction, didReceive cardReaderEvent: CFTCardReaderEvent, cardReaderInfo: CFTCardReaderInfo?)
    func transaction(_ transaction: CFTTransaction, didUpdate cardReaderArray: [CFTCardReaderInfo])
    func transaction(_ transaction: CFTTransaction, didRequestProcessOption cardInfo: CFTCardInfo)
    func transaction(_ transaction: CFTTransaction, didRequestDisplay message: CFTMessage)
    func transaction(_ transaction: CFTTransaction, didDefer transactionData: Data)
    func transaction(_ transaction: CFTTransaction, didRequest cvm: CFTCVM)
}

// CardHandler.swift:48,58,62,78; CardHandlerTests.swift:90-101 subclasses it.
open class CFTTransaction: NSObject {
    public weak var delegate: CFTTransactionDelegate?

    public init(delegate: CFTTransactionDelegate) {
        self.delegate = delegate
        super.init()
    }

    // Fails closed: reports zero readers and an .unknown state with an error.
    // Never reports a reader, a card, a token, or a completed transaction.
    open func beginTokenizing(tokenizationParameters: CFTTokenizationParameters) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self, let delegate = strongSelf.delegate else { return }
            delegate.transaction(strongSelf, didUpdate: [CFTCardReaderInfo]())
            delegate.transaction(strongSelf, didUpdate: .unknown, error: CFTShimError.serviceUnavailable)
        }
    }

    open func select(processOption: CFTProcessOption) {}

    open func select(cardReaderInfo: CFTCardReaderInfo?, cardReaderModel: CFTCardReaderModel) {}
}
