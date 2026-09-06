import Foundation
import ManagedApp

func testManagedAppErrorCodeStruct() {
    let code = ManagedAppConfigurationDecodingErrorCode(rawValue: 0)
    managedAppExpect(code != nil)
    managedAppExpectEqual(
        String(describing: type(of: code!)),
        "ManagedAppConfigurationDecodingErrorCode"
    )
}

func testManagedAppErrorCodeReservedValues() {
    let rows: [(String, Int, Int)] = [
        ("firstReserved", ManagedAppConfigurationDecodingErrorCode.firstReserved, 1000),
        ("generic", ManagedAppConfigurationDecodingErrorCode.generic, 1000),
        ("dataCorrupted", ManagedAppConfigurationDecodingErrorCode.dataCorrupted, 1001),
        ("keyNotFound", ManagedAppConfigurationDecodingErrorCode.keyNotFound, 1002),
        ("typeMismatch", ManagedAppConfigurationDecodingErrorCode.typeMismatch, 1003),
        ("valueNotFound", ManagedAppConfigurationDecodingErrorCode.valueNotFound, 1004),
        ("timeout", ManagedAppConfigurationDecodingErrorCode.timeout, 1005),
    ]
    for (name, actual, expected) in rows {
        managedAppExpectEqual(actual, expected, name)
        managedAppExpect(
            actual >= ManagedAppConfigurationDecodingErrorCode.firstReserved,
            "\(name) must be reserved"
        )
    }
    managedAppExpectEqual(
        Set(rows.map(\.1)).count,
        6,
        "six distinct reserved integers (generic shares firstReserved)"
    )
}

func testManagedAppErrorCodeRawValueTypealias() {
    let _: ManagedAppConfigurationDecodingErrorCode.RawValue = 0
    managedAppExpectEqual(
        MemoryLayout<ManagedAppConfigurationDecodingErrorCode.RawValue>.size,
        MemoryLayout<Int>.size
    )
}

func testManagedAppErrorCodeInitRawValue() {
    managedAppExpect(ManagedAppConfigurationDecodingErrorCode(rawValue: 0) != nil)
    managedAppExpect(ManagedAppConfigurationDecodingErrorCode(rawValue: -1) != nil)
    managedAppExpect(
        ManagedAppConfigurationDecodingErrorCode(
            rawValue: ManagedAppConfigurationDecodingErrorCode.firstReserved
        ) != nil
    )
    managedAppExpect(ManagedAppConfigurationDecodingErrorCode(rawValue: Int.max) != nil)
    let appSpecific = ManagedAppConfigurationDecodingErrorCode(rawValue: 42)!
    managedAppExpectEqual(appSpecific.rawValue, 42)
    managedAppExpect(appSpecific.rawValue < ManagedAppConfigurationDecodingErrorCode.firstReserved)
}

func testManagedAppErrorCodeRawValueProperty() {
    let code = ManagedAppConfigurationDecodingErrorCode(
        rawValue: ManagedAppConfigurationDecodingErrorCode.keyNotFound
    )!
    managedAppExpectEqual(code.rawValue, ManagedAppConfigurationDecodingErrorCode.keyNotFound)
    managedAppExpectEqual(
        ManagedAppConfigurationDecodingErrorCode(rawValue: 7)!.rawValue,
        7
    )
}

func testManagedAppErrorCodeEncode() {
    let code = ManagedAppConfigurationDecodingErrorCode(
        rawValue: ManagedAppConfigurationDecodingErrorCode.typeMismatch
    )!
    let data = try! JSONEncoder().encode(code)
    let number = try! JSONDecoder().decode(Int.self, from: data)
    managedAppExpectEqual(number, ManagedAppConfigurationDecodingErrorCode.typeMismatch)
}

func testManagedAppErrorCodeDecode() {
    let data = try! JSONEncoder().encode(ManagedAppConfigurationDecodingErrorCode.timeout)
    let decoded = try! JSONDecoder().decode(
        ManagedAppConfigurationDecodingErrorCode.self,
        from: data
    )
    managedAppExpectEqual(decoded.rawValue, ManagedAppConfigurationDecodingErrorCode.timeout)
    let zero = try! JSONDecoder().decode(
        ManagedAppConfigurationDecodingErrorCode.self,
        from: try! JSONEncoder().encode(0)
    )
    managedAppExpectEqual(zero.rawValue, 0)
}

func testManagedAppErrorCodeHashValue() {
    let a = ManagedAppConfigurationDecodingErrorCode(rawValue: 3)!
    let b = ManagedAppConfigurationDecodingErrorCode(rawValue: 3)!
    managedAppExpectEqual(a.hashValue, b.hashValue)
    managedAppExpectEqual(a, b)
}

func testManagedAppErrorCodeHashInto() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    let code = ManagedAppConfigurationDecodingErrorCode(
        rawValue: ManagedAppConfigurationDecodingErrorCode.dataCorrupted
    )!
    code.hash(into: &hasherA)
    code.hash(into: &hasherB)
    managedAppExpectEqual(hasherA.finalize(), hasherB.finalize())
    let set: Set<ManagedAppConfigurationDecodingErrorCode> = [
        ManagedAppConfigurationDecodingErrorCode(rawValue: 1)!,
        ManagedAppConfigurationDecodingErrorCode(rawValue: 2)!,
        ManagedAppConfigurationDecodingErrorCode(rawValue: 1)!,
    ]
    managedAppExpectEqual(set.count, 2)
}

func testManagedAppErrorCodeInequality() {
    let a = ManagedAppConfigurationDecodingErrorCode(rawValue: 1)!
    let b = ManagedAppConfigurationDecodingErrorCode(rawValue: 2)!
    managedAppExpect(a != b)
    managedAppExpectFalse(a != a)
}

private func managedAppExpectFalse(_ condition: Bool, _ message: String = "") {
    managedAppExpect(!condition, message)
}
