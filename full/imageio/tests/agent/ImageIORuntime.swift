import Foundation
import ImageIO

/// Isolated host probe kept for the wave-6 Runtime.swift requirement.
/// The sealed gate compiles `*Tests.swift` plus LoadSmoke, not this file.
func imageioRuntimeProbe() {
    precondition(CGImageSourceStatus.statusComplete.rawValue == 0)
    precondition(kCGImagePropertyPixelWidth == "PixelWidth")
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, "public.png", 1, nil) else {
        fatalError("destination")
    }
    let image = CGImage(width: 1, height: 1)
    image.pixels = [1, 2, 3, 255]
    CGImageDestinationAddImage(dest, image, nil)
    precondition(CGImageDestinationFinalize(dest))
    precondition(CGImageSourceCreateWithData(data as Data, nil) != nil)
    print("IMAGEIO_AGENT_RUNTIME_OK")
}
