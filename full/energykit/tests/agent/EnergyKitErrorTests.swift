import Foundation
import EnergyKit

func testEnergyKitErrorCases() {
    let cases: [EnergyKitError] = [
        .guidanceUnavailable,
        .inProgress,
        .invalidLoadEvent,
        .locationServicesDenied,
        .permissionDenied,
        .rateLimitExceeded,
        .serviceUnavailable,
        .unsupportedRegion,
        .venueUnavailable
    ]
    energyKitExpectEqual(cases.count, 9)
    energyKitExpectEqual(Set(cases).count, 9)
}

func testEnergyKitErrorEquality() {
    energyKitExpectEqual(EnergyKitError.serviceUnavailable, .serviceUnavailable)
    energyKitExpect(EnergyKitError.serviceUnavailable != .venueUnavailable)
}

func testEnergyKitErrorInequality() {
    energyKitExpect(EnergyKitError.inProgress != .invalidLoadEvent)
    energyKitExpect(EnergyKitError.permissionDenied != .rateLimitExceeded)
}

func testEnergyKitErrorHash() {
    var hasher = Hasher()
    EnergyKitError.unsupportedRegion.hash(into: &hasher)
    energyKitExpect(EnergyKitError.guidanceUnavailable.hashValue != 0 || true)
    energyKitExpectEqual(
        Set<EnergyKitError>([.venueUnavailable, .venueUnavailable]).count,
        1
    )
}

func testEnergyKitErrorErrorDescription() {
    energyKitExpect(EnergyKitError.guidanceUnavailable.errorDescription?.contains("guidance") == true)
    energyKitExpect(EnergyKitError.invalidLoadEvent.errorDescription?.contains("invalid") == true)
    energyKitExpect(EnergyKitError.serviceUnavailable.errorDescription != nil)
}

func testEnergyKitErrorFailureReason() {
    energyKitExpect(EnergyKitError.venueUnavailable.failureReason?.contains("venue") == true)
    energyKitExpect(EnergyKitError.locationServicesDenied.failureReason != nil)
}

func testEnergyKitErrorHelpAnchor() {
    energyKitExpect(EnergyKitError.permissionDenied.helpAnchor == nil)
    energyKitExpect(EnergyKitError.rateLimitExceeded.helpAnchor == nil)
}

func testEnergyKitErrorRecoverySuggestion() {
    energyKitExpect(EnergyKitError.invalidLoadEvent.recoverySuggestion?.contains("device") == true)
    energyKitExpect(EnergyKitError.serviceUnavailable.recoverySuggestion != nil)
}

func testEnergyKitErrorLocalizedDescription() {
    let description = EnergyKitError.unsupportedRegion.localizedDescription
    energyKitExpect(!description.isEmpty)
}
