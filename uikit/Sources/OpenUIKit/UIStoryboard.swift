// UIStoryboard, segues, and storyboard-backed view controllers.
// Owner: app-compat module (storyboard runtime).
//
// A compiled storyboard (`ibtool --compile X.storyboard`, which is what
// Xcode ships) is a `.storyboardc` directory: `Info.plist` (binary plist,
// BinaryPropertyList.swift) names the entry point
// (`UIStoryboardDesignatedEntryPointIdentifier`) and maps every storyboard
// identifier to a scene nib (`UIViewControllerIdentifiersToNibNames`). A
// scene nib archives the controller — with its nib name, navigation item,
// segue templates and the table of objects its view nib will need
// (`UIExternalObjectsTableForViewLoading`) — and the controller's view is a
// SEPARATE nib (`<id>-view-<id>.nib`) loaded when `view` is first touched.
// A navigation controller's root relationship is archived inside the
// navigation controller's own scene nib.
//
// Behaviour here is implemented against Tools/oracle2/nibruntimeprobe on a
// private iPhone 16 / iOS 26.1 simulator, loading the carried
// fixtures/nibruntime/NibRuntimeProbe.storyboardc (transcript:
// fixtures/nibruntime/oracle/nibruntime.json). MEASURED there:
//   * instantiation: the scene nib's File's Owner is a scene object whose
//     `sceneViewController` outlet receives the controller; the storyboard is
//     the `UIStoryboardPlaceholder` external object and reaches the
//     controller through its `storyboard` outlet (nil inside
//     `init(coder:)`, set by `awakeFromNib`);
//   * view load: the view nib is instantiated with the controller as File's
//     Owner and the archived external-object table; after `loadView`
//     returns and BEFORE `viewDidLoad`, each embed segue runs:
//     `shouldPerformSegue(withIdentifier:sender:)` with the controller as
//     sender, the destination is instantiated, `prepare(for:sender:)`, the
//     destination's view loads, `willMove(toParent:)`, its view is added
//     filling the container with autoresizing 18, `didMove(toParent:)`;
//   * `performSegue(withIdentifier:sender:)` does NOT ask
//     `shouldPerformSegue`; a control-triggered segue does, with the control
//     as sender. Both instantiate the destination, call `prepare`, then
//     perform (show = the source's `show(_:sender:)`);
//   * the segue object is a plain `UIStoryboardSegue` for show and embed.

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

// MARK: - UIStoryboard

@preconcurrency @MainActor
open class UIStoryboard: NSObject {
    public let name: String
    /// The `.storyboardc` directory, nil when it was not found.
    let directory: String?
    let entryPointIdentifier: String?
    let identifierToNibName: [String: String]

#if canImport(Foundation)
    public let bundle: Bundle?
#else
    public let bundle: Any?
#endif

    /// UIKit's `init(name:bundle:)`. The `.storyboardc` is found on
    /// `OpenUIKitRuntime.nibSearchPaths`, then in the bundle's resource
    /// directory (the main bundle when nil). UIKit raises when the
    /// storyboard does not exist; so does this, at the first instantiation,
    /// with the same message, rather than returning scenes that are not there.
#if canImport(Foundation)
    public init(name: String, bundle: Bundle?) {
        self.name = name
        self.bundle = bundle
        let found = UIStoryboard.locate(name, bundle: bundle)
        (directory, entryPointIdentifier, identifierToNibName) = found
        super.init()
    }
#else
    public init(name: String, bundle: Any?) {
        self.name = name
        self.bundle = bundle
        let found = UIStoryboard.locate(name, bundle: bundle as? Bundle)
        (directory, entryPointIdentifier, identifierToNibName) = found
        super.init()
    }
#endif

    static func locate(_ name: String, bundle: Bundle?)
        -> (String?, String?, [String: String]) {
        var directories = OpenUIKitRuntime.nibSearchPaths
        if let resources = _resourceDirectory(of: bundle) { directories.append(resources) }
        for directory in directories {
            let path = "\(directory)/\(name).storyboardc"
            guard let bytes = ResourceIO.readFile("\(path)/Info.plist"),
                  let plist = BinaryPropertyList.parse(bytes) else { continue }
            var table: [String: String] = [:]
            for (key, value) in plist["UIViewControllerIdentifiersToNibNames"]?.dictionary ?? [:] {
                if let nib = value.string { table[key] = nib }
            }
            return (path, plist["UIStoryboardDesignatedEntryPointIdentifier"]?.string, table)
        }
        return (nil, nil, [:])
    }

    private func requireDirectory() -> String {
        guard let directory else {
            fatalError("Could not find a storyboard named '\(name)' in bundle; point "
                       + "OpenUIKitRuntime.nibSearchPaths at the directory holding "
                       + "\(name).storyboardc")
        }
        return directory
    }

    /// UIKit: nil when the storyboard has no initial view controller.
    open func instantiateInitialViewController() -> UIViewController? {
        _ = requireDirectory()
        guard let entry = entryPointIdentifier else { return nil }
        return instantiateViewController(withIdentifier: entry)
    }

    /// UIKit raises NSInvalidArgumentException for an unknown identifier.
    open func instantiateViewController(withIdentifier identifier: String) -> UIViewController {
        let directory = requireDirectory()
        guard let nibName = identifierToNibName[identifier] else {
            fatalError("Storyboard (\(name)) doesn't contain a view controller with "
                       + "identifier '\(identifier)'")
        }
        let nib = UINib(path: "\(directory)/\(nibName).nib")
        guard nib.isLoaded else {
            fatalError("UIStoryboard: scene nib '\(nibName).nib' missing from \(directory)")
        }
        let scene = _UIStoryboardScene()
        _ = nib.instantiate(withOwner: scene,
                            options: [.externalObjects: ["UIStoryboardPlaceholder": self]])
        guard let controller = scene.sceneViewController else {
            fatalError("UIStoryboard: scene '\(identifier)' produced no view controller")
        }
        return controller
    }

    /// A controller's view nib, which lives beside its scene nib.
    func viewNib(named nibName: String) -> UINib? {
        guard let directory else { return nil }
        let nib = UINib(path: "\(directory)/\(nibName).nib")
        return nib.isLoaded ? nib : nil
    }
}

/// The File's Owner of a storyboard scene nib (UIKit's is private too); its
/// `sceneViewController` outlet receives the scene's controller.
@MainActor
final class _UIStoryboardScene: NSObject {
    var sceneViewController: UIViewController?
}

// MARK: - Segues

@preconcurrency @MainActor
open class UIStoryboardSegue: NSObject {
    public let identifier: String?
    public let source: UIViewController
    public let destination: UIViewController
    private let performHandler: (() -> Void)?

    public init(identifier: String?, source: UIViewController, destination: UIViewController) {
        self.identifier = identifier
        self.source = source
        self.destination = destination
        self.performHandler = nil
        super.init()
    }

    /// UIKit's block-based initializer (`segueWithIdentifier:source:
    /// destination:performHandler:`), which is also how the storyboard's
    /// own show / embed / presentation segues are built.
    public init(identifier: String?, source: UIViewController, destination: UIViewController,
                performHandler: @escaping () -> Void) {
        self.identifier = identifier
        self.source = source
        self.destination = destination
        self.performHandler = performHandler
        super.init()
    }

    open func perform() {
        performHandler?()
    }
}

/// An archived segue (`UIStoryboard*SegueTemplate`): how a controller
/// reaches its destination scene. Internal, as UIKit's are private.
@MainActor
final class UIStoryboardSegueTemplate: NSObject {
    enum Kind {
        case show(action: String)
        case push
        case modal
        case presentation
        case embed
        case other(String)
    }

    let kind: Kind
    let identifier: String?
    let destinationIdentifier: String?
    let performOnViewLoad: Bool
    let modalPresentationStyle: UIModalPresentationStyle?
    weak var viewController: UIViewController?
    weak var containerView: UIView?

    init(kind: Kind, identifier: String?, destinationIdentifier: String?,
         performOnViewLoad: Bool, modalPresentationStyle: UIModalPresentationStyle?) {
        self.kind = kind
        self.identifier = identifier
        self.destinationIdentifier = destinationIdentifier
        self.performOnViewLoad = performOnViewLoad
        self.modalPresentationStyle = modalPresentationStyle
        super.init()
    }

    /// A control-triggered segue (the archive connects the control to the
    /// template with selector `perform:`): asks the source first.
    func perform(_ sender: Any?) {
        guard let source = viewController else { return }
        guard source.shouldPerformSegue(withIdentifier: identifier ?? "", sender: sender) else { return }
        performSegue(sender: sender)
    }

    /// Instantiate the destination, let the source prepare, perform.
    func performSegue(sender: Any?) {
        guard let source = viewController else { return }
        guard let storyboard = source.storyboard, let destinationIdentifier else {
            UINib.noteUnhandled("segue-without-storyboard:\(identifier ?? "?")")
            return
        }
        let destination = storyboard.instantiateViewController(withIdentifier: destinationIdentifier)
        if let style = modalPresentationStyle { destination.modalPresentationStyle = style }
        let segue = UIStoryboardSegue(identifier: identifier, source: source,
                                      destination: destination) { [weak self] in
            self?.run(from: source, to: destination)
        }
        source.prepare(for: segue, sender: sender)
        segue.perform()
    }

    private func run(from source: UIViewController, to destination: UIViewController) {
        switch kind {
        case .show(let action):
            if action == "showDetailViewController:sender:" {
                source.showDetailViewController(destination, sender: source)
            } else {
                source.show(destination, sender: source)
            }
        case .push:
            source.navigationController?.pushViewController(destination, animated: true)
        case .modal, .presentation:
            source.present(destination, animated: true)
        case .embed:
            guard let container = containerView else {
                UINib.noteUnhandled("embed-without-container:\(identifier ?? "?")")
                return
            }
            let childView = destination.view!
            source.addChild(destination)
            childView.frame = container.bounds
            childView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            container.addSubview(childView)
            destination.didMove(toParent: source)
        case .other(let name):
            UINib.noteUnhandled("segue-kind:\(name)")
        }
    }
}

/// UIKit's `UIModalPresentationStyle` raw values (UIViewController.h).
func _archivedModalPresentationStyle(_ raw: Int) -> UIModalPresentationStyle? {
    switch raw {
    case 0: return .fullScreen
    case 1: return .pageSheet
    case 2: return .formSheet
    case 3: return .currentContext
    case 4: return .custom
    case 5: return .overFullScreen
    case 6: return .overCurrentContext
    case 7: return .popover
    case -1: return UIModalPresentationStyle.none
    case -2: return .automatic
    default: return nil
    }
}

// MARK: - Storyboard state of a controller

/// What a storyboard controller carries that a programmatic one does not.
/// Kept beside the controller rather than in its declaration so the
/// UIViewController class layout is unchanged.
@MainActor
final class _UIStoryboardControllerState {
    weak var owner: UIViewController?
    var storyboard: UIStoryboard?
    var storyboardIdentifier: String?
    var segueTemplates: [UIStoryboardSegueTemplate] = []
    /// The view nib's `UpstreamPlaceholder-N` objects; released once the
    /// view is loaded (the table references the controller itself).
    var externalObjectsForViewLoading: [String: AnyObject] = [:]
    var keepAlive: [AnyObject] = []

    init(owner: UIViewController) { self.owner = owner }
}

@MainActor
enum _UIStoryboardStates {
    static var table: [ObjectIdentifier: _UIStoryboardControllerState] = [:]
}

extension UIViewController {
    func _storyboardState(create: Bool) -> _UIStoryboardControllerState? {
        let key = ObjectIdentifier(self)
        if let state = _UIStoryboardStates.table[key], state.owner === self { return state }
        guard create else { return nil }
        // Entries whose controller is gone (an identifier can be reused).
        if _UIStoryboardStates.table.count > 64 {
            _UIStoryboardStates.table = _UIStoryboardStates.table.filter { $0.value.owner != nil }
        }
        let state = _UIStoryboardControllerState(owner: self)
        _UIStoryboardStates.table[key] = state
        return state
    }

    /// The storyboard this controller was instantiated from (UIKit: nil for
    /// a programmatic controller, and nil inside `init(coder:)`).
    public var storyboard: UIStoryboard? { _storyboardState(create: false)?.storyboard }

    /// Load the storyboard view nib; true when it produced the view.
    func _loadStoryboardView() -> Bool {
        guard let state = _storyboardState(create: false),
              let storyboard = state.storyboard, let name = nibName,
              let nib = storyboard.viewNib(named: name) else { return false }
        let externals = state.externalObjectsForViewLoading
        state.externalObjectsForViewLoading = [:]
        _ = nib.instantiate(withOwner: self, options: [.externalObjects: externals])
        guard let loaded = viewIfLoaded else { return false }
        // MEASURED: the child's archived 361 x 200 view reports the screen's
        // 393 x 852 in viewDidLoad — UIKit sizes a storyboard view to the
        // screen when it loads it.
        loaded.frame = UIScreen.main.bounds
        return true
    }

    /// Embed segues run between loadView and viewDidLoad (MEASURED order).
    func _performSeguesOnViewLoad() {
        guard let state = _storyboardState(create: false) else { return }
        for template in state.segueTemplates where template.performOnViewLoad {
            let identifier = template.identifier ?? ""
            guard shouldPerformSegue(withIdentifier: identifier, sender: self) else { continue }
            template.performSegue(sender: self)
        }
    }
}

#if canImport(ObjectiveC)
extension UIViewController {
    /// UIKit raises when no segue has `identifier`; so does this.
    @objc open func performSegue(withIdentifier identifier: String, sender: Any?) {
        _performSegue(withIdentifier: identifier, sender: sender)
    }

    /// Asked before a control-triggered or embed segue, never for
    /// `performSegue(withIdentifier:sender:)` (MEASURED).
    @objc open func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        true
    }

    @objc open func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
}
#else
extension UIViewController {
    open func performSegue(withIdentifier identifier: String, sender: Any?) {
        _performSegue(withIdentifier: identifier, sender: sender)
    }
    open func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool { true }
    open func prepare(for segue: UIStoryboardSegue, sender: Any?) {}
}
#endif

extension UIViewController {
    func _performSegue(withIdentifier identifier: String, sender: Any?) {
        guard let template = _storyboardState(create: false)?.segueTemplates
            .first(where: { $0.identifier == identifier }) else {
            fatalError("Receiver (\(self)) has no segue with identifier '\(identifier)'")
        }
        template.performSegue(sender: sender)
    }
}

// MARK: - Decoding a controller

extension NibDecoder {
    func makeSegueTemplate(_ object: NibArchive.Object) -> AnyObject? {
        let kind: UIStoryboardSegueTemplate.Kind
        switch object.className {
        case "UIStoryboardShowSegueTemplate":
            kind = .show(action: string(object.first("UIActionName")) ?? "showViewController:sender:")
        case "UIStoryboardPushSegueTemplate": kind = .push
        case "UIStoryboardModalSegueTemplate": kind = .modal
        case "UIStoryboardPresentationSegueTemplate": kind = .presentation
        case "UIStoryboardEmbedSegueTemplate": kind = .embed
        default: kind = .other(object.className)
        }
        return UIStoryboardSegueTemplate(
            kind: kind,
            identifier: string(object.first("UIIdentifier")),
            destinationIdentifier: string(object.first("UIDestinationViewControllerIdentifier")),
            performOnViewLoad: bool(object.first("UIPerformOnViewLoad")) ?? false,
            modalPresentationStyle: int(object.first("UIModalPresentationStyle"))
                .flatMap(_archivedModalPresentationStyle))
    }

    /// A controller's archived keys, decoded inside its `init(coder:)`
    /// (`UINibName` is read earlier, by the initializer itself).
    func applyController(_ object: NibArchive.Object, to controller: UIViewController) {
        var state: _UIStoryboardControllerState {
            controller._storyboardState(create: true)!
        }
        var children: [UIViewController]? = nil
        for pair in object.values {
            switch pair.key {
            case "UINibName", "UIClassName", "UIOriginalClassName", "UIParentViewController",
                 "UIChildViewControllers", "UINavigationBar":
                continue
            case "UITitle":
                controller.title = string(pair.value)
            case "UINavigationItem":
                if let item = self.object(pair.value) as? UINavigationItem {
                    controller._navigationItem = item
                }
            case "UIStoryboardIdentifier":
                state.storyboardIdentifier = string(pair.value)
            case "UIStoryboardSegueTemplates":
                if case .reference(let i) = pair.value {
                    state.segueTemplates = arrayElements(at: i).compactMap { $0 as? UIStoryboardSegueTemplate }
                }
            case "UIExternalObjectsTableForViewLoading":
                if case .reference(let i) = pair.value {
                    for (key, value) in dictionaryPairs(at: i) {
                        if let name = key as? NibString { state.externalObjectsForViewLoading[name.value] = value }
                    }
                }
            case "UITopLevelObjectsToKeepAliveFromStoryboard":
                if case .reference(let i) = pair.value { state.keepAlive = arrayElements(at: i) }
            case "UIViewControllers":
                if case .reference(let i) = pair.value {
                    children = arrayElements(at: i).compactMap { $0 as? UIViewController }
                }
            case "UINavigationBarHidden":
                if let hidden = bool(pair.value), let nav = controller as? UINavigationController {
                    nav.isNavigationBarHidden = hidden
                }
            case "UIModalPresentationStyle":
                if let raw = int(pair.value), let style = _archivedModalPresentationStyle(raw) {
                    controller.modalPresentationStyle = style
                }
            case "UIKeyAutomaticallyAdjustsScrollViewInsets", "UIAutoresizesArchivedViewToFullSize",
                 "UIPreferredContentSize", "UIRestorationIdentifier":
                continue
            default:
                UINib.noteUnhandled("\(type(of: controller)).\(pair.key)")
            }
        }
        if let children, let nav = controller as? UINavigationController {
            nav._setArchivedViewControllers(children)
        }
    }
}
