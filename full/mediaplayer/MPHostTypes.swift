import Foundation
import CoreGraphics

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
