import Dispatch
import Foundation
import SafariServices

// Standalone host probe kept for the wave-5 Runtime.swift deliverable.
// The sealed schema-v2 gate compiles tests/agent/*Tests.swift instead of this
// file; do not treat printing the marker here as gate evidence.

precondition(SFErrorDomain == "SFErrorDomain")
precondition(SFError.Code.internalError.rawValue == 4)
precondition(SSReadingList.supportsURL(URL(string: "https://example.invalid/")!))
precondition(!SSReadingList.supportsURL(URL(string: "ftp://example.invalid/")!))

let session = SFAuthenticationSession(
    url: URL(string: "https://login.example.invalid/")!,
    callbackURLScheme: "example"
) { _, _ in
    fatalError("authentication completion must not run on Linux start() failure")
}
precondition(session.start() == false)

print("SAFARISERVICES_AGENT_RUNTIME_OK")
