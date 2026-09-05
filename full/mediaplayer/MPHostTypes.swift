import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#else
/// Isolated-host geometry so artwork / volume compile without a CoreGraphics
/// module. Not CoreGraphics identity. Guest builds import real CoreGraphics.
public struct CGPoint: Equatable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    public static var zero: CGPoint { CGPoint(x: 0, y: 0) }
}

public struct CGSize: Equatable, Hashable, Sendable {
    public var width: Double
    public var height: Double
    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
    public static var zero: CGSize { CGSize(width: 0, height: 0) }
}

public struct CGRect: Equatable, Hashable, Sendable {
    public var origin: CGPoint
    public var size: CGSize
    public init(origin: CGPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }
    public init(x: Double, y: Double, width: Double, height: Double) {
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }
    public static var zero: CGRect { CGRect(origin: .zero, size: .zero) }
    public var width: Double { size.width }
    public var height: Double { size.height }
}
#endif

#if !canImport(ObjectiveC)
/// Isolated-host lookalike: this Swift toolchain has no Objective-C interop,
/// so `Selector` is not in scope. Guest/ObjC builds use the real type.
public struct Selector: Equatable, Hashable, Sendable {
    public let name: String
    public init(_ name: String) { self.name = name }
}
#endif

#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
import OpenUIKit
#else
/// Isolated-host lookalikes so artwork / volume / picker compile without
/// UIKit. Not UIKit identity. The guest route imports OpenUIKit.
public final class UIImage: NSObject {
    public var size: CGSize
    public init(size: CGSize = .zero) {
        self.size = size
        super.init()
    }
}

open class UIView: NSObject {
    public var frame: CGRect
    public init(frame: CGRect) {
        self.frame = frame
        super.init()
    }
    public convenience override init() { self.init(frame: .zero) }
    public required init?(coder: NSCoder) {
        self.frame = .zero
        super.init()
    }
}

open class UIViewController: NSObject {
    public override init() { super.init() }
}

public struct UIControl {
    public struct State: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let normal = State([])
        public static let highlighted = State(rawValue: 1 << 0)
        public static let disabled = State(rawValue: 1 << 1)
        public static let selected = State(rawValue: 1 << 2)
    }
}
#endif
