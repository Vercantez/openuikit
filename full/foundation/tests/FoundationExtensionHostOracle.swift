import Darwin
import Foundation

// Compile-time signature pins from the iPhoneOS 26.1 import surface. The
// macOS runtime supplies the same Objective-C declarations for behavior
// observations; iOS-only constant objects are read from their exported slots.
let completeSignature:
    (NSExtensionContext) ->
        ([Any]?, (@Sendable (Bool) -> Void)?) -> Void =
    NSExtensionContext.completeRequest
let cancelSignature:
    (NSExtensionContext) -> (any Error) -> Void =
    NSExtensionContext.cancelRequest
let openSignature:
    (NSExtensionContext) ->
        (URL, (@Sendable (Bool) -> Void)?) -> Void =
    NSExtensionContext.open
let asyncOpenSignature:
    (NSExtensionContext) -> (URL) async -> Bool =
    NSExtensionContext.open

final class OracleRequestHandler: NSObject, NSExtensionRequestHandling {
    func beginRequest(with context: NSExtensionContext) {
        _ = context
    }
}

func exportedString(_ name: String) -> String {
    guard let slot = dlsym(UnsafeMutableRawPointer(bitPattern: -2), name),
          let value = slot.assumingMemoryBound(
              to: Optional<AnyObject>.self
          ).pointee else {
        return "MISSING"
    }
    return String(describing: value)
}

func reflectedKeys(_ item: NSExtensionItem) -> String {
    (item.userInfo ?? [:]).keys.compactMap { $0 as? String }.sorted()
        .joined(separator: ",")
}

_ = (
    completeSignature,
    cancelSignature,
    openSignature,
    asyncOpenSignature,
    OracleRequestHandler.self
)

print(
    "FOUNDATION_EXTENSION_ORACLE constants=" + [
        NSExtensionItemsAndErrorsKey,
        NSExtensionItemAttributedTitleKey,
        NSExtensionItemAttributedContentTextKey,
        NSExtensionItemAttachmentsKey,
        NSExtensionJavaScriptPreprocessingResultsKey,
        exportedString("NSExtensionJavaScriptFinalizeArgumentKey"),
        exportedString("NSExtensionHostWillEnterForegroundNotification"),
        exportedString("NSExtensionHostDidEnterBackgroundNotification"),
        exportedString("NSExtensionHostWillResignActiveNotification"),
        exportedString("NSExtensionHostDidBecomeActiveNotification"),
    ].joined(separator: ",")
)

let context = NSExtensionContext()
let item = NSExtensionItem()
print(
    "FOUNDATION_EXTENSION_ORACLE defaults="
        + "input:\(context.inputItems.count),"
        + "title:\(item.attributedTitle == nil ? "nil" : "value"),"
        + "content:\(item.attributedContentText == nil ? "nil" : "value"),"
        + "attachments:\(item.attachments == nil ? "nil" : "value"),"
        + "userInfo:\(item.userInfo?.count ?? -1),"
        + "secure:\(NSExtensionItem.supportsSecureCoding)"
)

let title = NSAttributedString(string: "title")
let content = NSMutableAttributedString(string: "content")
let provider = NSItemProvider(
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

let itemCopy = item.copy() as! NSExtensionItem
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

let providerCopy = provider.copy() as! NSItemProvider
print(
    "FOUNDATION_EXTENSION_ORACLE provider="
        + "copyDistinct:\(providerCopy !== provider),"
        + "types:\(providerCopy.registeredTypeIdentifiers.joined(separator: ","))"
)
