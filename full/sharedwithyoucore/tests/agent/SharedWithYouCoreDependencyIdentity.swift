import Foundation
import SharedWithYouCore

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest Foundation success.
// This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest Foundation and `libFoundation.dylib`.
// 2. Build SharedWithYouCore with that module on `-I` / `-L`.
// 3. Link this file as a client that imports SharedWithYouCore and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `SHAREDWITHYOUCORE_DEPENDENCY_IDENTITY_OK` and that
//    `libSharedWithYouCore.dylib` was loaded.

private func assertNotSharedWithYouCoreType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("SharedWithYouCore."))
}

func sharedWithYouCoreDependencyIdentityProbe() {
    let identifier = UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!
    assertNotSharedWithYouCoreType(identifier)
    let action = SWAction()
    precondition(type(of: action.uuid) == UUID.self)

    let rootHash = Data([0x01, 0x02, 0x03, 0x04])
    assertNotSharedWithYouCoreType(rootHash)
    let identity = SWPerson.Identity(rootHash: rootHash)
    precondition(identity.rootHash == rootHash)

    let url = URL(string: "https://example.invalid/collaboration")!
    assertNotSharedWithYouCoreType(url)
    let metadata = SWCollaborationMetadata(
        collaborationIdentifier: SWCollaborationIdentifier("dep.collab")
    )
    metadata.title = "Dependency"
    let person = SWPerson(
        handle: "user@example.invalid",
        identity: identity,
        displayName: "Ada",
        thumbnailImageData: rootHash
    )
    _ = person
    _ = url
    _ = action.uuid
    _ = UTCollaborationOptionsTypeIdentifier

    var name = PersonNameComponents()
    name.givenName = "Ada"
    metadata.initiatorNameComponents = name
    precondition(metadata.initiatorNameComponents?.givenName == "Ada")
}

#if SHAREDWITHYOUCORE_IDENTITY_MAIN
sharedWithYouCoreDependencyIdentityProbe()
print("SHAREDWITHYOUCORE_DEPENDENCY_IDENTITY_OK")
#endif
