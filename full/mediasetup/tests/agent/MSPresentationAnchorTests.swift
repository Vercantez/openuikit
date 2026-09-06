import Foundation
import MediaSetup

func testPresentationAnchorTypealias() {
#if canImport(UIKit)
    precondition(MSPresentationAnchor.self == UIWindow.self)
#else
    precondition(MSPresentationAnchor.self == NSObject.self)
#endif
    let anchor: MSPresentationAnchor? = nil
    precondition(anchor == nil)
}
