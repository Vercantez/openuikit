import Foundation
import MediaSetup

final class MediaSetupTestPresentationContext: NSObject, MSAuthenticationPresentationContext {
    var storedAnchor: MSPresentationAnchor?

    init(anchor: MSPresentationAnchor? = nil) {
        storedAnchor = anchor
        super.init()
    }

    func presentationAnchor() -> MSPresentationAnchor? {
        storedAnchor
    }
}

func testAuthenticationPresentationContextConformance() {
    let context = MediaSetupTestPresentationContext()
    let asProtocol: any MSAuthenticationPresentationContext = context
    let asObject = asProtocol as NSObject
    precondition(asObject === context)
}

func testPresentationAnchorReturnsOptionalWindow() {
    let missing = MediaSetupTestPresentationContext(anchor: nil)
    precondition(missing.presentationAnchor() == nil)

    let object = NSObject()
    let present = MediaSetupTestPresentationContext(anchor: object)
    let returned = present.presentationAnchor()
    precondition(returned === object)
}
