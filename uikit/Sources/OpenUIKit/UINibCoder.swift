// UINibCoder — the NSCoder an archived object's `init(coder:)` receives, and
// the connection objects that wire a nib's outlets, actions and runtime
// attributes. Owner: app-compat module (storyboard runtime).
//
// Real UIKit builds every archived object as `[[cls alloc]
// initWithCoder:nibDecoder]`, where the decoder is positioned on that
// object's archived keys; the class's own initializer — including an app's
// `required init?(coder:)` — runs, and UIKit's `-[UIView initWithCoder:]`
// decodes the geometry, colours, subviews and constraints. This file is that
// path for OpenUIKit: `NibDecoder` hands a `UINibCoder` to the class's
// `init(coder:)`, and `UIView.init?(coder:)` / `UIViewController.init?(coder:)`
// call back into `decodeViewState` / `decodeControllerState` to apply the
// archived keys to `self`.
//
// MEASURED ORDER (Tools/oracle2/nibruntimeprobe on iOS 26.1, the carried
// transcript fixtures/nibruntime/oracle/nibruntime.json):
//   * a custom view's `init(coder:)` sees its archived frame and background
//     once `super.init(coder:)` returns, with no superview yet;
//   * user-defined runtime attributes are set after every object is built
//     and before any outlet is connected;
//   * outlets connect in archive order, then `awakeFromNib` runs.

// MARK: sugar-unify scoped imports (docs/agent_reports/sugar-unify.md):
// Foundation / ObjectiveC names OpenUIKit re-exports rather than re-declares.
// Each is @_exported here too: a plain scoped import that precedes the
// re-export in file order hides the name from clients (swiftc).
#if canImport(ObjectiveC)
@_exported import struct ObjectiveC.Selector
#endif

#if canImport(Foundation)
@_exported import class Foundation.NSCoder
import class Foundation.NSObject
import class Foundation.NSArray
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif
#if canImport(ObjectiveC)
import ObjectiveC
#endif

/// The keyed coder positioned on one archived object.
///
/// Not main-actor isolated because Foundation's `NSCoder` is not: its
/// overrides must match. Every override hops onto the decoder with
/// `MainActor.assumeIsolated`, which holds because nib loading is a
/// main-thread operation in UIKit and in OpenUIKit.
final class UINibCoder: NSCoder, @unchecked Sendable {
    let decoder: NibDecoder
    let index: Int

    init(decoder: NibDecoder, index: Int) {
        self.decoder = decoder
        self.index = index
        super.init()
    }

    private func value(_ key: String) -> NibArchive.Value? {
        MainActor.assumeIsolated { decoder.archive.objects[index].first(key) }
    }

    /// What an app's `coder.decodeObject(forKey:)` returns: the built object,
    /// with archive boxes unwrapped to the values UIKit's decoder returns.
    private func object(_ key: String) -> Any? {
        MainActor.assumeIsolated { () -> Any? in
            guard case .reference(let i)? = decoder.archive.objects[index].first(key),
                  let built = decoder.build(i) else { return nil }
            return decoder.unboxed(built)
        }
    }

    private func number(_ key: String) -> Double? {
        switch value(key) {
        case .integer(let i)?: return Double(i)
        case .number(let d)?: return d
        case .boolean(let b)?: return b ? 1 : 0
        default: return nil
        }
    }

#if canImport(Foundation)
    override var allowsKeyedCoding: Bool { true }
    override func containsValue(forKey key: String) -> Bool { value(key) != nil }
    override func decodeObject(forKey key: String) -> Any? { object(key) }
    override func decodeBool(forKey key: String) -> Bool { (number(key) ?? 0) != 0 }
    override func decodeInteger(forKey key: String) -> Int { Int(number(key) ?? 0) }
    override func decodeInt32(forKey key: String) -> Int32 { Int32(truncatingIfNeeded: Int(number(key) ?? 0)) }
    override func decodeInt64(forKey key: String) -> Int64 { Int64(number(key) ?? 0) }
    override func decodeFloat(forKey key: String) -> Float { Float(number(key) ?? 0) }
    override func decodeDouble(forKey key: String) -> Double { number(key) ?? 0 }
#else
    var allowsKeyedCoding: Bool { true }
    func containsValue(forKey key: String) -> Bool { value(key) != nil }
    func decodeObject(forKey key: String) -> Any? { object(key) }
    func decodeBool(forKey key: String) -> Bool { (number(key) ?? 0) != 0 }
    func decodeInteger(forKey key: String) -> Int { Int(number(key) ?? 0) }
    func decodeDouble(forKey key: String) -> Double { number(key) ?? 0 }
    func decodeFloat(forKey key: String) -> Float { Float(number(key) ?? 0) }
#endif

    // MARK: Hooks called from the framework's init(coder:)

    /// From `UIView.init?(coder:)`: register the view under construction
    /// (so references back to it resolve) and decode its archived state.
    @MainActor
    static func decodeViewState(_ view: UIView, from coder: NSCoder) {
        guard let nib = coder as? UINibCoder else { return }
        nib.decoder.register(view, at: nib.index)
        nib.decoder.applyView(nib.decoder.archive.objects[nib.index], to: view)
    }

    /// From a framework subclass's `init(coder:)` after it reset properties
    /// UIKit decodes (UILabel's defaults, UIButton's title font, UISwitch's
    /// forced size): apply the archived property keys once more so the
    /// archive wins, as it does when UIKit decodes inside `initWithCoder:`.
    @MainActor
    static func reapplyFrameworkState(_ view: UIView, from coder: NSCoder) {
        guard let nib = coder as? UINibCoder else { return }
        let object = nib.decoder.archive.objects[nib.index]
        nib.decoder.applyView(object, to: view, scalarsOnly: true)
        // A cell's own init re-adds its default text label and image view
        // to the content view; an archived custom cell has neither
        // (`UITextLabel` / `UIImageView` archive nil).
        if let cell = view as? UITableViewCell, object.first("UIContentView") != nil {
            cell.textLabel?.removeFromSuperview()
            cell.imageView?.removeFromSuperview()
        }
    }

    /// From `UIViewController.init?(coder:)`.
    @MainActor
    static func decodeControllerState(_ controller: UIViewController, from coder: NSCoder) {
        guard let nib = coder as? UINibCoder else { return }
        nib.decoder.register(controller, at: nib.index)
        nib.decoder.applyController(nib.decoder.archive.objects[nib.index], to: controller)
    }

    /// A string key of the object being decoded, readable before
    /// `super.init` (for a `let` the class must assign first).
    static func archivedString(_ coder: NSCoder, _ key: String) -> String? {
        guard let nib = coder as? UINibCoder else { return nil }
        return MainActor.assumeIsolated { nib.decoder.string(nib.decoder.archive.objects[nib.index].first(key)) }
    }

    /// An integer key of the object being decoded, readable before
    /// `super.init`.
    static func archivedInteger(_ coder: NSCoder, _ key: String) -> Int? {
        guard let nib = coder as? UINibCoder else { return nil }
        return MainActor.assumeIsolated { nib.decoder.int(nib.decoder.archive.objects[nib.index].first(key)) }
    }
}

extension NibDecoder {
    /// Archive boxes as the values Foundation's keyed decoder returns.
    func unboxed(_ object: AnyObject) -> Any {
        switch object {
        case let string as NibString: return string.value
        case let number as NibNumberBox:
            return number.isInteger ? Int(number.value) as Any : number.value as Any
        case let font as NibFontBox: return font.font
        case let array as NibArrayBox: return arrayElements(at: array.index).map { unboxed($0) }
        default: return object
        }
    }
}

// MARK: - Connections

/// One archived connection, made after every object exists.
@MainActor
protocol NibConnecting: AnyObject {
    func connect()
}

/// Outlet assignment in the order UIKit's `UIRuntimeOutletConnection
/// -connect` uses: framework-owned names first (UIKit fills these through
/// KVC on its own classes, where the port's properties are not `@objc`),
/// then a class's `UINibOutletConnecting` table, then — on an Objective-C
/// runtime — Key-Value Coding, which is what `@IBOutlet` means on Apple
/// platforms.
@MainActor
enum NibOutlets {
    static func assign(_ value: AnyObject?, named name: String, on source: AnyObject) -> Bool {
        if assignFrameworkOutlet(value, named: name, on: source) { return true }
        if let receiver = source as? UINibOutletConnecting,
           receiver.setNibOutlet(value, forName: name) {
            return true
        }
        return assignByKeyValueCoding(value.map { $0 as Any }, named: name, on: source)
    }

    static func assignFrameworkOutlet(_ value: AnyObject?, named name: String, on source: AnyObject) -> Bool {
        switch (source, name) {
        case (let controller as UIViewController, "view"):
            controller.view = value as? UIView
            return true
        case (let controller as UIViewController, "storyboard"):
            controller._storyboardState(create: true)?.storyboard = value as? UIStoryboard
            return true
        case (let scene as _UIStoryboardScene, "sceneViewController"):
            scene.sceneViewController = value as? UIViewController
            return true
        case (let template as UIStoryboardSegueTemplate, "viewController"):
            template.viewController = value as? UIViewController
            return true
        case (let template as UIStoryboardSegueTemplate, "containerView"):
            template.containerView = value as? UIView
            return true
        case (let table as UITableView, "dataSource"):
            table.dataSource = value as? UITableViewDataSource
            return true
        case (let collection as UICollectionView, "dataSource"):
            collection.dataSource = value as? UICollectionViewDataSource
            return true
        // A table's / collection's `delegate` IS the inherited scroll-view
        // delegate, as in UIKit (UITableViewDelegate refines
        // UIScrollViewDelegate).
        case (let scroll as UIScrollView, "delegate"):
            scroll.delegate = value as? UIScrollViewDelegate
            return true
        case (let field as UITextField, "delegate"):
            field.delegate = value as? UITextFieldDelegate
            return true
        case (let recognizer as UIGestureRecognizer, "delegate"):
            recognizer.delegate = value as? UIGestureRecognizerDelegate
            return true
        default:
            return false
        }
    }

    /// `setValue(_:forKey:)` when it will not raise: the class has the
    /// `set<Name>:` setter an `@IBOutlet` property compiles to, or it
    /// overrides `setValue(_:forUndefinedKey:)`. UIKit would raise
    /// NSUnknownKeyException otherwise (MEASURED: Eidolon's KeypadView.xib
    /// with no app classes raises "not key value coding-compliant for the key
    /// keys"); the port records the outlet in `UINib.unhandledKeys` instead
    /// of terminating.
    static func assignByKeyValueCoding(_ value: Any?, named name: String, on source: AnyObject) -> Bool {
#if canImport(ObjectiveC)
        guard let object = source as? NSObject, let first = name.first else { return false }
        let setterName = "set" + first.uppercased() + name.dropFirst() + ":"
        let setter = sel_registerName(setterName)
        let answers = object.responds(to: setter) || overridesUndefinedKey(type(of: object))
        guard answers else { return false }
#if canImport(Foundation)
        object.setValue(value, forKey: name)
        return true
#else
        guard object.responds(to: setter) else { return false }
        _ = object.perform(setter, with: value)
        return true
#endif
#else
        _ = value; _ = name; _ = source
        return false
#endif
    }

#if canImport(ObjectiveC)
    /// True when `cls` replaces NSObject's `setValue:forUndefinedKey:`
    /// (which raises) with its own.
    static func overridesUndefinedKey(_ cls: AnyClass) -> Bool {
        let selector = sel_registerName("setValue:forUndefinedKey:")
        guard let base = class_getInstanceMethod(NSObject.self, selector),
              let own = class_getInstanceMethod(cls, selector) else { return false }
        return method_getImplementation(base) != method_getImplementation(own)
    }
#endif
}

/// One archived `UIRuntimeOutletConnection`.
@MainActor
final class NibConnection: NibConnecting {
    let name: String
    let source: AnyObject
    let destination: AnyObject?

    init(name: String, source: AnyObject, destination: AnyObject?) {
        self.name = name
        self.source = source
        self.destination = destination
    }

    func connect() {
        guard !(source is NibProxyPlaceholder) else {
            UINib.noteUnhandled("outlet-from-placeholder:\(name)")
            return
        }
        let target = destination is NibProxyPlaceholder ? nil : destination
        if NibOutlets.assign(target, named: name, on: source) { return }
        UINib.noteUnhandled("outlet:\(type(of: source)).\(name)")
    }
}

/// One archived `UIRuntimeOutletCollectionConnection`: an `@IBOutlet var
/// labels: [UILabel]!` filled with every destination at once (MEASURED: the
/// probe's two-label collection is set once, with both).
@MainActor
final class NibCollectionConnection: NibConnecting {
    let name: String
    let source: AnyObject
    let destinations: [AnyObject]
    let appends: Bool

    init(name: String, source: AnyObject, destinations: [AnyObject], appends: Bool) {
        self.name = name
        self.source = source
        self.destinations = destinations
        self.appends = appends
    }

    func connect() {
        // `gestureRecognizers` with addsContentToExistingCollection is how
        // IB attaches a recognizer to its view.
        if name == "gestureRecognizers", let view = source as? UIView {
            for case let recognizer as UIGestureRecognizer in destinations {
                view.addGestureRecognizer(recognizer)
            }
            return
        }
        if let receiver = source as? UINibOutletConnecting,
           receiver.setNibOutlet(destinations as AnyObject, forName: name) {
            return
        }
        if NibOutlets.assignByKeyValueCoding(destinations as [Any], named: name, on: source) {
            return
        }
        UINib.noteUnhandled("outlet-collection:\(type(of: source)).\(name)")
    }
}

/// One archived `UIRuntimeEventConnection`: target-action on a control or a
/// gesture recognizer, or a control that triggers a storyboard segue (its
/// destination is the segue template and its selector `perform:`).
@MainActor
final class NibEventConnection: NibConnecting {
    let selectorName: String
    let source: AnyObject
    let destination: AnyObject?
    let eventMask: UInt

    init(selectorName: String, source: AnyObject, destination: AnyObject?, eventMask: UInt) {
        self.selectorName = selectorName
        self.source = source
        self.destination = destination
        self.eventMask = eventMask
    }

    func connect() {
        if let template = destination as? UIStoryboardSegueTemplate,
           selectorName == "perform:", let control = source as? UIControl {
            control.addTarget(for: UIControl.Event(rawValue: eventMask)) { [weak template] sender, _ in
                template?.perform(sender)
            }
            return
        }
        let action = Selector.named(selectorName)
        if let control = source as? UIControl {
            control.addTarget(destination, action: action, for: UIControl.Event(rawValue: eventMask))
            return
        }
        if let recognizer = source as? UIGestureRecognizer {
            recognizer.addTarget(destination as Any, action: action)
            return
        }
        if let item = source as? UIBarButtonItem {
            item.target = destination
            item.action = action
            return
        }
        UINib.noteUnhandled("action:\(type(of: source)).\(selectorName)")
    }
}

/// One `UINibKeyValuePair`: an Interface Builder user-defined runtime
/// attribute, set through Key-Value Coding (`setValue(_:forKeyPath:)`).
@MainActor
final class NibKeyValuePair {
    let target: AnyObject
    let keyPath: String
    let value: AnyObject?

    init(target: AnyObject, keyPath: String, value: AnyObject?) {
        self.target = target
        self.keyPath = keyPath
        self.value = value
    }

    func apply() {
        // ibtool writes the frame of a control whose archived bounds it
        // normalized (a switch's) as a runtime attribute; UIKit's `frame`
        // setter then applies the control's own size rule.
        if keyPath == "frame", let view = target as? UIView,
           let rect = value as? NibValueBox, rect.numbers.count == 4 {
            view.frame = CGRect(x: rect.numbers[0], y: rect.numbers[1],
                                width: rect.numbers[2], height: rect.numbers[3])
            return
        }
#if canImport(Foundation) && canImport(ObjectiveC)
        if let object = target as? NSObject, !keyPath.contains("."),
           let first = keyPath.first {
            let setter = sel_registerName("set" + first.uppercased() + keyPath.dropFirst() + ":")
            if object.responds(to: setter) || NibOutlets.overridesUndefinedKey(type(of: object)) {
                let bridged: Any? = {
                    switch value {
                    case let number as NibNumberBox:
                        return number.isInteger ? Int(number.value) as Any : number.value as Any
                    case let string as NibString: return string.value
                    default: return value
                    }
                }()
                object.setValue(bridged, forKey: keyPath)
                return
            }
        }
#endif
        UINib.noteUnhandled("runtime-attribute:\(type(of: target)).\(keyPath)")
    }
}
