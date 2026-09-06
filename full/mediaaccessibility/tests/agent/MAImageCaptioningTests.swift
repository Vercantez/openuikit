import Foundation
import MediaAccessibility

func testImageCaptioningMetadataTagPath() {
    let path = unsafeBitCast(MAImageCaptioningCopyMetadataTagPath(), to: NSString.self) as String
    precondition(path == "{IPTC}:{Caption/Abstract}")
    precondition(path == MAImageCaptioningMetadataTagPath)
}

func testImageCaptioningCopyCaptionFailClosed() {
    let url = unsafeBitCast(
        URL(fileURLWithPath: "/tmp/mediaaccessibility-missing.jpg") as NSURL,
        to: CFURL.self
    )
    var error: CFError?
    let caption = MAImageCaptioningCopyCaption(url, &error)
    precondition(caption == nil)
    precondition(error != nil)
    let ns = unsafeBitCast(error!, to: NSError.self)
    precondition(ns.domain == MAImageCaptioningErrorDomain)
    precondition(ns.code == MAImageCaptioningErrorCode.unsupported.rawValue)
}

func testImageCaptioningSetCaptionFailClosed() {
    let url = unsafeBitCast(
        URL(fileURLWithPath: "/tmp/mediaaccessibility-missing.jpg") as NSURL,
        to: CFURL.self
    )
    var error: CFError?
    let caption = unsafeBitCast("alt text" as NSString, to: CFString.self)
    let ok = MAImageCaptioningSetCaption(url, caption, &error)
    precondition(ok == false)
    precondition(error != nil)
    let ns = unsafeBitCast(error!, to: NSError.self)
    precondition(ns.domain == MAImageCaptioningErrorDomain)
    precondition(ns.code == MAImageCaptioningErrorCode.unsupported.rawValue)
}

func testImageCaptioningSetCaptionRejectsNonFileURL() {
    let url = unsafeBitCast(
        URL(string: "https://example.invalid/caption.jpg")! as NSURL,
        to: CFURL.self
    )
    var error: CFError?
    let ok = MAImageCaptioningSetCaption(url, nil, &error)
    precondition(ok == false)
    let ns = unsafeBitCast(error!, to: NSError.self)
    precondition(ns.code == MAImageCaptioningErrorCode.invalidURL.rawValue)
}
