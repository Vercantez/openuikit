import Foundation
import CryptoTokenKit

private func tkMust(_ condition: Bool, _ message: String) {
    if !condition {
        preconditionFailure(message)
    }
}

func testTKSmartCardPINFormatProperties() {
    let format = TKSmartCardPINFormat()
    tkMust(format.charset == .numeric, "default charset")
    tkMust(format.encoding == .binary, "default encoding")
    tkMust(format.minPINLength == 0, "min")
    tkMust(format.maxPINLength == 0, "max")
    tkMust(format.pinBlockByteLength == 0, "block")
    tkMust(format.pinJustification == .left, "justification")
    tkMust(format.pinBitOffset == 0, "bit offset")
    tkMust(format.pinLengthBitOffset == 0, "len offset")
    tkMust(format.pinLengthBitSize == 0, "len size")
    format.charset = .alphanumeric
    format.encoding = .ascii
    format.minPINLength = 4
    format.maxPINLength = 12
    format.pinBlockByteLength = 8
    format.pinJustification = .right
    format.pinBitOffset = 4
    format.pinLengthBitOffset = 8
    format.pinLengthBitSize = 4
    tkMust(format.charset == .alphanumeric, "set charset")
    tkMust(format.encoding == .ascii, "set encoding")
    tkMust(format.minPINLength == 4, "set min")
    tkMust(format.maxPINLength == 12, "set max")
    tkMust(format.pinBlockByteLength == 8, "set block")
    tkMust(format.pinJustification == .right, "set just")
    tkMust(format.pinBitOffset == 4, "set bit")
    tkMust(format.pinLengthBitOffset == 8, "set len off")
    tkMust(format.pinLengthBitSize == 4, "set len size")
}

func testTKSmartCardDefaults() {
    let card = TKSmartCard()
    tkMust(card.isValid == false, "valid")
    tkMust(card.allowedProtocols.isEmpty, "allowed")
    tkMust(card.currentProtocol.isEmpty, "current")
    tkMust(card.isSensitive == false, "sensitive")
    tkMust(card.context == nil, "context")
    tkMust(card.cla == 0, "cla")
    tkMust(card.useCommandChaining == false, "chaining")
    tkMust(card.useExtendedLength == false, "extended")
    tkMust(card.slot.state == .missing, "slot")
    card.cla = 0x00
    card.allowedProtocols = [.t0, .t1]
    card.useExtendedLength = true
    card.useCommandChaining = true
    tkMust(card.allowedProtocols.contains(.t0), "t0 allowed")
    tkMust(card.useExtendedLength, "ext set")
    tkMust(card.useCommandChaining, "chain set")
}

func testTKSmartCardBeginSessionFailsClosed() {
    let card = TKSmartCard()
    var called = false
    card.beginSession { success, error in
        called = true
        tkMust(success == false, "success")
        tkMust(TKError.Code.communicationError ~= (error ?? NSError(domain: "", code: 0)), "code")
    }
    tkMust(called, "sync reply")
    tkMust(card.isValid == false, "still invalid")
}

func testTKSmartCardEndSessionClearsSensitiveContext() {
    let card = TKSmartCard()
    card.context = "secret"
    card.isSensitive = true
    card.endSession()
    tkMust(card.context == nil, "cleared")
    tkMust(card.isValid == false, "invalid")
}

func testTKSmartCardEndSessionPreservesNonSensitiveContext() {
    let card = TKSmartCard()
    card.context = "keep"
    card.isSensitive = false
    card.endSession()
    tkMust((card.context as? String) == "keep", "kept")
}

func testTKSmartCardSendThrows() {
    let card = TKSmartCard()
    do {
        _ = try card.send(ins: 0xA4, p1: 0x04, p2: 0x00, data: Data([0x01]), le: 0)
        preconditionFailure("should throw")
    } catch {
        tkMust(TKError.Code.communicationError ~= error, "send throws")
    }
}

func testTKSmartCardSendReplyFailsClosed() {
    let card = TKSmartCard()
    var called = false
    card.send(ins: 0x84, p1: 0, p2: 0, data: nil, le: 8) { data, sw, error in
        called = true
        tkMust(data == nil, "no data")
        tkMust(sw == 0, "sw")
        tkMust(TKError.Code.communicationError ~= (error ?? NSError(domain: "", code: 0)), "err")
    }
    tkMust(called, "sync reply")
}

func testTKSmartCardWithSessionThrows() {
    let card = TKSmartCard()
    do {
        _ = try card.withSession { 1 }
        preconditionFailure("should throw")
    } catch {
        tkMust(TKError.Code.communicationError ~= error, "withSession")
    }
}

func testTKSmartCardUserInteractionForPINReturnsNil() {
    let card = TKSmartCard()
    let format = TKSmartCardPINFormat()
    tkMust(
        card.userInteractionForSecurePINVerification(format, apdu: Data([0x00]), pinByteOffset: 0) == nil,
        "verify"
    )
    tkMust(
        card.userInteractionForSecurePINChange(format, apdu: Data([0x00]), currentPINByteOffset: 0, newPINByteOffset: 8) == nil,
        "change"
    )
}

func testTKSmartCardSlotHasNoCard() {
    let slot = TKSmartCardSlot(name: "reader-0", state: .empty)
    tkMust(slot.name == "reader-0", "name")
    tkMust(slot.state == .empty, "state")
    tkMust(slot.atr == nil, "atr")
    tkMust(slot.maxInputLength == 0, "in")
    tkMust(slot.maxOutputLength == 0, "out")
    tkMust(slot.makeSmartCard() == nil, "no card")
}

func testTKSmartCardSlotManagerEmpty() {
    guard let manager = TKSmartCardSlotManager.default else {
        preconditionFailure("default manager")
    }
    tkMust(manager.slotNames.isEmpty, "names")
    tkMust(manager.slotNamed("x") == nil, "named")
    tkMust(manager.isNFCSupported() == false, "nfc")
}

func testTKSmartCardSlotNFCSessionFailClosed() {
    let session = TKSmartCardSlotNFCSession()
    tkMust(session.slotName == nil, "slotName")
    do {
        try session.update(message: "Hold card")
        preconditionFailure("update")
    } catch {
        tkMust(TKError.Code.notImplemented ~= error, "update error")
    }
    session.end()
    tkMust(session.slotName == nil, "ended")
}

func testTKSmartCardUserInteractionRunAndCancel() {
    let interaction = TKSmartCardUserInteraction()
    interaction.initialTimeout = 5
    interaction.interactionTimeout = 30
    tkMust(interaction.initialTimeout == 5, "initial")
    tkMust(interaction.interactionTimeout == 30, "interaction")
    tkMust(interaction.cancel() == false, "not running")
    var called = false
    interaction.run { success, error in
        called = true
        tkMust(success == false, "run success")
        tkMust(TKError.Code.notImplemented ~= (error ?? NSError(domain: "", code: 0)), "run err")
    }
    tkMust(called, "sync run")
    tkMust(interaction.delegate == nil, "delegate")
}

func testTKSmartCardUserInteractionPINOperationProperties() {
    let pin = TKSmartCardUserInteractionForPINOperation()
    pin.pinCompletion = [.key, .timeout]
    pin.pinMessageIndices = [NSNumber(value: 1)]
    pin.locale = Locale(identifier: "en_US")
    pin.resultData = Data([0x90, 0x00])
    pin.resultSW = 0x9000
    tkMust(pin.pinCompletion.contains(.key), "completion")
    tkMust(pin.pinMessageIndices?.first?.intValue == 1, "indices")
    tkMust(pin.locale.identifier == "en_US", "locale")
    tkMust(pin.resultData == Data([0x90, 0x00]), "result")
    tkMust(pin.resultSW == 0x9000, "sw")
    let change = TKSmartCardUserInteractionForSecurePINChange()
    change.pinConfirmation = [.current, .new]
    tkMust(change.pinConfirmation.contains(.new), "confirm")
    _ = TKSmartCardUserInteractionForSecurePINVerification()
}

func testTKSmartCardProtocolAlgebra() {
    var protocols: TKSmartCardProtocol = []
    tkMust(protocols.isEmpty, "empty init")
    protocols = [.t0, .t1]
    tkMust(protocols.contains(.t0), "contains t0")
    tkMust(protocols.union(.t15).contains(.t15), "union")
    tkMust(protocols.intersection(.t0) == .t0, "intersection")
    let fromLiteral: TKSmartCardProtocol = [.t0]
    tkMust(fromLiteral == .t0, "array literal")
}

func testTKPINCompletionAlgebra() {
    var flags: TKSmartCardUserInteractionForPINOperation.Completion = []
    tkMust(flags.isEmpty, "empty")
    flags.insert(.maxLength)
    tkMust(flags.contains(.maxLength), "insert")
    flags.formUnion(.timeout)
    tkMust(flags.contains(.timeout), "formUnion")
}

func testTKPINConfirmationAlgebra() {
    let flags: TKSmartCardUserInteractionForSecurePINChange.Confirmation = [.new, .current]
    tkMust(flags.contains(.new) && flags.contains(.current), "both")
    tkMust(flags.subtracting(.new) == .current, "subtracting")
}
