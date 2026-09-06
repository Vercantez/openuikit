import ColorSync
import CoreFoundation
import Foundation

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation does not execute this file.
func colorSyncDependencyIdentityProbe() {
    let bytes = Data([0x00, 0x00, 0x00, 0x80])
    precondition(!String(reflecting: type(of: bytes)).hasPrefix("ColorSync."))
    var error: Unmanaged<CFError>?
    _ = ColorSyncProfileCreate(
        unsafeBitCast(bytes as NSData, to: CFData.self),
        &error
    )
    if let error {
        _ = error.takeRetainedValue()
    }
    let name = unsafeBitCast("com.apple.ColorSync.sRGB" as NSString, to: CFString.self)
    _ = ColorSyncProfileCreateWithName(name)
    let url = unsafeBitCast(URL(fileURLWithPath: "/tmp") as NSURL, to: CFURL.self)
    _ = ColorSyncProfileCreateWithURL(url, nil)
    _ = Date(timeIntervalSince1970: 1)
    _ = FileManager.default
}

#if COLORSYNC_IDENTITY_MAIN
colorSyncDependencyIdentityProbe()
print("COLORSYNC_DEPENDENCY_IDENTITY_OK")
#endif
