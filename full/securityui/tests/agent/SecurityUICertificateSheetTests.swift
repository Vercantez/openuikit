import Foundation
@_spi(OpenUIKitHost) import SecurityUI

func testCertificateSheet() {
    var stored: SecTrust? = SecurityUIHostControl.makeTrust()
    var writes = 0
    let binding = Binding(
        get: { stored },
        set: { newValue in
            writes += 1
            stored = newValue
        }
    )
    let help = URL(string: "https://example.invalid/help")!
    let view = EmptyView().certificateSheet(
        trust: binding,
        title: "Certificate",
        message: "Inspect this certificate.",
        help: help
    )

    precondition(view.title == "Certificate")
    precondition(view.message == "Inspect this certificate.")
    precondition(view.help == help)
    precondition(SecurityUIHostControl.certificateSheetHasTrust(view))
    precondition(!SecurityUIHostControl.certificateSheetDidPresent(view))
    precondition(writes == 0)
    precondition(stored != nil)

    _ = view.body
    precondition(writes == 0)
    precondition(stored != nil)

    let defaults = EmptyView().certificateSheet(trust: Binding(get: { nil }, set: { _ in }))
    precondition(defaults.title == nil)
    precondition(defaults.message == nil)
    precondition(defaults.help == nil)
    precondition(!SecurityUIHostControl.certificateSheetHasTrust(defaults))
    precondition(!SecurityUIHostControl.certificateSheetDidPresent(defaults))
}
