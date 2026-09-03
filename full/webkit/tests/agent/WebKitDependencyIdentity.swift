import Foundation
import WebKit

/// EC2 identity probe. Isolated host compilation does not link this file.
/// Passes Foundation values through public WebKit APIs.
func webKitDependencyIdentityProbe() {
    let url = URL(string: "https://example.invalid/")!
    let request = URLRequest(url: url)
    let store = WKWebsiteDataStore.nonPersistent()
    _ = store.isPersistent
    _ = request
    let error = WKError(code: .unknown, operation: "identity", requestedURL: url)
    precondition((error as NSError).domain == WKErrorDomain)
    precondition(WKErrorDomain == "WKErrorDomain")
}

#if WEBKIT_IDENTITY_MAIN
webKitDependencyIdentityProbe()
print("WEBKIT_DEPENDENCY_IDENTITY_OK")
#endif
