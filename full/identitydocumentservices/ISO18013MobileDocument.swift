import Foundation

#if canImport(Security)
import Security
#else
/// Isolated-host stand-in for Security.SecCertificate.
///
/// Security is not a declared `IdentityDocumentServices` dependency, so the
/// isolated host gate cannot import it. This type exists only so the public
/// `[SecCertificate]` signature compiles. It has no certificate bytes, parsing,
/// or trust evaluation. The later EC2 integration build should import real
/// Security.
public final class SecCertificate: @unchecked Sendable {
    init() {}
}
#endif

/// A type that represents an incoming ISO 18013-5 mobile document request.
public struct ISO18013MobileDocumentRequest: IdentityDocumentWebPresentmentRequest, Sendable {
    /// Presentment requests in the incoming mobile document request.
    ///
    /// All presentment requests marked as mandatory must be returned in order
    /// to satisfy the mobile document request.
    public var presentmentRequests: [PresentmentRequest]

    /// Authentication information for the mobile document request.
    public var requestAuthentications: [RequestAuthentication]

    public init(
        presentmentRequests: [PresentmentRequest],
        requestAuthentications: [RequestAuthentication]
    ) {
        self.presentmentRequests = presentmentRequests
        self.requestAuthentications = requestAuthentications
    }

    /// Authentication material for the incoming request.
    public struct RequestAuthentication: Sendable {
        /// Certificate chain used to authenticate the relying party.
        ///
        /// On this isolated Linux host the element type is not Security's
        /// `SecCertificate`; callers typically pass an empty chain.
        public var authenticationCertificateChain: [SecCertificate]

        public init(authenticationCertificateChain: [SecCertificate]) {
            self.authenticationCertificateChain = authenticationCertificateChain
        }
    }

    /// An individual presentment request.
    public struct PresentmentRequest: Sendable {
        /// Document request sets that can satisfy this presentment request.
        ///
        /// Exactly one document request set needs to be satisfied.
        public var documentRequestSets: [DocumentRequestSet]

        /// Whether this presentment request must be satisfied.
        public var isMandatory: Bool

        public init(documentRequestSets: [DocumentRequestSet], isMandatory: Bool) {
            self.documentRequestSets = documentRequestSets
            self.isMandatory = isMandatory
        }
    }

    /// A set of document requests defined in a `PresentmentRequest`.
    public struct DocumentRequestSet: Sendable {
        /// Document requests required to satisfy the set.
        ///
        /// Every document request must be responded to.
        public var requests: [DocumentRequest]

        public init(requests: [DocumentRequest]) {
            self.requests = requests
        }
    }

    /// A request for one mobile document type and its element namespaces.
    public struct DocumentRequest: Sendable {
        public var documentType: String
        public var namespaces: [String: [String: ElementInfo]]

        public init(documentType: String, namespaces: [String: [String: ElementInfo]]) {
            self.documentType = documentType
            self.namespaces = namespaces
        }
    }

    /// Request information about one ISO 18013-5 element.
    public struct ElementInfo: Sendable {
        /// Whether the requestor intends to retain this element.
        public var isRetaining: Bool

        public init(isRetaining: Bool) {
            self.isRetaining = isRetaining
        }
    }
}

/// A type representing the document response from a web presentment request.
public struct ISO18013MobileDocumentResponse: IdentityDocumentWebPresentmentResponse, Sendable {
    /// Presentment response data, formatted according to ISO 18013-5.
    ///
    /// Linux does not emit Apple-format CBOR; callers supply the bytes they
    /// already hold. Constructing this value is not evidence of a successful
    /// presentment.
    public let responseData: Data

    public init(responseData: Data) {
        self.responseData = responseData
    }
}
