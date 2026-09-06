import Foundation
@_spi(OpenUIKitHost) import IdentityLookupUI

func testClassificationUIExtensionContextClass() {
    let context = ILClassificationUIExtensionContext()
    let asObject: NSObject = context
    precondition(asObject === context)
    precondition(type(of: context) == ILClassificationUIExtensionContext.self)
    precondition(context.isReadyForClassificationResponse == false)
    do {
        try IdentityLookupUIHostControl.presentClassificationUI()
        preconditionFailure("Linux must not present Apple classification UI")
    } catch IdentityLookupUIUnavailable.linuxHost(let operation) {
        precondition(operation == "presentClassificationUI")
    } catch {
        preconditionFailure("unexpected error: \(error)")
    }
}

func testIsReadyForClassificationResponse() {
    let context = ILClassificationUIExtensionContext()
    precondition(context.isReadyForClassificationResponse == false)
    context.isReadyForClassificationResponse = true
    precondition(context.isReadyForClassificationResponse == true)
    context.isReadyForClassificationResponse = false
    precondition(context.isReadyForClassificationResponse == false)
    context.isReadyForClassificationResponse = true
    let other = ILClassificationUIExtensionContext()
    precondition(other.isReadyForClassificationResponse == false)
    precondition(context.isReadyForClassificationResponse == true)
    other.isReadyForClassificationResponse = true
    context.isReadyForClassificationResponse = false
    precondition(other.isReadyForClassificationResponse == true)
    precondition(context.isReadyForClassificationResponse == false)
}
