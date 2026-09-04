import Foundation
import FoundationNetworking
import LinkPresentation

/// Isolated-host identity probe. The sealed cloud gate does not compile this
/// file. The later EC2 integration build imports the real Foundation module
/// and passes genuine Foundation values through public LinkPresentation APIs.

func linkPresentationDependencyIdentityProbe() {
    let url = URL(string: "https://example.com/identity")!
    precondition(type(of: url) == URL.self)
    precondition(!String(reflecting: type(of: url)).hasPrefix("LinkPresentation."))

    let metadata = LPLinkMetadata()
    metadata.url = url
    metadata.originalURL = url
    metadata.title = "identity"
    precondition(metadata.url == url)
    precondition(!String(reflecting: type(of: metadata.url as Any)).hasPrefix("LinkPresentation."))

    let request = URLRequest(url: url)
    precondition(type(of: request) == URLRequest.self)
    precondition(!String(reflecting: type(of: request)).hasPrefix("LinkPresentation."))

    let error = LPError(.metadataFetchFailed, userInfo: ["probe": url.absoluteString])
    precondition(error.errorCode == LPError.Code.metadataFetchFailed.rawValue)
    let bridged = error as NSError
    precondition(bridged.domain == LPErrorDomain)
    precondition(!String(reflecting: type(of: bridged)).hasPrefix("LinkPresentation."))

    print("LINKPRESENTATION_DEPENDENCY_IDENTITY_OK")
}

linkPresentationDependencyIdentityProbe()
