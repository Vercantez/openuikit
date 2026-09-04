import Foundation
import FoundationNetworking
import LinkPresentation

/// Schema-v2 host gate compiles `*Tests.swift` and a generated runner, not this
/// file. Keep it as a standalone probe of the fail-closed metadata surface.

func linkPresentationRuntimeProbe() {
    precondition(LPErrorDomain == "LPErrorDomain")
    precondition(LPError.Code.unknown.rawValue == 1)
    precondition(LPError.metadataFetchFailed.rawValue == 2)

    let metadata = LPLinkMetadata()
    metadata.title = "runtime"
    metadata.url = URL(string: "https://example.com/runtime")
    precondition(metadata.title == "runtime")

    let provider = LPMetadataProvider()
    precondition(provider.shouldFetchSubresources == false)
    provider.cancel()

    print("LINKPRESENTATION_AGENT_RUNTIME_OK")
}

linkPresentationRuntimeProbe()
