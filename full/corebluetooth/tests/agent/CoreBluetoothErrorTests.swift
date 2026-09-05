@_spi(OpenUIKitHost) import CoreBluetooth
import Foundation

func testCBErrorCodes() {
    let cases: [(CBError.Code, Int)] = [
        (.unknown, 0),
        (.invalidParameters, 1),
        (.invalidHandle, 2),
        (.notConnected, 3),
        (.outOfSpace, 4),
        (.operationCancelled, 5),
        (.connectionTimeout, 6),
        (.peripheralDisconnected, 7),
        (.uuidNotAllowed, 8),
        (.alreadyAdvertising, 9),
        (.connectionFailed, 10),
        (.connectionLimitReached, 11),
        (.unkownDevice, 12),
        (.operationNotSupported, 13),
        (.peerRemovedPairingInformation, 14),
        (.encryptionTimedOut, 15),
        (.tooManyLEPairedDevices, 16),
    ]
    for (code, raw) in cases {
        precondition(code.rawValue == raw)
        precondition(CBError.Code(rawValue: raw) == code)
        _ = code.hashValue
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBError.Code(rawValue: 99) == nil)
    precondition(CBError.Code.unknownDevice == .unkownDevice)
    precondition(CBError.unknown == .unknown)
    precondition(CBError.invalidParameters == .invalidParameters)
    precondition(CBError.invalidHandle == .invalidHandle)
    precondition(CBError.notConnected == .notConnected)
    precondition(CBError.outOfSpace == .outOfSpace)
    precondition(CBError.operationCancelled == .operationCancelled)
    precondition(CBError.connectionTimeout == .connectionTimeout)
    precondition(CBError.peripheralDisconnected == .peripheralDisconnected)
    precondition(CBError.uuidNotAllowed == .uuidNotAllowed)
    precondition(CBError.alreadyAdvertising == .alreadyAdvertising)
    precondition(CBError.connectionFailed == .connectionFailed)
    precondition(CBError.connectionLimitReached == .connectionLimitReached)
    precondition(CBError.unkownDevice == .unkownDevice)
    precondition(CBError.unknownDevice == .unkownDevice)
    precondition(CBError.operationNotSupported == .operationNotSupported)
    precondition(CBError.peerRemovedPairingInformation == .peerRemovedPairingInformation)
    precondition(CBError.encryptionTimedOut == .encryptionTimedOut)
    precondition(CBError.tooManyLEPairedDevices == .tooManyLEPairedDevices)
}

func testCBErrorOverlay() {
    let typed = CBError(.notConnected, userInfo: ["reason": "linux"])
    precondition(typed.code == .notConnected)
    precondition(typed.errorCode == 3)
    precondition(typed.userInfo["reason"] as? String == "linux")
    precondition(typed.errorUserInfo["reason"] as? String == "linux")
    precondition(CBError.errorDomain == CBErrorDomain)
    precondition(!typed.userInfo.keys.contains(NSLocalizedDescriptionKey))
    precondition(typed == CBError(.notConnected, userInfo: ["reason": "linux"]))
    precondition(typed != CBError(.unknown))
    precondition(
        CBError(.notConnected, userInfo: ["x": 1])
            != CBError(.notConnected, userInfo: ["x": "1"])
    )
    precondition(typed.hashValue == CBError(.notConnected, userInfo: ["other": 1]).hashValue)
    precondition(CBError.notConnected ~= typed)
    precondition(!(CBError.unknown ~= typed))
    assertTypedOriginCBError(typed, key: "reason", stringValue: "linux")
    let fresh = NSError(domain: CBErrorDomain, code: CBError.notConnected.rawValue, userInfo: ["k": "v"])
    precondition((fresh as? CBError) == nil)
    precondition(CBError.notConnected ~= fresh)
    let freshRebuilt = rehydrateCBError(from: fresh)
    precondition(freshRebuilt?.code == .notConnected)
    precondition(freshRebuilt?.userInfo["k"] as? String == "v")
    var hasher = Hasher()
    typed.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(!typed.localizedDescription.isEmpty)
}

func testCBATTErrorCodes() {
    let cases: [(CBATTError.Code, Int)] = [
        (.success, 0x00),
        (.invalidHandle, 0x01),
        (.readNotPermitted, 0x02),
        (.writeNotPermitted, 0x03),
        (.invalidPdu, 0x04),
        (.insufficientAuthentication, 0x05),
        (.requestNotSupported, 0x06),
        (.invalidOffset, 0x07),
        (.insufficientAuthorization, 0x08),
        (.prepareQueueFull, 0x09),
        (.attributeNotFound, 0x0A),
        (.attributeNotLong, 0x0B),
        (.insufficientEncryptionKeySize, 0x0C),
        (.invalidAttributeValueLength, 0x0D),
        (.unlikelyError, 0x0E),
        (.insufficientEncryption, 0x0F),
        (.unsupportedGroupType, 0x10),
        (.insufficientResources, 0x11),
    ]
    for (code, raw) in cases {
        precondition(code.rawValue == raw)
        precondition(CBATTError.Code(rawValue: raw) == code)
        _ = code.hashValue
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(CBATTError.Code(rawValue: 99) == nil)
    precondition(CBATTError.success == .success)
    precondition(CBATTError.invalidHandle == .invalidHandle)
    precondition(CBATTError.readNotPermitted == .readNotPermitted)
    precondition(CBATTError.writeNotPermitted == .writeNotPermitted)
    precondition(CBATTError.invalidPdu == .invalidPdu)
    precondition(CBATTError.insufficientAuthentication == .insufficientAuthentication)
    precondition(CBATTError.requestNotSupported == .requestNotSupported)
    precondition(CBATTError.invalidOffset == .invalidOffset)
    precondition(CBATTError.insufficientAuthorization == .insufficientAuthorization)
    precondition(CBATTError.prepareQueueFull == .prepareQueueFull)
    precondition(CBATTError.attributeNotFound == .attributeNotFound)
    precondition(CBATTError.attributeNotLong == .attributeNotLong)
    precondition(CBATTError.insufficientEncryptionKeySize == .insufficientEncryptionKeySize)
    precondition(CBATTError.invalidAttributeValueLength == .invalidAttributeValueLength)
    precondition(CBATTError.unlikelyError == .unlikelyError)
    precondition(CBATTError.insufficientEncryption == .insufficientEncryption)
    precondition(CBATTError.unsupportedGroupType == .unsupportedGroupType)
    precondition(CBATTError.insufficientResources == .insufficientResources)
}

func testCBATTErrorOverlay() {
    let att = CBATTError(.readNotPermitted, userInfo: ["att": 2])
    precondition(att.code == .readNotPermitted)
    precondition(att.errorCode == 2)
    precondition(att.userInfo["att"] as? Int == 2)
    precondition(att.errorUserInfo["att"] as? Int == 2)
    precondition(CBATTError.errorDomain == CBATTErrorDomain)
    precondition(CBATTError.readNotPermitted ~= att)
    precondition(CBATTError(.readNotPermitted) == CBATTError(.readNotPermitted))
    precondition(att != CBATTError(.success))
    precondition(att.hashValue == CBATTError(.readNotPermitted, userInfo: ["other": 1]).hashValue)
    assertTypedOriginCBATTError(att, key: "att", intValue: 2)
    let freshATT = NSError(
        domain: CBATTErrorDomain,
        code: CBATTError.readNotPermitted.rawValue,
        userInfo: ["att": 2]
    )
    precondition((freshATT as? CBATTError) == nil)
    precondition(CBATTError.readNotPermitted ~= freshATT)
    precondition(rehydrateCBATTError(from: freshATT)?.code == .readNotPermitted)
    var hasher = Hasher()
    att.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(!att.localizedDescription.isEmpty)
}
