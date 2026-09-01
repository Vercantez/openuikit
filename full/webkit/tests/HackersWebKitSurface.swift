import Foundation
import UIKit
import WebKit

/// Strict Swift 6 spelling gate for the exact WebKit/Foundation surface used
/// by Hackers' untouched `EmbeddedWebView.swift`. The full application driver
/// remains the authoritative source-denominator proof. Pinned source SHA-256:
/// `627146616ab48fd16ceb6c87890eb52b621e2cf2ad0e21d657e1576736f7d30f`.
@MainActor
func compileHackersWebKitSurface(webView: WKWebView) {
    var obscuredContentInsets = webView.obscuredContentInsets
    obscuredContentInsets.bottom = 24
    webView.obscuredContentInsets = obscuredContentInsets

    webView.setAllMediaPlaybackSuspended(true) {}
    _ = webView.underPageBackgroundColor

    let observations: [NSKeyValueObservation] = [
        webView.observe(\.url, options: [.new]) { _, _ in },
        webView.observe(\.title, options: [.new]) { _, _ in },
        webView.observe(\.canGoBack, options: [.new]) { _, _ in },
        webView.observe(\.canGoForward, options: [.new]) { _, _ in },
        webView.observe(\.isLoading, options: [.new]) { _, _ in },
        webView.observe(
            \.underPageBackgroundColor,
            options: [.initial, .new]
        ) { _, _ in },
    ]
    withExtendedLifetime(observations) {}
}
