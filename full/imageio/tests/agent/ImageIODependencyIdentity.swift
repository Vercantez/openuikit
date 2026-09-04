import Foundation
import ImageIO

/// Future clean EC2 dependency-identity client. Isolated host-gate success
/// against toolchain Foundation is not integrated guest-Foundation success.
func imageioDependencyIdentityProbe() {
    let bytes = Data([0x89, 0x50, 0x4E, 0x47])
    precondition(!String(reflecting: type(of: bytes)).hasPrefix("ImageIO."))

    let url = URL(fileURLWithPath: "/tmp")
    precondition(!String(reflecting: type(of: url)).hasPrefix("ImageIO."))
    _ = CGImageSourceCreateWithURL(url, nil)

    let buffer = NSMutableData()
    precondition(!String(reflecting: type(of: buffer)).hasPrefix("ImageIO."))
    _ = CGImageDestinationCreateWithData(buffer, "public.png", 1, nil)

    let options: NSDictionary = [kCGImageSourceShouldCache: true]
    _ = CGImageSourceCreateWithData(bytes, options as? CFDictionary)
    precondition(!String(reflecting: NSDictionary.self).hasPrefix("ImageIO."))
}
