// Non-action dependencies for the isolated Focus source compilation probe.
// The cells, PaddedSwitch, ToggleItem and SystemThemeDelegate are copied from
// the pinned Blockzilla sources by route_a_focus_probe.py. Settings,
// colors and the localized label are deliberately fixture values; neither
// selector registration nor action delivery is implemented here.
import UIKit

extension UIColor {
    static var accent: UIColor { .systemBlue }
    static var primaryText: UIColor { .label }
}

enum UIConstants {
    enum strings {
        static let useSystemTheme = "Use system theme"
    }
}

enum SettingsToggle: String {
    case blockAds
}

enum Settings {
    static func getToggle(_ key: SettingsToggle) -> Bool { false }
    static func set(_ value: Bool, forToggle key: SettingsToggle) {}
}
