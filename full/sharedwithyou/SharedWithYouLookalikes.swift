@_exported import Foundation

// Isolated-host stand-ins for UIKit and UniformTypeIdentifiers types named
// by the public SharedWithYou surface. The sealed host gate compiles this
// module alone. When a real `UIKit` / `UniformTypeIdentifiers` module is on
// the link line, these blocks compile out. They are not a Linux UIKit port
// and not a substitute once those declared/related modules are staged.
//
// `NSItemProvider` is a Foundation type on Darwin; swift-corelibs-foundation
// does not currently vend it, so the isolated host provides a storage-only
// handle. EC2 identity builds must use Foundation's type.

#if canImport(UIKit)
import UIKit
#else

open class UIView: NSObject {
    public var frame: CGRect = .zero

    public init(frame: CGRect = .zero) {
        self.frame = frame
        super.init()
    }
}

open class UIViewController: NSObject {
    public var view: UIView?

    public override init() {
        super.init()
    }

    public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init()
        _ = (nibNameOrNil, nibBundleOrNil)
    }
}

open class UIImage: NSObject {
    public override init() {
        super.init()
    }
}

open class UIMenu: NSObject {
    public let title: String
    public let children: [NSObject]

    public init(title: String = "", children: [NSObject] = []) {
        self.title = title
        self.children = children
        super.init()
    }
}

open class NSItemProvider: NSObject {
    public override init() {
        super.init()
    }
}

public protocol UICloudSharingControllerDelegate: AnyObject {}

#endif

#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#else

/// Isolated-host stand-in for `UniformTypeIdentifiers.UTType`. Not a UTI
/// database. Identifier strings are caller-supplied.
public struct UTType: Hashable, Sendable {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }
}

#endif
