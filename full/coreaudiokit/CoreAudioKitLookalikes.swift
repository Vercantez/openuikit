@_exported import Foundation

// Isolated-host stand-ins for UIKit and AudioToolbox types named by the
// public CoreAudioKit surface. The sealed host gate compiles this module
// alone. When a real `UIKit` / `AudioToolbox` module is on the link line,
// these blocks compile out. They are not a Linux UIKit or AudioToolbox port
// and must not be cited as proof of those identities.

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AudioToolbox)
import AudioToolbox
#endif

#if !canImport(UIKit)

open class UIColor: NSObject, @unchecked Sendable {
    public let linuxName: String

    public init(linuxName: String) {
        self.linuxName = linuxName
        super.init()
    }

    public static let black = UIColor(linuxName: "black")
    public static let white = UIColor(linuxName: "white")
    public static let red = UIColor(linuxName: "red")
    public static let blue = UIColor(linuxName: "blue")
    public static let green = UIColor(linuxName: "green")
    public static let clear = UIColor(linuxName: "clear")

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIColor else { return false }
        return linuxName == other.linuxName
    }

    open override var hash: Int { linuxName.hashValue }
}

open class UIFont: NSObject, @unchecked Sendable {
    public let familyName: String
    public let pointSize: CGFloat

    public init(familyName: String, pointSize: CGFloat) {
        self.familyName = familyName
        self.pointSize = pointSize
        super.init()
    }

    public static func systemFont(ofSize size: CGFloat) -> UIFont {
        UIFont(familyName: "LinuxSystem", pointSize: size)
    }

    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIFont else { return false }
        return familyName == other.familyName && pointSize == other.pointSize
    }

    open override var hash: Int {
        var hasher = Hasher()
        hasher.combine(familyName)
        hasher.combine(Double(pointSize))
        return hasher.finalize()
    }
}

open class UITraitCollection: NSObject {
    public override init() {
        super.init()
    }
}

open class UIView: NSObject {
    public var frame: CGRect
    public private(set) weak var superview: UIView?

    public init(frame: CGRect = .zero) {
        self.frame = frame
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        self.frame = .zero
        super.init()
    }

    open func addSubview(_ view: UIView) {
        view.superview = self
    }

    open func removeFromSuperview() {
        superview = nil
    }

    open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        _ = previousTraitCollection
    }
}

open class UICollectionReusableView: UIView {}

open class UICollectionViewCell: UICollectionReusableView {}

open class UICollectionView: UIView {
    public static let elementKindSectionHeader = "UICollectionElementKindSectionHeader"
    public static let elementKindSectionFooter = "UICollectionElementKindSectionFooter"
}

open class UIViewController: NSObject {
    public var title: String?
    public var view: UIView?

    public override init() {
        super.init()
    }

    public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        _ = nibNameOrNil
        _ = nibBundleOrNil
        super.init()
    }

    public required init?(coder: NSCoder) {
        _ = coder
        super.init()
    }

    open func loadView() {
        if view == nil {
            view = UIView()
        }
    }

    open func viewDidLoad() {}

    open func loadViewIfNeeded() {
        if view == nil {
            loadView()
        }
        viewDidLoad()
    }
}

open class UITableView: UIView {
    public enum Style: Int, Sendable {
        case plain = 0
        case grouped = 1
        case insetGrouped = 2
    }

    public let style: Style

    public init(frame: CGRect, style: Style) {
        self.style = style
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        self.style = .plain
        super.init(coder: coder)
    }
}

open class UITableViewController: UIViewController {
    public let tableView: UITableView

    public init(style: UITableView.Style = .plain) {
        self.tableView = UITableView(
            frame: CGRect(x: 0, y: 0, width: 375, height: 667),
            style: style
        )
        super.init()
        self.view = tableView
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.tableView = UITableView(
            frame: CGRect(x: 0, y: 0, width: 375, height: 667),
            style: .plain
        )
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.view = tableView
    }

    public required init?(coder: NSCoder) {
        self.tableView = UITableView(
            frame: CGRect(x: 0, y: 0, width: 375, height: 667),
            style: .plain
        )
        super.init(coder: coder)
        self.view = tableView
    }
}

#endif

#if !canImport(AudioToolbox)

public struct AudioComponentDescription: Equatable, Hashable, Sendable {
    public var componentType: UInt32
    public var componentSubType: UInt32
    public var componentManufacturer: UInt32
    public var componentFlags: UInt32
    public var componentFlagsMask: UInt32

    public init() {
        componentType = 0
        componentSubType = 0
        componentManufacturer = 0
        componentFlags = 0
        componentFlagsMask = 0
    }

    public init(
        componentType: UInt32,
        componentSubType: UInt32,
        componentManufacturer: UInt32,
        componentFlags: UInt32 = 0,
        componentFlagsMask: UInt32 = 0
    ) {
        self.componentType = componentType
        self.componentSubType = componentSubType
        self.componentManufacturer = componentManufacturer
        self.componentFlags = componentFlags
        self.componentFlagsMask = componentFlagsMask
    }
}

public typealias AudioComponentInstance = OpaquePointer
public typealias AudioUnit = AudioComponentInstance
public typealias AUParameterObserverToken = UnsafeMutableRawPointer

open class AUAudioUnit: NSObject {
    public let componentDescription: AudioComponentDescription

    public override init() {
        self.componentDescription = AudioComponentDescription()
        super.init()
    }

    public init(componentDescription: AudioComponentDescription) {
        self.componentDescription = componentDescription
        super.init()
    }
}

#endif
