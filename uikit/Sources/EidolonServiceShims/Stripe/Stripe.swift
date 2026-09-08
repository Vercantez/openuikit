import Foundation

// Eidolon Podfile.lock pins Stripe 12.1.0, commit
// e3c35c97963b938baac22612e4f4aae4b1cab8eb. PublicHeaders/STPAPIClient.h:
// 37,54,192 and STPBlocks.h:91 supply these Swift-imported call signatures.
// Podfile requests 14.0.1 instead: dependency resolution is an open wall, so
// this is explicitly the locked 12.1.0 service boundary, not an upgraded SDK.
public enum EidolonStripeError: Error {
    case serviceUnavailable
}

public final class Stripe: NSObject {
    public static func setDefaultPublishableKey(_ publishableKey: String) {
        // Accepting configuration does not enable a service or retain its key.
    }
}

public final class STPAPIClient: NSObject {
    private static let instance = STPAPIClient()
    public static func shared() -> STPAPIClient { instance }

    public func createToken(withCard card: STPCardParams,
                            completion: ((STPToken?, Error?) -> Void)?) {
        // StripeManager.swift:48-52 force-unwraps error when token is nil.
        // One failure callback with a nonnil error preserves that app contract;
        // this adapter can never return a token or create a payment/account.
        completion?(nil, EidolonStripeError.serviceUnavailable)
    }
}

// The parameter field types are measured in STPCardParams.h:28,38,43,48,64
// and STPAddress.h:99. Parameters live only in the caller-owned object.
public final class STPAddress: NSObject {
    public var postalCode: String?
}

public final class STPCardParams: NSObject {
    public var number: String?
    public var expMonth: UInt = 0
    public var expYear: UInt = 0
    public var cvc: String?
    public var address = STPAddress()
}

// STPCardBrand.h:14-50 has exactly these seven NS_ENUM values in this order.
public enum STPCardBrand: Int {
    case visa, amex, masterCard, discover, JCB, dinersClub, unknown
}

// STPCard.h:56 forbids direct initialization. The app only reads the three
// properties below (STPCard.h:61,88,98); the unavailable service creates none.
public final class STPCard: NSObject {
    public let name: String?
    public let last4: String
    public let brand: STPCardBrand

    private init(name: String?, last4: String, brand: STPCardBrand) {
        self.name = name
        self.last4 = last4
        self.brand = brand
    }
}

// STPToken.h:25 likewise forbids direct initialization; readonly fields are
// declared at lines 30 and 41. No initializer or token factory is exposed.
public final class STPToken: NSObject {
    public let tokenId: String
    public let card: STPCard?

    private init(tokenId: String, card: STPCard?) {
        self.tokenId = tokenId
        self.card = card
    }
}
