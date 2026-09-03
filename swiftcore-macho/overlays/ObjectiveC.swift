// Swift overlay for the Clang ObjectiveC module.
// 6.2.4 does not ship stdlib/public/Darwin/ObjectiveC (Apple picks it up
// from the SDK). This is the public overlay surface from Apple's
// ObjectiveC.swift: ObjCBool, Selector, NSObject Equatable/Hashable,
// autoreleasepool. Private objc_internal / dyld enumeration is omitted
// (those headers are not in this Linux sysroot).
@_exported import ObjectiveC
import Swift

@frozen
public struct ObjCBool: ExpressibleByBooleanLiteral, Sendable {
#if arch(x86_64)
  @usableFromInline var _value: Int8

  @_transparent
  public init(_ value: Bool) {
    self._value = value ? 1 : 0
  }

  @_transparent
  public var boolValue: Bool {
    return _value != 0
  }
#else
  @usableFromInline var _value: Bool

  @_transparent
  public init(_ value: Bool) {
    self._value = value
  }

  @_transparent
  public var boolValue: Bool {
    return _value
  }
#endif

  @_transparent
  public init(booleanLiteral value: Bool) {
    self.init(value)
  }
}

extension ObjCBool: CustomReflectable {
  public var customMirror: Mirror {
    return Mirror(reflecting: boolValue)
  }
}

extension ObjCBool: CustomStringConvertible {
  public var description: String {
    return boolValue.description
  }
}

@_transparent
public func _convertBoolToObjCBool(_ x: Bool) -> ObjCBool {
  return ObjCBool(x)
}

@_transparent
public func _convertObjCBoolToBool(_ x: ObjCBool) -> Bool {
  return x.boolValue
}

@frozen
public struct Selector: ExpressibleByStringLiteral, @unchecked Sendable {
  var ptr: OpaquePointer

  public init(_ str: String) {
    ptr = str.withCString { name in
      sel_registerName(name).ptr
    }
  }

  public init(stringLiteral value: String) {
    self.init(value)
  }
}

extension Selector: Equatable, Hashable {}

extension Selector: CustomStringConvertible {
  public var description: String {
    return String(_sel: self)
  }
}

extension String {
  public init(_sel: Selector) {
    self = String(cString: sel_getName(_sel))
  }
}

extension Selector: CustomReflectable {
  public var customMirror: Mirror {
    return Mirror(reflecting: String(_sel: self))
  }
}

@frozen
public struct NSZone {
  var pointer: OpaquePointer
}

@available(*, unavailable)
extension NSZone: Sendable {}

@_silgen_name("_objc_autoreleasePoolPush")
public func _autoreleasePoolPush() -> UnsafeMutableRawPointer

@_silgen_name("_objc_autoreleasePoolPop")
public func _autoreleasePoolPop(_: UnsafeMutableRawPointer)

@inline(__always)
public func autoreleasepool<Result>(
  invoking body: () throws -> Result
) rethrows -> Result {
  let pool = _autoreleasePoolPush()
  defer { _autoreleasePoolPop(pool) }
  return try body()
}

extension NSObject: Equatable, Hashable {
  public static func == (lhs: NSObject, rhs: NSObject) -> Bool {
    return lhs.isEqual(rhs)
  }

  @nonobjc
  public var hashValue: Int {
    return hash
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.hash)
  }

  public func _rawHashValue(seed: Int) -> Int {
    return self.hash._rawHashValue(seed: seed)
  }
}
