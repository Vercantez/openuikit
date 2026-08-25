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

public enum RealAppScreen {
    /// iPhone 15 Pro points — the picker is a bottom sheet over a full screen.
    public static let windowSize = CGSize(width: 393, height: 852)

    /// Where UIImage(named:) finds the app's icons. `openrender`/`openhost`
    /// point this at fixtures/realapp/assets before building the screen.
    public static func configureAssets(directory: String) {
        OpenUIKitRuntime.imageSearchPaths = [directory]
        UIImage.clearNamedCache()
    }

    /// pocket-casts-ios podcasts/ListeningHistoryViewController.swift:234
    /// `menuTapped(_:)` — the History screen's "..." menu, verbatim apart from
    /// the analytics calls and the `self?` captures into app state.
    public static func makeListeningHistoryPicker(theme: Theme.ThemeType) -> OptionsPicker {
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
    public static func makeSettingsPicker(theme: Theme.ThemeType) -> OptionsPicker {
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
        return makeRoot(picker: makeSettingsPicker(theme: theme), theme: theme)
    }

    /// Repo-relative default for `UIImage(named:)`.
    public static let defaultAssetsDirectory = "fixtures/realapp/assets"


    public static func makeRoot(picker: OptionsPicker,
                                theme: Theme.ThemeType) -> UIViewController {
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
