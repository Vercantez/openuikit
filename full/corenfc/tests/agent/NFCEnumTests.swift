import Foundation
@_spi(OpenUIKitHost) import CoreNFC

func testNFCTypeNameFormatRawValues() {
    let cases: [(NFCTypeNameFormat, UInt8)] = [
        (.empty, 0x00),
        (.nfcWellKnown, 0x01),
        (.media, 0x02),
        (.absoluteURI, 0x03),
        (.nfcExternal, 0x04),
        (.unknown, 0x05),
        (.unchanged, 0x06),
    ]
    for (value, raw) in cases {
        precondition(value.rawValue == raw)
        precondition(NFCTypeNameFormat(rawValue: raw) == value)
    }
    precondition(NFCTypeNameFormat(rawValue: 7) == nil)
    precondition(NFCTypeNameFormat.empty != .unknown)
    var hasher = Hasher()
    hasher.combine(NFCTypeNameFormat.nfcWellKnown)
    _ = hasher.finalize()
    _ = NFCTypeNameFormat.media.hashValue
}

func testNFCNDEFStatusRawValues() {
    precondition(NFCNDEFStatus.notSupported.rawValue == 1)
    precondition(NFCNDEFStatus.readWrite.rawValue == 2)
    precondition(NFCNDEFStatus.readOnly.rawValue == 3)
    precondition(NFCNDEFStatus(rawValue: 1) == .notSupported)
    precondition(NFCNDEFStatus(rawValue: 2) == .readWrite)
    precondition(NFCNDEFStatus(rawValue: 3) == .readOnly)
    precondition(NFCNDEFStatus(rawValue: 0) == nil)
    precondition(NFCNDEFStatus.notSupported != .readWrite)
    _ = NFCNDEFStatus.readOnly.hashValue
    var hasher = Hasher()
    hasher.combine(NFCNDEFStatus.readWrite)
    _ = hasher.finalize()
}

func testNFCMiFareFamilyRawValues() {
    precondition(NFCMiFareFamily.unknown.rawValue == 1)
    precondition(NFCMiFareFamily.ultralight.rawValue == 2)
    precondition(NFCMiFareFamily.plus.rawValue == 3)
    precondition(NFCMiFareFamily.desfire.rawValue == 4)
    precondition(NFCMiFareFamily(rawValue: 4) == .desfire)
    precondition(NFCMiFareFamily(rawValue: 99) == nil)
    precondition(NFCMiFareFamily.ultralight != .plus)
    _ = NFCMiFareFamily.unknown.hashValue
    var hasher = Hasher()
    hasher.combine(NFCMiFareFamily.desfire)
    _ = hasher.finalize()
}

func testNFCFeliCaEncryptionIdRawValues() {
    precondition(NFCFeliCaEncryptionId.AES.rawValue == 79)
    precondition(NFCFeliCaEncryptionId.AES_DES.rawValue == 65)
    precondition(NFCFeliCaEncryptionId.aes == .AES)
    precondition(NFCFeliCaEncryptionId.aes_des == .AES_DES)
    precondition(NFCFeliCaEncryptionId(rawValue: 79) == .AES)
    precondition(NFCFeliCaEncryptionId(rawValue: 0) == nil)
    precondition(NFCFeliCaEncryptionId.AES != .AES_DES)
    _ = NFCFeliCaEncryptionId.AES.hashValue
    var hasher = Hasher()
    hasher.combine(NFCFeliCaEncryptionId.aes_des)
    _ = hasher.finalize()
}

func testNFCFeliCaPollingRequestCodeRawValues() {
    precondition(NFCFeliCaPollingRequestCode.noRequest.rawValue == 0)
    precondition(NFCFeliCaPollingRequestCode.systemCode.rawValue == 1)
    precondition(NFCFeliCaPollingRequestCode.communicationPerformance.rawValue == 2)
    precondition(NFCFeliCaPollingRequestCode.PollingRequestCodeNoRequest == .noRequest)
    precondition(NFCFeliCaPollingRequestCode.PollingRequestCodeSystemCode == .systemCode)
    precondition(
        NFCFeliCaPollingRequestCode.PollingRequestCodeCommunicationPerformance
            == .communicationPerformance
    )
    precondition(NFCFeliCaPollingRequestCode(rawValue: 1) == .systemCode)
    precondition(NFCFeliCaPollingRequestCode(rawValue: 9) == nil)
    precondition(NFCFeliCaPollingRequestCode.noRequest != .systemCode)
    _ = NFCFeliCaPollingRequestCode.systemCode.hashValue
    var hasher = Hasher()
    hasher.combine(NFCFeliCaPollingRequestCode.communicationPerformance)
    _ = hasher.finalize()
}

func testNFCFeliCaPollingTimeSlotRawValues() {
    precondition(NFCFeliCaPollingTimeSlot.max1.rawValue == 0)
    precondition(NFCFeliCaPollingTimeSlot.max2.rawValue == 1)
    precondition(NFCFeliCaPollingTimeSlot.max4.rawValue == 3)
    precondition(NFCFeliCaPollingTimeSlot.max8.rawValue == 7)
    precondition(NFCFeliCaPollingTimeSlot.max16.rawValue == 15)
    precondition(NFCFeliCaPollingTimeSlot.PollingTimeSlotMax1 == .max1)
    precondition(NFCFeliCaPollingTimeSlot.PollingTimeSlotMax2 == .max2)
    precondition(NFCFeliCaPollingTimeSlot.PollingTimeSlotMax4 == .max4)
    precondition(NFCFeliCaPollingTimeSlot.PollingTimeSlotMax8 == .max8)
    precondition(NFCFeliCaPollingTimeSlot.PollingTimeSlotMax16 == .max16)
    precondition(NFCFeliCaPollingTimeSlot(rawValue: 15) == .max16)
    precondition(NFCFeliCaPollingTimeSlot(rawValue: 2) == nil)
    precondition(NFCFeliCaPollingTimeSlot.max1 != .max16)
    _ = NFCFeliCaPollingTimeSlot.max8.hashValue
    var hasher = Hasher()
    hasher.combine(NFCFeliCaPollingTimeSlot.max4)
    _ = hasher.finalize()
}

func testNFCVASModeRawValues() {
    precondition(NFCVASCommandConfiguration.Mode.urlOnly.rawValue == 0)
    precondition(NFCVASCommandConfiguration.Mode.normal.rawValue == 1)
    precondition(NFCVASCommandConfiguration.Mode.VASModeURLOnly == .urlOnly)
    precondition(NFCVASCommandConfiguration.Mode.VASModeNormal == .normal)
    precondition(NFCVASCommandConfiguration.Mode(rawValue: 0) == .urlOnly)
    precondition(NFCVASCommandConfiguration.Mode(rawValue: 2) == nil)
    precondition(NFCVASCommandConfiguration.Mode.urlOnly != .normal)
    _ = NFCVASCommandConfiguration.Mode.normal.hashValue
    var hasher = Hasher()
    hasher.combine(NFCVASCommandConfiguration.Mode.urlOnly)
    _ = hasher.finalize()
}

func testNFCVASErrorCodeRawValues() {
    let codes: [(NFCVASResponse.ErrorCode, Int)] = [
        (.success, 36864),
        (.dataNotFound, 27267),
        (.dataNotActivated, 25223),
        (.wrongParameters, 27392),
        (.wrongLCField, 26368),
        (.userIntervention, 27012),
        (.incorrectData, 27264),
        (.unsupportedApplicationVersion, 25408),
    ]
    for (value, raw) in codes {
        precondition(value.rawValue == raw)
        precondition(NFCVASResponse.ErrorCode(rawValue: raw) == value)
    }
    precondition(NFCVASResponse.ErrorCode.VASErrorCodeSuccess == .success)
    precondition(NFCVASResponse.ErrorCode.VASErrorCodeDataNotFound == .dataNotFound)
    precondition(NFCVASResponse.ErrorCode.VASErrorCodeDataNotActivated == .dataNotActivated)
    precondition(NFCVASResponse.ErrorCode.VASErrorCodeWrongParameters == .wrongParameters)
    precondition(NFCVASResponse.ErrorCode.VASErrorCodeWrongLCField == .wrongLCField)
    precondition(NFCVASResponse.ErrorCode.VASErrorCodeUserIntervention == .userIntervention)
    precondition(NFCVASResponse.ErrorCode.VASErrorCodeIncorrectData == .incorrectData)
    precondition(
        NFCVASResponse.ErrorCode.VASErrorCodeUnsupportedApplicationVersion
            == .unsupportedApplicationVersion
    )
    precondition(NFCVASResponse.ErrorCode(rawValue: 1) == nil)
    precondition(NFCVASResponse.ErrorCode.success != .dataNotFound)
    _ = NFCVASResponse.ErrorCode.success.hashValue
    var hasher = Hasher()
    hasher.combine(NFCVASResponse.ErrorCode.incorrectData)
    _ = hasher.finalize()
}

func testCardSessionErrorCases() {
    let cases: [CardSession.Error] = [
        .transmissionError,
        .maxSessionDurationReached,
        .invalidated,
        .radioDisabled,
        .userInvalidated,
        .emulationStopped,
        .accessNotAccepted,
        .systemNotAvailable,
        .systemEligibilityFailed,
    ]
    for value in cases {
        precondition(value == value)
        precondition(!value.localizedDescription.isEmpty)
        _ = value.hashValue
        var hasher = Hasher()
        hasher.combine(value)
        _ = hasher.finalize()
    }
    precondition(CardSession.Error.systemNotAvailable != .radioDisabled)
}

func testCardSessionEmulationUIStatus() {
    precondition(CardSession.EmulationUIStatus.failure == .failure)
    precondition(CardSession.EmulationUIStatus.success == .success)
    precondition(CardSession.EmulationUIStatus.failure != .success)
    _ = CardSession.EmulationUIStatus.success.hashValue
    var hasher = Hasher()
    hasher.combine(CardSession.EmulationUIStatus.failure)
    _ = hasher.finalize()
}

func testCardSessionEventCases() {
    let apdu = CardSession.APDU(payload: Data([0x00, 0xA4]))
    let events: [CardSession.Event] = [
        .readerDetected,
        .sessionStarted,
        .readerDeselected,
        .sessionInvalidated(reason: .userInvalidated),
        .received(apdu),
    ]
    switch events[0] {
    case .readerDetected:
        break
    default:
        preconditionFailure("readerDetected")
    }
    switch events[1] {
    case .sessionStarted:
        break
    default:
        preconditionFailure("sessionStarted")
    }
    switch events[2] {
    case .readerDeselected:
        break
    default:
        preconditionFailure("readerDeselected")
    }
    switch events[3] {
    case .sessionInvalidated(let reason):
        precondition(reason == .userInvalidated)
    default:
        preconditionFailure("sessionInvalidated")
    }
    switch events[4] {
    case .received(let payload):
        precondition(payload.payload == Data([0x00, 0xA4]))
    default:
        preconditionFailure("received")
    }
}

func testPresentmentIntentAssertionErrorCases() {
    precondition(
        NFCPresentmentIntentAssertion.Error.systemNotAvailable
            == .systemNotAvailable
    )
    precondition(
        NFCPresentmentIntentAssertion.Error.systemEligibilityFailed
            == .systemEligibilityFailed
    )
    precondition(
        NFCPresentmentIntentAssertion.Error.systemNotAvailable
            != .systemEligibilityFailed
    )
    precondition(!NFCPresentmentIntentAssertion.Error.systemNotAvailable.localizedDescription.isEmpty)
    precondition(
        !NFCPresentmentIntentAssertion.Error.systemEligibilityFailed.localizedDescription.isEmpty
    )
    _ = NFCPresentmentIntentAssertion.Error.systemNotAvailable.hashValue
    var hasher = Hasher()
    hasher.combine(NFCPresentmentIntentAssertion.Error.systemEligibilityFailed)
    _ = hasher.finalize()
}

func testCoreNFCTypeAliases() {
    let encryption: EncryptionId = .aes
    precondition(encryption == NFCFeliCaEncryptionId.AES)
    let request: PollingRequestCode = .noRequest
    precondition(request == NFCFeliCaPollingRequestCode.noRequest)
    let slot: PollingTimeSlot = .max1
    precondition(slot == NFCFeliCaPollingTimeSlot.max1)
    let flags: RequestFlag = .address
    precondition(flags == NFCISO15693RequestFlag.address)
    let vas: VASErrorCode = .success
    precondition(vas == NFCVASResponse.ErrorCode.success)
    let mode: VASMode = .normal
    precondition(mode == NFCVASCommandConfiguration.Mode.normal)
}
