// KioskInterop — Swift/Objective-C interop that route (b) cannot express on
// its own, one entry per measured wall (docs/agent_reports/eidolon-kiosk.md).
// Linked into Kiosk by the chain spec (docs/agent_reports/eidolon-kiosk-chain.json)
// and imported implicitly (-import-module KioskInterop); no Kiosk or pod
// source changes.
//
// 1. Initializers an Objective-C class inherits from a SWIFT superclass.
//    ARTiledImageView 1.1.1 declares `@interface ARTiledImageScrollView :
//    UIScrollView` with no initializer of its own. On Apple's UIKit it
//    inherits `-initWithFrame:` and Swift sees `ARTiledImageScrollView(frame:)`
//    (Kiosk SaleArtworkZoomViewController.swift:15). With OpenUIKit the
//    superclass is a Swift class, and Swift's ClangImporter imports inherited
//    initializers only from a superclass that has a Clang declaration.
//    MEASURED, all three from Swift in Kiosk's chain:
//      - `ARTiledImageScrollView(frame: .zero)`: "argument passed to call that
//        takes no arguments";
//      - an extension `convenience init(frame:)`: "overriding declaration
//        requires an 'override' keyword" (the Swift superclass's designated
//        init(frame:) is seen, but not as inherited);
//      - a category re-declaring `-initWithFrame:` in an Objective-C header:
//        not imported (the same error as the first).
//    So the interop initializer carries a defaulted extra parameter: the
//    app's `ARTiledImageScrollView(frame: rect)` resolves to it and nothing
//    overrides anything. Its body is exactly what `-initWithFrame:` does for
//    this class, which implements no initializer: UIView's `init()` sends
//    `-initWithFrame:CGRectZero` (Objective-C dispatch reaches UIScrollView's
//    implementation), then the frame is set.
import UIKit
import ARTiledImageView

extension ARTiledImageScrollView {
    public convenience init(frame: CGRect, _ inheritedFromSwiftSuperclass: Void = ()) {
        self.init()
        self.frame = frame
    }
}
