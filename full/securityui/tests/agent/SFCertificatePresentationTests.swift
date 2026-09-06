import Foundation
@_spi(OpenUIKitHost) import SecurityUI

func testSFCertificatePresentationClass() {
    let trust = SecurityUIHostControl.makeTrust()
    let presentation = SFCertificatePresentation(trust: trust)
    let object: NSObject = presentation
    precondition(object === presentation)
    precondition(String(reflecting: type(of: presentation)).hasSuffix("SFCertificatePresentation"))
    precondition(presentation.trust === trust)
    precondition(presentation.title == nil)
    precondition(presentation.message == nil)
    precondition(presentation.helpURL == nil)
    precondition(SecurityUIHostControl.phase(of: presentation) == .idle)
}

func testInitWithTrust() {
    let first = SecurityUIHostControl.makeTrust()
    let second = SecurityUIHostControl.makeTrust()
    precondition(first !== second)

    let left = SFCertificatePresentation(trust: first)
    let right = SFCertificatePresentation(trust: second)
    precondition(left.trust === first)
    precondition(right.trust === second)
    precondition(left.trust !== right.trust)
    precondition(left !== right)

    left.title = "A"
    right.title = "B"
    precondition(left.title == "A")
    precondition(right.title == "B")
}

func testTrustProperty() {
    let trust = SecurityUIHostControl.makeTrust()
    let presentation = SFCertificatePresentation(trust: trust)
    let read = presentation.trust
    precondition(read === trust)
    precondition(read === presentation.trust)

    let other = SecurityUIHostControl.makeTrust()
    let second = SFCertificatePresentation(trust: other)
    precondition(second.trust === other)
    precondition(presentation.trust !== second.trust)
}

func testTitleProperty() {
    let trust = SecurityUIHostControl.makeTrust()
    let presentation = SFCertificatePresentation(trust: trust)
    precondition(presentation.title == nil)

    presentation.title = "Server identity"
    precondition(presentation.title == "Server identity")
    presentation.title = ""
    precondition(presentation.title == "")
    presentation.title = nil
    precondition(presentation.title == nil)

    presentation.message = "unchanged-by-title"
    presentation.title = "T"
    precondition(presentation.message == "unchanged-by-title")
    precondition(presentation.title == "T")
}

func testMessageProperty() {
    let trust = SecurityUIHostControl.makeTrust()
    let presentation = SFCertificatePresentation(trust: trust)
    precondition(presentation.message == nil)

    presentation.message = "Issued by Example CA"
    precondition(presentation.message == "Issued by Example CA")
    presentation.message = ""
    precondition(presentation.message == "")
    presentation.message = nil
    precondition(presentation.message == nil)

    presentation.title = "keep"
    presentation.message = "M"
    precondition(presentation.title == "keep")
    precondition(presentation.message == "M")
}

func testHelpURLProperty() {
    let trust = SecurityUIHostControl.makeTrust()
    let presentation = SFCertificatePresentation(trust: trust)
    precondition(presentation.helpURL == nil)

    let url = URL(string: "https://example.invalid/learn-more")!
    presentation.helpURL = url
    precondition(presentation.helpURL == url)
    precondition(presentation.helpURL?.absoluteString == "https://example.invalid/learn-more")

    let other = URL(string: "https://example.invalid/other")!
    presentation.helpURL = other
    precondition(presentation.helpURL == other)
    precondition(presentation.helpURL != url)

    presentation.helpURL = nil
    precondition(presentation.helpURL == nil)
}

func testPresentSheet() {
    let trust = SecurityUIHostControl.makeTrust()
    let presentation = SFCertificatePresentation(trust: trust)
    let presenter = UIViewController()
    var handlerCalls = 0

    let result = SecurityUIHostControl.presentSheetFailClosed(
        presentation,
        in: presenter,
        dismissHandler: { handlerCalls += 1 }
    )
    switch result {
    case .success:
        preconditionFailure("Linux must not invent certificate-sheet chrome")
    case .failure(let error):
        precondition(error == .linuxHost(operation: "SFCertificatePresentation.presentSheet"))
    }

    precondition(handlerCalls == 0)
    precondition(SecurityUIHostControl.phase(of: presentation) == .requested)
    precondition(SecurityUIHostControl.presentingViewController(of: presentation) === presenter)
    precondition(SecurityUIHostControl.dismissHandlerInstalled(on: presentation))
    precondition(SecurityUIHostControl.presentCount(of: presentation) == 1)
    precondition(presentation.trust === trust)

    let otherPresenter = UIViewController()
    presentation.presentSheet(in: otherPresenter, dismissHandler: { handlerCalls += 10 })
    precondition(handlerCalls == 0)
    precondition(SecurityUIHostControl.presentCount(of: presentation) == 2)
    precondition(SecurityUIHostControl.presentingViewController(of: presentation) === presenter)
    precondition(SecurityUIHostControl.phase(of: presentation) == .requested)
}

func testDismissSheet() {
    let trust = SecurityUIHostControl.makeTrust()
    let presentation = SFCertificatePresentation(trust: trust)
    let presenter = UIViewController()
    var handlerCalls = 0

    presentation.dismissSheet()
    precondition(handlerCalls == 0)
    precondition(SecurityUIHostControl.phase(of: presentation) == .idle)
    precondition(SecurityUIHostControl.dismissCount(of: presentation) == 1)

    presentation.presentSheet(in: presenter) {
        handlerCalls += 1
    }
    precondition(handlerCalls == 0)
    presentation.dismissSheet()
    precondition(handlerCalls == 1)
    precondition(SecurityUIHostControl.phase(of: presentation) == .dismissed)
    precondition(SecurityUIHostControl.presentingViewController(of: presentation) == nil)
    precondition(!SecurityUIHostControl.dismissHandlerInstalled(on: presentation))
    precondition(SecurityUIHostControl.dismissCount(of: presentation) == 2)

    presentation.dismissSheet()
    precondition(handlerCalls == 1)
    precondition(SecurityUIHostControl.dismissCount(of: presentation) == 3)
}
