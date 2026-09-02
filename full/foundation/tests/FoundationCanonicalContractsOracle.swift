import Foundation
import CoreFoundation

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
let _: CFAbsoluteTime.Type = Double.self
let _: (CFAllocator?, CFUUIDBytes) -> CFUUID? =
    CFUUIDCreateFromUUIDBytes
let _: (CFUUID?) -> CFUUIDBytes = CFUUIDGetUUIDBytes

func requireCoderSurface(_ coder: NSCoder, object: NSString) {
    coder.encode(object, forKey: "object")
    coder.encode(Int64(42), forKey: "int64")
    coder.encode(Float(1.25), forKey: "float")
    _ = coder.containsValue(forKey: "object")
    _ = coder.decodeInt64(forKey: "int64")
    _ = coder.decodeFloat(forKey: "float")
    _ = coder.decodeObject(of: NSString.self, forKey: "object")
    _ = coder.decodeObject(of: [NSString.self], forKey: "object")
}

final class CopyProbe: NSObject, NSCopying {
    var nilZoneCalls = 0

    func copy(with zone: NSZone? = nil) -> Any {
        if zone == nil { nilZoneCalls += 1 }
        return self
    }
}

let probe = CopyProbe()
let copyable: any NSCopying = probe
precondition((copyable.copy() as AnyObject) === probe)
precondition(probe.nilZoneCalls == 1)

let truePredicate = NSPredicate(value: true)
let falsePredicate = NSPredicate(value: false)
precondition(truePredicate.evaluate(with: nil))
precondition(!falsePredicate.evaluate(with: NSObject()))

var receivedObject = false
var receivedBinding = false
let blockPredicate = NSPredicate { object, bindings in
    receivedObject = object is NSString
    receivedBinding = bindings?["answer"] as? Int == 42
    return receivedObject && receivedBinding
}
precondition(
    blockPredicate.evaluate(
        with: "value" as NSString,
        substitutionVariables: ["answer": 42]
    )
)

let dictionary = NSMutableDictionary()
precondition(dictionary.count == 0)
dictionary.setObject("first", forKey: "alpha" as NSString)
dictionary.setObject("second", forKey: "beta" as NSString)
precondition(dictionary.count == 2)
precondition(dictionary.object(forKey: "alpha") as? String == "first")
let immutable = dictionary.copy() as! NSDictionary
precondition(immutable.count == 2)

let referenceArray: NSArray = ["a", 2]
precondition(referenceArray.count == 2)
let swiftArray = referenceArray as! [Any]
precondition(swiftArray[0] as? String == "a")
let mutableArray = referenceArray.mutableCopy() as! NSMutableArray
mutableArray.add(3)
precondition(mutableArray.count == 3)
precondition(referenceArray.count == 2)
let referenceDataValue = Data([1, 3, 5, 7])
let referenceData = referenceDataValue as NSData
precondition(referenceData.length == 4)
precondition(Data(referencing: referenceData) == referenceDataValue)
precondition(immutable !== dictionary)
dictionary.removeAllObjects()
precondition(dictionary.count == 0)
precondition(immutable.count == 2)

let output = OutputStream(toMemory: ())
output.open()
let outputBytes: [UInt8] = [10, 20, 30, 40]
precondition(
    outputBytes.withUnsafeBufferPointer {
        output.write($0.baseAddress!, maxLength: $0.count)
    } == 4
)
precondition(
    output.property(forKey: .dataWrittenToMemoryStreamKey) as? Data
        == Data(outputBytes)
)
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
precondition(boundedCount == 3)
precondition(boundedStorage == [10, 20, 30])
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
precondition(overflowCount == -1)
precondition(overflow.streamStatus == .error)
precondition(overflow.streamError != nil)
precondition((0..<3).map { overflowStorage[$0] } == [0, 0, 0])

let uuidBytes = CFUUIDBytes(
    byte0: 0, byte1: 1, byte2: 2, byte3: 3,
    byte4: 4, byte5: 5, byte6: 6, byte7: 7,
    byte8: 8, byte9: 9, byte10: 10, byte11: 11,
    byte12: 12, byte13: 13, byte14: 14, byte15: 15
)
precondition(MemoryLayout<CFUUIDBytes>.size == 16)
let cfUUID = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, uuidBytes)!
let roundTripUUID = CFUUIDGetUUIDBytes(cfUUID)
precondition(roundTripUUID.byte0 == 0 && roundTripUUID.byte15 == 15)

print(
    "FOUNDATION_CANONICAL_ORACLE_OK predicate=constant,block "
        + "dictionary=copy,removeAll nscopying=nil-zone "
        + "coder=keyed stream=memory,buffer corefoundation=uuid,time "
        + "reference=array,data"
)
