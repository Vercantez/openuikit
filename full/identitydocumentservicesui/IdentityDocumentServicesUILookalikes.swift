import Foundation

#if canImport(IdentityDocumentServices)
import IdentityDocumentServices
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(ExtensionFoundation)
import ExtensionFoundation
#endif
#if canImport(ExtensionKit)
import ExtensionKit
#endif

// Isolated-host stand-ins for IdentityDocumentServices, UIKit, SwiftUI,
// ExtensionFoundation, and ExtensionKit types named by the public
// IdentityDocumentServicesUI surface. The sealed host gate compiles this
// module alone. When a real dependency module is on the link line, these
// blocks compile out. They are not Linux ports of those modules and must
// not be cited as proof of those identities.

#if !canImport(IdentityDocumentServices)
/// IdentityDocumentServices-owned ISO 18013 request. Isolation stand-in only.
public struct ISO18013MobileDocumentRequest: Sendable {
    public var presentmentRequests: [PresentmentRequest]
    public var requestAuthentications: [RequestAuthentication]

    public init(
        presentmentRequests: [PresentmentRequest],
        requestAuthentications: [RequestAuthentication]
    ) {
        self.presentmentRequests = presentmentRequests
        self.requestAuthentications = requestAuthentications
    }

    public struct PresentmentRequest: Sendable {
        public var documentRequestSets: [DocumentRequestSet]
        public var isMandatory: Bool

        public init(documentRequestSets: [DocumentRequestSet], isMandatory: Bool) {
            self.documentRequestSets = documentRequestSets
            self.isMandatory = isMandatory
        }
    }

    public struct DocumentRequestSet: Sendable {
        public var requests: [DocumentRequest]

        public init(requests: [DocumentRequest]) {
            self.requests = requests
        }
    }

    public struct DocumentRequest: Sendable {
        public var documentType: String
        public var namespaces: [String: [String: ElementInfo]]

        public init(
            documentType: String,
            namespaces: [String: [String: ElementInfo]]
        ) {
            self.documentType = documentType
            self.namespaces = namespaces
        }
    }

    public struct ElementInfo: Sendable {
        public var isRetaining: Bool

        public init(isRetaining: Bool) {
            self.isRetaining = isRetaining
        }
    }

    /// Darwin stores a `SecCertificate` chain. Isolation has no Security
    /// module; this empty stand-in only exists so the request initializer
    /// type-checks.
    public struct RequestAuthentication: Sendable {
        public init() {}
    }
}

/// IdentityDocumentServices-owned ISO 18013 response. Isolation stand-in only.
public struct ISO18013MobileDocumentResponse: Sendable {
    public let responseData: Data

    public init(responseData: Data) {
        self.responseData = responseData
    }
}

/// IdentityDocumentServices-owned web-presentment request. Isolation stand-in only.
public protocol IdentityDocumentWebPresentmentRequest: Sendable {}

/// IdentityDocumentServices-owned web-presentment response. Isolation stand-in only.
public protocol IdentityDocumentWebPresentmentResponse: Sendable {}

/// IdentityDocumentServices-owned raw web-presentment request. Isolation stand-in only.
public struct IdentityDocumentWebPresentmentRawRequest: Sendable {
    public enum RequestType: Sendable, Equatable, Hashable {
        case iso18013MobileDocument
    }

    public var requestType: RequestType
    public var requestData: Data

    public init(requestType: RequestType, requestData: Data) {
        self.requestType = requestType
        self.requestData = requestData
    }
}
#endif

#if !canImport(UIKit)
/// UIKit-owned window. Isolation stand-in only.
open class UIWindow: NSObject {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(SwiftUI)
/// SwiftUI-owned view protocol. Isolation stand-in only.
public protocol View {
    associatedtype Body: View
    var body: Self.Body { get }
}

/// SwiftUI-owned empty view. Isolation stand-in only.
public struct EmptyView: View {
    public init() {}

    public var body: Never {
        fatalError("EmptyView is a leaf View")
    }
}
#endif

#if !canImport(ExtensionFoundation)
/// ExtensionFoundation-owned configuration protocol. Isolation stand-in only.
public protocol AppExtensionConfiguration {}

/// ExtensionFoundation-owned extension protocol. Isolation stand-in only.
public protocol AppExtension {
    associatedtype Configuration: AppExtensionConfiguration
    var configuration: Configuration { get }
}
#endif

#if !canImport(ExtensionKit)
/// ExtensionKit-owned scene protocol. Isolation stand-in only.
public protocol AppExtensionScene {
    associatedtype Body: AppExtensionScene
    var body: Self.Body { get }
}

/// ExtensionKit-owned scene configuration. Isolation stand-in only.
/// Linux stores no XPC accept policy and never talks to `appex`.
public struct AppExtensionSceneConfiguration: AppExtensionConfiguration, Sendable {
    public let hostSceneTypeName: String

    public init<S: AppExtensionScene>(_ scene: S) {
        self.hostSceneTypeName = String(reflecting: type(of: scene))
    }
}
#endif

#if !canImport(SwiftUI) && !canImport(ExtensionKit)
extension Never: View, AppExtensionScene {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf View and AppExtensionScene")
    }
}
#elseif !canImport(SwiftUI)
extension Never: View {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf View")
    }
}
#elseif !canImport(ExtensionKit)
extension Never: AppExtensionScene {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf AppExtensionScene")
    }
}
#endif
