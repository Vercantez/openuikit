import BackgroundAssets
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Compiled against the product module on the clean EC2 integration build.
func backgroundAssetsDependencyIdentityProbe() {
    let url = URL(string: "https://example.com/identity.bin")!
    let request = URLRequest(url: url)
    let download = BAURLDownload(
        identifier: "identity",
        request: request,
        essential: false,
        fileSize: 4,
        applicationGroupIdentifier: "group.identity",
        priority: .default
    )
    precondition(download.request?.url == url)

    let date = Date(timeIntervalSince1970: 1_700_000_000)
    var invoked = false
    BADownloadManager.shared.withExclusiveControl(beforeDate: date) { granted, error in
        invoked = true
        precondition(granted == false)
        precondition(error != nil)
    }
    precondition(invoked)

    let json = Data("{\"assetPacks\":[{\"id\":\"identity-pack\",\"downloadSize\":4,\"version\":1}]}".utf8)
    let manifest = try! AssetPackManifest(from: json, appGroupID: "group.identity")
    precondition(manifest.assetPacks.first?.id == "identity-pack")
    let nsError = BAErrorCode.downloadInvalid as NSError
    precondition(nsError.domain == BAErrorDomain)
}
