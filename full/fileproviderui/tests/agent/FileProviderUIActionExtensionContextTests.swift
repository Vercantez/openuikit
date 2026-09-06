import Foundation
@_spi(OpenUIKitHost) import FileProviderUI

func testActionExtensionContextClass() {
    let context = FPUIActionExtensionContext()
    let asObject: NSObject = context
    precondition(asObject === context)
    precondition(type(of: context) == FPUIActionExtensionContext.self)
    precondition(context.hostDisposition == .active)
    precondition(context.domainIdentifier == nil)
}

func testCompleteRequest() {
    let context = FPUIActionExtensionContext()
    precondition(context.hostDisposition == .active)
    context.completeRequest()
    precondition(context.hostDisposition == .completed)
    precondition(context.hostCancellationError == nil)
    context.completeRequest()
    precondition(context.hostDisposition == .completed)
    context.cancelRequest(withError: FPUIExtensionErrorCode.failed)
    precondition(context.hostDisposition == .completed)
    precondition(context.hostCancellationError == nil)
}

func testCancelRequestWithError() {
    let context = FPUIActionExtensionContext()
    context.cancelRequest(withError: FPUIExtensionErrorCode.userCancelled)
    precondition(context.hostDisposition == .cancelled)
    let stored = context.hostCancellationError as? FPUIExtensionErrorCode
    precondition(stored == .userCancelled)
    let nsError = stored.map { $0 as NSError }
    precondition(nsError?.domain == FPUIErrorDomain)
    precondition(nsError?.code == 0)
    context.completeRequest()
    precondition(context.hostDisposition == .cancelled)
    context.cancelRequest(withError: FPUIExtensionErrorCode.failed)
    let stillCancelled = context.hostCancellationError as? FPUIExtensionErrorCode
    precondition(stillCancelled == .userCancelled)
}

func testDomainIdentifier() {
    let context = FPUIActionExtensionContext()
    precondition(context.domainIdentifier == nil)
    let domain = NSFileProviderDomainIdentifier("com.example.domain")
    context.hostSetDomainIdentifier(domain)
    precondition(context.domainIdentifier == domain)
    precondition(context.domainIdentifier?.rawValue == "com.example.domain")
    context.hostSetDomainIdentifier(nil)
    precondition(context.domainIdentifier == nil)
}
