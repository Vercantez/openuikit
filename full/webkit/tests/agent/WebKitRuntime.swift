import Foundation
import WebKit

/// Schema-v2 lanes use LoadSmoke as the sealed marker. This probe keeps a
/// focused runtime check that operators can compile separately.
func webKitRuntimeProbe() {
    precondition(WKErrorDomain == "WKErrorDomain")
    precondition(WKError.Code.unknown.rawValue == 1)
    let store = WKWebsiteDataStore.nonPersistent()
    precondition(!store.isPersistent)
}

#if WEBKIT_RUNTIME_MAIN
webKitRuntimeProbe()
print("WEBKIT_AGENT_RUNTIME_OK")
#endif
