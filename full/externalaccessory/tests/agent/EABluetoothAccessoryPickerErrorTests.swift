import ExternalAccessory
import Foundation

func testEABluetoothAccessoryPickerErrorCodes() {
    let cases: [(EABluetoothAccessoryPickerError.Code, Int)] = [
        (.alreadyConnected, 0),
        (.resultNotFound, 1),
        (.resultCancelled, 2),
        (.resultFailed, 3),
    ]
    for (code, raw) in cases {
        precondition(code.rawValue == raw)
        precondition(EABluetoothAccessoryPickerError.Code(rawValue: raw) == code)
        _ = code.hashValue
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(EABluetoothAccessoryPickerError.Code(rawValue: 99) == nil)
    precondition(EABluetoothAccessoryPickerError.alreadyConnected == .alreadyConnected)
    precondition(EABluetoothAccessoryPickerError.resultNotFound == .resultNotFound)
    precondition(EABluetoothAccessoryPickerError.resultCancelled == .resultCancelled)
    precondition(EABluetoothAccessoryPickerError.resultFailed == .resultFailed)
    precondition(EABluetoothAccessoryPickerError.Code.alreadyConnected != .resultFailed)
}

func testEABluetoothAccessoryPickerErrorDomain() {
    precondition(EABluetoothAccessoryPickerErrorDomain == "EABluetoothAccessoryPickerErrorDomain")
    precondition(EABluetoothAccessoryPickerError.errorDomain == EABluetoothAccessoryPickerErrorDomain)
}

func testEABluetoothAccessoryPickerErrorConstruction() {
    let empty = EABluetoothAccessoryPickerError(.resultFailed)
    precondition(empty.code == .resultFailed)
    precondition(empty.errorCode == 3)
    precondition(EABluetoothAccessoryPickerError.errorDomain == EABluetoothAccessoryPickerErrorDomain)
    precondition(!empty.localizedDescription.isEmpty)
    precondition(empty.userInfo.isEmpty)
    precondition(empty.errorUserInfo.isEmpty)

    let sentinel = EABluetoothAccessoryPickerError(
        .alreadyConnected,
        userInfo: ["sentinel": "value"]
    )
    precondition(sentinel.userInfo["sentinel"] as? String == "value")
    precondition(sentinel.errorUserInfo["sentinel"] as? String == "value")
    precondition(sentinel.code == .alreadyConnected)
    precondition(sentinel.errorCode == EABluetoothAccessoryPickerError.Code.alreadyConnected.rawValue)
}

func testEABluetoothAccessoryPickerErrorEquality() {
    let a = EABluetoothAccessoryPickerError(.resultNotFound)
    let b = EABluetoothAccessoryPickerError(.resultNotFound)
    let c = EABluetoothAccessoryPickerError(.resultCancelled)
    precondition(a == b)
    precondition(a != c)
    let withInfo = EABluetoothAccessoryPickerError(.resultNotFound, userInfo: ["k": "v"])
    precondition(a != withInfo)
}

func testEABluetoothAccessoryPickerErrorHash() {
    let a = EABluetoothAccessoryPickerError(.resultCancelled)
    let b = EABluetoothAccessoryPickerError(.resultCancelled, userInfo: ["other": 1])
    var hasherA = Hasher()
    var hasherB = Hasher()
    a.hash(into: &hasherA)
    b.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(a.hashValue == b.hashValue)
}

func testEABluetoothAccessoryPickerErrorPatternMatch() {
    let typed = EABluetoothAccessoryPickerError(.resultFailed)
    precondition(EABluetoothAccessoryPickerError.Code.resultFailed ~= typed)
    let ns = typed as NSError
    precondition(ns.domain == EABluetoothAccessoryPickerErrorDomain)
    precondition(ns.code == 3)
    precondition(EABluetoothAccessoryPickerError.Code.resultFailed ~= ns)
    precondition(!(EABluetoothAccessoryPickerError.Code.alreadyConnected ~= typed))
}

func testEABluetoothAccessoryPickerCompletion() {
    let completion: EABluetoothAccessoryPickerCompletion = { error in
        precondition(error == nil)
    }
    completion(nil)
}
