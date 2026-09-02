// Narrow declaration boundary for compiling NSExtensionHost.swift as the
// actual module named Foundation against a packaged guest SDK. Production
// builds get these aliases from the earlier ordered facade sources.

@_exported import FoundationEssentials
@_exported import ObjectiveC
@_exported import OpenCoreGraphics
@_exported import struct OpenUIKit.Notification
import OpenUIKit

public typealias NSObject = ObjectiveC.NSObject
public typealias NSObjectProtocol = ObjectiveC.NSObjectProtocol
public typealias NSCoder = OpenUIKit.NSCoder
public typealias NSAttributedString = OpenUIKit.NSAttributedString
public typealias NSMutableAttributedString =
    OpenUIKit.NSMutableAttributedString
public typealias Notification = OpenUIKit.Notification

public protocol NSCopying: AnyObject {
    func copy(with zone: NSZone?) -> Any
}

public extension NSCopying {
    func copy() -> Any { copy(with: nil) }
}
