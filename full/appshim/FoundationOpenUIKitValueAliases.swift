// Foundation value identities that must remain identical to the declarations
// used when OpenUIKit was compiled with the Foundation umbrella hidden.

@_exported import ObjectiveC
import OpenUIKit

public typealias NSObject = ObjectiveC.NSObject
public typealias NSObjectProtocol = ObjectiveC.NSObjectProtocol

public typealias NSRange = OpenUIKit.NSRange
public typealias NSRangePointer = OpenUIKit.NSRangePointer

public func NSMakeRange(_ location: Int, _ length: Int) -> NSRange {
    NSRange(location: location, length: length)
}
