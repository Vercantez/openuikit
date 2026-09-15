import Foundation

extension WebPage {
    // Local navigation-policy values. There is no Web Content process on the
    // isolated host, so these describe already-decided local state rather
    // than driving a renderer. `buttonNumber` (UIKit `UIEvent.ButtonMask`)
    // is intentionally absent: the isolated host has no UIKit module and
    // framework-local substitutes for dependency-owned types are forbidden.

    @preconcurrency @MainActor
    public struct FrameInfo: Sendable {
        public let isMainFrame: Bool
        public let request: URLRequest
        public let securityOrigin: WKSecurityOrigin

        public init(
            isMainFrame: Bool = true,
            request: URLRequest = URLRequest(url: URL(string: "about:blank")!),
            securityOrigin: WKSecurityOrigin? = nil
        ) {
            self.isMainFrame = isMainFrame
            self.request = request
            self.securityOrigin = securityOrigin ?? WKSecurityOrigin()
        }
    }

    @preconcurrency @MainActor
    public struct NavigationAction: Sendable {
        public let source: FrameInfo
        public let target: FrameInfo?
        public let navigationType: WKNavigationType
        public let request: URLRequest
        public let shouldPerformDownload: Bool
        public let isContentRuleListRedirect: Bool

        public init(
            source: FrameInfo,
            target: FrameInfo? = nil,
            navigationType: WKNavigationType = .other,
            request: URLRequest = URLRequest(url: URL(string: "about:blank")!),
            shouldPerformDownload: Bool = false,
            isContentRuleListRedirect: Bool = false
        ) {
            self.source = source
            self.target = target
            self.navigationType = navigationType
            self.request = request
            self.shouldPerformDownload = shouldPerformDownload
            self.isContentRuleListRedirect = isContentRuleListRedirect
        }
    }

    @preconcurrency @MainActor
    public struct NavigationResponse: Sendable {
        public let response: URLResponse
        public let canShowMimeType: Bool

        public init(response: URLResponse, canShowMimeType: Bool) {
            self.response = response
            self.canShowMimeType = canShowMimeType
        }
    }
}
