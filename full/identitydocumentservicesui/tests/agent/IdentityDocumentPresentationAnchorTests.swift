import Foundation
@_spi(OpenUIKitHost) import IdentityDocumentServicesUI

func testIdentityDocumentPresentationAnchor() {
    precondition(IdentityDocumentPresentationAnchor.self == UIWindow.self)
    let window = IdentityDocumentPresentationAnchor()
    let asWindow: UIWindow = window
    precondition(asWindow === window)
    precondition(type(of: window) == UIWindow.self)
    do {
        try IdentityDocumentServicesUIHostControl.presentWebPresentment()
        preconditionFailure("Linux must not present Apple identity-document UI")
    } catch IdentityDocumentServicesUIUnavailable.linuxHost(let operation) {
        precondition(operation == "presentWebPresentment")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}
