import CarKey
import Foundation

func testVehicleReportIdentifierAndConnection() {
    let disconnected = VehicleReport(identifier: "veh-a")
    precondition(disconnected.identifier == "veh-a")
    precondition(disconnected.isConnected == false)
    precondition(disconnected.supportedFunctions.isEmpty)

    let connected = VehicleReport(identifier: "veh-b", isConnected: true)
    precondition(connected.identifier == "veh-b")
    precondition(connected.isConnected == true)
}

func testVehicleReportSupportedFunctionsAndStatus() {
    let lock = FunctionIdentifier(10)
    let climate = FunctionIdentifier(11)
    let unknown = FunctionIdentifier(99)
    let report = VehicleReport(
        identifier: "veh-c",
        isConnected: true,
        supportedFunctions: [lock, climate],
        statusByFunction: [lock: FunctionStatus(3)],
        proprietaryDataByFunction: [climate: Data([0xCA, 0xFE])]
    )
    precondition(report.supportedFunctions == [lock, climate])
    do {
        let status = try report.status(for: lock)
        precondition(status == FunctionStatus(3))
        let missingStatus = try report.status(for: climate)
        precondition(missingStatus == nil)
        let proprietary = try report.proprietaryData(for: climate)
        precondition(proprietary == Data([0xCA, 0xFE]))
        let missingProprietary = try report.proprietaryData(for: lock)
        precondition(missingProprietary == nil)
    } catch {
        preconditionFailure("supported function lookup threw \(error)")
    }
    expectCarKeyError(.FunctionUnknown) {
        _ = try report.status(for: unknown)
    }
    expectCarKeyError(.FunctionUnknown) {
        _ = try report.proprietaryData(for: unknown)
    }
}
