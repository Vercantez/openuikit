@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
// UIKit/OpenUIKit types come from WebKit.swift (real import or Linux lookalikes).

@preconcurrency @MainActor
open class WKWebView: UIView {
    public let configuration: WKWebViewConfiguration
    public weak var navigationDelegate: WKNavigationDelegate?
    public weak var uiDelegate: WKUIDelegate?
    public let backForwardList = WKBackForwardList()
    public let scrollView: UIScrollView

    open var allowsBackForwardNavigationGestures = false
    open var allowsLinkPreview = true
    open var customUserAgent: String? = ""
    open var isInspectable = false
    open var isFindInteractionEnabled = false
    open var interactionState: Any?
    open var mediaType: String?
    open var pageZoom: CGFloat = 1
    public private(set) var cameraCaptureState: WKMediaCaptureState = .none
    public private(set) var microphoneCaptureState: WKMediaCaptureState = .none
    public private(set) var fullscreenState: FullscreenState = .notInFullscreen
    public private(set) var isBlockedByScreenTime = false
    public private(set) var isWritingToolsActive = false
    public private(set) var certificateChain: [Any] = []
    public private(set) var themeColor: UIColor?
    public private(set) var minimumViewportInset: UIEdgeInsets = .zero
    public private(set) var maximumViewportInset: UIEdgeInsets = .zero

    public enum FullscreenState: Int, Hashable, Sendable {
        case notInFullscreen = 0
        case enteringFullscreen = 1
        case inFullscreen = 2
        case exitingFullscreen = 3
    }

    private var _obscuredContentInsets: UIEdgeInsets = .zero
    /// Insets covered by app-owned chrome. WebKit requires every edge to be
    /// non-negative; invalid geometry fails before mutating retained state.
    open var obscuredContentInsets: UIEdgeInsets {
        get { _obscuredContentInsets }
        set {
            precondition(
                newValue.top >= 0 && newValue.left >= 0 &&
                    newValue.bottom >= 0 && newValue.right >= 0,
                "WKWebView obscuredContentInsets must be non-negative"
            )
            _setObserved(
                \WKWebView.obscuredContentInsets,
                stringKey: "obscuredContentInsets",
                storage: &_obscuredContentInsets,
                to: newValue
            )
        }
    }

    private var _underPageBackgroundColor: UIColor? = .white
    /// A renderer may replace this value from page content. With no renderer,
    /// the explicitly assigned app value remains authoritative and observable.
    open var underPageBackgroundColor: UIColor? {
        get { _underPageBackgroundColor }
        set {
            // `null_resettable` resets to WebKit's opaque-white default.
            let resolvedValue: UIColor? = newValue ?? .white
            _setObservedIfChanged(
                \WKWebView.underPageBackgroundColor,
                stringKey: "underPageBackgroundColor",
                storage: &_underPageBackgroundColor,
                to: resolvedValue
            )
        }
    }

    public private(set) var url: URL?
    public private(set) var title: String? = ""
    // MEASURED mozilla-mobile/focus-ios a2832521
    // WebViewController.swift:177 `observe(\WKWebView.estimatedProgress)`.
    // Apple Foundation's NSObject.observe requires `_kvcKeyPathString`;
    // without @objc dynamic that KeyPath traps
    // `Could not extract a String from KeyPath`.
    // `@objc` is Darwin-only: Linux Swift 6.2.4 has no ObjC interop
    // (`swift build --build-tests` on swift:6.2-noble compiles this product).
#if canImport(ObjectiveC)
    @objc dynamic public private(set) var estimatedProgress: Double = 0
#else
    public private(set) var estimatedProgress: Double = 0
#endif
    public private(set) var isLoading = false
    public private(set) var hasOnlySecureContent = false
    internal var _portableLastError: WKError?

    open var canGoBack: Bool {
        backForwardList.backItem != nil
    }
    open var canGoForward: Bool {
        backForwardList.forwardItem != nil
    }

    private var navigationGeneration: UInt64 = 0
    private var isDeliveringFailure = false
    private var isAllMediaPlaybackSuspended = false
    private var stringObservers: [_WKStringKeyPathObserver] = []
    private var portableDocumentHTML: String?
    private var portableDocumentMIME = "text/html"

    public init(frame: CGRect, configuration: WKWebViewConfiguration) {
        self.configuration = configuration._portableCopyForWebView()
        self.scrollView = UIScrollView(
            frame: CGRect(origin: .zero, size: frame.size)
        )
        super.init(frame: frame)
        addSubview(scrollView)
    }

    public override convenience init(frame: CGRect) {
        self.init(frame: frame, configuration: WKWebViewConfiguration())
    }

    public required init?(coder: NSCoder) {
        self.configuration = WKWebViewConfiguration()
        self.scrollView = UIScrollView()
        super.init(coder: coder)
        addSubview(scrollView)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = bounds
    }

    @discardableResult
    open func load(_ request: URLRequest) -> WKNavigation? {
        _beginNavigation(
            request: request,
            navigationType: .other,
            operation: "load(request:)",
            html: nil,
            mimeType: "text/html",
            networkUnavailable: WKPortableIsNetworkURL(request.url)
        )
    }

    @discardableResult
    open func loadFileURL(
        _ url: URL,
        allowingReadAccessTo readAccessURL: URL
    ) -> WKNavigation? {
        var html: String?
        var unavailable = true
        if url.path.hasPrefix(readAccessURL.path),
           FileManager.default.fileExists(atPath: url.path),
           let data = try? Data(contentsOf: url) {
            html = String(data: data, encoding: .utf8) ?? ""
            unavailable = false
        }
        return _beginNavigation(
            request: URLRequest(url: url),
            navigationType: .other,
            operation: "loadFileURL(_:allowingReadAccessTo:)",
            html: html,
            mimeType: "text/html",
            networkUnavailable: unavailable
        )
    }

    @discardableResult
    open func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        let requested = baseURL ?? URL(string: "about:blank")!
        return _beginNavigation(
            request: URLRequest(url: requested),
            navigationType: .other,
            operation: "loadHTMLString(_:baseURL:)",
            html: string,
            mimeType: "text/html",
            networkUnavailable: false
        )
    }

    @discardableResult
    open func load(
        _ data: Data,
        mimeType: String,
        characterEncodingName: String,
        baseURL: URL
    ) -> WKNavigation? {
        let encoding = _portableStringEncoding(characterEncodingName)
        let html = String(data: data, encoding: encoding) ?? String(data: data, encoding: .utf8)
        return _beginNavigation(
            request: URLRequest(url: baseURL),
            navigationType: .other,
            operation: "load(_:mimeType:characterEncodingName:baseURL:)",
            html: html,
            mimeType: mimeType,
            networkUnavailable: false
        )
    }

    open func stopLoading() {
        navigationGeneration &+= 1
        _setObservedIfChanged(
            \WKWebView.isLoading, stringKey: "isLoading", storage: &isLoading, to: false
        )
    }

    /// Retains the suspension state even though the portable WebKit has no
    /// media engine. Completion is delivered exactly once after the state
    /// transition has committed, allowing callers to serialize later loads.
    open func setAllMediaPlaybackSuspended(
        _ suspended: Bool,
        completionHandler: (@MainActor @Sendable () -> Void)? = nil
    ) {
        isAllMediaPlaybackSuspended = suspended
        guard let completionHandler else { return }
        Task { @MainActor in
            // Apple's completion is never delivered before this method
            // returns. Yielding also preserves call order on the main actor.
            await Task.yield()
            completionHandler()
        }
    }

    /// Swift-concurrency spelling synthesized by Apple's WebKit importer.
    open func setAllMediaPlaybackSuspended(_ suspended: Bool) async {
        await withCheckedContinuation { continuation in
            setAllMediaPlaybackSuspended(suspended) {
                continuation.resume()
            }
        }
    }

    @discardableResult
    open func reload() -> WKNavigation? {
        guard let url else { return nil }
        return _beginNavigation(
            request: URLRequest(url: url),
            navigationType: .reload,
            operation: "reload()",
            html: portableDocumentHTML,
            mimeType: portableDocumentMIME,
            networkUnavailable: portableDocumentHTML == nil && WKPortableIsNetworkURL(url)
        )
    }

    @discardableResult
    open func reloadFromOrigin() -> WKNavigation? {
        guard let url else { return nil }
        return _beginNavigation(
            request: URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalCacheData
            ),
            navigationType: .reload,
            operation: "reloadFromOrigin()",
            html: portableDocumentHTML,
            mimeType: portableDocumentMIME,
            networkUnavailable: portableDocumentHTML == nil && WKPortableIsNetworkURL(url)
        )
    }

    @discardableResult
    open func goBack() -> WKNavigation? {
        guard let item = backForwardList.backItem else { return nil }
        return _navigateToHistoryItem(item, operation: "goBack()")
    }

    @discardableResult
    open func goForward() -> WKNavigation? {
        guard let item = backForwardList.forwardItem else { return nil }
        return _navigateToHistoryItem(item, operation: "goForward()")
    }

    @discardableResult
    open func go(to item: WKBackForwardListItem) -> WKNavigation? {
        guard backForwardList._portableContains(item) else { return nil }
        return _navigateToHistoryItem(item, operation: "go(to:)")
    }

    open func evaluateJavaScript(
        _ javaScriptString: String,
        completionHandler: ((Any?, Error?) -> Void)? = nil
    ) {
        if let post = WKPortableParsePostMessage(javaScriptString) {
            let delivered = configuration.userContentController._portableDeliver(
                name: post.name,
                body: post.body,
                webView: self,
                world: .page
            )
            if delivered {
                completionHandler?(nil, nil)
            } else {
                completionHandler?(
                    nil,
                    WKPortableJavaScriptUnavailable("evaluateJavaScript(_:)")
                )
            }
            return
        }
        if let dialog = WKPortableParseJSDialog(javaScriptString) {
            let frame = WKFrameInfo(isMainFrame: true, request: URLRequest(url: url ?? URL(string: "about:blank")!), webView: self)
            switch dialog {
            case .alert(let message):
                var finished = false
                uiDelegate?.webView(
                    self,
                    runJavaScriptAlertPanelWithMessage: message,
                    initiatedByFrame: frame
                ) {
                    finished = true
                }
                completionHandler?(finished ? NSNull() : NSNull(), nil)
                return
            case .confirm(let message):
                var allowed = false
                uiDelegate?.webView(
                    self,
                    runJavaScriptConfirmPanelWithMessage: message,
                    initiatedByFrame: frame
                ) { allowed = $0 }
                completionHandler?(allowed, nil)
                return
            case .prompt(let prompt, let defaultText):
                var text: String?
                uiDelegate?.webView(
                    self,
                    runJavaScriptTextInputPanelWithPrompt: prompt,
                    defaultText: defaultText,
                    initiatedByFrame: frame
                ) { text = $0 }
                completionHandler?(text ?? NSNull(), nil)
                return
            }
        }
        switch WKPortableJavaScriptLiteral(javaScriptString) {
        case .value(let value):
            completionHandler?(value, nil)
        case .notLiteral:
            completionHandler?(
                nil,
                WKPortableJavaScriptUnavailable("evaluateJavaScript(_:)")
            )
        }
    }

    open func evaluateJavaScript(_ javaScriptString: String) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            evaluateJavaScript(javaScriptString) { value, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: value)
                }
            }
        }
    }

    open func evaluateJavaScript(
        _ javaScriptString: String,
        in frame: WKFrameInfo?,
        in contentWorld: WKContentWorld,
        completionHandler: ((Any?, Error?) -> Void)? = nil
    ) {
        _ = (frame, contentWorld)
        evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

    open func evaluateJavaScript(
        _ javaScriptString: String,
        in frame: WKFrameInfo?,
        contentWorld: WKContentWorld
    ) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            evaluateJavaScript(
                javaScriptString,
                in: frame,
                in: contentWorld
            ) { value, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: value)
                }
            }
        }
    }

    open func callAsyncJavaScript(
        _ functionBody: String,
        arguments: [String: Any] = [:],
        in frame: WKFrameInfo?,
        in contentWorld: WKContentWorld,
        completionHandler: ((Any?, Error?) -> Void)? = nil
    ) {
        _ = (arguments, frame, contentWorld)
        var body = functionBody.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.hasPrefix("return ") {
            body = String(body.dropFirst(7))
        }
        if body.hasSuffix(";") {
            body.removeLast()
        }
        body = body.trimmingCharacters(in: .whitespacesAndNewlines)
        switch WKPortableJavaScriptLiteral(body) {
        case .value(let value):
            completionHandler?(value, nil)
        case .notLiteral:
            completionHandler?(
                nil,
                WKPortableJavaScriptUnavailable("callAsyncJavaScript")
            )
        }
    }

    open func callAsyncJavaScript(
        _ functionBody: String,
        arguments: [String: Any] = [:],
        in frame: WKFrameInfo?,
        contentWorld: WKContentWorld
    ) async throws -> Any? {
        try await withCheckedThrowingContinuation { continuation in
            callAsyncJavaScript(
                functionBody,
                arguments: arguments,
                in: frame,
                in: contentWorld
            ) { value, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: value)
                }
            }
        }
    }

    public class func handlesURLScheme(_ urlScheme: String) -> Bool {
        WKPortableEqualsIgnoreASCIICase(urlScheme, "http")
            || WKPortableEqualsIgnoreASCIICase(urlScheme, "https")
            || WKPortableEqualsIgnoreASCIICase(urlScheme, "file")
            || WKPortableEqualsIgnoreASCIICase(urlScheme, "about")
            || WKPortableEqualsIgnoreASCIICase(urlScheme, "data")
    }

    open func closeAllMediaPresentations() {
        closeAllMediaPresentations(completionHandler: nil)
    }

    open func closeAllMediaPresentations(completionHandler: (@MainActor () -> Void)? = nil) {
        if let completionHandler {
            WKPortableCompleteAfterReturn(completionHandler)
        }
    }

    open func pauseAllMediaPlayback(completionHandler: (@MainActor () -> Void)? = nil) {
        if let completionHandler {
            WKPortableCompleteAfterReturn(completionHandler)
        }
    }

    open func requestMediaPlaybackState(
        completionHandler: @escaping @MainActor (WKMediaPlaybackState) -> Void
    ) {
        WKPortableCompleteAfterReturn {
            completionHandler(.none)
        }
    }

    open func setCameraCaptureState(_ state: WKMediaCaptureState) async {
        cameraCaptureState = state
    }

    open func setMicrophoneCaptureState(_ state: WKMediaCaptureState) async {
        microphoneCaptureState = state
    }

    open func setMinimumViewportInset(
        _ minimumViewportInset: UIEdgeInsets,
        maximumViewportInset: UIEdgeInsets
    ) {
        self.minimumViewportInset = minimumViewportInset
        self.maximumViewportInset = maximumViewportInset
    }

    @discardableResult
    open func loadFileRequest(
        _ request: URLRequest,
        allowingReadAccessTo readAccessURL: URL
    ) -> WKNavigation? {
        guard let url = request.url else {
            return _beginNavigation(
                request: request,
                navigationType: .other,
                operation: "loadFileRequest(_:allowingReadAccessTo:)",
                html: nil,
                mimeType: "text/html",
                networkUnavailable: true
            )
        }
        return loadFileURL(url, allowingReadAccessTo: readAccessURL)
    }

    @discardableResult
    open func loadSimulatedRequest(
        _ request: URLRequest,
        responseHTML string: String
    ) -> WKNavigation {
        _beginNavigation(
            request: request,
            navigationType: .other,
            operation: "loadSimulatedRequest(_:responseHTML:)",
            html: string,
            mimeType: "text/html",
            networkUnavailable: false
        )
    }

    @discardableResult
    open func loadSimulatedRequest(
        _ request: URLRequest,
        withResponseHTML string: String
    ) -> WKNavigation {
        loadSimulatedRequest(request, responseHTML: string)
    }

    @discardableResult
    open func loadSimulatedRequest(
        _ request: URLRequest,
        response: URLResponse,
        responseData data: Data
    ) -> WKNavigation {
        let mime = response.mimeType ?? "application/octet-stream"
        let html = String(data: data, encoding: .utf8)
        return _beginNavigation(
            request: request,
            navigationType: .other,
            operation: "loadSimulatedRequest(_:response:responseData:)",
            html: html,
            mimeType: mime,
            networkUnavailable: false,
            responseOverride: response
        )
    }

    @discardableResult
    open func loadSimulatedRequest(
        _ request: URLRequest,
        with response: URLResponse,
        responseData data: Data
    ) -> WKNavigation {
        loadSimulatedRequest(request, response: response, responseData: data)
    }

    open func fetchData(of dataTypes: WKWebViewDataType) async throws -> Data {
        _ = dataTypes
        throw WKPortableUnknown("fetchData(of:)")
    }

    open func restoreData(_ data: Data) async throws {
        _ = data
        throw WKPortableUnknown("restoreData")
    }

    open func startDownload(
        using request: URLRequest,
        completionHandler: @escaping (WKDownload) -> Void
    ) {
        completionHandler(WKDownload(request: request, webView: self, userInitiated: true))
    }

    open func startDownload(using request: URLRequest) async -> WKDownload {
        await withCheckedContinuation { continuation in
            startDownload(using: request) { continuation.resume(returning: $0) }
        }
    }

    open func resumeDownload(
        fromResumeData resumeData: Data,
        completionHandler: @escaping (WKDownload) -> Void
    ) {
        _ = resumeData
        completionHandler(WKDownload(request: nil, webView: self))
    }

    open func resumeDownload(fromResumeData resumeData: Data) async -> WKDownload {
        await withCheckedContinuation { continuation in
            resumeDownload(fromResumeData: resumeData) { continuation.resume(returning: $0) }
        }
    }

    open func takeSnapshot(
        configuration snapshotConfiguration: WKSnapshotConfiguration?,
        completionHandler: @escaping (UIImage?, Error?) -> Void
    ) {
        _ = snapshotConfiguration
        completionHandler(nil, WKPortableUnknown("takeSnapshot"))
    }

    open func takeSnapshot(configuration snapshotConfiguration: WKSnapshotConfiguration?) async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            takeSnapshot(configuration: snapshotConfiguration) { image, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(throwing: WKPortableUnknown("takeSnapshot"))
                }
            }
        }
    }

    open func createPDF(
        configuration: WKPDFConfiguration,
        completionHandler: @escaping (Result<Data, any Error>) -> Void
    ) {
        _ = configuration
        completionHandler(.failure(WKPortableUnknown("createPDF")))
    }

    open func pdf(configuration: WKPDFConfiguration) async throws -> Data {
        throw WKPortableUnknown("pdf(configuration:)")
    }

    open func createWebArchiveData(completionHandler: @escaping (Result<Data, any Error>) -> Void) {
        completionHandler(.failure(WKPortableUnknown("createWebArchiveData")))
    }

    open func find(
        _ string: String,
        configuration: WKFindConfiguration,
        completionHandler: @escaping (WKFindResult) -> Void
    ) {
        _ = (string, configuration)
        completionHandler(WKFindResult(matchFound: false))
    }

    open func find(_ string: String, configuration: WKFindConfiguration) async -> WKFindResult {
        await withCheckedContinuation { continuation in
            find(string, configuration: configuration) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// String-keypath KVO used by Focus. Typed `observe(\.url)` is delivered
    /// through Foundation's portable observation substrate; this path delivers
    /// the classic `addObserver` seam deterministically without an ObjC runtime.
    #if canImport(Darwin)
    open override func addObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions = [],
        context: UnsafeMutableRawPointer? = nil
    ) {
        _portableAddObserver(
            observer, forKeyPath: keyPath, options: options, context: context
        )
    }

    open override func removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        _portableRemoveObserver(observer, forKeyPath: keyPath, context: nil, matchContext: false)
    }

    open override func removeObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        context: UnsafeMutableRawPointer?
    ) {
        _portableRemoveObserver(observer, forKeyPath: keyPath, context: context, matchContext: true)
    }
    #else
    open func addObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions = [],
        context: UnsafeMutableRawPointer? = nil
    ) {
        _portableAddObserver(
            observer, forKeyPath: keyPath, options: options, context: context
        )
    }

    open func removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        _portableRemoveObserver(observer, forKeyPath: keyPath, context: nil, matchContext: false)
    }

    open func removeObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        context: UnsafeMutableRawPointer?
    ) {
        _portableRemoveObserver(observer, forKeyPath: keyPath, context: context, matchContext: true)
    }
    #endif

    private func _portableAddObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions,
        context: UnsafeMutableRawPointer?
    ) {
        stringObservers.append(
            _WKStringKeyPathObserver(
                observer: observer,
                keyPath: keyPath,
                options: options,
                context: context
            )
        )
        if options.contains(.initial) {
            _deliverStringKVO(
                keyPath: keyPath,
                oldValue: nil,
                newValue: _portableValue(forStringKeyPath: keyPath),
                isPrior: false,
                forceInitial: true
            )
        }
    }

    private func _portableRemoveObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        context: UnsafeMutableRawPointer?,
        matchContext: Bool
    ) {
        stringObservers.removeAll {
            $0.observer === observer && $0.keyPath == keyPath &&
                (!matchContext || $0.context == context)
        }
    }

    internal func _portableRecordCommittedItem(url: URL, title: String?) {
        let oldBack = canGoBack
        let oldForward = canGoForward
        backForwardList._portableRecordCommitted(url: url, title: title)
        _setObservedIfChanged(\WKWebView.url, stringKey: "url", storage: &self.url, to: Optional(url))
        let recordedTitle: String? = title ?? ""
        _setObservedIfChanged(\WKWebView.title, stringKey: "title", storage: &self.title, to: recordedTitle)
        _publishHistoryKVO(oldBack: oldBack, oldForward: oldForward)
    }

    @discardableResult
    private func _navigateToHistoryItem(
        _ item: WKBackForwardListItem,
        operation: String
    ) -> WKNavigation? {
        var allowed = true
        navigationDelegate?.webView(
            self,
            shouldGoTo: item,
            willUseInstantBack: false
        ) { allowed = $0 }
        guard allowed else { return nil }
        let hasLocalDocument = item.portableHTML != nil
        return _beginNavigation(
            request: URLRequest(url: item.url),
            navigationType: .backForward,
            operation: operation,
            html: item.portableHTML,
            mimeType: item.portableMIME,
            networkUnavailable: !hasLocalDocument && WKPortableIsNetworkURL(item.url),
            historyItem: item
        )
    }

    @discardableResult
    private func _beginNavigation(
        request: URLRequest,
        navigationType: WKNavigationType,
        operation: String,
        html: String?,
        mimeType: String,
        networkUnavailable: Bool,
        historyItem: WKBackForwardListItem? = nil,
        responseOverride: URLResponse? = nil
    ) -> WKNavigation {
        navigationGeneration &+= 1
        let generation = navigationGeneration
        let preferences = configuration.defaultWebpagePreferences._portableCopy()
        let navigation = WKNavigation(
            requestedURL: request.url,
            effectiveContentMode: preferences.preferredContentMode
        )
        let action = WKNavigationAction(
            request: request,
            navigationType: navigationType,
            targetFrame: WKFrameInfo(
                isMainFrame: true,
                request: request,
                webView: self
            )
        )
        if isDeliveringFailure {
            // A nested load from `didFailProvisionalNavigation` installs a
            // local error document without a second provisional cycle. The
            // first-pass host runtime requires starts==1, failures==1, and
            // no back-forward item for `about:portable-error`.
            _setObservedIfChanged(
                \WKWebView.url, stringKey: "url", storage: &url, to: request.url
            )
            let nestedTitle = html.flatMap(WKPortableHTMLTitle) ?? ""
            _setObservedIfChanged(
                \WKWebView.title, stringKey: "title", storage: &title, to: nestedTitle
            )
            _setObservedIfChanged(
                \WKWebView.estimatedProgress,
                stringKey: "estimatedProgress",
                storage: &estimatedProgress,
                to: 0
            )
            hasOnlySecureContent = false
            portableDocumentHTML = html
            portableDocumentMIME = mimeType
            _setObservedIfChanged(
                \WKWebView.isLoading, stringKey: "isLoading", storage: &isLoading, to: false
            )
            if networkUnavailable {
                _portableLastError = WKError(
                    code: .unknown,
                    operation: operation,
                    requestedURL: request.url
                )
            }
            return navigation
        }
        var decided = false

        let apply: (WKNavigationActionPolicy, WKWebpagePreferences) -> Void = {
            [weak self, weak navigation] policy, selectedPreferences in
            guard let self, let navigation, !decided else { return }
            decided = true
            guard self.navigationGeneration == generation else { return }
            guard policy == .allow else {
                if policy == .download {
                    let download = WKDownload(
                        request: request,
                        webView: self,
                        userInitiated: false
                    )
                    self.navigationDelegate?.webView(
                        self,
                        navigationAction: action,
                        didBecome: download
                    )
                    download.delegate?.download(
                        download,
                        didFailWithError: WKPortableUnknown(
                            "WKNavigationActionPolicy.download",
                            url: request.url
                        ),
                        resumeData: nil
                    )
                }
                self._setObservedIfChanged(
                    \WKWebView.isLoading,
                    stringKey: "isLoading",
                    storage: &self.isLoading,
                    to: false
                )
                return
            }

            navigation.effectiveContentMode = selectedPreferences.preferredContentMode
            self._setObservedIfChanged(
                \WKWebView.isLoading, stringKey: "isLoading", storage: &self.isLoading, to: true
            )
            self._setObservedIfChanged(
                \WKWebView.url, stringKey: "url", storage: &self.url, to: request.url
            )
            self._setObservedIfChanged(
                \WKWebView.title, stringKey: "title", storage: &self.title, to: ""
            )
            // WebKit WKWebView.mm initialProgressValue = 0.1 at provisional start.
            self._setObservedIfChanged(
                \WKWebView.estimatedProgress,
                stringKey: "estimatedProgress",
                storage: &self.estimatedProgress,
                to: 0.1
            )
            self.hasOnlySecureContent = {
                guard let scheme = request.url?.scheme else { return false }
                return WKPortableEqualsIgnoreASCIICase(scheme, "https")
            }()
            self._portableLastError = nil
            // Apple: didStartProvisionalNavigation after provisional approval,
            // before a response (WKNavigationDelegate).
            self.navigationDelegate?.webView(
                self,
                didStartProvisionalNavigation: navigation
            )
            guard self.navigationGeneration == generation else { return }

            var documentHTML = html
            var documentMIME = mimeType
            var documentResponse = responseOverride
            var unavailable = networkUnavailable

            if let scheme = request.url?.scheme,
               let handler = self.configuration.urlSchemeHandler(forURLScheme: scheme) {
                let task = _WKPortableURLSchemeTask(request: request)
                handler.webView(self, start: task)
                if let error = task.failure {
                    self._failProvisional(
                        navigation: navigation,
                        error: error as? WKError ?? WKError(
                            code: .unknown,
                            operation: operation,
                            requestedURL: request.url
                        ),
                        generation: generation
                    )
                    return
                }
                if let response = task.response {
                    documentResponse = response
                    documentMIME = response.mimeType ?? documentMIME
                    documentHTML = String(data: task.body, encoding: .utf8) ?? documentHTML
                    unavailable = false
                }
            }

            if unavailable {
                let failure = WKError(
                    code: .unknown,
                    operation: operation,
                    requestedURL: request.url
                )
                self._failProvisional(
                    navigation: navigation,
                    error: failure,
                    generation: generation
                )
                return
            }

            let response = documentResponse ?? URLResponse(
                url: request.url ?? URL(string: "about:blank")!,
                mimeType: documentMIME,
                expectedContentLength: documentHTML?.utf8.count ?? 0,
                textEncodingName: "utf-8"
            )
            let navigationResponse = WKNavigationResponse(
                response: response,
                canShowMIMEType: WKPortableCanShowMIMEType(documentMIME),
                isForMainFrame: true
            )
            var responseDecided = false
            let applyResponse: (WKNavigationResponsePolicy) -> Void = { policy in
                guard !responseDecided else { return }
                responseDecided = true
                guard self.navigationGeneration == generation else { return }
                guard policy == .allow else {
                    if policy == .download {
                        let download = WKDownload(
                            request: request,
                            webView: self,
                            userInitiated: false
                        )
                        self.navigationDelegate?.webView(
                            self,
                            navigationResponse: navigationResponse,
                            didBecome: download
                        )
                        download.delegate?.download(
                            download,
                            didFailWithError: WKPortableUnknown(
                                "WKNavigationResponsePolicy.download",
                                url: request.url
                            ),
                            resumeData: nil
                        )
                        self._setObservedIfChanged(
                            \WKWebView.isLoading,
                            stringKey: "isLoading",
                            storage: &self.isLoading,
                            to: false
                        )
                        return
                    }
                    self._failProvisional(
                        navigation: navigation,
                        error: WKError(
                            code: .unknown,
                            operation: operation,
                            requestedURL: request.url
                        ),
                        generation: generation
                    )
                    return
                }
                self._commitAndFinish(
                    navigation: navigation,
                    request: request,
                    html: documentHTML,
                    mimeType: documentMIME,
                    historyItem: historyItem,
                    generation: generation
                )
            }
            if let navigationDelegate = self.navigationDelegate {
                navigationDelegate.webView(
                    self,
                    decidePolicyFor: navigationResponse,
                    decisionHandler: applyResponse
                )
            } else {
                applyResponse(.allow)
            }
        }

        if let navigationDelegate {
            navigationDelegate.webView(
                self,
                decidePolicyFor: action,
                preferences: preferences,
                decisionHandler: apply
            )
        } else {
            apply(.allow, preferences)
        }
        return navigation
    }

    private func _failProvisional(
        navigation: WKNavigation,
        error: WKError,
        generation: UInt64
    ) {
        guard navigationGeneration == generation else { return }
        _setObservedIfChanged(
            \WKWebView.estimatedProgress,
            stringKey: "estimatedProgress",
            storage: &estimatedProgress,
            to: 0
        )
        _setObservedIfChanged(
            \WKWebView.isLoading, stringKey: "isLoading", storage: &isLoading, to: false
        )
        _portableLastError = error
        isDeliveringFailure = true
        navigationDelegate?.webView(
            self,
            didFailProvisionalNavigation: navigation,
            withError: error
        )
        isDeliveringFailure = false
    }

    private func _commitAndFinish(
        navigation: WKNavigation,
        request: URLRequest,
        html: String?,
        mimeType: String,
        historyItem: WKBackForwardListItem?,
        generation: UInt64
    ) {
        guard navigationGeneration == generation else { return }
        // Apple: didCommit after navigation-response policy, immediately
        // before the main frame updates (webView(_:didCommit:)).
        navigationDelegate?.webView(self, didCommit: navigation)
        guard navigationGeneration == generation else { return }

        portableDocumentHTML = html
        portableDocumentMIME = mimeType
        let parsedTitle = html.flatMap(WKPortableHTMLTitle)
        let committedURL = request.url ?? URL(string: "about:blank")!
        let oldBack = canGoBack
        let oldForward = canGoForward
        if let historyItem {
            backForwardList._portableSelect(historyItem)
            _setObservedIfChanged(
                \WKWebView.url, stringKey: "url", storage: &url, to: Optional(historyItem.url)
            )
            let restored: String? = parsedTitle ?? historyItem.title ?? ""
            _setObservedIfChanged(
                \WKWebView.title, stringKey: "title", storage: &title, to: restored
            )
        } else {
            backForwardList._portableRecordCommitted(
                url: committedURL,
                title: parsedTitle,
                html: html,
                mimeType: mimeType
            )
            _setObservedIfChanged(
                \WKWebView.url, stringKey: "url", storage: &url, to: Optional(committedURL)
            )
            _setObservedIfChanged(
                \WKWebView.title, stringKey: "title", storage: &title, to: parsedTitle ?? ""
            )
        }
        _publishHistoryKVO(oldBack: oldBack, oldForward: oldForward)
        _setObservedIfChanged(
            \WKWebView.estimatedProgress,
            stringKey: "estimatedProgress",
            storage: &estimatedProgress,
            to: 1.0
        )
        navigationDelegate?.webView(self, didFinish: navigation)
        guard navigationGeneration == generation else { return }
        _setObservedIfChanged(
            \WKWebView.isLoading, stringKey: "isLoading", storage: &isLoading, to: false
        )
    }

    private func _publishHistoryKVO(oldBack: Bool, oldForward: Bool) {
        if oldBack != canGoBack {
            _deliverStringKVO(
                keyPath: "canGoBack",
                oldValue: oldBack,
                newValue: canGoBack,
                isPrior: false,
                forceInitial: false
            )
        }
        if oldForward != canGoForward {
            _deliverStringKVO(
                keyPath: "canGoForward",
                oldValue: oldForward,
                newValue: canGoForward,
                isPrior: false,
                forceInitial: false
            )
        }
    }

    private func _portableStringEncoding(_ name: String) -> String.Encoding {
        if WKPortableEqualsIgnoreASCIICase(name, "utf-8") { return .utf8 }
        if WKPortableEqualsIgnoreASCIICase(name, "utf-16") { return .utf16 }
        if WKPortableEqualsIgnoreASCIICase(name, "iso-8859-1") { return .isoLatin1 }
        return .utf8
    }

    private func _setObserved<Value>(
        _ keyPath: KeyPath<WKWebView, Value>,
        stringKey: String? = nil,
        storage: inout Value,
        to newValue: Value
    ) {
        let oldValue = storage
        #if !PORTABLE_WEBKIT_HOST && (canImport(UIKit) || canImport(OpenUIKit))
        _portableWillChangeValue(for: keyPath, oldValue: oldValue)
        #endif
        if let stringKey {
            _deliverStringKVO(
                keyPath: stringKey,
                oldValue: oldValue,
                newValue: newValue,
                isPrior: true,
                forceInitial: false
            )
        }
        storage = newValue
        #if !PORTABLE_WEBKIT_HOST && (canImport(UIKit) || canImport(OpenUIKit))
        _portableDidChangeValue(
            for: keyPath, oldValue: oldValue, newValue: newValue
        )
        #endif
        if let stringKey {
            _deliverStringKVO(
                keyPath: stringKey,
                oldValue: oldValue,
                newValue: newValue,
                isPrior: false,
                forceInitial: false
            )
        }
    }

    private func _setObservedIfChanged<Value: Equatable>(
        _ keyPath: KeyPath<WKWebView, Value>,
        stringKey: String? = nil,
        storage: inout Value,
        to newValue: Value
    ) {
        guard storage != newValue else { return }
        _setObserved(keyPath, stringKey: stringKey, storage: &storage, to: newValue)
    }

    private func _portableValue(forStringKeyPath keyPath: String) -> Any? {
        switch keyPath {
        case "url", "URL":
            return url
        case "title":
            return title
        case "isLoading", "loading":
            return isLoading
        case "estimatedProgress":
            return estimatedProgress
        case "hasOnlySecureContent":
            return hasOnlySecureContent
        case "canGoBack":
            return canGoBack
        case "canGoForward":
            return canGoForward
        case "underPageBackgroundColor":
            return underPageBackgroundColor
        case "obscuredContentInsets":
            return obscuredContentInsets
        default:
            return nil
        }
    }

    private func _deliverStringKVO(
        keyPath: String,
        oldValue: Any?,
        newValue: Any?,
        isPrior: Bool,
        forceInitial: Bool
    ) {
        let aliases: [String]
        switch keyPath {
        case "url":
            aliases = ["url", "URL"]
        case "isLoading":
            aliases = ["isLoading", "loading"]
        default:
            aliases = [keyPath]
        }
        for registration in stringObservers {
            guard aliases.contains(registration.keyPath) else { continue }
            guard let observer = registration.observer else { continue }
            if forceInitial {
                guard registration.options.contains(.initial) else { continue }
            } else if isPrior {
                guard registration.options.contains(.prior) else { continue }
            }
            var change: [String: Any] = ["kind": 1]
            if isPrior {
                change["notificationIsPrior"] = true
            }
            if registration.options.contains(.old) {
                if let oldValue {
                    change["old"] = oldValue
                }
            }
            if forceInitial || (!isPrior && registration.options.contains(.new)) {
                if let newValue {
                    change["new"] = newValue
                }
            }
            if let host = observer as? any WebKitHostKeyValueObserver {
                host.observeValue(
                    forKeyPath: registration.keyPath,
                    of: self,
                    change: change,
                    context: registration.context
                )
            }
        }
    }
}

private struct _WKStringKeyPathObserver {
    weak var observer: NSObject?
    let keyPath: String
    let options: NSKeyValueObservingOptions
    let context: UnsafeMutableRawPointer?
}

@MainActor
private final class _WKPortableURLSchemeTask: NSObject, WKURLSchemeTask {
    let request: URLRequest
    private(set) var response: URLResponse?
    private(set) var body = Data()
    private(set) var failure: Error?
    private var stopped = false

    init(request: URLRequest) {
        self.request = request
        super.init()
    }

    func didReceive(_ response: URLResponse) {
        guard !stopped else { return }
        self.response = response
    }

    func didReceive(_ data: Data) {
        guard !stopped else { return }
        body.append(data)
    }

    func didFinish() {
        stopped = true
    }

    func didFailWithError(_ error: any Error) {
        failure = error
        stopped = true
    }
}
