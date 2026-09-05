// The harness entry point: builds the pocket-casts options-picker screen out
// of the VENDORED app source in Vendored/ and hands back a root view
// controller, the same way DemoApp does.
//
// The two configurations below are transcriptions of REAL call sites in
// pocket-casts-ios (file + line noted on each), so what renders is a screen
// the app actually ships, not a demo assembled to flatter the renderer.
//
// This file is harness code, not app source, and is counted as such in
// docs/REAL_APP_TEST.md.

import OpenUIKit

// Harness, not app source: the whole builder runs on the main actor because
// everything it builds (view controllers, the picker) is main-actor isolated,
// exactly as it would be in the app's own code.
@MainActor
public enum RealAppScreen {
    /// iPhone 16 points — the picker is a bottom sheet over a full screen.
    public static let windowSizePhone = CGSize(width: 393, height: 852)
    /// iPad (A16) portrait. MEASURED `UIScreen.main.bounds` on the
    /// `iPad-A16` simulator (2x): 820 × 1180.
    public static let windowSizePad = CGSize(width: 820, height: 1180)
    /// Default (phone) window; openhost `--app pocketcasts` uses this.
    public static let windowSize = windowSizePhone
    /// MEASURED realappprobe, iPhone 16 / iOS 26.1: window safe area
    /// `[59, 0, 34, 0]`.
    public static let phoneSafeArea = UIEdgeInsets(top: 59, left: 0, bottom: 34, right: 0)
    /// Filled from realapp_settings_light_ipad / ipadprobe on the
    /// iPad (A16) 820×1180 @2x / iOS 26.1: window `safeAreaInsets`
    /// `[32, 0, 25, 0]`.
    public static let padSafeArea = UIEdgeInsets(top: 32, left: 0, bottom: 25, right: 0)

    /// Where UIImage(named:) finds the app's icons. `openrender`/`openhost`
    /// point this at fixtures/realapp/assets before building the screen.
    public static func configureAssets(directory: String) {
        OpenUIKitRuntime.imageSearchPaths = [directory]
        UIImage.clearNamedCache()
    }

    /// Where `UINib(nibName:bundle:)` finds the app's compiled xibs. In the
    /// app these are resources inside the bundle; the harness points the
    /// runtime at fixtures/realapp/nibs, the `ibtool --compile` output
    /// scripts/compile_realapp_nibs.sh produces.
    public static func configureNibs(directory: String) {
        OpenUIKitRuntime.nibSearchPaths = [directory]
    }

    /// Repo-relative default, the twin of `defaultAssetsDirectory`.
    public static let defaultNibsDirectory = "fixtures/realapp/nibs"

    /// Publishes the nib class registry and the outlet tables
    /// (NibClasses.swift). Real UIKit gets both from the Objective-C runtime,
    /// so scripts/realapp_probe_sim.sh empties this body for the Darwin build,
    /// the same way it drops SelectorTables.swift.
    static func registerNibClasses() {
        RealAppNibClasses.register()
    }

    /// pocket-casts-ios podcasts/ListeningHistoryViewController.swift:234
    /// `menuTapped(_:)` — the History screen's "..." menu, verbatim apart from
    /// the analytics calls and the `self?` captures into app state.
    /// Which of the app's real call sites to build. This exists so that
    /// `OptionsPicker` — vendored app source — never appears in a `public`
    /// signature, and can therefore stay `internal`, exactly as upstream
    /// declares it. See docs/REAL_APP_TEST.md: keeping the module boundary on
    /// the harness side of the line is what retired the last non-UIKit entry
    /// in the adaptation ledger.
    public enum Variant {
        case listeningHistory
        case settings
        /// pocket-casts-ios podcasts/StorageAndDataUseViewController.swift —
        /// a whole settings SCREEN rather than a sheet, and the first variant
        /// whose views come out of a compiled xib.
        case storage
        /// mozilla-mobile/focus-ios Blockzilla/Settings/Controller/
        /// SettingsViewController.swift at a2832521 — Firefox Focus Settings,
        /// wrapped in a UINavigationController as BrowserViewController
        /// `showSettings` does.
        case focusSettings
    }

    /// One headless configuration: which app screen, which theme, and which
    /// Dynamic Type category. `openrender realapp` and
    /// `scripts/realapp_probe_sim.sh` both iterate this table so the port
    /// and the iOS 26.1 oracle capture the same four Settings sizes.
    ///
    /// The `_xs` / `_xxxl` / `_ax1` rows are `realapp_settings_light` at
    /// `.extraSmall` / `.extraExtraExtraLarge` / `.accessibilityLarge`;
    /// `.large` is the device default and keeps the original name.
    public struct Screen {
        public let name: String
        public let variant: Variant
        public let theme: Theme.ThemeType
        public let style: UIUserInterfaceStyle
        public let contentSizeCategory: UIContentSizeCategory
        public let presentsSheet: Bool
        /// `.pad` rows render and capture on the iPad (A16) surface.
        public let idiom: UIUserInterfaceIdiom
        public let windowSize: CGSize
        /// Device backing-store scale. iPhone 16 goldens are 3x; iPad (A16)
        /// goldens are 2x. `openrender realapp` uses this for pad rows even
        /// when `OPENUIKIT_REALAPP_SCALE=3` (the phone-oracle scale).
        public let nativeScale: CGFloat
        public let safeAreaInsets: UIEdgeInsets

        public init(name: String, variant: Variant, theme: Theme.ThemeType,
                    style: UIUserInterfaceStyle,
                    contentSizeCategory: UIContentSizeCategory,
                    presentsSheet: Bool,
                    idiom: UIUserInterfaceIdiom = .phone,
                    windowSize: CGSize? = nil,
                    nativeScale: CGFloat? = nil,
                    safeAreaInsets: UIEdgeInsets? = nil) {
            self.name = name
            self.variant = variant
            self.theme = theme
            self.style = style
            self.contentSizeCategory = contentSizeCategory
            self.presentsSheet = presentsSheet
            self.idiom = idiom
            self.windowSize = windowSize ?? (idiom == .pad
                ? RealAppScreen.windowSizePad : RealAppScreen.windowSizePhone)
            self.nativeScale = nativeScale ?? (idiom == .pad ? 2 : 3)
            self.safeAreaInsets = safeAreaInsets ?? (idiom == .pad
                ? RealAppScreen.padSafeArea : RealAppScreen.phoneSafeArea)
        }
    }

    public static let screens: [Screen] = [
        Screen(name: "realapp_history_light", variant: .listeningHistory,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: true),
        Screen(name: "realapp_settings_light", variant: .settings,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: true),
        Screen(name: "realapp_settings_dark", variant: .settings,
               theme: .dark, style: .dark, contentSizeCategory: .large,
               presentsSheet: true),
        Screen(name: "realapp_storage_light", variant: .storage,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: false),
        Screen(name: "realapp_settings_light_xs", variant: .settings,
               theme: .light, style: .light, contentSizeCategory: .extraSmall,
               presentsSheet: true),
        Screen(name: "realapp_settings_light_xxxl", variant: .settings,
               theme: .light, style: .light,
               contentSizeCategory: .extraExtraExtraLarge, presentsSheet: true),
        Screen(name: "realapp_settings_light_ax1", variant: .settings,
               theme: .light, style: .light,
               contentSizeCategory: .accessibilityLarge, presentsSheet: true),
        // iPad (A16) portrait of the same Settings picker. Captured by
        // scripts/realapp_probe_sim.sh on a private iPad-A16 simulator
        // (SIM_DEVICE_SUFFIX); rendered by `openrender realapp` with
        // `.pad` on UITraitCollection.current / UIDevice.
        Screen(name: "realapp_settings_light_ipad", variant: .settings,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: true, idiom: .pad),
        // Same History picker (Listening History "...") on the iPad (A16).
        Screen(name: "realapp_history_light_ipad", variant: .listeningHistory,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: true, idiom: .pad),
        // Same xib-driven Storage & Data Use screen on the iPad (A16).
        // The app pushes this onto a large-title settings stack; the phone
        // golden stays a bare root so it does not move.
        Screen(name: "realapp_storage_light_ipad", variant: .storage,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: false, idiom: .pad),
    ] + focusScreens

    /// Firefox Focus's screen joins the table only where its stub modules
    /// (Onboarding, Glean, Licenses, DesignSystem, Intents) exist — the
    /// SwiftPM routes on macOS and Linux corelibs. The Linux-hosted guest
    /// builder (full/scripts/build_full.sh) compiles this harness from the
    /// top-level files against the port's own Foundation and has no
    /// SwiftUI, Combine or stub modules yet, so there the table stops at the
    /// Pocket Casts screens and Focus/ is not compiled. Both authorities
    /// went red on f6912fa1 ("no such module 'Onboarding'") when the screen
    /// sat in this file. See Focus/FocusScreens.swift.
    static var focusScreens: [Screen] {
        #if canImport(Onboarding)
        return focusScreenTable
        #else
        return []
        #endif
    }

    static func makeListeningHistoryPicker(theme: Theme.ThemeType) -> OptionsPicker {
        Theme.sharedTheme.activeTheme = theme
        let optionsPicker = OptionsPicker(title: nil, themeOverride: theme)

        let MultiSelectAction = OptionAction(label: "Select Episodes",
                                             icon: "option-multiselect") {}
        optionsPicker.addAction(action: MultiSelectAction)

        let clearAction = OptionAction(label: "Clear Listening History",
                                       icon: "option-cleanup") {}
        optionsPicker.addAction(action: clearAction)

        return optionsPicker
    }

    /// A titled picker that exercises the branches the History menu does not:
    /// a section title (GeneralSettingsViewController.swift:352), a selected
    /// row with the tick (same file, `selected:`), a row with a secondary
    /// label, an on/off row, and a destructive row
    /// (NowPlayingPlayerItemViewController+Shelf.swift:313).
    static func makeSettingsPicker(theme: Theme.ThemeType) -> OptionsPicker {
        Theme.sharedTheme.activeTheme = theme
        let options = OptionsPicker(title: "ROW ACTION", themeOverride: theme)

        options.addAction(action: OptionAction(label: "Play", selected: true) {})
        options.addAction(action: OptionAction(label: "Download",
                                               secondaryLabel: "Wi-Fi only") {})
        options.addAction(action: OptionAction(label: "Up Next Swipe",
                                               icon: "option-multiselect",
                                               selected: true,
                                               onOffAction: true) {})
        let remove = OptionAction(label: "Remove Download", icon: nil) {}
        remove.destructive = true
        options.addAction(action: remove)

        return options
    }

    /// The picker mounted the way `openrender`/`openhost` need it: a root
    /// controller whose view is the full screen, with the picker presented as
    /// a sheet on top.
    public static func makeRootViewController() -> UIViewController {
        // `openhost --app pocketcasts` has no place to pass an assets path.
        configureAssets(directory: defaultAssetsDirectory)
        let theme: Theme.ThemeType =
            UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
        return makeRoot(variant: .settings, theme: theme)
    }

    /// Repo-relative default for `UIImage(named:)`.
    public static let defaultAssetsDirectory = "fixtures/realapp/assets"


    /// The storage screen the way the app pushes it: a bare
    /// `StorageAndDataUseViewController()`, whose view, table and both cell
    /// prototypes all come from nibs. Nothing here configures the screen —
    /// that is the point of the variant.
    ///
    /// On the pad idiom the real app's settings stack is a large-title
    /// `UINavigationController`. Phone goldens stay a bare root.
    static func makeStorageScreen(theme: Theme.ThemeType) -> UIViewController {
        Theme.sharedTheme.activeTheme = theme
        let vc = StorageAndDataUseViewController()
        guard UIDevice.current.userInterfaceIdiom == .pad else { return vc }
        let nav = UINavigationController(rootViewController: vc)
        nav.navigationBar.prefersLargeTitles = true
        vc.navigationItem.largeTitleDisplayMode = .always
        return nav
    }

    public static func makeRoot(variant: Variant,
                                theme: Theme.ThemeType) -> UIViewController {
        registerNibClasses()
        let picker: OptionsPicker
        switch variant {
        case .listeningHistory: picker = makeListeningHistoryPicker(theme: theme)
        case .settings:         picker = makeSettingsPicker(theme: theme)
        case .storage:          return makeStorageScreen(theme: theme)
        case .focusSettings:
            #if canImport(Onboarding)
            return makeFocusSettingsScreen()
            #else
            fatalError("realapp_focus_settings_light is not in this build (no Focus stub modules)")
            #endif
        }
        let host = BackdropViewController(theme: theme)
        host.pendingPicker = picker
        return host
    }
}

/// The screen the sheet is presented over. pocket-casts presents the picker
/// from whatever controller is on screen; the harness uses a plain backdrop so
/// the render is of the picker and nothing else.
public final class BackdropViewController: UIViewController {
    let theme: Theme.ThemeType
    var pendingPicker: OptionsPicker?
    private var presented = false

    init(theme: Theme.ThemeType) {
        self.theme = theme
        super.init()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme == .dark ? UIColor(white: 0.08, alpha: 1)
                                              : UIColor(white: 0.93, alpha: 1)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !presented, let picker = pendingPicker else { return }
        presented = true
        picker.present(from: self)
    }

    /// openrender has no run loop, so it drives the presentation itself.
    public func presentPickerNow() {
        guard !presented, let picker = pendingPicker else { return }
        presented = true
        picker.present(from: self)
    }
}
