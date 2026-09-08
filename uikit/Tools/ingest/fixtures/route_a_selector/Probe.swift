import UIKit
import Combine

@MainActor
private final class ThemeObserver: SystemThemeDelegate {
    var values: [Bool] = []
    func didEnableSystemTheme(_ isEnabled: Bool) { values.append(isEnabled) }
}

@main
struct RouteASelectorProbe {
    @MainActor
    static func main() {
        var unresolved: [String] = []
        SelectorDispatch.onUnresolved = { _, name in unresolved.append(name) }

        let theme = ThemeTableViewToggleCell(style: .default, reuseIdentifier: nil)
        let observer = ThemeObserver()
        theme.delegate = observer
        for value in [true, false, true] {
            theme.toggle.isOn = value
            theme.toggle.sendActions(for: .valueChanged)
        }
        precondition(observer.values == [true, false, true])
        print("ThemeTableViewToggleCell: valueChanged -> private toggleSwitched(_:) -> delegate = \(observer.values)")

        let cell = SwitchTableViewCell(item: ToggleItem(label: "Ads", settingsKey: .blockAds), reuseIdentifier: nil)
        guard let toggle = cell.accessoryView?.subviews.compactMap({ $0 as? UISwitch }).first else {
            fatalError("the upstream cell did not install its UISwitch")
        }
        var published: [Bool] = []
        let token = cell.valueChanged.sink { published.append($0) }
        withExtendedLifetime(token) {
            for value in [true, false, true] {
                toggle.isOn = value
                toggle.sendActions(for: .valueChanged)
            }
        }
        precondition(published == [true, false, true])
        precondition(unresolved.isEmpty)
        print("SwitchTableViewCell: valueChanged -> private toggle(sender:) -> Combine = \(published)")
        print("ROUTE_A_SELECTOR_PASS cells=2 deliveries=6 unresolved=0")
    }
}
