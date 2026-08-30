@_exported import Foundation

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
import class Foundation.NSObject
#endif

public enum WKUserScriptInjectionTime: Int, Sendable {
    case atDocumentStart = 0
    case atDocumentEnd = 1
}

@preconcurrency @MainActor
open class WKUserScript: NSObject {
    public let source: String
    public let injectionTime: WKUserScriptInjectionTime
    public let isForMainFrameOnly: Bool

    public init(
        source: String,
        injectionTime: WKUserScriptInjectionTime,
        forMainFrameOnly: Bool
    ) {
        self.source = source
        self.injectionTime = injectionTime
        self.isForMainFrameOnly = forMainFrameOnly
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

    public init(name: String, body: Any, frameInfo: WKFrameInfo? = nil) {
        self.name = name
        self.body = body
        self.frameInfo = frameInfo ?? WKFrameInfo()
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

private struct _WKRuleEnvelope: Decodable {
    let trigger: _WKJSONValue
    let action: _WKJSONValue
}

private struct _WKDynamicKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

private enum _WKJSONValue: Decodable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([_WKJSONValue])
    case object([String: _WKJSONValue])

    init(from decoder: Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: _WKDynamicKey.self) {
            var result: [String: _WKJSONValue] = [:]
            for key in keyed.allKeys {
                result[key.stringValue] = try keyed.decode(_WKJSONValue.self, forKey: key)
            }
            self = .object(result)
            return
        }
        if var unkeyed = try? decoder.unkeyedContainer() {
            var result: [_WKJSONValue] = []
            while !unkeyed.isAtEnd {
                result.append(try unkeyed.decode(_WKJSONValue.self))
            }
            self = .array(result)
            return
        }
        let single = try decoder.singleValueContainer()
        if single.decodeNil() {
            self = .null
        } else if let value = try? single.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? single.decode(Double.self) {
            self = .number(value)
        } else {
            self = .string(try single.decode(String.self))
        }
    }
}

@preconcurrency @MainActor
open class WKContentRuleListStore: NSObject {
    private static let shared = WKContentRuleListStore()
    private var lists: [String: WKContentRuleList] = [:]

    public static func `default`() -> WKContentRuleListStore {
        shared
    }

    open func compileContentRuleList(
        forIdentifier identifier: String,
        encodedContentRuleList: String?,
        completionHandler: @escaping (WKContentRuleList?, Error?) -> Void
    ) {
        guard !identifier.isEmpty, let encodedContentRuleList,
              let payload = encodedContentRuleList.data(using: .utf8),
              (try? JSONDecoder().decode([_WKRuleEnvelope].self, from: payload)) != nil
        else {
            completionHandler(
                nil,
                WKPortableError(
                    code: .invalidContentRuleList,
                    operation: "compileContentRuleList(\(identifier))"
                )
            )
            return
        }

        // This is a syntax-validated receipt, not an executable matcher.  With
        // no transport there are no requests on which rules could be falsely
        // claimed to run; the distinction is documented and runtime-tested.
        let list = WKContentRuleList(
            identifier: identifier,
            encodedSource: encodedContentRuleList
        )
        lists[identifier] = list
        completionHandler(list, nil)
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
                WKPortableError(
                    code: .contentRuleListNotFound,
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
}

@preconcurrency @MainActor
open class WKUserContentController: NSObject {
    private var scripts: [WKUserScript] = []
    private var handlers: [String: WKScriptMessageHandler] = [:]
    private var rules: [String: WKContentRuleList] = [:]

    public override init() {
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

    open func removeScriptMessageHandler(forName name: String) {
        handlers.removeValue(forKey: name)
    }

    open func removeAllScriptMessageHandlers() {
        handlers.removeAll(keepingCapacity: false)
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
        handlers.keys.sorted()
    }

    public var registeredContentRuleListIdentifiers: [String] {
        rules.keys.sorted()
    }
}
