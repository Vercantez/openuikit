import CoreFoundation
import Foundation

/// Image captioning talks to ImageIO IPTC tags on Apple platforms. Linux has
/// no ImageIO dependency here, so copy/set fail closed with a typed error.
public let MAImageCaptioningErrorDomain = "MAImageCaptioningErrorDomain"

public enum MAImageCaptioningErrorCode: Int, Sendable {
    case unsupported = 1
    case invalidURL = 2
}

/// ImageIO-style IPTC caption path used as the process-local tag identity.
/// Darwin's exact `MAImageCaptioningCopyMetadataTagPath` bytes are unobserved.
public let MAImageCaptioningMetadataTagPath = "{IPTC}:{Caption/Abstract}"

func _maImageCaptioningError(
    _ destination: UnsafeMutablePointer<CFError?>?,
    code: MAImageCaptioningErrorCode,
    url: URL?
) {
    guard let destination else { return }
    var info: [String: Any] = [
        NSLocalizedDescriptionKey: "Image captioning is unavailable on this platform"
    ]
    if let url {
        info[NSURLErrorKey] = url
    }
    let nsError = NSError(
        domain: MAImageCaptioningErrorDomain,
        code: code.rawValue,
        userInfo: info
    )
    destination.pointee = _maCFError(nsError)
}

public func MAImageCaptioningCopyMetadataTagPath() -> CFString {
    _maCFString(MAImageCaptioningMetadataTagPath)
}

public func MAImageCaptioningCopyCaption(
    _ url: CFURL,
    _ error: UnsafeMutablePointer<CFError?>?
) -> CFString? {
    let fileURL = _maURL(url)
    _maImageCaptioningError(error, code: .unsupported, url: fileURL)
    return nil
}

public func MAImageCaptioningSetCaption(
    _ url: CFURL,
    _ string: CFString?,
    _ error: UnsafeMutablePointer<CFError?>?
) -> Bool {
    let fileURL = _maURL(url)
    _ = string
    guard fileURL.isFileURL else {
        _maImageCaptioningError(error, code: .invalidURL, url: fileURL)
        return false
    }
    _maImageCaptioningError(error, code: .unsupported, url: fileURL)
    return false
}
