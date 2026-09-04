import CoreTransferable
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build CoreTransferable with that Foundation on `-I` / `-L`.
// 3. Link this file as a client that imports CoreTransferable and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm `CORETRANSFERABLE_DEPENDENCY_IDENTITY_OK` and that
//    `libCoreTransferable.dylib` was loaded.

private func assertNotCoreTransferableType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("CoreTransferable."))
}

func coreTransferableDependencyIdentityProbe() {
    let data = Data("identity-bytes".utf8)
    assertNotCoreTransferableType(data)
    precondition(type(of: data) == Data.self)

    let url = URL(fileURLWithPath: "/tmp/identity-transfer")
    assertNotCoreTransferableType(url)
    precondition(type(of: url) == URL.self)

    let text = "identity-text"
    assertNotCoreTransferableType(text)

    let attributed = AttributedString("identity-rich")
    assertNotCoreTransferableType(attributed)

    let encoded = try! JSONEncoder().encode("identity-json")
    assertNotCoreTransferableType(encoded)

    let sent = SentTransferredFile(url)
    precondition(sent.file == url)
    assertNotCoreTransferableType(sent.file)

    _ = Data.exportedContentTypes()
    _ = String.importedContentTypes()
    _ = TransferRepresentationVisibility.all
}

#if CORETRANSFERABLE_IDENTITY_MAIN
coreTransferableDependencyIdentityProbe()
print("CORETRANSFERABLE_DEPENDENCY_IDENTITY_OK")
#endif
