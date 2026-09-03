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
    public private(set) var estimatedProgress: Double = 0
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
        _beginUnavailableNavigation(
            request: request,
            navigationType: .other,
            operation: "load(request:)"
        )
    }

    @discardableResult
    open func loadFileURL(
        _ url: URL,
        allowingReadAccessTo readAccessURL: URL
    ) -> WKNavigation? {
        _beginUnavailableNavigation(
            request: URLRequest(url: url),
            navigationType: .other,
            operation: "loadFileURL(_:allowingReadAccessTo:)"
        )
    }

    @discardableResult
    open func loadHTMLString(_ string: String, baseURL: URL?) -> WKNavigation? {
        let requested = baseURL ?? URL(string: "about:blank")!
        return _beginUnavailableNavigation(
            request: URLRequest(url: requested),
            navigationType: .other,
            operation: "loadHTMLString(_:baseURL:)"
        )
    }

    @discardableResult
    open func load(
        _ data: Data,
        mimeType: String,
        characterEncodingName: String,
        baseURL: URL
    ) -> WKNavigation? {
        _beginUnavailableNavigation(
            request: URLRequest(url: baseURL),
            navigationType: .other,
            operation: "load(_:mimeType:characterEncodingName:baseURL:)"
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
        return _beginUnavailableNavigation(
            request: URLRequest(url: url),
            navigationType: .reload,
            operation: "reload()"
        )
    }

    @discardableResult
    open func reloadFromOrigin() -> WKNavigation? {
        guard let url else { return nil }
        return _beginUnavailableNavigation(
            request: URLRequest(
                url: url,
                cachePolicy: .reloadIgnoringLocalCacheData
            ),
            navigationType: .reload,
            operation: "reloadFromOrigin()"
        )
    }

    @discardableResult
    open func goBack() -> WKNavigation? {
        guard let item = backForwardList.backItem else { return nil }
        return _beginUnavailableNavigation(
            request: URLRequest(url: item.url),
            navigationType: .backForward,
            operation: "goBack()"
        )
    }

    @discardableResult
    open func goForward() -> WKNavigation? {
        guard let item = backForwardList.forwardItem else { return nil }
        return _beginUnavailableNavigation(
            request: URLRequest(url: item.url),
            navigationType: .backForward,
            operation: "goForward()"
        )
    }

    @discardableResult
    open func go(to item: WKBackForwardListItem) -> WKNavigation? {
        guard backForwardList._portableContains(item) else { return nil }
        return _beginUnavailableNavigation(
            request: URLRequest(url: item.url),
            navigationType: .backForward,
            operation: "go(to:)"
        )
    }

    open func evaluateJavaScript(
        _ javaScriptString: String,
        completionHandler: ((Any?, Error?) -> Void)? = nil
    ) {
        completionHandler?(
            nil,
            WKError(
                code: .unknown,
                operation: "evaluateJavaScript(_:)"
            )
        )
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
        backForwardList._portableRecordCommitted(url: url, title: title)
        _setObservedIfChanged(\WKWebView.url, stringKey: "url", storage: &self.url, to: Optional(url))
        let recordedTitle: String? = title ?? ""
        _setObservedIfChanged(\WKWebView.title, stringKey: "title", storage: &self.title, to: recordedTitle)
    }

    @discardableResult
    private func _beginUnavailableNavigation(
        request: URLRequest,
        navigationType: WKNavigationType,
        operation: String
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
            targetFrame: WKFrameInfo(isMainFrame: true, request: request)
        )
        if isDeliveringFailure {
            _setObservedIfChanged(
                \WKWebView.url, stringKey: "url", storage: &url, to: request.url
            )
            _setObservedIfChanged(
                \WKWebView.title, stringKey: "title", storage: &title, to: ""
            )
            estimatedProgress = 0
            hasOnlySecureContent = false
            _setObservedIfChanged(
                \WKWebView.isLoading, stringKey: "isLoading", storage: &isLoading, to: false
            )
            _portableLastError = WKError(
                code: .unknown,
                operation: operation,
                requestedURL: request.url
            )
            return navigation
        }
        var decided = false

        let apply: (WKNavigationActionPolicy, WKWebpagePreferences) -> Void = {
            [weak self, weak navigation] policy, selectedPreferences in
            guard let self, let navigation, !decided else { return }
            decided = true
            guard self.navigationGeneration == generation else { return }
            guard policy == .allow else {
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
                \WKWebView.url, stringKey: "url", storage: &self.url, to: request.url
            )
            self._setObservedIfChanged(
                \WKWebView.title, stringKey: "title", storage: &self.title, to: ""
            )
            self.estimatedProgress = 0
            self.hasOnlySecureContent = false
            self._setObservedIfChanged(
                \WKWebView.isLoading, stringKey: "isLoading", storage: &self.isLoading, to: true
            )
            self._portableLastError = nil
            self.navigationDelegate?.webView(
                self,
                didStartProvisionalNavigation: navigation
            )

            // No transport or renderer is linked. A provisional failure is a
            // real outcome; didCommit/didFinish are deliberately impossible.
            // Setting the requested URL without committing history is the
            // established inert-but-stateful load: a silent fake success would
            // put a URL bar into browsing mode over a blank page.
            let failure = WKError(
                code: .unknown,
                operation: operation,
                requestedURL: request.url
            )
            self._setObservedIfChanged(
                \WKWebView.isLoading, stringKey: "isLoading", storage: &self.isLoading, to: false
            )
            self._portableLastError = failure
            // Focus and many browsers respond to a provisional failure by
            // synchronously loading locally generated error-page data. There
            // is still no renderer, so that nested request cannot succeed;
            // record its terminal error without recursively invoking the same
            // delegate until the stack overflows. A later, non-reentrant load
            // remains observable through a fresh failure callback.
            self.isDeliveringFailure = true
            self.navigationDelegate?.webView(
                self,
                didFailProvisionalNavigation: navigation,
                withError: failure
            )
            self.isDeliveringFailure = false
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
