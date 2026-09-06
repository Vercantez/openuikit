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
