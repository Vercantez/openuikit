@_spi(OpenUIKitHost) import Foundation
import CoreFoundation
import OpenUIKit
import Synchronization

enum GuestRuntimeFailure: Error {
    case expected(String)
    case cancelled
}

func require(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() { throw GuestRuntimeFailure.expected(message) }
}

final class RequestHandler: NSObject, NSExtensionRequestHandling {
    private(set) var received: NSExtensionContext?

    func beginRequest(with context: NSExtensionContext) {
        received = context
    }
}

final class GuestDictionaryKey: NSObject, NSCopying {
    let value: Int

    init(_ value: Int) {
        self.value = value
        super.init()
    }

    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return GuestDictionaryKey(value)
    }

    override func isEqual(_ object: Any?) -> Bool {
        (object as? GuestDictionaryKey)?.value == value
    }

    override var hash: Int { value }
}

let _: (NSExtensionContext) ->
    ([Any]?, (@Sendable (Bool) -> Void)?) -> Void =
    NSExtensionContext.completeRequest
let _: (NSExtensionContext) -> (any Error) -> Void =
    NSExtensionContext.cancelRequest
let _: (NSExtensionContext) ->
    (URL, (@Sendable (Bool) -> Void)?) -> Void = NSExtensionContext.open
let _: (NSExtensionContext) -> (URL) async -> Bool =
    NSExtensionContext.open
let _: (Bool) -> NSPredicate = NSPredicate.init(value:)
let _: (NSPredicate) -> (Any?) -> Bool = NSPredicate.evaluate
let _: (NSPredicate) -> (Any?, [String: Any]?) -> Bool =
    NSPredicate.evaluate
let _: () -> NSMutableDictionary = NSMutableDictionary.init
let _: (NSMutableDictionary) -> () -> Void =
    NSMutableDictionary.removeAllObjects
let _: (()) -> OutputStream = OutputStream.init(toMemory:)
let _: (UnsafeMutablePointer<UInt8>, Int) -> OutputStream =
    OutputStream.init(toBuffer:capacity:)
let _: (OutputStream) -> (UnsafePointer<UInt8>, Int) -> Int =
    OutputStream.write
let _: CFAbsoluteTime.Type = Double.self
let _: (CFAllocator?, CFUUIDBytes) -> CFUUID? =
    CFUUIDCreateFromUUIDBytes
let _: (CFUUID?) -> CFUUIDBytes = CFUUIDGetUUIDBytes
let _: CoreFoundation.CFUUID.Type = Foundation.CFUUID.self

let _: OpenUIKit.NSAttributedString.Type = Foundation.NSAttributedString.self
let _: OpenUIKit.NSCoder.Type = Foundation.NSCoder.self

try require(
    Notification.Name.NSExtensionHostWillEnterForeground.rawValue
        == "NSExtensionHostWillEnterForegroundNotification",
    "foreground notification identity"
)
try require(
    Notification.Name.NSExtensionHostDidEnterBackground.rawValue
        == "NSExtensionHostDidEnterBackgroundNotification",
    "background notification identity"
)
try require(
    Notification.Name.NSExtensionHostWillResignActive.rawValue
        == "NSExtensionHostWillResignActiveNotification",
    "resign notification identity"
)
try require(
    Notification.Name.NSExtensionHostDidBecomeActive.rawValue
        == "NSExtensionHostDidBecomeActiveNotification",
    "active notification identity"
)

let item = NSExtensionItem()
try require(item.userInfo?.isEmpty == true, "default userInfo")
let title = NSAttributedString(string: "guest-title")
let provider = NSItemProvider()
provider.suggestedName = "guest.txt"
item.attributedTitle = title
item.attachments = [provider]
try require(item.attributedTitle !== title, "copy-on-set title")
try require(item.attachments?.first === provider, "attachment retention")
let itemCopy = item.copy() as! NSExtensionItem
try require(itemCopy !== item, "item copy identity")
try require(
    itemCopy.attributedTitle !== item.attributedTitle,
    "item copied title"
)
try require(
    itemCopy.attachments?.first !== item.attachments?.first,
    "item copied provider"
)

let coder = NSCoder()
item.encode(with: coder)
let decoded = NSExtensionItem(coder: coder)
try require(decoded?.attributedTitle?.string == "guest-title", "guest coding title")
try require(
    decoded?.attributedTitle !== item.attributedTitle,
    "guest coding copied title"
)
try require(
    decoded?.attachments?.first?.suggestedName == "guest.txt",
    "guest coding provider"
)
try require(
    decoded?.attachments?.first !== item.attachments?.first,
    "guest coding copied provider"
)
try require(NSExtensionItem(coder: NSCoder()) == nil, "missing archive rejection")

let context = NSExtensionContext(inputItems: [item])
try require(context.inputItems.first as? NSExtensionItem === item, "input identity")
let openResult = Mutex<Bool?>(nil)
context.open(URL(string: "https://example.invalid/")!) { success in
    openResult.withLock { $0 = success }
}
try require(openResult.withLock { $0 } == false, "open fail-closed")
let expiredResult = Mutex<Bool?>(nil)
context.completeRequest(returningItems: [itemCopy]) { expired in
    expiredResult.withLock { $0 = expired }
}
try require(expiredResult.withLock { $0 } == true, "completion expiry")
try require(
    context.portableHostDisposition
        == .completionUnavailable(returnedItemCount: 1),
    "completion disposition"
)

let cancelled = NSExtensionContext()
cancelled.cancelRequest(withError: GuestRuntimeFailure.cancelled)
guard case .cancelled = cancelled.portableHostDisposition else {
    throw GuestRuntimeFailure.expected("cancel disposition")
}

final class ContextBox: @unchecked Sendable {
    let value: NSExtensionContext
    init(_ value: NSExtensionContext) { self.value = value }
}
let concurrentContext = NSExtensionContext()
let box = ContextBox(concurrentContext)
let callbackCount = Mutex(0)
await withTaskGroup(of: Void.self) { group in
    for index in 0..<64 {
        group.addTask {
            box.value.open(URL(string: "https://example.invalid/\(index)")!) {
                success in
                if !success { callbackCount.withLock { $0 += 1 } }
            }
        }
    }
}
try require(callbackCount.withLock { $0 } == 64, "callback count")
try require(
    concurrentContext.portableRejectedOpenRequestCount == 64,
    "rejected open count"
)

let handler = RequestHandler()
handler.beginRequest(with: context)
try require(handler.received === context, "request handling context identity")

let truePredicate = NSPredicate(value: true)
let falsePredicate = NSPredicate(value: false)
try require(truePredicate.evaluate(with: nil), "true predicate")
try require(!falsePredicate.evaluate(with: item), "false predicate")
let blockPredicate = NSPredicate { object, bindings in
    (object as? Int) == 7 && (bindings?["answer"] as? Int) == 42
}
try require(
    blockPredicate.evaluate(
        with: 7,
        substitutionVariables: ["answer": 42]
    ),
    "block predicate"
)
let predicateCoder = NSCoder()
truePredicate.encode(with: predicateCoder)
try require(
    NSPredicate(coder: predicateCoder)?.evaluate(with: nil) == true,
    "constant predicate coding"
)
let unsupportedPredicateCoder = NSCoder()
blockPredicate.encode(with: unsupportedPredicateCoder)
try require(
    NSPredicate(coder: unsupportedPredicateCoder) == nil,
    "block predicate coding fails closed"
)

let firstKey = GuestDictionaryKey(1)
let equalKey = GuestDictionaryKey(1)
let secondKey = GuestDictionaryKey(2)
let dictionary = NSMutableDictionary()
dictionary.setObject("first", forKey: firstKey)
dictionary.setObject("replacement", forKey: equalKey)
dictionary[secondKey] = "second"
try require(dictionary.count == 2, "mutable dictionary count")
try require(
    dictionary.object(forKey: equalKey) as? String == "replacement",
    "mutable dictionary equality"
)
let storedFirstKey = dictionary.allKeys.first {
    ($0 as? GuestDictionaryKey)?.value == 1
} as? GuestDictionaryKey
try require(
    storedFirstKey != nil && storedFirstKey !== firstKey,
    "mutable dictionary copied key"
)
let dictionaryCopy = dictionary.copy() as! NSDictionary
try require(dictionaryCopy !== dictionary, "immutable dictionary copy identity")
try require(dictionaryCopy.count == 2, "immutable dictionary copy count")
let copyableKey: any NSCopying = firstKey
try require(
    (copyableKey.copy() as? GuestDictionaryKey)?.value == 1,
    "NSCopying nil-zone spelling"
)
dictionary.removeAllObjects()
try require(dictionary.count == 0, "mutable dictionary removeAllObjects")
try require(dictionaryCopy.count == 2, "dictionary copy isolation")

let keyedCoder = NSCoder()
keyedCoder.encode(Int64(9_223_372_036), forKey: "int64")
keyedCoder.encode(Float(1.25), forKey: "float")
keyedCoder.encode(item, forKey: "item")
keyedCoder.encode([item], forKey: "items")
keyedCoder.encode(nil, forKey: "nil")
try require(keyedCoder.containsValue(forKey: "int64"), "keyed contains int64")
try require(keyedCoder.containsValue(forKey: "nil"), "keyed contains nil")
try require(
    keyedCoder.decodeInt64(forKey: "int64") == 9_223_372_036,
    "keyed int64"
)
try require(keyedCoder.decodeFloat(forKey: "float") == 1.25, "keyed float")
try require(
    keyedCoder.decodeObject(of: NSExtensionItem.self, forKey: "item") === item,
    "keyed allowed class"
)
try require(
    keyedCoder.decodeObject(of: NSPredicate.self, forKey: "item") == nil,
    "keyed disallowed class"
)
let decodedItems = keyedCoder.decodeObject(
    of: [NSArray.self, NSExtensionItem.self],
    forKey: "items"
) as? [NSExtensionItem]
try require(decodedItems?.first === item, "keyed allowed class array")

let bridgedArray = [item, itemCopy] as NSArray
try require(bridgedArray.count == 2, "NSArray bridge count")
let roundTripArray = bridgedArray as! [NSExtensionItem]
try require(
    roundTripArray[0] === item && roundTripArray[1] === itemCopy,
    "NSArray bridge values"
)
let mutableArray = bridgedArray.mutableCopy() as! NSMutableArray
mutableArray.add(item)
try require(mutableArray.count == 3, "NSMutableArray mutation")
try require(bridgedArray.count == 2, "NSArray copy isolation")

let dataValue = Data([1, 3, 5, 7])
let bridgedData = dataValue as NSData
try require(bridgedData.length == 4, "NSData bridge length")
try require(Data(bridgedData) == dataValue, "NSData bridge bytes")
keyedCoder.encode(bridgedData, forKey: "data")
let decodedData = keyedCoder.decodeObject(
    of: NSData.self,
    forKey: "data"
)
try require(decodedData === bridgedData, "NSData keyed identity")

let output = OutputStream(toMemory: ())
output.open()
let outputBytes: [UInt8] = [10, 20, 30, 40]
let outputCount = outputBytes.withUnsafeBufferPointer {
    output.write($0.baseAddress!, maxLength: $0.count)
}
try require(outputCount == 4, "memory output count")
try require(
    output.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
        == Data(outputBytes),
    "memory output bytes"
)
output.close()
try require(!output.hasSpaceAvailable, "closed output space")
var boundedStorage = [UInt8](repeating: 0, count: 3)
let boundedCount = boundedStorage.withUnsafeMutableBufferPointer { destination in
    let bounded = OutputStream(
        toBuffer: destination.baseAddress!,
        capacity: destination.count
    )
    bounded.open()
    return outputBytes.withUnsafeBufferPointer {
        bounded.write($0.baseAddress!, maxLength: destination.count)
    }
}
try require(boundedCount == 3, "bounded output count")
try require(boundedStorage == [10, 20, 30], "bounded output bytes")
let overflowStorage = UnsafeMutablePointer<UInt8>.allocate(capacity: 3)
overflowStorage.initialize(repeating: 0, count: 3)
defer {
    overflowStorage.deinitialize(count: 3)
    overflowStorage.deallocate()
}
let overflow = OutputStream(toBuffer: overflowStorage, capacity: 3)
overflow.open()
let overflowCount = outputBytes.withUnsafeBufferPointer {
    overflow.write($0.baseAddress!, maxLength: $0.count)
}
try require(overflowCount == -1, "bounded overflow rejection")
try require(overflow.streamStatus == .error, "bounded overflow status")
try require(overflow.streamError != nil, "bounded overflow error")
try require(
    (0..<3).map { overflowStorage[$0] } == [0, 0, 0],
    "bounded overflow no partial write"
)

let uuidBytes = CFUUIDBytes(
    byte0: 0, byte1: 1, byte2: 2, byte3: 3,
    byte4: 4, byte5: 5, byte6: 6, byte7: 7,
    byte8: 8, byte9: 9, byte10: 10, byte11: 11,
    byte12: 12, byte13: 13, byte14: 14, byte15: 15
)
try require(MemoryLayout<CFUUIDBytes>.size == 16, "CFUUIDBytes ABI size")
let cfUUID = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, uuidBytes)!
let roundTripUUID = CFUUIDGetUUIDBytes(cfUUID)
try require(
    roundTripUUID.byte0 == 0 && roundTripUUID.byte15 == 15,
    "CFUUID byte round trip"
)

print(
    "FOUNDATION_EXTENSION_GUEST_OK module=Foundation "
        + "identity=OpenUIKit callbacks=66 concurrency=64 coding=fail-closed "
        + "canonical=predicate,dictionary,nscopying,coder,stream,cfuuid "
        + "reference=array,data"
)
