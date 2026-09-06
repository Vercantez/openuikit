import Foundation
import LocalAuthenticationEmbeddedUI

func testLAPresentationContextIsUIWindow() {
    precondition(LAPresentationContext.self == UIWindow.self)
    let window = UIWindow()
    let context: LAPresentationContext = window
    precondition(context === window)
    precondition(context is UIWindow)
    precondition(type(of: context) == UIWindow.self)
}
