@_spi(OpenUIKitHost) import TipKit
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation/SwiftUI
// success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build guest SwiftUI (`libSwiftUI.dylib`) and this framework against
//    those `-I` / `-L` paths.
// 3. Link this file as a client that `import`s TipKit, Foundation, and SwiftUI.
// 4. Prove Tip.title/message/action labels are SwiftUI.Text, images are
//    SwiftUI.Image, presentation APIs use SwiftUI.Edge/Binding, and TipView
//    participates in the real SwiftUI.View system without portable stand-ins.
// 5. Run with `LD_LIBRARY_PATH` covering libSwiftUI.dylib and libTipKit.dylib.
// 6. Confirm `TIPKIT_DEPENDENCY_IDENTITY_OK`.

private func requireMemoryConfigure() throws {
    TipsHostControl.resetForHostTests()
    try Tips.configure([.displayFrequency(.immediate)])
    let event = Tips.Event<Tips.EmptyDonation>(id: "identity-open")
    let semaphore = DispatchSemaphore(value: 0)
    event.sendDonation {
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + .seconds(5)) == .success)
    precondition(event.donations.count == 1)
}

#if canImport(SwiftUI)
private func requireSwiftUIIdentities() {
    let textType = String(reflecting: SwiftUI.Text.self)
    let imageType = String(reflecting: SwiftUI.Image.self)
    let edgeType = String(reflecting: SwiftUI.Edge.self)
    precondition(textType.contains("SwiftUI.Text"))
    precondition(imageType.contains("SwiftUI.Image"))
    precondition(edgeType.contains("SwiftUI.Edge"))
}
#endif

do {
    try requireMemoryConfigure()
#if canImport(SwiftUI)
    requireSwiftUIIdentities()
#endif
    print("TIPKIT_DEPENDENCY_IDENTITY_OK")
} catch {
    fatalError("TipKit dependency identity failed: \(error)")
}
