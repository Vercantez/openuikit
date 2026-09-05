import TabularData
import Foundation

// Future clean EC2 dependency-identity client. Isolated host-gate success
// against toolchain Foundation is not integrated guest-Foundation success.
//
// Expected EC2 steps (no local Docker):
// 1. Build the actual guest Foundation module and `libFoundation.dylib`.
// 2. Build TabularData with that Foundation on `-I` / `-L` (and rpath as needed).
// 3. Link this file as a client that `import`s TabularData and Foundation.
// 4. Run with `LD_LIBRARY_PATH` covering both dylibs.
// 5. Confirm Foundation `Data` / `URL` values flow through public TabularData APIs
//    without a framework-local Data stand-in.

private func assertNotTabularDataType<T>(_ value: T) {
    precondition(!String(reflecting: type(of: value)).hasPrefix("TabularData."))
}

func tabularDataDependencyIdentityMain() {
    let payload = Data("name,age\na,1\n".utf8)
    assertNotTabularDataType(payload)
    precondition(type(of: payload) == Data.self)
    precondition(!String(reflecting: Data.self).hasPrefix("TabularData."))

    let frame = try! DataFrame(csvData: payload)
    let encoded = try! frame.csvRepresentation()
    precondition(!encoded.isEmpty)
    assertNotTabularDataType(encoded)
    precondition(type(of: encoded) == Data.self)

    let url = FileManager.default.temporaryDirectory.appendingPathComponent("td-identity.csv")
    assertNotTabularDataType(url)
    try! encoded.write(to: url)
    let roundTrip = try! DataFrame(contentsOfCSVFile: url)
    precondition(roundTrip.shape.rows == 1)
}

tabularDataDependencyIdentityMain()
