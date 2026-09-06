import Foundation
#if canImport(Glibc)
import Glibc
#endif

// Isolated Linux host compilation imports Foundation only. UIKit, Core
// Animation, AVFoundation, UniformTypeIdentifiers, ExtensionFoundation, and
// libxpc types are module-local lookalikes when those modules are absent.
// They are not Darwin types and compile out when the real modules are on
// the import path. `tests/agent/BrowserEngineKitDependencyIdentity.swift`
// carries the genuine Foundation (and, when present, UIKit) imports for EC2.

public typealias mach_port_t = UInt32

#if !canImport(ObjectiveC)
public struct Selector: Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}
#endif

#if !canImport(UIKit) && !canImport(OpenUIKit)

public enum NSWritingDirection: Int, Equatable, Hashable, Sendable {
    case natural = -1
    case leftToRight = 0
    case rightToLeft = 1
}

public struct UIAccessibilityTraits: OptionSet, Hashable, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
}

public enum UIAccessibility {
    public struct Notification: Equatable, Hashable, Sendable {
        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }
}

public struct UITextContentType: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public enum UITextGranularity: Int, Equatable, Hashable, Sendable {
    case character = 0
    case word = 1
    case sentence = 2
    case paragraph = 3
    case line = 4
    case document = 5
}

public enum UITextLayoutDirection: Int, Equatable, Hashable, Sendable {
    case right = 2
    case left = 3
    case up = 4
    case down = 5
}

public enum UITextStorageDirection: Int, Equatable, Hashable, Sendable {
    case forward = 0
    case backward = 1
}

public enum UIEditMenuArrowDirection: Int, Equatable, Hashable, Sendable {
    case automatic = 0
    case up = 1
    case down = 2
    case left = 3
    case right = 4
}

public enum UIGestureRecognizer {
    public enum State: Int, Equatable, Hashable, Sendable {
        case possible = 0
        case began = 1
        case changed = 2
        case ended = 3
        case cancelled = 4
        case failed = 5
    }
}

open class UIColor: NSObject, @unchecked Sendable {
    public let r: CGFloat
    public let g: CGFloat
    public let b: CGFloat
    public let a: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        r = red
        g = green
        b = blue
        a = alpha
        super.init()
    }

    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
}

open class UIView: NSObject, @unchecked Sendable {
    public var frame: CGRect
    public var bounds: CGRect

    public init(frame: CGRect = .zero) {
        self.frame = frame
        bounds = CGRect(origin: .zero, size: frame.size)
        super.init()
    }
}

open class UIScrollView: UIView, @unchecked Sendable {
    public var contentOffset: CGPoint = .zero
    public var contentSize: CGSize = .zero
}

open class UIKey: NSObject, @unchecked Sendable {
    public let characters: String
    public init(characters: String = "") {
        self.characters = characters
        super.init()
    }
}

open class UITextPosition: NSObject, @unchecked Sendable {}

open class UITextRange: NSObject, @unchecked Sendable {
    public let startPosition: UITextPosition
    public let endPosition: UITextPosition

    public init(start: UITextPosition = UITextPosition(), end: UITextPosition = UITextPosition()) {
        startPosition = start
        endPosition = end
        super.init()
    }
}

open class UITextSelectionRect: NSObject, @unchecked Sendable {
    public let rect: CGRect
    public init(rect: CGRect = .zero) {
        self.rect = rect
        super.init()
    }
}

open class UITextPlaceholder: NSObject, @unchecked Sendable {}

open class UITextSelectionDisplayInteraction: NSObject, @unchecked Sendable {}

open class UIContextMenuConfiguration: NSObject, @unchecked Sendable {}

open class UIContextMenuInteraction: NSObject, @unchecked Sendable {}

open class UIDragInteraction: NSObject, @unchecked Sendable {}

open class UIDragItem: NSObject, @unchecked Sendable {}

public protocol UIDragSession: AnyObject {}

open class BEHostDragSession: NSObject, UIDragSession, @unchecked Sendable {}

public protocol UIInteraction: AnyObject {
    var view: UIView? { get }
}

open class BEHostInteraction: NSObject, UIInteraction, @unchecked Sendable {
    public weak var view: UIView?
}

public protocol UIKeyInput: AnyObject {
    var hasText: Bool { get }
    func insertText(_ text: String)
    func deleteBackward()
}

public protocol UIResponderStandardEditActions: AnyObject {}

public protocol UITextInputTraits: AnyObject {}

public protocol UIScrollViewDelegate: AnyObject {}

public protocol UIDragInteractionDelegate: AnyObject {}

public protocol UIContextMenuInteractionDelegate: AnyObject {}

public protocol UIEditMenuInteractionAnimating: AnyObject {}

open class BEHostEditMenuAnimator: NSObject, UIEditMenuInteractionAnimating, @unchecked Sendable {}

#endif

#if !canImport(QuartzCore) && !canImport(CoreAnimation)
open class CALayer: NSObject, @unchecked Sendable {}
#endif

#if !canImport(AVFoundation)
open class AVCaptureSession: NSObject, @unchecked Sendable {}
#endif

#if !canImport(UniformTypeIdentifiers)
public struct UTType: Equatable, Hashable, Sendable {
    public let identifier: String
    public init(identifier: String) { self.identifier = identifier }
}
#endif

#if os(Linux)
open class NSXPCConnection: NSObject, @unchecked Sendable {
    public let serviceName: String?

    public override init() {
        serviceName = nil
        super.init()
    }

    public init(serviceName: String) {
        self.serviceName = serviceName
        super.init()
    }
}
#endif

#if !canImport(ExtensionFoundation)
public protocol AppExtension {
    associatedtype Configuration
    var configuration: Configuration { get }
}
#endif

public protocol OS_xpc_object: AnyObject {}
public typealias xpc_object_t = OS_xpc_object
public typealias xpc_connection_t = OS_xpc_object

public final class BEHostXPCObject: NSObject, OS_xpc_object, @unchecked Sendable {}
