import MediaAccessibility
import CoreFoundation
import CoreGraphics
import Foundation

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation does not execute this file.
func mediaAccessibilityDependencyIdentityProbe() {
    let language = unsafeBitCast("en-US" as NSString, to: CFString.self)
    _ = MACaptionAppearanceAddSelectedLanguage(.user, language)
    let opacity: CGFloat = MACaptionAppearanceGetForegroundOpacity(.user, nil)
    _ = opacity
    let url = unsafeBitCast(
        URL(fileURLWithPath: "/tmp/mediaaccessibility-identity.jpg") as NSURL,
        to: CFURL.self
    )
    var error: CFError?
    _ = MAImageCaptioningCopyCaption(url, &error)
    _ = MACaptionAppearanceGetWindowRoundedCornerRadius(.default, nil)
    _ = Date(timeIntervalSince1970: 1)
}
