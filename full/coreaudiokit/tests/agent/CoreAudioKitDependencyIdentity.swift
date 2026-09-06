import CoreAudioKit
import AudioToolbox
import Foundation
import UIKit
@_spi(OpenUIKitHost) import CoreAudioKit

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest AudioToolbox/UIKit
// success. This file is not compiled by the sealed host gate.
//
// Expected EC2 steps (no local Docker):
// 1. Build guest AudioToolbox, Foundation, UIKit (and their dylibs).
// 2. Build CoreAudioKit with those modules on `-I` / `-L`.
// 3. Link this file as a client that imports CoreAudioKit and every dependency.
// 4. Run with `LD_LIBRARY_PATH` covering those dylibs.
// 5. Confirm `COREAUDIOKIT_DEPENDENCY_IDENTITY_OK` and that
//    `libCoreAudioKit.dylib` was loaded.

private func assertNotCoreAudioKitType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("CoreAudioKit."))
}

func assertFoundationIdentity() {
    let frame = CGRect(x: 0, y: 0, width: 320, height: 240)
    assertNotCoreAudioKitType(frame)
    let view = CAInterAppAudioSwitcherView(frame: frame)
    precondition(view.frame.width == 320)
    precondition(view.contentWidth() == 0)
    _ = Foundation.IndexSet()
    _ = Foundation.IndexPath(indexes: [0, 0])
}

func assertUIKitIdentity() {
    let transport = CAInterAppAudioTransportView(frame: .zero)
    precondition(transport is UIView)
    transport.labelColor = UIColor.white
    transport.currentTimeLabelFont = UIFont.systemFont(ofSize: 14)
    precondition(transport.isConnected == false)
    let controller = AUViewController()
    precondition(controller is UIViewController)
}

func assertAudioToolboxIdentity() {
    let description = AudioComponentDescription()
    assertNotCoreAudioKitType(description)
    let loader = AUAppleCustomViewLoader()
    let dummyUnit = OpaquePointer(bitPattern: 1)!
    let controller = loader.customViewController(
        for: description,
        audioUnit: dummyUnit,
        v3AU: nil
    )
    precondition(controller == nil)
    let unit = AUAudioUnit()
    var delivered = false
    unit.requestViewController { viewController in
        delivered = true
        precondition(viewController == nil)
    }
    precondition(delivered)
}

func coreAudioKitDependencyIdentityMain() {
    assertFoundationIdentity()
    assertUIKitIdentity()
    assertAudioToolboxIdentity()
    print("COREAUDIOKIT_DEPENDENCY_IDENTITY_OK")
}
