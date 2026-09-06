import Foundation
import WebKit

// Exercises equality, inequality, hash(into:), hashValue and keyed lookup.
// No fixed hash output is assumed: Swift seeds Hasher per process.
private func pageValueTable<T: Hashable>(_ values: [T]) {
    precondition(Set(values).count == values.count)
    var map: [T: Int] = [:]
    for (index, value) in values.enumerated() {
        let copy = value
        precondition(value == copy && !(value != copy))
        precondition(value.hashValue == copy.hashValue)
        var first = Hasher()
        var second = first
        value.hash(into: &first)
        copy.hash(into: &second)
        precondition(first.finalize() == second.finalize())
        map[value] = index
        for (otherIndex, other) in values.enumerated() {
            precondition((value == other) == (index == otherIndex))
            precondition((value != other) == (index != otherIndex))
        }
    }
    for (index, value) in values.enumerated() { precondition(map[value] == index) }
}

func testPageCSSMediaRoundTrip() {
    let values: [WebPage.CSSMediaType] = [.all, .print, .screen]
    precondition(values.map(\.rawValue) == ["all", "print", "screen"])
    for value in values {
        let raw: WebPage.CSSMediaType.RawValue = value.rawValue
        precondition(WebPage.CSSMediaType(rawValue: raw) == value)
    }
    let custom = WebPage.CSSMediaType(rawValue: "projection")
    precondition(custom.rawValue == "projection")
    precondition(WebPage.CSSMediaType(rawValue: "SCREEN") != .screen)
    precondition(WebPage.CSSMediaType(rawValue: "").rawValue.isEmpty)
    pageValueTable(values + [custom, .init(rawValue: "SCREEN"), .init(rawValue: "")])
}

func testPageNavigationPreferenceCopies() {
    let original = WebPage.NavigationPreferences()
    precondition(original.preferredContentMode == .recommended)
    precondition(original.allowsContentJavaScript)
    precondition(original.preferredHTTPSNavigationPolicy == .keepAsRequested)
    precondition(!original.isLockdownModeEnabled)
    var changed = original
    changed.preferredContentMode = .desktop
    changed.allowsContentJavaScript = false
    changed.preferredHTTPSNavigationPolicy = .errorOnFailure
    changed.isLockdownModeEnabled = true
    precondition(changed.preferredContentMode == .desktop)
    precondition(!changed.allowsContentJavaScript)
    precondition(changed.preferredHTTPSNavigationPolicy == .errorOnFailure)
    precondition(changed.isLockdownModeEnabled)
    precondition(original.preferredContentMode == .recommended)
    precondition(original.allowsContentJavaScript)
    precondition(original.preferredHTTPSNavigationPolicy == .keepAsRequested)
    precondition(!original.isLockdownModeEnabled)
}

func testPageContentModeValues() {
    pageValueTable([WebPage.NavigationPreferences.ContentMode.recommended, .mobile, .desktop])
}

func testPageHTTPSPolicyValues() {
    pageValueTable([WebPage.NavigationPreferences.UpgradeToHTTPSPolicy.keepAsRequested,
                   .automaticFallbackToHTTP, .userMediatedFallbackToHTTP, .errorOnFailure])
}

func testPageJavaScriptConfirmResults() {
    pageValueTable([WebPage.JavaScriptConfirmResult.ok, .cancel])
    func accepted(_ result: WebPage.JavaScriptConfirmResult) -> Bool {
        switch result {
        case .ok: return true
        case .cancel: return false
        @unknown default: preconditionFailure("unknown confirmation result")
        }
    }
    precondition(accepted(.ok) && !accepted(.cancel))
}

func testPageJavaScriptPromptPayloads() {
    let inputs = ["", "line\nbreak", "café 🧪", "cancel"]
    for input in inputs {
        let result = WebPage.JavaScriptPromptResult.ok(input)
        guard case .ok(let output) = result else { preconditionFailure("lost prompt text") }
        precondition(output == input)
    }
    pageValueTable([WebPage.JavaScriptPromptResult.cancel] + inputs.map { .ok($0) })
}

func testPageFilePromptSelectionOrder() {
    let a = URL(fileURLWithPath: "/tmp/alpha.txt")
    let b = URL(fileURLWithPath: "/tmp/beta.txt")
    var input = [a, b, a]
    let result = WebPage.FileInputPromptResult.selected(input)
    input.removeAll()
    guard case .selected(let output) = result else { preconditionFailure("lost file selection") }
    precondition(output == [a, b, a])
    pageValueTable([WebPage.FileInputPromptResult.cancel, .selected([]), .selected([a]),
                   .selected([a, b]), .selected([b, a]), result])
}

func testPageNavigationEventValues() {
    let sequence: [WebPage.NavigationEvent] = [.startedProvisionalNavigation,
        .receivedServerRedirect, .committed, .finished]
    pageValueTable(sequence)
    var committed = false
    for event in sequence {
        switch event {
        case .startedProvisionalNavigation: precondition(!committed)
        case .receivedServerRedirect: precondition(!committed)
        case .committed: committed = true
        case .finished: precondition(committed)
        @unknown default: preconditionFailure("unknown navigation event")
        }
    }
}

func testPageFullscreenStateValues() {
    pageValueTable([WebPage.FullscreenState.notInFullscreen, .enteringFullscreen,
                   .inFullscreen, .exitingFullscreen])
}

func testPageSensorPermissionPayloads() {
    let types: [WKMediaCaptureType] = [.camera, .microphone, .cameraAndMicrophone]
    var permissions: [WebPage.DeviceSensorAuthorization.Permission] = [.deviceOrientationAndMotion]
    for type in types {
        let permission = WebPage.DeviceSensorAuthorization.Permission.mediaCapture(type)
        guard case .mediaCapture(let restored) = permission else { preconditionFailure("lost capture type") }
        precondition(restored == type)
        permissions.append(permission)
    }
    pageValueTable(permissions)
}

func testPageNavigationErrorBridgeAndPayload() {
    let underlying = NSError(domain: "WebPageValueProbe", code: 77, userInfo: ["detail": "kept"])
    let failure = WebPage.NavigationError.failedProvisionalNavigation(underlying)
    guard case .failedProvisionalNavigation(let restored) = failure else {
        preconditionFailure("lost underlying navigation failure")
    }
    precondition((restored as NSError) === underlying)
    precondition((restored as NSError).userInfo["detail"] as? String == "kept")
    let cases: [(WebPage.NavigationError, Int)] = [
        (failure, 0), (.pageClosed, 1), (.webContentProcessTerminated, 2), (.invalidURL, 3)
    ]
    for (value, code) in cases {
        let bridged = value as NSError
        precondition(bridged.domain == "WebKit.WebPage.NavigationError")
        precondition(bridged.code == code)
        precondition(!value.localizedDescription.isEmpty)
    }
}

func testPageConfigurationNavigationValueIsolation() {
    MainActor.assumeIsolated {
        let original = WebPage.Configuration()
        var changed = original
        changed.defaultNavigationPreferences.allowsContentJavaScript = false
        changed.defaultNavigationPreferences.preferredContentMode = .mobile
        changed.defaultNavigationPreferences.preferredHTTPSNavigationPolicy = .automaticFallbackToHTTP
        changed.defaultNavigationPreferences.isLockdownModeEnabled = true
        precondition(original.defaultNavigationPreferences.allowsContentJavaScript)
        precondition(original.defaultNavigationPreferences.preferredContentMode == .recommended)
        precondition(original.defaultNavigationPreferences.preferredHTTPSNavigationPolicy == .keepAsRequested)
        precondition(!original.defaultNavigationPreferences.isLockdownModeEnabled)
        precondition(!changed.defaultNavigationPreferences.allowsContentJavaScript)
        precondition(changed.defaultNavigationPreferences.preferredContentMode == .mobile)
        precondition(changed.defaultNavigationPreferences.preferredHTTPSNavigationPolicy == .automaticFallbackToHTTP)
        precondition(changed.defaultNavigationPreferences.isLockdownModeEnabled)
    }
}

func testPageMediaPlaybackPreferenceValues() {
    pageValueTable([WebPage.Configuration.MediaPlaybackBehavior.automatic,
                   .alwaysFullscreen, .allowsInlinePlayback])
}

func testPageConfigurationCopyMutation() {
    MainActor.assumeIsolated {
        let original = WebPage.Configuration()
        var copy = original
        precondition(original.loadsSubresources && original.upgradeKnownHostsToHTTPS)
        precondition(!original.allowsInlinePredictions && !original.ignoresViewportScaleLimits)
        precondition(!original.supportsAdaptiveImageGlyph && original.allowsAirPlayForMediaPlayback)
        precondition(!original.suppressesIncrementalRendering && original.showsSystemScreenTimeBlockingView)
        precondition(!original.limitsNavigationsToAppBoundDomains && original.dataDetectorTypes.isEmpty)
        precondition(original.mediaPlaybackBehavior == .automatic)
        copy.loadsSubresources = false
        copy.upgradeKnownHostsToHTTPS = false
        copy.allowsInlinePredictions = true
        copy.ignoresViewportScaleLimits = true
        copy.supportsAdaptiveImageGlyph = true
        copy.allowsAirPlayForMediaPlayback = false
        copy.suppressesIncrementalRendering = true
        copy.showsSystemScreenTimeBlockingView = false
        copy.limitsNavigationsToAppBoundDomains = true
        copy.dataDetectorTypes = [.link, .phoneNumber]
        copy.mediaPlaybackBehavior = .allowsInlinePlayback
        copy.applicationNameForUserAgent = "ValueProbe/1"
        precondition(!copy.loadsSubresources && !copy.upgradeKnownHostsToHTTPS)
        precondition(copy.allowsInlinePredictions && copy.ignoresViewportScaleLimits)
        precondition(copy.supportsAdaptiveImageGlyph && !copy.allowsAirPlayForMediaPlayback)
        precondition(copy.suppressesIncrementalRendering && !copy.showsSystemScreenTimeBlockingView)
        precondition(copy.limitsNavigationsToAppBoundDomains && copy.dataDetectorTypes == [.link, .phoneNumber])
        precondition(copy.mediaPlaybackBehavior == .allowsInlinePlayback)
        precondition(copy.applicationNameForUserAgent == "ValueProbe/1")
        precondition(original.loadsSubresources && original.upgradeKnownHostsToHTTPS)
        precondition(!original.allowsInlinePredictions && !original.ignoresViewportScaleLimits)
        precondition(!original.supportsAdaptiveImageGlyph && original.allowsAirPlayForMediaPlayback)
        precondition(!original.suppressesIncrementalRendering && original.showsSystemScreenTimeBlockingView)
        precondition(!original.limitsNavigationsToAppBoundDomains && original.dataDetectorTypes.isEmpty)
        precondition(original.mediaPlaybackBehavior == .automatic)
        precondition(original.applicationNameForUserAgent == nil)
    }
}

func testPagePresentationPropertyRoundTrips() {
    MainActor.assumeIsolated {
        let page = WebPage(configuration: WebPage.Configuration())
        let title: String = page.title
        precondition(title.isEmpty && page.url == nil && !page.isLoading)
        precondition(page.estimatedProgress == 0 && !page.hasOnlySecureContent)
        precondition(page.customUserAgent == "" && page.mediaType == nil && !page.isInspectable)
        page.mediaType = .print
        precondition(page.mediaType == .print)
        page.mediaType = WebPage.CSSMediaType(rawValue: "projection")
        precondition(page.mediaType?.rawValue == "projection")
        page.mediaType = nil
        page.customUserAgent = "Probe/1"
        page.isInspectable = true
        precondition(page.mediaType == nil && page.customUserAgent == "Probe/1" && page.isInspectable)
        page.customUserAgent = nil
        page.isInspectable = false
        precondition(page.customUserAgent == "" && !page.isInspectable)
    }
}
