import Foundation
import EnergyKit

func testInsightServiceType() {
    energyKitExpectEqual(
        String(describing: type(of: ElectricityInsightService.shared)),
        "ElectricityInsightService"
    )
}

func testInsightServiceShared() {
    energyKitExpect(ElectricityInsightService.shared === ElectricityInsightService.shared)
}

func testInsightServiceEnergyInsightsFailClosed() {
    let query = energyKitSampleQuery()
    energyKitExpectError(
        energyKitAwait {
            try await ElectricityInsightService.shared.energyInsights(
                forDeviceID: "hvac-1",
                using: query,
                atVenue: UUID()
            )
        },
        .serviceUnavailable
    )
}

func testInsightServiceRuntimeInsightsFailClosed() {
    let query = energyKitSampleQuery()
    energyKitExpectError(
        energyKitAwait {
            try await ElectricityInsightService.shared.runtimeInsights(
                forDeviceID: "hvac-1",
                using: query,
                atVenue: UUID()
            )
        },
        .serviceUnavailable
    )
}

func testInsightServiceUnownedExecutor() {
    _ = ElectricityInsightService.shared.unownedExecutor
}

func testInsightServiceAssertIsolated() async {
    let observed = await { (service: isolated ElectricityInsightService) -> Bool in
        service.assertIsolated("isolated to insight service")
        return service === ElectricityInsightService.shared
    }(ElectricityInsightService.shared)
    energyKitExpect(observed)
}

func testInsightServicePreconditionIsolated() async {
    let observed = await { (service: isolated ElectricityInsightService) -> Bool in
        service.preconditionIsolated("isolated to insight service")
        return service === ElectricityInsightService.shared
    }(ElectricityInsightService.shared)
    energyKitExpect(observed)
}

func testInsightServiceAssumeIsolated() async {
    let observed = await { (service: isolated ElectricityInsightService) -> Bool in
        service.assumeIsolated { isolated in isolated === service }
    }(ElectricityInsightService.shared)
    energyKitExpect(observed)
}
