import Foundation
import CoreNFC

func testNFCISO15693RequestFlagMembers() {
    precondition(NFCISO15693RequestFlag.dualSubCarriers.rawValue == 1 << 0)
    precondition(NFCISO15693RequestFlag.highDataRate.rawValue == 1 << 1)
    precondition(NFCISO15693RequestFlag.protocolExtension.rawValue == 1 << 3)
    precondition(NFCISO15693RequestFlag.select.rawValue == 1 << 4)
    precondition(NFCISO15693RequestFlag.address.rawValue == 1 << 5)
    precondition(NFCISO15693RequestFlag.option.rawValue == 1 << 6)
    precondition(NFCISO15693RequestFlag.commandSpecificBit8.rawValue == 1 << 7)
    precondition(NFCISO15693RequestFlag.RequestFlagDualSubCarriers == .dualSubCarriers)
    precondition(NFCISO15693RequestFlag.RequestFlagHighDataRate == .highDataRate)
    precondition(NFCISO15693RequestFlag.RequestFlagProtocolExtension == .protocolExtension)
    precondition(NFCISO15693RequestFlag.RequestFlagSelect == .select)
    precondition(NFCISO15693RequestFlag.RequestFlagAddress == .address)
    precondition(NFCISO15693RequestFlag.RequestFlagOption == .option)
    precondition(NFCISO15693RequestFlag(rawValue: 1 << 5).contains(.address))
    precondition(NFCISO15693RequestFlag.address != .option)
}

func testNFCISO15693RequestFlagAlgebra() {
    var flags: NFCISO15693RequestFlag = [.highDataRate, .address]
    precondition(flags.contains(.highDataRate))
    precondition(flags.contains(.address))
    precondition(!flags.contains(.option))
    precondition(flags.union(.option).contains(.option))
    precondition(flags.intersection(.address) == .address)
    precondition(flags.isDisjoint(with: .select))
    precondition(flags.isSuperset(of: .highDataRate))
    precondition(flags.isSubset(of: [.highDataRate, .address, .option]))
    precondition(!flags.isEmpty)
    precondition(NFCISO15693RequestFlag().isEmpty)
    let inserted = flags.insert(.option)
    precondition(inserted.inserted)
    precondition(flags.contains(.option))
    let removed = flags.remove(.address)
    precondition(removed == .address)
    flags.formUnion(.select)
    precondition(flags.contains(.select))
    flags.formIntersection(.select)
    precondition(flags == .select)
    flags = [.address, .option]
    flags.formSymmetricDifference(.option)
    precondition(flags == .address)
    precondition(flags.symmetricDifference(.address).isEmpty)
    precondition(flags.subtracting(.address).isEmpty)
    flags.subtract(.address)
    precondition(flags.isEmpty)
    let updated = flags.update(with: .highDataRate)
    precondition(updated == nil)
    precondition(flags.contains(.highDataRate))
    precondition(NFCISO15693RequestFlag([.address, .select]).contains(.select))
    let fromSequence = NFCISO15693RequestFlag([NFCISO15693RequestFlag.option])
    precondition(fromSequence == .option)
    precondition(!flags.isStrictSubset(of: .highDataRate))
    precondition(NFCISO15693RequestFlag.address.isStrictSubset(of: [.address, .option]))
    precondition(([.address, .option] as NFCISO15693RequestFlag).isStrictSuperset(of: .address))
    precondition([.address, .option] as NFCISO15693RequestFlag != .address)
}

func testNFCISO15693ResponseFlagMembers() {
    precondition(NFCISO15693ResponseFlag.error.rawValue == 1 << 0)
    precondition(NFCISO15693ResponseFlag.responseBufferValid.rawValue == 1 << 1)
    precondition(NFCISO15693ResponseFlag.finalResponse.rawValue == 1 << 2)
    precondition(NFCISO15693ResponseFlag.protocolExtension.rawValue == 1 << 3)
    precondition(NFCISO15693ResponseFlag.blockSecurityStatusBit5.rawValue == 1 << 4)
    precondition(NFCISO15693ResponseFlag.blockSecurityStatusBit6.rawValue == 1 << 5)
    precondition(NFCISO15693ResponseFlag.waitTimeExtension.rawValue == 1 << 6)
    precondition(NFCISO15693ResponseFlag(rawValue: 1).contains(.error))
    precondition(NFCISO15693ResponseFlag.error != .finalResponse)
}

func testNFCISO15693ResponseFlagAlgebra() {
    var flags: NFCISO15693ResponseFlag = [.error, .finalResponse]
    precondition(flags.contains(.error))
    precondition(!flags.contains(.waitTimeExtension))
    precondition(flags.union(.protocolExtension).contains(.protocolExtension))
    precondition(flags.intersection(.finalResponse) == .finalResponse)
    precondition(flags.isDisjoint(with: .waitTimeExtension))
    precondition(flags.isSuperset(of: .error))
    precondition(flags.isSubset(of: [.error, .finalResponse, .protocolExtension]))
    precondition(!flags.isEmpty)
    precondition(NFCISO15693ResponseFlag().isEmpty)
    precondition(flags.insert(.responseBufferValid).inserted)
    precondition(flags.remove(.error) == .error)
    flags.formUnion(.waitTimeExtension)
    flags.formIntersection(.waitTimeExtension)
    precondition(flags == .waitTimeExtension)
    flags = [.error, .finalResponse]
    flags.formSymmetricDifference(.finalResponse)
    precondition(flags == .error)
    precondition(flags.symmetricDifference(.error).isEmpty)
    precondition(flags.subtracting(.error).isEmpty)
    flags.subtract(.error)
    precondition(flags.isEmpty)
    _ = flags.update(with: .protocolExtension)
    precondition(NFCISO15693ResponseFlag([.error]).contains(.error))
    let fromSequence = NFCISO15693ResponseFlag([NFCISO15693ResponseFlag.finalResponse])
    precondition(fromSequence == .finalResponse)
    precondition(NFCISO15693ResponseFlag.error.isStrictSubset(of: [.error, .finalResponse]))
    precondition(([.error, .finalResponse] as NFCISO15693ResponseFlag).isStrictSuperset(of: .error))
    precondition([.error] as NFCISO15693ResponseFlag != .finalResponse)
}

func testNFCPollingOptionMembers() {
    precondition(NFCTagReaderSession.PollingOption.iso14443.rawValue == 1 << 0)
    precondition(NFCTagReaderSession.PollingOption.iso15693.rawValue == 1 << 1)
    precondition(NFCTagReaderSession.PollingOption.iso18092.rawValue == 1 << 2)
    precondition(NFCTagReaderSession.PollingOption.pace.rawValue == 1 << 3)
    precondition(NFCTagReaderSession.PollingOption(rawValue: 1).contains(.iso14443))
    precondition(NFCTagReaderSession.PollingOption.iso14443 != .iso18092)
}

func testNFCPollingOptionAlgebra() {
    var polling: NFCTagReaderSession.PollingOption = [.iso14443, .iso15693]
    precondition(polling.contains(.iso14443))
    precondition(!polling.contains(.iso18092))
    precondition(polling.union(.pace).contains(.pace))
    precondition(polling.intersection(.iso15693) == .iso15693)
    precondition(polling.isDisjoint(with: .pace))
    precondition(polling.isSuperset(of: .iso14443))
    precondition(polling.isSubset(of: [.iso14443, .iso15693, .iso18092]))
    precondition(!polling.isEmpty)
    precondition(NFCTagReaderSession.PollingOption().isEmpty)
    precondition(polling.insert(.pace).inserted)
    precondition(polling.remove(.iso14443) == .iso14443)
    polling.formUnion(.iso18092)
    polling.formIntersection(.iso18092)
    precondition(polling == .iso18092)
    polling = [.iso14443, .pace]
    polling.formSymmetricDifference(.pace)
    precondition(polling == .iso14443)
    precondition(polling.symmetricDifference(.iso14443).isEmpty)
    precondition(polling.subtracting(.iso14443).isEmpty)
    polling.subtract(.iso14443)
    precondition(polling.isEmpty)
    _ = polling.update(with: .iso15693)
    precondition(NFCTagReaderSession.PollingOption([.iso14443]).contains(.iso14443))
    let fromSequence = NFCTagReaderSession.PollingOption(
        [NFCTagReaderSession.PollingOption.pace]
    )
    precondition(fromSequence == .pace)
    precondition(
        NFCTagReaderSession.PollingOption.iso14443
            .isStrictSubset(of: [.iso14443, .iso15693])
    )
    precondition(
        ([.iso14443, .iso15693] as NFCTagReaderSession.PollingOption)
            .isStrictSuperset(of: .iso14443)
    )
    precondition([.iso14443] as NFCTagReaderSession.PollingOption != .iso15693)
}
