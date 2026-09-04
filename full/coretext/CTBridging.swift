import CoreFoundation
import Foundation

#if !canImport(Darwin)
/// Isolated Linux Foundation does not export CFAttributedString; NSAttributedString is the object.
public typealias CFAttributedString = NSAttributedString
#endif

@inline(__always)
func _ctCFString(_ value: String) -> CFString {
    unsafeBitCast(value as NSString, to: CFString.self)
}

@inline(__always)
func _ctString(_ value: CFString) -> String {
    unsafeBitCast(value, to: NSString.self) as String
}

@inline(__always)
func _ctCFURL(_ url: URL) -> CFURL {
    unsafeBitCast(url as NSURL, to: CFURL.self)
}

@inline(__always)
func _ctURL(_ url: CFURL) -> URL {
    unsafeBitCast(url, to: NSURL.self) as URL
}

@inline(__always)
func _ctCFArray(_ array: NSArray) -> CFArray {
    unsafeBitCast(array, to: CFArray.self)
}

@inline(__always)
func _ctNSArray(_ array: CFArray) -> NSArray {
    unsafeBitCast(array, to: NSArray.self)
}

@inline(__always)
func _ctCFDictionary(_ dictionary: NSDictionary) -> CFDictionary {
    unsafeBitCast(dictionary, to: CFDictionary.self)
}

@inline(__always)
func _ctNSDictionary(_ dictionary: CFDictionary) -> NSDictionary {
    unsafeBitCast(dictionary, to: NSDictionary.self)
}

@inline(__always)
func _ctCFData(_ data: Data) -> CFData {
    unsafeBitCast(data as NSData, to: CFData.self)
}

@inline(__always)
func _ctData(_ data: CFData) -> Data {
    unsafeBitCast(data, to: NSData.self) as Data
}

@inline(__always)
func _ctCFError(_ error: NSError) -> CFError {
    unsafeBitCast(error, to: CFError.self)
}

@inline(__always)
func _ctCFSet(_ set: NSSet) -> CFSet {
    unsafeBitCast(set, to: CFSet.self)
}

@inline(__always)
func _ctCFCharacterSet(_ set: NSCharacterSet) -> CFCharacterSet {
    unsafeBitCast(set, to: CFCharacterSet.self)
}

@inline(__always)
func _ctNSAttributedString(_ string: CFAttributedString) -> NSAttributedString {
    string
}

@inline(__always)
func _ctCFAttributedString(_ string: NSAttributedString) -> CFAttributedString {
    string
}

@inline(__always)
func _ctEmptyCFArray() -> CFArray {
    _ctCFArray(NSArray())
}

@inline(__always)
func _ctEmptyCFDictionary() -> CFDictionary {
    _ctCFDictionary(NSDictionary())
}

@inline(__always)
func _ctNSError(_ error: CFError) -> NSError {
    unsafeBitCast(error, to: NSError.self)
}
