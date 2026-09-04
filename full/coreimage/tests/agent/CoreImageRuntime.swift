import CoreImage
import Foundation

/// Schema-v2 sealed runner compiles `CoreImageLoadSmoke.swift` and
/// `*Tests.swift`. This probe remains as the named runtime entry the wave-6
/// house rules ask for; it does not print.
func coreImageRuntimeProbe() {
    _ = CIColor.black
    _ = CIFilter.linearGradient()
    _ = COREIMAGE_SUPPORTS_IOSURFACE
    _ = kCIInputImageKey
}
