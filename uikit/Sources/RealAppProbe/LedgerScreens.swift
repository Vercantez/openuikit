// Harness, not app source: the Ledger row of RealAppScreen's table and
// its builder. Compiled into RealAppProbe on every route (SwiftPM and
// the guest builder's RealAppProbe/*.swift glob). Duplicate of the
// ConformanceApps/Ledger first screen so GUEST_REALAPP_SCREENS becomes 13
// without editing full/scripts/build_full.sh (outside uikit/).

import OpenUIKit
import Foundation

extension RealAppScreen {
    static let ledgerScreenTable: [Screen] = [
        // Ledger first screen (Sources/ConformanceApps/Ledger). Captured on
        // the iPhone 16 @3x once the operator runs realapp_probe_sim.sh.
        Screen(name: "realapp_ledger_light", variant: .ledger,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: false),
    ]

    static func makeLedgerScreen() -> UIViewController {
        UserDefaults.standard.removeObject(forKey: LedgerStore.persistKey)
        let list = LedgerListViewController(style: .insetGrouped)
        return UINavigationController(rootViewController: list)
    }
}
