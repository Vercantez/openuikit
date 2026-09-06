import Foundation

// Isolated Linux Swift has no CoreFoundation overlay. These aliases match the
// imported IOSurface C surface so public functions can be spelled as on Apple.
// They are not claimed as IOSurface identifiers. The EC2 integration build
// uses real CF / Darwin types from the guest sysroot.

public typealias CFString = NSString
public typealias CFDictionary = NSDictionary
public typealias CFArray = NSArray
public typealias CFTypeRef = AnyObject
public typealias CFTypeID = UInt
public typealias OSType = UInt32
public typealias kern_return_t = Int32
public typealias mach_port_t = UInt32
public typealias task_id_token_t = UInt32

let iosurfaceKERNSuccess: kern_return_t = 0
let iosurfaceKERNFailure: kern_return_t = 5
let iosurfaceMachPortNull: mach_port_t = 0

let iosurfaceTypeID: CFTypeID = 0x4953_5552 // 'ISUR'

func iosurfaceCFString(_ value: String) -> CFString {
    value as NSString
}

func iosurfaceKeyString(_ key: Any) -> String {
    if let string = key as? String {
        return string
    }
    if let string = key as? NSString {
        return string as String
    }
    return String(describing: key)
}

func iosurfaceInt(_ value: Any?) -> Int? {
    switch value {
    case let number as Int:
        return number
    case let number as Int32:
        return Int(number)
    case let number as Int64:
        return Int(truncatingIfNeeded: number)
    case let number as UInt:
        return Int(number)
    case let number as UInt32:
        return Int(number)
    case let number as UInt64:
        return Int(truncatingIfNeeded: number)
    case let number as NSNumber:
        return number.intValue
    default:
        return nil
    }
}

func iosurfaceUInt32(_ value: Any?) -> UInt32? {
    switch value {
    case let number as UInt32:
        return number
    case let number as Int:
        return UInt32(truncatingIfNeeded: number)
    case let number as NSNumber:
        return number.uint32Value
    default:
        return nil
    }
}

func iosurfaceBool(_ value: Any?) -> Bool? {
    switch value {
    case let flag as Bool:
        return flag
    case let number as NSNumber:
        return number.boolValue
    default:
        return nil
    }
}

func iosurfaceAlignUp(_ value: Int, _ alignment: Int) -> Int {
    guard alignment > 1 else { return max(value, 0) }
    let clamped = max(value, 0)
    return (clamped + alignment - 1) / alignment * alignment
}

func iosurfaceObject(_ value: Any) -> AnyObject {
    if let string = value as? String {
        return string as NSString
    }
    if let string = value as? NSString {
        return string
    }
    if let number = value as? Int {
        return NSNumber(value: number)
    }
    if let number = value as? Int32 {
        return NSNumber(value: number)
    }
    if let number = value as? UInt32 {
        return NSNumber(value: number)
    }
    if let flag = value as? Bool {
        return NSNumber(value: flag)
    }
    if let number = value as? NSNumber {
        return number
    }
    if let object = value as? NSObject {
        return object
    }
    return "\(value)" as NSString
}
