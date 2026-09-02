// Foundation.swift — the Swift overlay for the minimal Foundation slice.
//
// WHY THIS FILE HAS TO EXIST, and why it is the crux of the whole project:
//
// The Darwin Swift standard library ships the entire String <-> NSString
// bridging ENGINE — _StringGuts' cocoa storage, __SwiftNativeNSString*, the 128
// selectors it sends, swift_stdlib_connectNSBaseClasses — but NOT the
// conformance that starts it. Measured: `String : _ObjectiveCBridgeable` does
// not appear anywhere in libswiftCore's .swiftinterface, while the protocol and
// `String._bridgeToObjectiveCImpl()` both do, the latter `public`.
//
// So Foundation-on-this-stack is two separable halves:
//   1. Objective-C classes that answer the runtime contract  (src/slice/NSSlice.m)
//   2. this overlay, which declares the conformances that make `as NSString`,
//      `as? String` and the Array/Dictionary element bridging compile.
//
// Both halves are ours to write. Neither needs Apple's closed Foundation.

@_exported import FoundationSlice

// MARK: - String <-> NSString

extension String: _ObjectiveCBridgeable {
  public typealias _ObjectiveCType = NSString

  // The stdlib already knows how to make an NSString-shaped object out of a
  // String: _bridgeToObjectiveCImpl() returns a __StringStorage (or a tagged
  // pointer), whose class was re-parented onto our NSString by
  // connectNSBaseClasses. So this is a cast, not a copy — the fast path Apple
  // takes too.
  public func _bridgeToObjectiveC() -> NSString {
    return unsafeBitCast(_bridgeToObjectiveCImpl(), to: NSString.self)
  }

  public static func _forceBridgeFromObjectiveC(
    _ source: NSString, result: inout String?
  ) {
    result = _eagerStringFrom(source)
  }

  public static func _conditionallyBridgeFromObjectiveC(
    _ source: NSString, result: inout String?
  ) -> Bool {
    result = _eagerStringFrom(source)
    return true
  }

  @_effects(readonly)
  public static func _unconditionallyBridgeFromObjectiveC(
    _ source: NSString?
  ) -> String {
    guard let source = source else { return "" }
    return _eagerStringFrom(source)
  }
}

// NSString -> String by copying UTF-16 out through the primitive methods.
//
// Apple's Foundation instead hands the NSString to String._StringGuts as lazy
// *cocoa* storage (stdlib `_bridgeCocoaString`), so no copy happens until the
// bytes are needed. That entry point is `@usableFromInline internal`: it is
// exported from libswiftCore as `$ss18_bridgeCocoaStringys01_C4GutsVyXlF` and
// reachable via @_silgen_name, but it returns the internal type _StringGuts,
// which an out-of-module declaration cannot name. Closing that gap is a real
// task for the full Foundation (see docs/PLAN.md); for the slice, eager and
// obviously-correct beats lazy and subtly wrong.
@inline(__always)
internal func _eagerStringFrom(_ ns: NSString) -> String {
  let n = ns.length
  if n == 0 { return "" }
  var units = [UInt16](repeating: 0, count: n)
  units.withUnsafeMutableBufferPointer { buf in
    ns.getCharacters(buf.baseAddress!, range: NSRange(location: 0, length: n))
  }
  return String(decoding: units, as: UTF16.self)
}

// MARK: - Int <-> NSNumber
//
// Enough for `NSArray(array: [1, 2, 3])`: the elements must bridge to objects
// before NSArray can hold them.

extension Int: _ObjectiveCBridgeable {
  public typealias _ObjectiveCType = NSNumber

  public func _bridgeToObjectiveC() -> NSNumber {
    return SliceMakeNumberLongLong(Int64(self))
  }
  public static func _forceBridgeFromObjectiveC(
    _ source: NSNumber, result: inout Int?
  ) {
    result = Int(source.longLongValue)
  }
  public static func _conditionallyBridgeFromObjectiveC(
    _ source: NSNumber, result: inout Int?
  ) -> Bool {
    result = Int(source.longLongValue)
    return true
  }
  public static func _unconditionallyBridgeFromObjectiveC(
    _ source: NSNumber?
  ) -> Int {
    guard let source = source else { return 0 }
    return Int(source.longLongValue)
  }
}

// MARK: - NSArray convenience
//
// `NSArray(array:)` is the shape the brief's decisive test uses. Bridging each
// element through the stdlib's _bridgeAnythingToObjectiveC is exactly what
// Apple's NSArray(array:) does — and it is the call that routes Int through the
// conformance above and String through the one at the top of this file.

extension NSArray {
  public convenience init(array: [Any]) {
    // [AnyObject?], not [AnyObject]: `const id *` imports as
    // UnsafePointer<AnyObject?> because plain `id` is nullable to clang.
    let objects: [AnyObject?] = array.map { _bridgeAnythingToObjectiveC($0) }
    self.init(objectPointer: objects, count: objects.count)
  }
}
