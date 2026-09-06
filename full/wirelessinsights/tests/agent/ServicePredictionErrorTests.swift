import Foundation
import WirelessInsights

func testServicePredictionErrorType() {
    let error: ServicePredictionError = .unsupportedDevice
    wiExpect(type(of: error) == ServicePredictionError.self, "error metatype")
    let asError: any Error = error
    wiExpect(asError is ServicePredictionError, "Error existential")
}

func testServicePredictionErrorUnsupportedDevice() {
    let error = ServicePredictionError.unsupportedDevice
    wiExpect(error == .unsupportedDevice, "unsupportedDevice case")
    wiExpect(error != .connectionError, "not connectionError")
}

func testServicePredictionErrorConnectionError() {
    let error = ServicePredictionError.connectionError
    wiExpect(error == .connectionError, "connectionError case")
    wiExpect(error != .unsupportedDevice, "not unsupportedDevice")
}

func testServicePredictionErrorEquality() {
    wiExpect(
        ServicePredictionError.unsupportedDevice == .unsupportedDevice,
        "same case"
    )
    wiExpect(
        ServicePredictionError.connectionError == .connectionError,
        "connectionError == connectionError"
    )
}

func testServicePredictionErrorInequality() {
    wiExpect(
        ServicePredictionError.unsupportedDevice != .connectionError,
        "distinct cases"
    )
}

func testServicePredictionErrorHashValue() {
    wiExpect(
        ServicePredictionError.unsupportedDevice.hashValue
            == ServicePredictionError.unsupportedDevice.hashValue,
        "same case same hashValue"
    )
}

func testServicePredictionErrorHashInto() {
    var hasher = Hasher()
    ServicePredictionError.connectionError.hash(into: &hasher)
    _ = hasher.finalize()
}

func testServicePredictionErrorLocalizedDescription() {
    let unsupported = ServicePredictionError.unsupportedDevice.localizedDescription
    let connection = ServicePredictionError.connectionError.localizedDescription
    wiExpect(!unsupported.isEmpty, "unsupportedDevice description")
    wiExpect(!connection.isEmpty, "connectionError description")
    wiExpect(unsupported != connection, "distinct descriptions")
    wiExpect(
        unsupported.contains("support") || unsupported.contains("device"),
        "unsupportedDevice mentions device support"
    )
}
