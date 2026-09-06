import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MarketplaceKit

func testMarketplaceExtensionRequestFailedStatus() {
    let probe = MarketplaceKitProbeExtension()
    let url = URL(string: "https://api.example.invalid/v1")!
    let ok = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
    let notFound = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
    let server = HTTPURLResponse(url: url, statusCode: 503, httpVersion: "HTTP/1.1", headerFields: nil)!
    precondition(!probe.requestFailed(with: ok))
    precondition(probe.requestFailed(with: notFound))
    precondition(probe.requestFailed(with: server))
}

func testMarketplaceExtensionAdditionalHeadersAndVersions() {
    let probe = MarketplaceKitProbeExtension()
    var request = URLRequest(url: URL(string: "https://api.example.invalid/headers")!)
    request.setValue("1", forHTTPHeaderField: "X-Probe")
    precondition(probe.additionalHeaders(for: request, account: "acct") == nil)
    precondition(probe.availableAppVersions(forAppleItemIDs: [1, 2]) == nil)
}

func testMarketplaceExtensionConfiguration() {
    let probe = MarketplaceKitProbeExtension()
    let configuration: any MarketplaceExtensionConfiguration = probe.configuration
    _ = configuration
}

func testMarketplaceAppExtensionConfiguration() {
    let probe = MarketplaceKitProbeAppExtension()
    let configuration: any MarketplaceExtensionConfiguration = probe.configuration
    _ = configuration
}

func testExceptionRequestStatusRawValues() {
    precondition(AppLibrary.ExceptionRequest.Status.pending.rawValue == 0)
    precondition(AppLibrary.ExceptionRequest.Status.approved.rawValue == 1)
    precondition(AppLibrary.ExceptionRequest.Status.declined.rawValue == 2)
    precondition(AppLibrary.ExceptionRequest.Status(rawValue: 0) == .pending)
    precondition(AppLibrary.ExceptionRequest.Status(rawValue: 1) == .approved)
    precondition(AppLibrary.ExceptionRequest.Status(rawValue: 2) == .declined)
    precondition(AppLibrary.ExceptionRequest.Status(rawValue: 99) == nil)
    precondition(AppLibrary.ExceptionRequest.Status.pending != .approved)
    precondition(AppLibrary.ExceptionRequest.Status.approved.hashValue == AppLibrary.ExceptionRequest.Status(rawValue: 1)!.hashValue)
    var hasher = Hasher()
    AppLibrary.ExceptionRequest.Status.declined.hash(into: &hasher)
    _ = hasher.finalize()
    let decoded = marketplaceKitJSONRoundTrip(AppLibrary.ExceptionRequest.Status.approved)
    precondition(decoded == .approved)
    let raw: AppLibrary.ExceptionRequest.Status.RawValue = AppLibrary.ExceptionRequest.Status.pending.rawValue
    precondition(raw == 0)
}

func testExceptionRequestCodable() {
    let request = AppLibrary.ExceptionRequest(appleItemID: 88, status: .pending)
    precondition(request.appleItemID == 88)
    precondition(request.status == .pending)
    let decoded = marketplaceKitJSONRoundTrip(request)
    precondition(decoded.appleItemID == 88)
    precondition(decoded.status == .pending)
}
