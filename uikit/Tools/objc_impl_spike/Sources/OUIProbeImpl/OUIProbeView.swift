// Swift implementation of the class declared in OUIProbeView.h.
// Every member declared in the header must be implemented here; members
// that are NOT in the header are Swift-only and (per SE-0436) must be
// `final` or private. Stored properties become Objective-C ivars.
import Foundation
import OUIProbeHeader

/// Swift-only value type stored on the class (not ObjC-representable).
public struct OUIProbeAnimation {
    public var keyPath: String
    public var from: Double
    public var to: Double
}

/// Swift-only enum with payload stored on the class (not ObjC-representable).
public enum OUIProbeTint {
    case none
    case color(red: Double, green: Double, blue: Double)
}

@objc @implementation extension OUIProbeView {
    // MARK: Members declared in the header (Objective-C visible).

    var center: CGPoint = .zero
    var bounds: CGRect = .zero {
        didSet {
            if oldValue.size != bounds.size { setNeedsLayout() }
        }
    }
    var frame: CGRect {
        get {
            CGRect(x: center.x - bounds.width / 2, y: center.y - bounds.height / 2,
                   width: bounds.width, height: bounds.height)
        }
        set {
            bounds.size = newValue.size
            center = CGPoint(x: newValue.midX, y: newValue.midY)
        }
    }
    // MEASURED: a `readonly` header property implemented as
    // `private(set) var` is get-only even inside this extension
    // ("cannot assign to property: 'superview' is a get-only property"),
    // so readonly header properties need Swift-only backing storage.
    var superview: OUIProbeView? { _superview }
    var subviews: [OUIProbeView] { _subviews }
    var layoutCount: Int { _layoutCount }

    init(frame: CGRect) {
        super.init()
        self.frame = frame
    }

    convenience override init() {
        self.init(frame: .zero)
    }

    func addSubview(_ view: OUIProbeView) {
        guard view !== self else { return }
        view.removeFromSuperview()
        view._superview = self
        _subviews.append(view)
        setNeedsLayout()
    }

    func removeFromSuperview() {
        guard let parent = superview else { return }
        parent._subviews.removeAll { $0 === self }
        _superview = nil
        parent.setNeedsLayout()
    }

    func setNeedsLayout() {
        needsLayout = true
    }

    func layoutIfNeeded() {
        var top = self
        while let parent = top.superview { top = parent }
        top._layoutSubtree()
    }

    func layoutSubviews() {
        _layoutCount += 1
        OUIProbeTrace.record("\(type(of: self)).layoutSubviews(base)")
    }

    // MARK: Swift-only members (NOT in the header). They must be `final`
    // or private; stored ones become ivars of the Objective-C class.

    final var needsLayout: Bool = true
    final weak var _superview: OUIProbeView?
    final var _subviews: [OUIProbeView] = []
    final var _layoutCount: Int = 0
    /// Swift-only stored property of a Swift struct array.
    public final var animations: [OUIProbeAnimation] = []
    /// Swift-only stored property of an enum with payloads.
    public final var tint: OUIProbeTint = .none
    /// Swift-only stored closure.
    public final var onLayout: ((OUIProbeView) -> Void)?
    /// Swift-only stored optional of a non-ObjC type.
    public final var lastLayoutSize: CGSize?

#if OUIPROBE_NONFINAL
    // Compile-time measurement (`swift build -Xswiftc -DOUIPROBE_NONFINAL`):
    // can a member that is NOT in the header stay overridable? (A second
    // `@objc @implementation extension` of the same class is rejected:
    // "duplicate implementation of imported class", so it lives here.)
    func swiftOnlyOverridable() -> Int { 1 }
    var swiftOnlyOverridableProperty: Int { 2 }
    open func swiftOnlyOpen() {}
#endif

    fileprivate func _layoutSubtree() {
        if needsLayout {
            needsLayout = false
            layoutSubviews()
            lastLayoutSize = bounds.size
            onLayout?(self)
        }
        for child in subviews { child._layoutSubtree() }
    }
}

/// Process-wide call trace so Objective-C and Swift callers can verify the
/// override / super chain from either side.
public enum OUIProbeTrace {
    nonisolated(unsafe) public static var lines: [String] = []
    public static func record(_ line: String) { lines.append(line) }
    public static func reset() { lines = [] }
}
