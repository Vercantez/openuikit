import Foundation
import StickerKit

/// Future clean EC2 dependency-identity client. Isolated host-gate success
/// against toolchain Foundation is not integrated guest Foundation success.
/// This file is not compiled by the sealed host gate.
///
/// Expected EC2 steps (no local Docker):
/// 1. Build guest Foundation.
/// 2. Build StickerKit with that module on `-I` / `-L`.
/// 3. Link this file as a client that imports StickerKit and Foundation.
/// 4. Pass genuine Foundation.Bundle, String, and NSCoder values through
///    public StickerKit APIs.
/// 5. Confirm `init(coder:)` stays nil and the nib-name init records the
///    Foundation bundle without presenting Apple UI.
/// 6. Run with `LD_LIBRARY_PATH` covering those dylibs.
/// 7. Confirm `STICKERKIT_DEPENDENCY_IDENTITY_OK`.

private func assertNotStickerKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("StickerKit."))
}

func assertFoundationIdentity() {
    let nibName = "AvatarEditor"
    assertNotStickerKitType(nibName)
    precondition(type(of: nibName) == String.self)

    let bundle = Bundle.main
    assertNotStickerKitType(bundle)
    precondition(type(of: bundle) == Bundle.self)

    let editor = AvatarEditorViewController(nibName: nibName, bundle: bundle)
    precondition(editor is NSObject)

    let archiver = NSKeyedArchiver(requiringSecureCoding: true)
    assertNotStickerKitType(archiver)
    precondition(archiver is NSCoder)
    precondition(AvatarEditorViewController(coder: archiver) == nil)

    _ = Foundation.UUID.self
    _ = Foundation.NSError.self
}

func stickerkitDependencyIdentityMain() {
    assertFoundationIdentity()
    print("STICKERKIT_DEPENDENCY_IDENTITY_OK")
}
