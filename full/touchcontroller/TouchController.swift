import Foundation

/// Linux starting implementation of Apple's public `TouchController` module.
///
/// Software on-screen controls, descriptors, layout, hit-testing, and touch
/// routing are real in-memory state machines. Metal rendering, `MTKView`
/// pixel-format plumbing, `UIImage`/`CGImage` GPU upload, and the
/// `GCController` HID facade are fail-closed: this isolated host has no
/// Metal, UIKit, or GameController Swift modules, and this framework does
/// not ship lookalike substitutes for those dependency-owned types.

/// Product category advertised to Game Controller on Darwin. The exact
/// Darwin string payload is unobserved; Linux uses the human-readable
/// category name matching the `GCProductCategory*` pattern.
public let TCGameControllerProductCategoryTouchController = "Touch Controller"

/// Linux has no Apple touch-controller service, HID injection, or GPU
/// overlay. `TCTouchController.isSupported` is therefore `false`, and
/// `connect()` does not become connected.
public enum TouchControllerLinuxSupport {
    public static let isSupported = false
}
