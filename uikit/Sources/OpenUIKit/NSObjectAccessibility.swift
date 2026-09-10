// UIKit's accessibility informal protocol, where UIKit actually puts it:
// on NSObject. Owner: view module.
//
// SDK EVIDENCE — iOS 26.1, read from
// /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/
// Developer/SDKs/iPhoneSimulator26.1.sdk :
//
//   UIKit.framework/Headers/UIAccessibility.h:44
//       @interface NSObject (UIAccessibility)
//     :52   isAccessibilityElement            BOOL
//     :64   accessibilityLabel                NSString *  (nullable, copy)
//     :79   accessibilityHint                 NSString *  (nullable, copy)
//     :95   accessibilityValue                NSString *  (nullable, copy)
//     :113  accessibilityTraits               UIAccessibilityTraits
//     :160  accessibilityElementsHidden       BOOL   (default NO)
//     :167  accessibilityViewIsModal          BOOL   (default NO)
//     :174  shouldGroupAccessibilityChildren  BOOL   (default NO)
//     :182  accessibilityNavigationStyle      UIAccessibilityNavigationStyle
//
//   UIKit.framework/Headers/UIAccessibilityContainer.h:31
//       @interface NSObject (UIAccessibilityContainer)
//     :53   accessibilityElements             NSArray *   (nullable, strong)
//
//   UIKit.framework/Headers/UIAccessibilityIdentification.h:19
//       @protocol UIAccessibilityIdentification <NSObject>
//     :25   accessibilityIdentifier           NSString *  (nullable, copy)
//     :30-39 adopted by UIView, UIBarItem, UIAlertAction, UIMenuElement
//
// So `accessibilityIdentifier` is NOT an NSObject member: it rides the
// UIAccessibilityIdentification protocol on exactly four types. Every other
// property above is on the root class, which is why
// Kickstarter-ReactiveExtensions can write
// `extension Rac where Object: NSObject { var accessibilityLabel: … }` and
// why Kickstarter-Prelude's `KSObjectProtocol: NSObjectProtocol` lists nine
// of them as `{ get set }` requirements.
//
// Before this file the port declared them on UIResponder, which made both of
// those shapes uncompilable (docs/agent_reports/ios-oss-launch.md: 12 of
// ReactiveExtensions' 12 diagnostics, plus one Prelude_UIKit row).
//
// STORAGE ONLY, unchanged from the UIResponder era: OpenUIKit drives no
// assistive technology, nothing in the renderer reads these, and there is no
// oracle for something with no pixels. What they buy is that a real app's
// accessibility configuration compiles and reads back — which is what a UI
// test asserting `accessibilityLabel` needs. Stated in docs/KNOWN_GAPS.md.
//
// DEFAULTS are the ones the ios-oss-launch probe measured on a bare
// `NSObject()` on iPhone 16 / iOS 26.1: label/hint/value nil,
// `isAccessibilityElement` false, traits 0, `elementsHidden` false.

// NSObject provider, chosen exactly as UIResponder.swift chooses it — see
// that file's header for why this fails closed rather than falling back to a
// plain Swift class.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("OpenUIKit requires Foundation.NSObject or ObjectiveC.NSObject")
#endif

/// Every accessibility attribute the port stores for one object.
///
/// Kept as one value so the side table below holds a single box per object
/// instead of ten parallel maps.
struct AccessibilityState {
    var navigationStyle: UIAccessibilityNavigationStyle = .automatic
    var isElement = false
    var elementsHidden = false
    var viewIsModal = false
    var groupsChildren = false
    var label: String?
    var value: String?
    var hint: String?
    var identifier: String?
    var traits: UIAccessibilityTraits = .none
    var elements: [Any]?
    var customActions: [UIAccessibilityCustomAction]?
    var customActionsBlock: (() -> [UIAccessibilityCustomAction]?)?
    var customRotors: [UIAccessibilityCustomRotor]?
    var customRotorsBlock: (() -> [UIAccessibilityCustomRotor]?)?
}

/// Per-object accessibility storage for a root class the port does not own.
///
/// UIKit gets this for free: the properties are an Objective-C category with
/// runtime-allocated ivars on NSObject itself. OpenUIKit cannot add stored
/// properties to Foundation's NSObject, so it keeps a side table.
///
/// ADDRESS REUSE is the trap a naive `[ObjectIdentifier: State]` walks into:
/// `ObjectIdentifier` is the object's address, and a freshly allocated object
/// can land on a dead one's address and inherit its accessibility label. Each
/// entry therefore carries a `weak` reference to the object it was written
/// for, and a lookup whose weak owner is nil or is a *different* object is
/// treated as absent. A stale entry is overwritten on the next write to that
/// address, and an opportunistic sweep drops entries whose object is gone so
/// the table cannot grow without bound.
///
/// Not synchronized: the whole UIKit object graph is single-threaded in this
/// port (same standing assumption as `UIApplication._preferredContentSizeCategory`
/// and `UIColor.current`).
enum _UIAccessibilityStorage {
    final class Box {
        weak var owner: AnyObject?
        var state: AccessibilityState
        init(owner: AnyObject, state: AccessibilityState) {
            self.owner = owner
            self.state = state
        }
    }

    nonisolated(unsafe) static var boxes: [ObjectIdentifier: Box] = [:]
    nonisolated(unsafe) static var writesSinceSweep = 0

    /// Sweep after this many writes. Amortizes to O(1) per write.
    static let sweepInterval = 256

    static func state(for object: AnyObject) -> AccessibilityState? {
        guard let box = boxes[ObjectIdentifier(object)], box.owner === object
        else { return nil }
        return box.state
    }

    static func setState(_ state: AccessibilityState, for object: AnyObject) {
        let key = ObjectIdentifier(object)
        if let box = boxes[key], box.owner === object {
            box.state = state
        } else {
            boxes[key] = Box(owner: object, state: state)
        }
        writesSinceSweep += 1
        if writesSinceSweep >= sweepInterval { sweep() }
    }

    /// Drop every entry whose object has been deallocated.
    static func sweep() {
        writesSinceSweep = 0
        for (key, box) in boxes where box.owner == nil {
            boxes.removeValue(forKey: key)
        }
    }
}

/// The UIAccessibility informal protocol, made formal.
///
/// UIKit's version is an Objective-C category on NSObject, and a category
/// member is dynamically dispatched: an app can `override` it in a subclass
/// (Blockzilla's `AutocompleteTextField` overrides `accessibilityValue`).
/// A Swift `extension NSObject { var accessibilityValue … }` is NOT
/// overridable, and any subclass that redeclares the same member is rejected
/// with "non-'@objc' property … is declared in extension of 'NSObject' and
/// cannot be overridden" — on Linux and the Foundation-hidden guest there is
/// no `@objc` to reach for, so that route is closed on the two substrates
/// that matter most.
///
/// Declaring the surface as a protocol with default implementations and
/// conforming NSObject to it gets both halves at once, on every substrate:
///
///   * `extension Rac where Object: NSObject { object.accessibilityLabel = … }`
///     resolves through NSObject's conformance, which is the shape
///     Kickstarter-ReactiveExtensions and Kickstarter-Prelude need;
///   * a class in the port may still declare the member in its own body —
///     that shadows the protocol default instead of overriding a superclass
///     member — so `UIResponder.accessibilityValue` stays `open` and an app's
///     `override` keeps compiling.
///
/// DIVERGENCE from UIKit, recorded in docs/KNOWN_GAPS.md: UIKit's category
/// members are dynamically dispatched, these are not. An app override is seen
/// through the declaring class's static type but NOT through a call site
/// whose static type is only `NSObject`. There is no third option in Swift
/// without the Objective-C runtime. The protocol itself has no UIKit
/// counterpart and is additive: no app source names it.
public protocol UIAccessibilityInformalProtocol: AnyObject {
    var isAccessibilityElement: Bool { get set }
    var accessibilityLabel: String? { get set }
    var accessibilityHint: String? { get set }
    var accessibilityValue: String? { get set }
    var accessibilityTraits: UIAccessibilityTraits { get set }
    var accessibilityElementsHidden: Bool { get set }
    var accessibilityViewIsModal: Bool { get set }
    var shouldGroupAccessibilityChildren: Bool { get set }
    var accessibilityNavigationStyle: UIAccessibilityNavigationStyle { get set }
    var accessibilityElements: [Any]? { get set }
    var accessibilityCustomActions: [UIAccessibilityCustomAction]? { get set }
    var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? { get set }
}

extension UIAccessibilityInformalProtocol {
    /// The whole attribute set for this object. Internal: the port's classes
    /// read it directly (UIResponder's overridable `accessibilityValue`) and
    /// so do the tests.
    var _accessibility: AccessibilityState {
        get { _UIAccessibilityStorage.state(for: self) ?? AccessibilityState() }
        set { _UIAccessibilityStorage.setState(newValue, for: self) }
    }

    public var isAccessibilityElement: Bool {
        get { _accessibility.isElement }
        set { _accessibility.isElement = newValue }
    }
    public var accessibilityLabel: String? {
        get { _accessibility.label }
        set { _accessibility.label = newValue }
    }
    public var accessibilityHint: String? {
        get { _accessibility.hint }
        set { _accessibility.hint = newValue }
    }
    public var accessibilityValue: String? {
        get { _accessibility.value }
        set { _accessibility.value = newValue }
    }
    public var accessibilityTraits: UIAccessibilityTraits {
        get { _accessibility.traits }
        set { _accessibility.traits = newValue }
    }
    public var accessibilityElementsHidden: Bool {
        get { _accessibility.elementsHidden }
        set { _accessibility.elementsHidden = newValue }
    }
    public var accessibilityViewIsModal: Bool {
        get { _accessibility.viewIsModal }
        set { _accessibility.viewIsModal = newValue }
    }
    public var shouldGroupAccessibilityChildren: Bool {
        get { _accessibility.groupsChildren }
        set { _accessibility.groupsChildren = newValue }
    }
    public var accessibilityNavigationStyle: UIAccessibilityNavigationStyle {
        get { _accessibility.navigationStyle }
        set { _accessibility.navigationStyle = newValue }
    }
    /// UIAccessibilityContainer.h:53 — the container's ordered children.
    public var accessibilityElements: [Any]? {
        get { _accessibility.elements }
        set { _accessibility.elements = newValue }
    }
    public var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get { _accessibility.customActions }
        set { _accessibility.customActions = newValue }
    }
    public var accessibilityCustomActionsBlock: (() -> [UIAccessibilityCustomAction]?)? {
        get { _accessibility.customActionsBlock }
        set { _accessibility.customActionsBlock = newValue }
    }
    public var accessibilityCustomRotors: [UIAccessibilityCustomRotor]? {
        get { _accessibility.customRotors }
        set { _accessibility.customRotors = newValue }
    }
    public var accessibilityCustomRotorsBlock: (() -> [UIAccessibilityCustomRotor]?)? {
        get { _accessibility.customRotorsBlock }
        set { _accessibility.customRotorsBlock = newValue }
    }
}

/// Where UIKit puts it: on the root class, for every object in the graph.
extension NSObject: UIAccessibilityInformalProtocol {}

/// UIKit's `UIAccessibilityIdentification` (UIAccessibilityIdentification.h:19).
///
/// Apple adopts it on exactly four types — UIView, UIBarItem, UIAlertAction
/// and UIMenuElement — rather than putting `accessibilityIdentifier` on
/// NSObject, so the protocol is what a generic constraint can name.
public protocol UIAccessibilityIdentification: AnyObject {
    var accessibilityIdentifier: String? { get set }
}

/// UIKit adopts this on UIView; the port's declaration lives one level up on
/// UIResponder (so a view controller can carry an identifier too, which
/// several real apps set), and UIView inherits the member from there.
extension UIView: UIAccessibilityIdentification {}
