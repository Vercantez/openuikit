import CoreFoundation
import CoreAudioTypes

/// Dependency-identity client for the seeded CoreFoundation module token.
///
/// No CoreFoundation-owned type crosses a seeded `CoreAudioTypes` public
/// signature, so the product dylib does not import CoreFoundation. This
/// client proves an ordinary downstream source can import both modules and
/// bind the canonical overlay identities (`CFIndex`, `CFString`) without a
/// CoreAudioTypes-owned lookalike. The portable gate typechecks this client;
/// central integration is still responsible for linked CoreFoundation.
@main
enum CoreAudioTypesCoreFoundationIdentityClient {
    static func main() {
        let index: CFIndex = 8
        precondition(MemoryLayout<CFIndex>.size == MemoryLayout<Int>.size)
        precondition(index == 8)
        let stringType: CFString.Type = CFString.self
        precondition(String(describing: stringType).contains("CFString"))
        let time: CFTimeInterval = 0
        precondition(time == 0)
        let type: CoreAudioTypes.OSType = 0x61756678
        let status: CoreAudioTypes.OSStatus = -50
        precondition(type == UInt32(0x61756678))
        precondition(status == Int32(-50))
        print("COREAUDIOTYPES_COREFOUNDATION_IDENTITY_CLIENT_OK")
    }
}
