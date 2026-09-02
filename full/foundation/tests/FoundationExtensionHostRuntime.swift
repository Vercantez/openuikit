import Dispatch
import Foundation
@_spi(OpenUIKitHost) import FoundationExtensionHostSupport
import Synchronization

typealias PortableContext = FoundationExtensionHostSupport.NSExtensionContext
typealias PortableItem = FoundationExtensionHostSupport.NSExtensionItem
typealias PortableProvider = FoundationExtensionHostSupport.NSItemProvider

enum RuntimeFailure: Error {
    case expected(String)
    case cancelled
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw RuntimeFailure.expected(message) }
}

func reflectedKeys(_ item: PortableItem) -> String {
    (item.userInfo ?? [:]).keys.compactMap { $0 as? String }.sorted()
        .joined(separator: ",")
}

final class PortableRequestHandler: NSObject,
    FoundationExtensionHostSupport.NSExtensionRequestHandling {
    private(set) var received: PortableContext?

    func beginRequest(with context: PortableContext) {
        received = context
    }
}

let completeSignature:
    (PortableContext) ->
        ([Any]?, (@Sendable (Bool) -> Void)?) -> Void =
    PortableContext.completeRequest
let cancelSignature:
    (PortableContext) -> (any Error) -> Void =
    PortableContext.cancelRequest
let openSignature:
    (PortableContext) ->
        (URL, (@Sendable (Bool) -> Void)?) -> Void =
    PortableContext.open
let asyncOpenSignature:
    (PortableContext) -> (URL) async -> Bool =
    PortableContext.open
_ = (
    completeSignature,
    cancelSignature,
    openSignature,
    asyncOpenSignature
)

print(
    "FOUNDATION_EXTENSION_ORACLE constants=" + [
        FoundationExtensionHostSupport.NSExtensionItemsAndErrorsKey,
        FoundationExtensionHostSupport.NSExtensionItemAttributedTitleKey,
        FoundationExtensionHostSupport
            .NSExtensionItemAttributedContentTextKey,
        FoundationExtensionHostSupport.NSExtensionItemAttachmentsKey,
        FoundationExtensionHostSupport
            .NSExtensionJavaScriptPreprocessingResultsKey,
        FoundationExtensionHostSupport
            .NSExtensionJavaScriptFinalizeArgumentKey,
        "NSExtensionHostWillEnterForegroundNotification",
        "NSExtensionHostDidEnterBackgroundNotification",
        "NSExtensionHostWillResignActiveNotification",
        "NSExtensionHostDidBecomeActiveNotification",
    ].joined(separator: ",")
)

let context = PortableContext()
let item = PortableItem()
print(
    "FOUNDATION_EXTENSION_ORACLE defaults="
        + "input:\(context.inputItems.count),"
        + "title:\(item.attributedTitle == nil ? "nil" : "value"),"
        + "content:\(item.attributedContentText == nil ? "nil" : "value"),"
        + "attachments:\(item.attachments == nil ? "nil" : "value"),"
        + "userInfo:\(item.userInfo?.count ?? -1),"
        + "secure:\(PortableItem.supportsSecureCoding)"
)

let title = NSAttributedString(string: "title")
let content = NSMutableAttributedString(string: "content")
let provider = PortableProvider(
    item: "payload" as NSString,
    typeIdentifier: "public.text"
)
item.attributedTitle = title
item.attributedContentText = content
item.attachments = [provider]
print(
    "FOUNDATION_EXTENSION_ORACLE setterCopies="
        + "title:\(item.attributedTitle !== title),"
        + "content:\(item.attributedContentText !== content),"
        + "attachmentRetained:\(item.attachments?.first === provider)"
)
print(
    "FOUNDATION_EXTENSION_ORACLE reflectedKeys=\(reflectedKeys(item))"
)

let itemCopy = item.copy() as! PortableItem
print(
    "FOUNDATION_EXTENSION_ORACLE itemCopy="
        + "distinct:\(itemCopy !== item),"
        + "titleDistinct:\(itemCopy.attributedTitle !== item.attributedTitle),"
        + "contentDistinct:"
        + "\(itemCopy.attributedContentText !== item.attributedContentText),"
        + "providerDistinct:"
        + "\(itemCopy.attachments?.first !== item.attachments?.first)"
)

item.userInfo = ["custom": "value"]
print(
    "FOUNDATION_EXTENSION_ORACLE userInfoSetter="
        + "custom:\(item.userInfo?["custom"] as? String ?? "nil"),"
        + "title:\(item.attributedTitle == nil ? "nil" : "value"),"
        + "content:"
        + "\(item.attributedContentText == nil ? "nil" : "value"),"
        + "attachments:\(item.attachments == nil ? "nil" : "value")"
)

let providerCopy = provider.copy() as! PortableProvider
print(
    "FOUNDATION_EXTENSION_ORACLE provider="
        + "copyDistinct:\(providerCopy !== provider),"
        + "types:\(providerCopy.registeredTypeIdentifiers.joined(separator: ","))"
)

// Project-owned secure archive behavior. Unlike Apple's NSItemProvider,
// portable metadata archives do not require an NSXPCCoder and never restore
// an opaque item payload as if an XPC transfer had succeeded.
let archiveItem = PortableItem()
archiveItem.attributedTitle = NSAttributedString(string: "archive-title")
let archiveProvider = PortableProvider(
    item: "private" as NSString,
    typeIdentifier: "public.text"
)
archiveProvider.suggestedName = "note.txt"
archiveItem.attachments = [archiveProvider]
archiveItem.userInfo?["custom"] = "archive-value"
let archive = try NSKeyedArchiver.archivedData(
    withRootObject: archiveItem,
    requiringSecureCoding: true
)
let unarchiver = try NSKeyedUnarchiver(forReadingFrom: archive)
unarchiver.requiresSecureCoding = true
let decoded = try requireDecoded(
    unarchiver.decodeObject(
        of: PortableItem.self,
        forKey: NSKeyedArchiveRootObjectKey
    )
)
unarchiver.finishDecoding()
try require(decoded.attributedTitle?.string == "archive-title", "archive title")
try require(decoded.attachments?.count == 1, "archive attachment count")
try require(
    decoded.attachments?.first?.registeredTypeIdentifiers == ["public.text"],
    "archive provider identifiers"
)
try require(
    decoded.attachments?.first?.suggestedName == "note.txt",
    "archive provider suggested name"
)
try require(
    decoded.userInfo?["custom"] as? String == "archive-value",
    "archive custom user info"
)

let hostContext = PortableContext(inputItems: ["first", 2])
try require(hostContext.inputItems.count == 2, "host input items")
let openResult = Mutex<Bool?>(nil)
hostContext.open(URL(string: "https://example.invalid/")!) { success in
    openResult.withLock { $0 = success }
}
try require(openResult.withLock { $0 } == false, "URL open must fail closed")
try require(
    hostContext.portableRejectedOpenRequestCount == 1,
    "rejected URL count"
)

let expiredResult = Mutex<Bool?>(nil)
hostContext.completeRequest(returningItems: ["one", "two"]) { expired in
    expiredResult.withLock { $0 = expired }
}
try require(expiredResult.withLock { $0 } == true, "completion must expire")
try require(
    hostContext.portableHostDisposition
        == .completionUnavailable(returnedItemCount: 2),
    "completion disposition"
)

let cancelledContext = PortableContext()
cancelledContext.cancelRequest(withError: RuntimeFailure.cancelled)
guard case .cancelled = cancelledContext.portableHostDisposition else {
    throw RuntimeFailure.expected("cancel disposition")
}

let concurrentContext = PortableContext()
final class ContextBox: @unchecked Sendable {
    let value: PortableContext
    init(_ value: PortableContext) { self.value = value }
}
let contextBox = ContextBox(concurrentContext)
let falseCallbacks = Mutex(0)
DispatchQueue.concurrentPerform(iterations: 64) { index in
    contextBox.value.open(
        URL(string: "https://example.invalid/\(index)")!
    ) { success in
        if !success { falseCallbacks.withLock { $0 += 1 } }
    }
}
try require(falseCallbacks.withLock { $0 } == 64, "concurrent callbacks")
try require(
    concurrentContext.portableRejectedOpenRequestCount == 64,
    "concurrent rejected count"
)

let handler = PortableRequestHandler()
handler.beginRequest(with: hostContext)
try require(handler.received === hostContext, "request handling identity")

print(
    "FOUNDATION_EXTENSION_RUNTIME coding=secure,copy,metadata "
        + "context=fail-closed callbacks=66 concurrency=64"
)
print("FOUNDATION_EXTENSION_HOST_RUNTIME_OK")

func requireDecoded<T>(_ value: T?) throws -> T {
    guard let value else { throw RuntimeFailure.expected("archive decode") }
    return value
}
