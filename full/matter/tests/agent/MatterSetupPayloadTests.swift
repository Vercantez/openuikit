import Foundation
import Matter

func testManualPairingCode() {
    let payload = MTRSetupPayload(setupPasscode: n(20202021), discriminator: n(3840))
    payload.hasShortDiscriminator = false
    payload.discoveryCapabilities = []
    payload.commissioningFlow = .standard
    let code = payload.manualEntryCode()
    mtrRequire(code != nil, "manual encode")
    mtrRequire(code?.count == 11, "11 digits")
    let parsed = try? MTRManualSetupPayloadParser(decimalStringRepresentation: code!).populatePayload()
    mtrRequire(parsed != nil, "manual parse")
    mtrRequire(parsed?.setupPasscode.uint32Value == 20202021, "pin")
    mtrRequire(parsed?.hasShortDiscriminator == true, "short disc")
    let failable = MTRSetupPayload(payload: code!)
    mtrRequire(failable != nil, "failable")
    let throwing = try? MTRSetupPayload(onboardingPayload: code!)
    mtrRequire(throwing != nil, "throwing")
    let viaClass = try? MTRSetupPayload.setupPayload(forOnboardingPayload: code!)
    mtrRequire(viaClass?.setupPasscode.uint32Value == 20202021, "class")
    let viaOnboard = try? MTROnboardingPayloadParser.setupPayload(forOnboardingPayload: code!)
    mtrRequire(viaOnboard?.setupPasscode.uint32Value == 20202021, "onboard parser")
    payload.commissioningFlow = .userActionRequired
    payload.vendorID = n(0xFFF1)
    payload.productID = n(0x8001)
    let longCode = payload.manualEntryCode()
    mtrRequire(longCode?.count == 21, "21 digits")
    let longParsed = MTRSetupPayload(payload: longCode!)
    mtrRequire(longParsed?.vendorID.uintValue == 0xFFF1, "vid")
    mtrRequire(longParsed?.productID.uintValue == 0x8001, "pid")
    mtrRequire(MTRSetupPayload().setupPasscode.uintValue == 0, "empty")
    _ = MTRSetupPayload.new() as MTRSetupPayload
}

func testQRCodeRoundTrip() {
    let payload = MTRSetupPayload(setupPasscode: n(20202021), discriminator: n(3840))
    payload.version = n(0)
    payload.vendorID = n(0xFFF1)
    payload.productID = n(0x8001)
    payload.commissioningFlow = .standard
    payload.discoveryCapabilities = [.onNetwork, .BLE]
    payload.hasShortDiscriminator = false
    let qr = payload.qrCodeString()
    mtrRequire(qr != nil, "qr encode")
    mtrRequire(qr?.hasPrefix("MT:") == true, "prefix")
    let parsed = try? MTRQRCodeSetupPayloadParser(base38Representation: qr!).populatePayload()
    mtrRequire(parsed != nil, "qr parse")
    mtrRequire(parsed?.setupPasscode.uint32Value == 20202021, "qr pin")
    mtrRequire(parsed?.discriminator.uintValue == 3840, "qr disc")
    mtrRequire(parsed?.vendorID.uintValue == 0xFFF1, "qr vid")
    mtrRequire(parsed?.productID.uintValue == 0x8001, "qr pid")
    mtrRequire(parsed?.discoveryCapabilities.contains(.onNetwork) == true, "qr cap")
    mtrRequire(parsed?.hasShortDiscriminator == false, "long disc")
    var nsErr: NSError?
    let viaPtr = payload.qrCodeString(&nsErr)
    mtrRequire(viaPtr == qr, "ptr")
    mtrRequire(payload.rendezvousInformation != nil, "rendez")
    payload.rendezvousInformation = n(4)
    mtrRequire(payload.discoveryCapabilities.contains(.onNetwork), "rendez set")
    payload.setUpPINCode = n(20202021)
    mtrRequire(payload.setupPasscode.uint32Value == 20202021, "pin alias")
    let viaOnboard = try? MTRSetupPayload(onboardingPayload: qr!)
    mtrRequire(viaOnboard?.productID.uintValue == 0x8001, "onboard qr")
}

func testPasscodeValidation() {
    mtrRequire(MTRSetupPayload.isValidSetupPasscode(n(20202021)), "valid")
    mtrRequire(!MTRSetupPayload.isValidSetupPasscode(n(0)), "zero")
    mtrRequire(!MTRSetupPayload.isValidSetupPasscode(n(11111111)), "rep")
    mtrRequire(!MTRSetupPayload.isValidSetupPasscode(n(12345678)), "seq")
    mtrRequire(!MTRSetupPayload.isValidSetupPasscode(n(87654321)), "rev")
    mtrRequire(!MTRSetupPayload.isValidSetupPasscode(n(99999999)), "nines")
    let pin = MTRSetupPayload.generateRandomSetupPasscode()
    mtrRequire(MTRSetupPayload.isValidSetupPasscode(pin), "random")
    let intPin = MTRSetupPayload.generateRandomPIN()
    mtrRequire(intPin > 0, "int pin")
    mtrRequire(MTRSetupPayload(payload: "not-a-payload") == nil, "bad payload")
}

func testVendorElements() {
    let payload = MTRSetupPayload(setupPasscode: n(20202021), discriminator: n(3840))
    let info = MTROptionalQRCodeInfo(tag: n(1), stringValue: "serial")
    mtrRequire(info.type == .string, "type")
    mtrRequire(info.stringValue == "serial", "str")
    payload.addOrReplaceVendorElement(info)
    mtrRequire(payload.vendorElement(withTag: n(1))?.stringValue == "serial", "get")
    mtrRequire(payload.vendorElements.count == 1, "count")
    let all = try? payload.getAllOptionalVendorData()
    mtrRequire(all?.count == 1, "all")
    payload.removeVendorElement(withTag: n(1))
    mtrRequire(payload.vendorElement(withTag: n(1)) == nil, "removed")
    let intInfo = MTROptionalQRCodeInfo(tag: n(2), int32Value: 42)
    mtrRequire(infoTypeMatches(intInfo), "int32")
    payload.addOrReplaceVendorElement(intInfo)
    mtrRequire(payload.vendorElement(withTag: n(2))?.integerValue?.int32Value == 42, "int get")
    let empty = MTROptionalQRCodeInfo()
    mtrRequire(empty.type == .unknown, "empty type")
    empty.setType(.string)
    empty.setTag(n(3))
    empty.setStringValue("x")
    empty.setIntegerValue(n(0))
    payload.serialNumber = "SN"
    mtrRequire(payload.serialNumber == "SN", "serial")
}

private func infoTypeMatches(_ info: MTROptionalQRCodeInfo) -> Bool {
    info.type == .int32 && info.integerValue?.int32Value == 42 && info.infoType.uintValue == MTROptionalQRCodeInfoType.int32.rawValue
}
