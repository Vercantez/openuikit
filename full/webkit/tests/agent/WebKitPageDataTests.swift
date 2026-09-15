#if canImport(CoreGraphics)
import CoreGraphics
#endif
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import WebKit

// Data/policy WebPage surface: export configuration values, sensor decision
// values, and dialog/navigation-decider protocol conformance. No renderer,
// sensor hardware, entitlement, panel, or Web Content process is implied, and
// no async behavior is awaited: the sealed runner stays synchronous.

func testPageExportedRegionValues() {
    let contents = WebPage.ExportedContentConfiguration.Region.contents
    precondition(contents.rectValue == nil)
    let box = CGRect(x: 4, y: 8, width: 160, height: 90)
    let region = WebPage.ExportedContentConfiguration.Region.rect(box)
    precondition(region.rectValue == box)
    precondition(region != contents)
    precondition(region == WebPage.ExportedContentConfiguration.Region.rect(box))
    precondition(
        WebPage.ExportedContentConfiguration.Region.rect(CGRect(x: 0, y: 0, width: 1, height: 1))
            != region
    )
    precondition(contents == WebPage.ExportedContentConfiguration.Region.contents)
}

func testPageExportedContentConfigurationValues() {
    let region = WebPage.ExportedContentConfiguration.Region.rect(
        CGRect(x: 4, y: 8, width: 160, height: 90)
    )

    let pdf = WebPage.ExportedContentConfiguration.pdf()
    precondition(pdf.kind == .pdf)
    precondition(pdf.region == .contents)
    precondition(!pdf.allowTransparentBackground)
    precondition(pdf.snapshotWidth == nil)
    precondition(pdf.afterScreenUpdates)
    precondition(
        pdf
            == WebPage.ExportedContentConfiguration.pdf(
                region: .contents,
                allowTransparentBackground: false
            )
    )
    let pdfCustom = WebPage.ExportedContentConfiguration.pdf(
        region: region,
        allowTransparentBackground: true
    )
    precondition(pdfCustom.kind == .pdf)
    precondition(pdfCustom.region == region)
    precondition(pdfCustom.allowTransparentBackground)
    precondition(pdfCustom != pdf)

    let image = WebPage.ExportedContentConfiguration.image()
    precondition(image.kind == .image)
    precondition(image.region == .contents)
    precondition(!image.allowTransparentBackground)
    precondition(image.snapshotWidth == nil)
    precondition(image.afterScreenUpdates)
    precondition(image != pdf)
    let imageCustom = WebPage.ExportedContentConfiguration.image(
        region: region,
        allowTransparentBackground: true,
        snapshotWidth: 320,
        afterScreenUpdates: false
    )
    precondition(imageCustom.kind == .image)
    precondition(imageCustom.region == region)
    precondition(imageCustom.allowTransparentBackground)
    precondition(imageCustom.snapshotWidth == 320)
    precondition(!imageCustom.afterScreenUpdates)
    precondition(imageCustom != image)
    precondition(
        image
            == WebPage.ExportedContentConfiguration.image(
                region: .contents,
                allowTransparentBackground: false,
                snapshotWidth: nil,
                afterScreenUpdates: true
            )
    )

    var first = Hasher()
    var second = Hasher()
    pdf.hash(into: &first)
    WebPage.ExportedContentConfiguration.pdf().hash(into: &second)
    precondition(first.finalize() == second.finalize())
    precondition(pdf.hashValue == WebPage.ExportedContentConfiguration.pdf().hashValue)
}

func testPageSensorAuthorizationDecisions() {
    let fixed = WebPage.DeviceSensorAuthorization(decision: .deny)
    precondition(!fixed.usesDecisionHandler)
    precondition(fixed.permissionPolicy == .deny)
    precondition(
        WebPage.DeviceSensorAuthorization(decision: .grant).permissionPolicy == .grant
    )
    precondition(
        WebPage.DeviceSensorAuthorization(decision: .prompt).permissionPolicy == .prompt
    )
    precondition(WebPage.DeviceSensorAuthorization().permissionPolicy == .prompt)
    precondition(
        WebPage.DeviceSensorAuthorization(permissionPolicy: .grant).permissionPolicy == .grant
    )

    let handlerAuth = WebPage.DeviceSensorAuthorization(decisionHandler: { _, _, _ in .deny })
    precondition(handlerAuth.usesDecisionHandler)
    precondition(handlerAuth.permissionPolicy == .prompt)
    precondition(handlerAuth != fixed)
    precondition(!(handlerAuth == fixed))
    let copy = handlerAuth
    precondition(copy == handlerAuth)
    precondition(copy.hashValue == handlerAuth.hashValue)
    precondition(
        WebPage.DeviceSensorAuthorization(decision: .deny) == fixed
    )
    precondition(
        WebPage.DeviceSensorAuthorization()
            == WebPage.DeviceSensorAuthorization(permissionPolicy: .prompt)
    )
}

@MainActor
private final class DataProbeDialogDecider: WebPage.DialogPresenting, WebPage.NavigationDeciding {
    func handleFileInputPrompt(
        parameters: WKOpenPanelParameters,
        initiatedBy frame: WebPage.FrameInfo
    ) async -> WebPage.FileInputPromptResult {
        _ = (parameters, frame)
        return .cancel
    }
    func handleJavaScriptAlert(
        message: String,
        initiatedBy frame: WebPage.FrameInfo
    ) async {
        _ = (message, frame)
    }
    func handleJavaScriptPrompt(
        message: String,
        defaultText: String?,
        initiatedBy frame: WebPage.FrameInfo
    ) async -> WebPage.JavaScriptPromptResult {
        _ = (message, defaultText, frame)
        return .cancel
    }
    func handleJavaScriptConfirm(
        message: String,
        initiatedBy frame: WebPage.FrameInfo
    ) async -> WebPage.JavaScriptConfirmResult {
        _ = (message, frame)
        return .cancel
    }
    func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        _ = (action, preferences)
        return .cancel
    }
    func decidePolicy(
        for response: WebPage.NavigationResponse
    ) async -> WKNavigationResponsePolicy {
        _ = response
        return .cancel
    }
    func decideAuthenticationChallengeDisposition(
        for challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        _ = challenge
        return (.cancelAuthenticationChallenge, nil)
    }
}

func testPageDialogAndNavigationDeciderConformances() {
    MainActor.assumeIsolated {
        let stub = DataProbeDialogDecider()
        let dialog: any WebPage.DialogPresenting = stub
        let decider: any WebPage.NavigationDeciding = stub
        _ = (dialog, decider)
        let page = WebPage(
            configuration: WebPage.Configuration(),
            navigationDecider: stub,
            dialogPresenter: stub
        )
        _ = page.configuration
    }
}
