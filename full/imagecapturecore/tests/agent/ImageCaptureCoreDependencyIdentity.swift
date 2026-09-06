import ImageCaptureCore
import Foundation

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public ImageCaptureCore APIs.
func imageCaptureCoreDependencyIdentityProbe() {
    let domain: String = ICErrorDomain
    precondition(domain == "com.apple.ImageCaptureCore")

    let info: [String: Any] = ["foundation": UUID().uuidString]
    let error = ICReturn(.downloadFailed, userInfo: info)
    precondition(error.userInfo["foundation"] as? String == info["foundation"] as? String)
    let ns = error as NSError
    precondition(ns.domain == ICErrorDomain)
    precondition(ns.code == ICReturn.Code.downloadFailed.rawValue)

    let url = URL(fileURLWithPath: "/tmp")
    let options: [ICDownloadOption: Any] = [.downloadsDirectoryURL: url]
    precondition((options[.downloadsDirectoryURL] as? URL) == url)

    let status = ICAuthorizationStatus.denied
    precondition(status.rawValue == "ICAuthorizationStatusDenied")

    _ = NotificationCenter.default
    _ = Date()
    _ = Data()
    _ = Progress(totalUnitCount: 0)
}
