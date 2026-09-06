@_exported import Foundation

/// Linux starting point for Apple's public `ProximityReader` module.
///
/// Tap to Pay on iPhone, Store and Forward, Value Added Services, and
/// Mobile Document Reader / ID Verifier need Apple's reader daemon, NFC,
/// Secure Element, merchant entitlements, and privacy UI. Those paths
/// fail closed with the documented `PaymentCardReaderError.unsupported`,
/// `MobileDocumentReaderError.notSupported`, or
/// `ProximityReaderDiscovery.ContentError.notSupported` errors.
///
/// Value types, request builders, element identities, enum cases, VAS
/// status raw values (sequential from the pinned API-digester child
/// order), error names, and Hashable/Equatable witnesses are real on
/// this isolated Foundation host.

enum ProximityReaderHostBoundary {
    static func paymentUnsupported() -> PaymentCardReaderError {
        .unsupported
    }

    static func documentUnsupported() -> MobileDocumentReaderError {
        .notSupported
    }

    static func discoveryUnsupported() -> ProximityReaderDiscovery.ContentError {
        .notSupported
    }

    static func storeUnsupported() -> PaymentCardReaderStore.StoreError {
        .notAllowed
    }

    static func readUnsupported() -> PaymentCardReaderSession.ReadError {
        .readerNotAvailable
    }
}

public protocol MobileDocumentRequest: Hashable, Sendable {
    associatedtype Response: Hashable, Sendable
}

public protocol MobileDocumentDataRequest: MobileDocumentRequest {}

public protocol MobileDocumentDataResponse: Hashable, Sendable {}

public protocol MobileDocumentRawDataRequest: MobileDocumentRequest {}
