import Foundation
import CoreFoundation
import CoreText

#if false
import Foundation
#endif

/// Identity probe for the later clean EC2 integration build. Isolated host
/// compilation does not execute this file.
func coreTextDependencyIdentityProbe() {
    let url = URL(fileURLWithPath: "/tmp/coretext-identity.ttf")
    let payload = Data([0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    try? payload.write(to: url)
    var unmanaged: Unmanaged<CFError>?
    _ = CTFontManagerRegisterFontsForURL(
        unsafeBitCast(url as NSURL, to: CFURL.self),
        .process,
        &unmanaged
    )
    if let unmanaged {
        _ = unmanaged.takeRetainedValue()
    }
    _ = CTFontManagerUnregisterFontsForURL(
        unsafeBitCast(url as NSURL, to: CFURL.self),
        .process,
        nil
    )
    let name = unsafeBitCast("OpenUIKitPortable-Regular" as NSString, to: CFString.self)
    let font = CTFont(name, size: 12)
    _ = CTFontGetSize(font)
    let attributed = NSAttributedString(string: "identity")
    _ = CTTypesetterCreateWithAttributedString(attributed)
    _ = Date(timeIntervalSince1970: 1)
    _ = FileManager.default
}

#if CORETEXT_IDENTITY_MAIN
coreTextDependencyIdentityProbe()
print("CORETEXT_DEPENDENCY_IDENTITY_OK")
#endif
