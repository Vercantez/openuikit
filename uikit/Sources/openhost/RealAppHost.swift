// Launch a RealAppScreen row as a LIVE app window. Owner: host module.
//
// The same setup `openrender realapp` / render_full perform before they
// render one screen (Sources/openrender/RealApp.swift runRealApp: traits,
// asset and nib roots, the screen, a window at the row's geometry and safe
// area, the real root controller, its appearance), minus the render, so a
// host can run the app. Compiled into openhost (unused there so far) and
// host_full (full/driver/host_full, the Mach-O guest). For Firefox Focus the
// root is FocusBrowserLaunch.makeRoot(): the real AppDelegate through
// UIApplicationMain.
//
// No Foundation here (same rule as HostCore.swift).

import OpenUIKit
import RealAppProbe

/// Keeps the launched window and root alive for the life of the host.
var realAppHostRetained: [AnyObject] = []

/// The RealAppScreen rows a host can run, by name.
@MainActor
func realAppHostRowNames() -> [String] { RealAppScreen.screens.map(\.name) }

/// Build `row` into a live window. `assets` is the absolute
/// fixtures/realapp/assets directory (nibs are its sibling). `phoneScale`
/// is the backing scale for phone rows (pad rows use their native scale).
/// Returns nil when this build has no such row.
@MainActor
func launchRealAppHost(row name: String, assets: String, phoneScale: CGFloat,
                       sceneName: String) -> HostScene? {
    guard let row = RealAppScreen.screens.first(where: { $0.name == name }) else { return nil }
    RealAppScreen.installFocusBundleResourcesIfNeeded()
    let size = row.windowSize
    let scale = row.idiom == .pad ? row.nativeScale : phoneScale
    Timer._reset()
    GlyphInkTable.windowCompositing = false
    OpenUIKitRuntime.systemFontCut = .iOS
    UIDevice.current.userInterfaceIdiom = row.idiom
    OpenUIKitRuntime.assetCatalogIdiom = row.idiom
    UITraitCollection.current = UITraitCollection(
        userInterfaceStyle: row.style,
        displayScale: scale,
        preferredContentSizeCategory: row.contentSizeCategory,
        userInterfaceIdiom: row.idiom)
    RealAppScreen.configureAssets(directory: assets)
    var nibs = RealAppScreen.defaultNibsDirectory
    if assets.hasSuffix("/assets") {
        nibs = String(assets.dropLast(7)) + "/nibs"
    }
    RealAppScreen.configureNibs(directory: nibs)
    OpenUIKitRuntime.imageScreenScale = scale
    UIScreen.main._hostConfigure(bounds: CGRect(origin: .zero, size: size), scale: scale)

    let window = UIWindow(frame: CGRect(origin: .zero, size: size))
    window.backgroundColor = .black
    window._setSafeAreaInsets(row.safeAreaInsets)
    window.overrideUserInterfaceStyle = row.style
    let root = RealAppScreen.makeRoot(variant: row.variant, theme: row.theme)
    window.rootViewController = root
    window.makeKeyAndVisible()
    if row.presentsSheet {
        (root as? BackdropViewController)?.presentPickerNow()
    } else {
        root.beginAppearanceTransition(true, animated: false)
        root.endAppearanceTransition()
    }
    window.setNeedsLayout()
    window.layoutIfNeeded()
    realAppHostRetained.append(window)
    realAppHostRetained.append(root)
    return HostScene(name: sceneName, sizePt: size, scale: scale,
                     window: window, container: root.view, sceneAnimationDeadline: 0)
}

/// Per-capture app state for scripted replays (what host checks assert on):
/// text fields, first responder, keyboard, presented controllers, visible
/// labels, primary-action menus.
@MainActor
func realAppHostState(_ scene: HostScene, t: Double) -> JSONValue {
    var fields: [JSONValue] = []
    var labels: [JSONValue] = []
    func collect(_ v: UIView, path: String, visible: Bool) {
        let shown = visible && !v.isHidden && v.alpha > 0.01
        if let tf = v as? UITextField {
            let r = tf.convert(tf.bounds, to: nil)
            fields.append(.object([
                "path": .string(path),
                "class": .string(String(describing: type(of: tf))),
                "frameInWindow": .array([r.origin.x, r.origin.y, r.width, r.height]
                    .map { .number((Double($0) * 1000).rounded() / 1000) }),
                "text": .string(tf.text ?? ""),
                "placeholder": .string(tf.placeholder ?? ""),
                "isEditing": .bool(tf.isEditing),
                "isFirstResponder": .bool(tf.isFirstResponder),
                "visible": .bool(shown),
            ]))
        }
        if shown, let l = v as? UILabel, let t = l.text, !t.isEmpty { labels.append(.string(t)) }
        if shown, let b = v as? UIButton, let t = b.currentTitle, !t.isEmpty { labels.append(.string(t)) }
        if shown, let b = v as? UIButton, b.showsMenuAsPrimaryAction, let menu = b.menu {
            func rows(_ m: UIMenu) -> [String] {
                m.children.flatMap { child -> [String] in
                    if let sub = child as? UIMenu { return rows(sub) }
                    return [child.title]
                }
            }
            labels.append(.string("menuButton:" + rows(menu).joined(separator: "|")))
        }
        if shown, String(describing: type(of: v)) == "_UIContextMenuView" {
            labels.append(.string("contextMenuView"))
        }
        for (i, sub) in v.subviews.enumerated() {
            collect(sub, path: path.isEmpty ? "\(i)" : "\(path).\(i)", visible: shown)
        }
    }
    collect(scene.window, path: "", visible: true)
    var presented: [JSONValue] = []
    var vc = scene.window.rootViewController?.presentedViewController
    while let p = vc {
        presented.append(.string(String(describing: type(of: p))))
        if let nav = p as? UINavigationController, let top = nav.topViewController {
            presented.append(.string("top=" + String(describing: type(of: top))))
        }
        vc = p.presentedViewController
    }
    let responder = scene.window.firstResponder
    return .object([
        "t": .number(t),
        "firstResponder": responder.map { .string(String(describing: type(of: $0))) } ?? .null,
        "keyboardUp": .bool(responder is UIKeyInput),
        "keyboardOverlap": .number(Double(_UIKeyboardChrome.currentOverlap)),
        "textFields": .array(fields),
        "presented": .array(presented),
        "labels": .array(labels),
    ])
}

/// host_full's loop choices for a real app, shared: the software keyboard
/// composited above the app window, `beginTurn` running the main queue,
/// Escape as an app key, an idle redraw, 60 Hz run-loop turns between
/// scripted steps.
@MainActor
func realAppHostHooks(drainMainQueue: @escaping @MainActor () -> Void) -> HostLoopHooks {
    var hooks = HostLoopHooks()
    hooks.render = { window, scale in
        _UIKeyboardChrome.renderCapture(appWindow: window, scale: scale)
    }
    hooks.beginTurn = drainMainQueue
    hooks.escapeQuits = false
    hooks.idleRedrawInterval = 0.5
    hooks.scriptStepHz = 60
    return hooks
}
