import UIKit

// M15: RESTORED to the app's original text. The `public` that used to be here
// was harness plumbing, not a UIKit gap — `openrender` needed to name this
// type across the module boundary. The boundary moved instead: the harness now
// exposes `RealAppScreen.makeRoot(variant:theme:)`, so `OptionsPicker` never
// appears in a `public` signature and stays `internal`, as upstream declares
// it. `@MainActor` is likewise upstream's own text (pocket-casts compiles this
// class under main-actor isolation because it creates and drives a
// UIViewController); OpenUIKit simply had no isolation to annotate against
// until this milestone. Instead of writing `@MainActor` into the app's source,
// the RealAppProbe target is now built with `-default-isolation MainActor`
// (Package.swift) — the same module-wide default an Xcode 26 app target
// carries — so upstream's bare `class OptionsPicker` compiles as written.
//
// Every line of CODE below is now the app's own; this comment block is the
// only thing the harness adds to the file.
class OptionsPicker {
    private var title: String?
    private var optionsController: OptionsPickerRootController?

    private var noActionCallback: (() -> Void)?

    init(title: String? = nil, themeOverride: Theme.ThemeType? = nil, iconTintStyle: ThemeStyle = .primaryIcon01, colors: OptionsPickerRootController.Colors? = nil) {
        self.title = title
        setup(themeOverride: themeOverride, iconTintStyle: iconTintStyle, colors: colors)
    }

    private func setup(themeOverride: Theme.ThemeType?, iconTintStyle: ThemeStyle = .primaryIcon01, colors: OptionsPickerRootController.Colors? = nil) {
        optionsController = OptionsPickerRootController()
        optionsController?.delegate = self
        optionsController?.setup(title: title, themeOverride: themeOverride, iconTintStyle: iconTintStyle, colors: colors)
    }

    func addAction(action: OptionAction) {
        optionsController?.addAction(action: action)
    }

    func addActions(_ actions: [OptionAction]) {
        for action in actions {
            addAction(action: action)
        }
    }

    func addSegmentedAction(name: String, icon: String?, actions: [OptionAction]) {
        optionsController?.addSegmentedAction(name: name, icon: icon, actions: actions)
    }

    func addDescriptiveActions(title: String, message: String?, icon: String, actions: [OptionAction]) {
        optionsController?.addDescriptiveActions(title: title, message: message, icon: icon, actions: actions)
    }

    func addAttributedDescriptiveActions(title: String, message: String, icon: String, actions: [OptionAction]) {
        optionsController?.addAttributedDescriptiveActions(title: title, message: message, icon: icon, actions: actions)
    }

    func setNoActionCallback(_ callback: @escaping () -> Void) {
        noActionCallback = callback
    }

    /// Presents the options using a native, self-sizing sheet from the given
    /// view controller. The sheet's height is adjusted to fit the available
    /// options, capped at the screen height.
    func present(from presentingViewController: UIViewController) {
        guard let optionsController else { return }
        optionsController.modalPresentationStyle = .formSheet
        if let sheet = optionsController.sheetPresentationController {
            optionsController.configureForSheetPresentation()
            sheet.delegate = optionsController
            sheet.detents = [.custom { [weak optionsController] context in
                optionsController?.preferredSheetHeight(limitedTo: context.maximumDetentValue, traitCollection: context.containerTraitCollection) ?? context.maximumDetentValue
            }]
        }
        presentingViewController.present(optionsController, animated: true)
    }

    /// Presents the options as a native sheet from the app's top-most view
    /// controller. Use this when there's no obvious presenting controller at
    /// the call site.
    func present() {
        #if !APPCLIP
        guard let presenter = SceneHelper.rootViewController() else {
            // This should never happen
            assertionFailure("Unable to find a view controller to present the options picker from")
            return
        }
        present(from: presenter)
        #endif
    }

    func controllerDidAnimateOut(optionChosen: Bool) {
        if let noActionCallback, !optionChosen {
            noActionCallback()
        }

        optionsController?.delegate = nil
    }
}
