import Foundation
import ManagedApp

func testManagedAppConfigurationProviderClass() {
    let provider = ManagedAppConfigurationProvider()
    managedAppExpectEqual(
        String(describing: type(of: provider)),
        "ManagedAppConfigurationProvider"
    )
}

func testManagedAppConfigurationProviderInit() {
    let first = ManagedAppConfigurationProvider()
    let second = ManagedAppConfigurationProvider()
    managedAppExpect(first !== second)
}

func testManagedAppConfigurationProviderConfigurations() {
    let provider = ManagedAppConfigurationProvider()
    let snapshots: [ManagedAppProbeConfiguration?] = managedAppAwaitValue {
        let sequence = await provider.configurations(ManagedAppProbeConfiguration.self)
        var collected: [ManagedAppProbeConfiguration?] = []
        for await configuration in sequence {
            collected.append(configuration)
        }
        return collected
    }
    managedAppExpectEqual(snapshots.count, 1)
    managedAppExpect(snapshots[0] == nil)
}
