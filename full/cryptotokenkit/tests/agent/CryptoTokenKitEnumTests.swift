import Foundation
import CryptoTokenKit

private func tkMust(_ condition: Bool, _ message: String) {
    if !condition {
        preconditionFailure(message)
    }
}

func testTKSmartCardPINCharsetRawValues() {
    tkMust(TKSmartCardPINFormat.Charset.numeric.rawValue == 0, "numeric")
    tkMust(TKSmartCardPINFormat.Charset.alphanumeric.rawValue == 1, "alphanumeric")
    tkMust(TKSmartCardPINFormat.Charset.upperAlphanumeric.rawValue == 2, "upper")
    tkMust(TKSmartCardPINFormat.Charset(rawValue: 1) == .alphanumeric, "init")
    tkMust(TKSmartCardPINFormat.Charset(rawValue: 99) == nil, "nil")
}

func testTKSmartCardPINEncodingRawValues() {
    tkMust(TKSmartCardPINFormat.Encoding.binary.rawValue == 0, "binary")
    tkMust(TKSmartCardPINFormat.Encoding.ascii.rawValue == 1, "ascii")
    tkMust(TKSmartCardPINFormat.Encoding.bcd.rawValue == 2, "bcd")
    tkMust(TKSmartCardPINFormat.Encoding(rawValue: 2) == .bcd, "init")
}

func testTKSmartCardPINJustificationRawValues() {
    tkMust(TKSmartCardPINFormat.Justification.left.rawValue == 0, "left")
    tkMust(TKSmartCardPINFormat.Justification.right.rawValue == 1, "right")
    tkMust(TKSmartCardPINFormat.Justification(rawValue: 0) == .left, "init")
}

func testTKSmartCardSlotStateRawValues() {
    tkMust(TKSmartCardSlot.State.missing.rawValue == 0, "missing")
    tkMust(TKSmartCardSlot.State.empty.rawValue == 1, "empty")
    tkMust(TKSmartCardSlot.State.probing.rawValue == 2, "probing")
    tkMust(TKSmartCardSlot.State.muteCard.rawValue == 3, "mute")
    tkMust(TKSmartCardSlot.State.validCard.rawValue == 4, "valid")
    tkMust(TKSmartCardSlot.State(rawValue: 4) == .validCard, "init")
}

func testTKTokenOperationRawValues() {
    tkMust(TKTokenOperation.none.rawValue == 0, "none")
    tkMust(TKTokenOperation.readData.rawValue == 1, "read")
    tkMust(TKTokenOperation.signData.rawValue == 2, "sign")
    tkMust(TKTokenOperation.decryptData.rawValue == 3, "decrypt")
    tkMust(TKTokenOperation.performKeyExchange.rawValue == 4, "kex")
    tkMust(TKTokenOperation(rawValue: 3) == .decryptData, "init")
}

func testTKSmartCardProtocolRawValues() {
    tkMust(TKSmartCardProtocol.t0.rawValue == 1 << 0, "t0")
    tkMust(TKSmartCardProtocol.t1.rawValue == 1 << 1, "t1")
    tkMust(TKSmartCardProtocol.t15.rawValue == 1 << 15, "t15")
    tkMust(TKSmartCardProtocol.any.rawValue == (1 << 16) - 1, "any")
    let constructed = TKSmartCardProtocol(rawValue: 1)
    tkMust(constructed == .t0, "init raw")
}

func testTKSmartCardPINCompletionRawValues() {
    tkMust(
        TKSmartCardUserInteractionForPINOperation.Completion.maxLength.rawValue == 1 << 0,
        "maxLength"
    )
    tkMust(
        TKSmartCardUserInteractionForPINOperation.Completion.key.rawValue == 1 << 1,
        "key"
    )
    tkMust(
        TKSmartCardUserInteractionForPINOperation.Completion.timeout.rawValue == 1 << 2,
        "timeout"
    )
    let value = TKSmartCardUserInteractionForPINOperation.Completion(rawValue: 1 << 1)
    tkMust(value == .key, "init")
}

func testTKSmartCardPINConfirmationRawValues() {
    tkMust(
        TKSmartCardUserInteractionForSecurePINChange.Confirmation.new.rawValue == 1 << 0,
        "new"
    )
    tkMust(
        TKSmartCardUserInteractionForSecurePINChange.Confirmation.current.rawValue == 1 << 1,
        "current"
    )
    let value = TKSmartCardUserInteractionForSecurePINChange.Confirmation(rawValue: 1 << 1)
    tkMust(value == .current, "init")
}

func testTKTLVTagTypealias() {
    let tag: TKTLVTag = 0x7F21
    tkMust(tag == UInt64(0x7F21), "TKTLVTag is UInt64")
}

func testTKTokenTypealiases() {
    let instance: TKToken.InstanceID = "instance-1"
    tkMust(instance == "instance-1", "InstanceID")
    let object: TKToken.ObjectID = NSNumber(value: 7)
    tkMust((object as? NSNumber)?.intValue == 7, "ObjectID")
    let classID: TKTokenDriver.ClassID = "driver.class"
    tkMust(classID == "driver.class", "ClassID")
    let constraint: TKTokenOperationConstraint = NSObject()
    tkMust(constraint is NSObject, "constraint")
}
