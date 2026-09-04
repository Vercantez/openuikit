// HARNESS CODE — the nib class registry and the outlet tables the vendored
// app source cannot supply for itself.
//
// This is the nib-side twin of SelectorTables.swift, and it exists for the
// same reason (docs/OBJC_RUNTIME.md item 1, docs/REAL_APP_TEST.md blocker 1):
// real UIKit instantiates an archived class with `NSClassFromString` and fills
// an `@IBOutlet` with `setValue:forKey:`, and both need an Objective-C runtime
// with every app class and property registered in it. A portable build has
// none, so the classes a nib names are registered by name and the outlets are
// published one line each.
//
// Real UIKit needs none of this: scripts/realapp_probe_sim.sh does not compile
// this file, and the same vendored source there gets `@IBOutlet` back.
//
// It lives OUTSIDE Vendored/ so the vendored files stay a clean diff against
// the app's own source.

import OpenUIKit

@MainActor
enum RealAppNibClasses {
    /// Every class the three fixture nibs name (`customClass` in the xib,
    /// mangled as `_TtC8podcasts…` in the archive).
    ///
    /// Each constructor is `init(coder:)`, which is the initializer real UIKit
    /// runs for an archived object, and the choice matters: these classes give
    /// `init(coder:)` a DIFFERENT body from `init(frame:)`. ThemeableTable
    /// skips `commonInit()` under the coder and does it in `awakeFromNib()`;
    /// ThemeableCell skips `updateColor()`, which is the only reason
    /// DisclosureCell survives instantiation at all — its
    /// `handleThemeDidChange()` dereferences the `disclosureImage` outlet, and
    /// under `init(style:reuseIdentifier:)` that runs before the nib has
    /// connected anything (measured: a nil-unwrap trap in
    /// DisclosureCell.handleThemeDidChange, 2026-09-04).
    static func register() {
        guard !registered else { return }
        registered = true
        let coder = NSCoder()
        // SwitchCell.xib / DisclosureCell.xib
        UINibClassRegistry.register("SwitchCell") { SwitchCell(coder: coder)! }
        UINibClassRegistry.register("DisclosureCell") { DisclosureCell(coder: coder)! }
        UINibClassRegistry.register("ThemeableLabel") { ThemeableLabel(coder: coder)! }
        UINibClassRegistry.register("TintableImageView") { TintableImageView(coder: coder)! }
        // StorageAndDataUseViewController.xib
        UINibClassRegistry.register("ThemeableView") { ThemeableView(coder: coder)! }
        UINibClassRegistry.register("ThemeableTable") { ThemeableTable(coder: coder)! }
    }

    private static var registered = false
}

// MARK: - Outlet tables

// One line per `<outlet>` in the xib. The property assignment (not a stored
// write) is deliberate: every one of these has a `didSet` in the app's own
// source that sets the font or the theme style, and UIKit's KVC fires it too.

extension SwitchCell: UINibOutletConnecting {
    func setNibOutlet(_ object: AnyObject?, forName name: String) -> Bool {
        switch name {
        case "cellLabel": cellLabel = object as? UILabel
        case "cellImage": cellImage = object as? UIImageView
        case "cellTextToImageConstraint":
            cellTextToImageConstraint = object as? NSLayoutConstraint
        default: return false
        }
        return true
    }
}

extension DisclosureCell: UINibOutletConnecting {
    func setNibOutlet(_ object: AnyObject?, forName name: String) -> Bool {
        switch name {
        case "cellLabel": cellLabel = object as? UILabel
        case "cellImage": cellImage = object as? UIImageView
        case "disclosureImage": disclosureImage = object as? UIImageView
        case "cellSecondaryLabel": cellSecondaryLabel = object as? ThemeableLabel
        case "cellTextToImageConstraint":
            cellTextToImageConstraint = object as? NSLayoutConstraint
        case "cellTextToMarginConstraint":
            cellTextToMarginConstraint = object as? NSLayoutConstraint
        case "cellSecondaryTextWidthConstraint":
            cellSecondaryTextWidthConstraint = object as? NSLayoutConstraint
        default: return false
        }
        return true
    }
}

extension StorageAndDataUseViewController: UINibOutletConnecting {
    func setNibOutlet(_ object: AnyObject?, forName name: String) -> Bool {
        guard name == "settingsTable" else { return false }
        settingsTable = object as? UITableView
        return true
    }
}
