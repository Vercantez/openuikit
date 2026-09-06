@_exported import Foundation

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

public enum WKUserScriptInjectionTime: Int, Hashable, Sendable {
    case atDocumentStart = 0
    case atDocumentEnd = 1
}

@preconcurrency @MainActor
open class WKUserScript: NSObject {
    public let source: String
    public let injectionTime: WKUserScriptInjectionTime
    public let isForMainFrameOnly: Bool
    public let world: WKContentWorld

    public init(
        source: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool
    ) {
        self.source = source
        self.injectionTime = injectionTime
        self.isForMainFrameOnly = forMainFrameOnly
        self.world = .page
        super.init()
    }

    public init(
        source: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool,
        in world: WKContentWorld
    ) {
        self.source = source
        self.injectionTime = injectionTime
        self.isForMainFrameOnly = forMainFrameOnly
        self.world = world
        super.init()
    }
}

@preconcurrency @MainActor
public protocol WKScriptMessageHandler: AnyObject {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    )
}

@preconcurrency @MainActor
open class WKScriptMessage: NSObject {
    public let name: String
    public let body: Any
    public let frameInfo: WKFrameInfo
    public weak var webView: WKWebView?
    public let world: WKContentWorld

    public init(
        name: String,
        body: Any,
        frameInfo: WKFrameInfo? = nil,
        webView: WKWebView? = nil,
        world: WKContentWorld? = nil
    ) {
        self.name = name
        self.body = body
        self.frameInfo = frameInfo ?? WKFrameInfo()
        self.webView = webView
        self.world = world ?? .page
        super.init()
    }
}

@preconcurrency @MainActor
open class WKContentRuleList: NSObject {
    public let identifier: String

    // The input is retained so lookup is stateful.  It is not public because
    // native WKContentRuleList does not expose source and because this object
    // is not an executable rule program without an engine.
    internal let _portableEncodedSource: String

    internal init(identifier: String, encodedSource: String) {
        self.identifier = identifier
        self._portableEncodedSource = encodedSource
        super.init()
    }
}

@preconcurrency @MainActor
open class WKContentRuleListStore: NSObject {
    private static let shared = WKContentRuleListStore()
    private static var directoryStores: [String: WKContentRuleListStore] = [:]
    private var lists: [String: WKContentRuleList] = [:]

    public static func `default`() -> WKContentRuleListStore! {
        shared
    }

    /// Apple's `storeWithURL:` — a store rooted at `url`. Bytes stay in process
    /// memory; the URL is the identity key only (no Web Content compiler).
    public static func store(with url: URL) -> WKContentRuleListStore {
        let key = url.absoluteString
        if let existing = directoryStores[key] { return existing }
        let created = WKContentRuleListStore()
        directoryStores[key] = created
        return created
    }

    public convenience init(url: URL) {
        self.init()
        _ = url
    }

    open func compileContentRuleList(
        forIdentifier identifier: String,
        encodedContentRuleList: String?,
        completionHandler: @escaping (WKContentRuleList?, Error?) -> Void
    ) {
        guard !identifier.isEmpty, let encodedContentRuleList else {
            completionHandler(
                nil,
                WKError(
                    code: .contentRuleListStoreCompileFailed,
                    operation: "compileContentRuleList(\(identifier))"
                )
            )
            return
        }
        // Schema from Apple "Creating a content blocker": array of
        // {trigger.url-filter, action.type}; css-display-none needs selector.
        if let error = WKPortableValidateContentRuleList(
            encodedContentRuleList,
            identifier: identifier
        ) {
            completionHandler(nil, error)
            return
        }

        // Syntax-validated receipt, not an executable matcher. With no
        // transport there are no requests on which rules could run.
        let list = WKContentRuleList(
            identifier: identifier,
            encodedSource: encodedContentRuleList
        )
        lists[identifier] = list
        completionHandler(list, nil)
    }

    open func compileContentRuleList(
        forIdentifier identifier: String,
        encodedContentRuleList: String?
    ) async throws -> WKContentRuleList? {
        try await withCheckedThrowingContinuation { continuation in
            compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: encodedContentRuleList
            ) { list, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: list)
                }
            }
        }
    }

    open func contentRuleList(forIdentifier identifier: String) async throws -> WKContentRuleList? {
        try await withCheckedThrowingContinuation { continuation in
            lookUpContentRuleList(forIdentifier: identifier) { list, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: list)
                }
            }
        }
    }

    open func lookUpContentRuleList(
        forIdentifier identifier: String,
        completionHandler: @escaping (WKContentRuleList?, Error?) -> Void
    ) {
        if let list = lists[identifier] {
            completionHandler(list, nil)
        } else {
            completionHandler(
                nil,
                WKError(
                    code: .contentRuleListStoreLookUpFailed,
                    operation: "lookUpContentRuleList(\(identifier))"
                )
            )
        }
    }

    open func removeContentRuleList(
        forIdentifier identifier: String,
        completionHandler: @escaping (Error?) -> Void
    ) {
        lists.removeValue(forKey: identifier)
        completionHandler(nil)
    }

    open func getAvailableContentRuleListIdentifiers(
        _ completionHandler: @escaping ([String]?) -> Void
    ) {
        completionHandler(lists.keys.sorted())
    }

    open func availableIdentifiers() async -> [String]? {
        await withCheckedContinuation { continuation in
            getAvailableContentRuleListIdentifiers { continuation.resume(returning: $0) }
        }
    }

    open func removeContentRuleList(forIdentifier identifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            removeContentRuleList(forIdentifier: identifier) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

@preconcurrency @MainActor
open class WKUserContentController: NSObject {
    private var scripts: [WKUserScript] = []
    private var handlers: [String: WKScriptMessageHandler] = [:]
    private var replyHandlers: [String: WKScriptMessageHandlerWithReply] = [:]
    private var rules: [String: WKContentRuleList] = [:]

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
    }

    open var userScripts: [WKUserScript] {
        scripts
    }

    open func addUserScript(_ userScript: WKUserScript) {
        scripts.append(userScript)
    }

    open func removeAllUserScripts() {
        scripts.removeAll(keepingCapacity: false)
    }

    open func add(_ scriptMessageHandler: WKScriptMessageHandler, name: String) {
        precondition(!name.isEmpty, "WKScriptMessageHandler name must not be empty")
        precondition(handlers[name] == nil, "duplicate WKScriptMessageHandler name: \(name)")
        handlers[name] = scriptMessageHandler
    }

    open func add(
        _ scriptMessageHandler: any WKScriptMessageHandler,
        contentWorld world: WKContentWorld,
        name: String
    ) {
        _ = world
        add(scriptMessageHandler, name: name)
    }

    open func addScriptMessageHandler(
        _ scriptMessageHandlerWithReply: any WKScriptMessageHandlerWithReply,
        contentWorld world: WKContentWorld,
        name: String
    ) {
        _ = world
        precondition(!name.isEmpty, "WKScriptMessageHandler name must not be empty")
        replyHandlers[name] = scriptMessageHandlerWithReply
    }

    open func removeScriptMessageHandler(forName name: String) {
        handlers.removeValue(forKey: name)
        replyHandlers.removeValue(forKey: name)
    }

    open func removeScriptMessageHandler(forName name: String, contentWorld: WKContentWorld) {
        _ = contentWorld
        removeScriptMessageHandler(forName: name)
    }

    open func removeAllScriptMessageHandlers() {
        handlers.removeAll(keepingCapacity: false)
        replyHandlers.removeAll(keepingCapacity: false)
    }

    open func removeAllScriptMessageHandlers(from contentWorld: WKContentWorld) {
        _ = contentWorld
        removeAllScriptMessageHandlers()
    }

    open func add(_ contentRuleList: WKContentRuleList) {
        rules[contentRuleList.identifier] = contentRuleList
    }

    open func remove(_ contentRuleList: WKContentRuleList) {
        guard rules[contentRuleList.identifier] === contentRuleList else { return }
        rules.removeValue(forKey: contentRuleList.identifier)
    }

    open func removeAllContentRuleLists() {
        rules.removeAll(keepingCapacity: false)
    }

    /// Portable diagnostic state. No script can be delivered without an
    /// engine; exposing registered names makes that configuration observable
    /// without pretending JavaScript ran.
    public var registeredScriptMessageHandlerNames: [String] {
        Set(handlers.keys).union(replyHandlers.keys).sorted()
    }

    public var registeredContentRuleListIdentifiers: [String] {
        rules.keys.sorted()
    }

    internal func _portableDeliver(
        name: String,
        body: Any,
        webView: WKWebView?,
        world: WKContentWorld
    ) -> Bool {
        let message = WKScriptMessage(
            name: name,
            body: body,
            webView: webView,
            world: world
        )
        if let handler = handlers[name] {
            handler.userContentController(self, didReceive: message)
            return true
        }
        if let handler = replyHandlers[name] {
            handler.userContentController(self, didReceive: message) { _, _ in }
            return true
        }
        return false
    }
}
