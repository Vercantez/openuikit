import Foundation
@_spi(OpenUIKitHost) import CoreNFC

func testHostTagProperties() {
    let tag = nfcHostTag()
    precondition(tag.isAvailable == false)
    precondition(tag.currentIDm.isEmpty)
    precondition(tag.currentSystemCode.isEmpty)
    precondition(tag.icManufacturerCode == 0)
    precondition(tag.icSerialNumber.isEmpty)
    precondition(tag.identifier.isEmpty)
    precondition(tag.applicationData == nil)
    precondition(tag.historicalBytes == nil)
    precondition(tag.initialSelectedAID.isEmpty)
    precondition(tag.proprietaryApplicationDataCoding == false)
    precondition(tag.mifareFamily == .unknown)
}

func testNFCTagCases() {
    let host = nfcHostTag()
    let iso15693 = NFCTag.iso15693(host)
    precondition(iso15693.isAvailable == false)
    let feliCa = NFCTag.feliCa(host)
    precondition(feliCa.isAvailable == false)
    let miFare = NFCTag.miFare(host)
    precondition(miFare.isAvailable == false)
    let iso7816 = NFCTag.iso7816(host)
    precondition(iso7816.isAvailable == false)
}

func testNDEFTagFailClosed() {
    let tag: any NFCNDEFTag = nfcHostTag()
    let status = nfcWait { finish in
        tag.queryNDEFStatus { ndefStatus, capacity, error in
            finish((ndefStatus, capacity, error))
        }
    }
    precondition(status.0 == .notSupported)
    precondition(status.1 == 0)
    precondition(nfcReaderError(status.2!).code == .readerErrorUnsupportedFeature)

    let read = nfcWait { finish in
        tag.readNDEF { message, error in
            finish((message, error))
        }
    }
    precondition(read.0 == nil)
    precondition(nfcReaderError(read.1!).code == .ndefReaderSessionErrorZeroLengthMessage)

    let lockError = nfcWait { finish in
        tag.writeLock(completionHandler: finish)
    }
    precondition(nfcReaderError(lockError!).code == .ndefReaderSessionErrorTagNotWritable)

    let message = NFCNDEFMessage(records: [])
    nfcExpectReaderCode(
        nfcAwait { try await tag.writeNDEF(message) },
        .ndefReaderSessionErrorTagNotWritable
    )
}

func testFeliCaTagAsyncFailClosed() {
    let tag: any NFCFeliCaTag = nfcHostTag()
    nfcExpectUnsupported(
        nfcAwait { try await tag.polling(systemCode: Data([0x00, 0x01]), requestCode: .noRequest, timeSlot: .max1) }
    )
    nfcExpectUnsupported(
        nfcAwait { try await tag.readWithoutEncryption(serviceCodeList: [], blockList: []) }
    )
    nfcExpectUnsupported(nfcAwait { try await tag.requestServiceV2(nodeCodeList: []) })
    nfcExpectUnsupported(nfcAwait { try await tag.requestService(nodeCodeList: []) })
    nfcExpectUnsupported(nfcAwait { try await tag.sendFeliCaCommand(commandPacket: Data([0x00])) })
    nfcExpectUnsupported(
        nfcAwait { try await tag.writeWithoutEncryption(serviceCodeList: [], blockList: [], blockData: []) }
    )
}

func testFeliCaTagCallbacksFailClosed() {
    let tag: any NFCFeliCaTag = nfcHostTag()
    let response = nfcWait { finish in
        tag.requestResponse { value, error in
            finish((value, error))
        }
    }
    precondition(nfcReaderError(response.1!).code == .readerErrorUnsupportedFeature)

    let spec = nfcWait { finish in
        tag.requestSpecificationVersion { a, b, c, d, error in
            finish((a, b, c, d, error))
        }
    }
    precondition(nfcReaderError(spec.4!).code == .readerErrorUnsupportedFeature)

    let system = nfcWait { finish in
        tag.requestSystemCode { codes, error in
            finish((codes, error))
        }
    }
    precondition(system.0.isEmpty)
    precondition(nfcReaderError(system.1!).code == .readerErrorUnsupportedFeature)

    let reset = nfcWait { finish in
        tag.resetMode { a, b, error in
            finish((a, b, error))
        }
    }
    precondition(nfcReaderError(reset.2!).code == .readerErrorUnsupportedFeature)
}

func testFeliCaTagResultHandlersFailClosed() {
    let tag: any NFCFeliCaTag = nfcHostTag()
    switch nfcWait({ finish in tag.sendFeliCaCommand(commandPacket: Data([0x00]), resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("sendFeliCaCommand")
    }
    switch nfcWait({ finish in tag.requestService(nodeCodeList: [], resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("requestService")
    }
    switch nfcWait({ finish in tag.requestResponse(resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("requestResponse")
    }
    switch nfcWait({ finish in tag.requestServiceV2(nodeCodeList: [], resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("requestServiceV2")
    }
    switch nfcWait({ finish in tag.requestSystemCode(resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("requestSystemCode")
    }
    switch nfcWait({ finish in
        tag.readWithoutEncryption(serviceCodeList: [], blockList: [], resultHandler: finish)
    }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("readWithoutEncryption")
    }
    switch nfcWait({ finish in
        tag.writeWithoutEncryption(serviceCodeList: [], blockList: [], blockData: [], resultHandler: finish)
    }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("writeWithoutEncryption")
    }
    switch nfcWait({ finish in tag.requestSpecificationVersion(resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("requestSpecificationVersion")
    }
    switch nfcWait({ finish in
        tag.polling(systemCode: Data([0x00, 0x01]), requestCode: .systemCode, timeSlot: .max8, resultHandler: finish)
    }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("polling")
    }
    switch nfcWait({ finish in tag.resetMode(resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("resetMode")
    }
}

func testISO15693TagAsyncFailClosed() {
    let tag: any NFCISO15693Tag = nfcHostTag()
    let flags: NFCISO15693RequestFlag = [.highDataRate, .address]
    nfcExpectUnsupported(
        nfcAwait { try await tag.customCommand(requestFlags: flags, customCommandCode: 0xA0, customRequestParameters: Data()) }
    )
    nfcExpectUnsupported(nfcAwait { try await tag.extendedLockBlock(requestFlags: flags, blockNumber: 1) })
    nfcExpectUnsupported(
        nfcAwait { try await tag.extendedReadMultipleBlocks(requestFlags: flags, blockRange: NSRange(location: 0, length: 1)) }
    )
    nfcExpectUnsupported(nfcAwait { try await tag.extendedReadSingleBlock(requestFlags: flags, blockNumber: 0) })
    nfcExpectUnsupported(
        nfcAwait { try await tag.extendedWriteSingleBlock(requestFlags: flags, blockNumber: 0, dataBlock: Data([0x00])) }
    )
    nfcExpectUnsupported(
        nfcAwait { try await tag.getMultipleBlockSecurityStatus(requestFlags: flags, blockRange: NSRange(location: 0, length: 1)) }
    )
    nfcExpectUnsupported(nfcAwait { try await tag.lockAFI(requestFlags: flags) })
    nfcExpectUnsupported(nfcAwait { try await tag.lockBlock(requestFlags: flags, blockNumber: 0) })
    nfcExpectUnsupported(nfcAwait { try await tag.lockDSFID(requestFlags: flags) })
    nfcExpectUnsupported(
        nfcAwait { try await tag.readMultipleBlocks(requestFlags: flags, blockRange: NSRange(location: 0, length: 1)) }
    )
    nfcExpectUnsupported(nfcAwait { try await tag.readSingleBlock(requestFlags: flags, blockNumber: 0) })
    nfcExpectUnsupported(nfcAwait { try await tag.resetToReady(requestFlags: flags) })
    nfcExpectUnsupported(nfcAwait { try await tag.select(requestFlags: flags) })
    nfcExpectUnsupported(nfcAwait { try await tag.writeAFI(requestFlags: flags, afi: 0) })
    nfcExpectUnsupported(nfcAwait { try await tag.writeDSFID(requestFlags: flags, dsfid: 0) })
    nfcExpectUnsupported(
        nfcAwait {
            try await tag.writeMultipleBlocks(
                requestFlags: flags,
                blockRange: NSRange(location: 0, length: 1),
                dataBlocks: [Data([0x00])]
            )
        }
    )
    nfcExpectUnsupported(
        nfcAwait { try await tag.writeSingleBlock(requestFlags: flags, blockNumber: 0, dataBlock: Data([0x00])) }
    )
}

func testISO15693TagCallbacksFailClosed() {
    let tag: any NFCISO15693Tag = nfcHostTag()
    let flags: NFCISO15693RequestFlag = .highDataRate
    let info = nfcWait { finish in
        tag.getSystemInfo(requestFlags: flags) { a, b, c, d, e, error in
            finish((a, b, c, d, e, error))
        }
    }
    precondition(nfcReaderError(info.5!).code == .readerErrorUnsupportedFeature)

    let lockDFSID = nfcWait { finish in
        tag.lockDFSID(requestFlags: flags, completionHandler: finish)
    }
    precondition(nfcReaderError(lockDFSID!).code == .readerErrorUnsupportedFeature)

    let readConfig = NFCISO15693ReadMultipleBlocksConfiguration(
        range: NSRange(location: 0, length: 1),
        chunkSize: 1
    )
    let multi = nfcWait { finish in
        tag.readMultipleBlock(readConfiguration: readConfig) { data, error in
            finish((data, error))
        }
    }
    precondition(nfcReaderError(multi.1!).code == .readerErrorUnsupportedFeature)

    let custom = NFCISO15693CustomCommandConfiguration(
        manufacturerCode: 4,
        customCommandCode: 0xA0,
        requestParameters: nil
    )
    let customResult = nfcWait { finish in
        tag.sendCustomCommand(commandConfiguration: custom) { data, error in
            finish((data, error))
        }
    }
    precondition(nfcReaderError(customResult.1!).code == .readerErrorUnsupportedFeature)

    let quiet = nfcWait { finish in
        tag.stayQuiet(completionHandler: finish)
    }
    precondition(nfcReaderError(quiet!).code == .readerErrorUnsupportedFeature)
}

func testISO15693TagOverlaysFailClosed() {
    let tag: any NFCISO15693Tag = nfcHostTag()
    let flags: NFCISO15693RequestFlag = .option
    nfcExpectUnsupported(nfcAwait { try await tag.readBuffer(requestFlags: flags) })
    nfcExpectUnsupported(nfcAwait { try await tag.systemInfo(requestFlags: flags) })
    nfcExpectUnsupported(nfcAwait { try await tag.sendRequest(requestFlags: 0, commandCode: 1, data: nil) })
    nfcExpectUnsupported(
        nfcAwait { try await tag.authenticate(requestFlags: flags, cryptoSuiteIdentifier: 0, message: Data()) }
    )
    nfcExpectUnsupported(
        nfcAwait { try await tag.fastReadMultipleBlocks(requestFlags: flags, blockRange: NSRange(location: 0, length: 1)) }
    )
    nfcExpectUnsupported(
        nfcAwait {
            try await tag.extendedWriteMultipleBlocks(
                requestFlags: flags,
                blockRange: NSRange(location: 0, length: 1),
                dataBlocks: [Data([0x00])]
            )
        }
    )
    nfcExpectUnsupported(
        nfcAwait {
            try await tag.extendedFastReadMultipleBlocks(
                requestFlags: flags,
                blockRange: NSRange(location: 0, length: 1)
            )
        }
    )
    nfcExpectUnsupported(
        nfcAwait {
            try await tag.extendedGetMultipleBlockSecurityStatus(
                requestFlags: flags,
                blockRange: NSRange(location: 0, length: 1)
            )
        }
    )
    nfcExpectUnsupported(
        nfcAwait { try await tag.challenge(requestFlags: flags, cryptoSuiteIdentifier: 0, message: Data()) }
    )
    nfcExpectUnsupported(
        nfcAwait { try await tag.keyUpdate(requestFlags: flags, keyIdentifier: 0, message: Data()) }
    )
}

func testISO15693TagResultHandlersFailClosed() {
    let tag: any NFCISO15693Tag = nfcHostTag()
    let flags: NFCISO15693RequestFlag = .address
    func expectFailure<T>(_ result: Result<T, any Error>) {
        switch result {
        case .failure(let error):
            precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
        case .success:
            preconditionFailure("ISO15693 overlay must fail closed")
        }
    }
    expectFailure(nfcWait { finish in tag.readBuffer(requestFlags: flags, resultHandler: finish) })
    expectFailure(
        nfcWait { finish in tag.sendRequest(requestFlags: 0, commandCode: 1, data: nil, resultHandler: finish) }
    )
    expectFailure(
        nfcWait { finish in
            tag.authenticate(requestFlags: flags, cryptoSuiteIdentifier: 0, message: Data(), resultHandler: finish)
        }
    )
    expectFailure(
        nfcWait { finish in
            tag.customCommand(
                requestFlags: flags,
                customCommandCode: 0xA0,
                customRequestParameters: Data(),
                resultHandler: finish
            )
        }
    )
    expectFailure(nfcWait { finish in tag.getSystemInfo(requestFlags: flags, resultHandler: finish) })
    expectFailure(
        nfcWait { finish in tag.readSingleBlock(requestFlags: flags, blockNumber: 0, resultHandler: finish) }
    )
    expectFailure(
        nfcWait { finish in
            tag.readMultipleBlocks(requestFlags: flags, blockRange: NSRange(location: 0, length: 1), resultHandler: finish)
        }
    )
    expectFailure(
        nfcWait { finish in
            tag.fastReadMultipleBlocks(
                requestFlags: flags,
                blockRange: NSRange(location: 0, length: 1),
                resultHandler: finish
            )
        }
    )
    expectFailure(
        nfcWait { finish in
            tag.extendedReadSingleBlock(requestFlags: flags, blockNumber: 0, resultHandler: finish)
        }
    )
    let writeError = nfcWait { finish in
        tag.extendedWriteMultipleBlocks(
            requestFlags: flags,
            blockRange: NSRange(location: 0, length: 1),
            dataBlocks: [Data([0x00])],
            completionHandler: finish
        )
    }
    precondition(nfcReaderError(writeError!).code == .readerErrorUnsupportedFeature)
    expectFailure(
        nfcWait { finish in
            tag.extendedFastReadMultipleBlocks(
                requestFlags: flags,
                blockRange: NSRange(location: 0, length: 1),
                resultHandler: finish
            )
        }
    )
    expectFailure(
        nfcWait { finish in
            tag.extendedGetMultipleBlockSecurityStatus(
                requestFlags: flags,
                blockRange: NSRange(location: 0, length: 1),
                resultHandler: finish
            )
        }
    )
    let challengeError = nfcWait { finish in
        tag.challenge(requestFlags: flags, cryptoSuiteIdentifier: 0, message: Data(), completionHandler: finish)
    }
    precondition(nfcReaderError(challengeError!).code == .readerErrorUnsupportedFeature)
    expectFailure(
        nfcWait { finish in
            tag.keyUpdate(requestFlags: flags, keyIdentifier: 0, message: Data(), resultHandler: finish)
        }
    )
}

func testISO7816TagFailClosed() {
    let tag: any NFCISO7816Tag = nfcHostTag()
    let apdu = NFCISO7816APDU(
        instructionClass: 0x00,
        instructionCode: 0xA4,
        p1Parameter: 0x04,
        p2Parameter: 0x00,
        data: Data([0x01]),
        expectedResponseLength: -1
    )
    nfcExpectUnsupported(nfcAwait { try await tag.sendCommand(apdu: apdu) })
    switch nfcWait({ finish in tag.sendCommand(apdu: apdu, resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("ISO7816 sendCommand")
    }
}

func testMiFareTagFailClosed() {
    let tag: any NFCMiFareTag = nfcHostTag()
    nfcExpectUnsupported(nfcAwait { try await tag.sendMiFareCommand(commandPacket: Data([0x30, 0x00])) })
    let apdu = NFCISO7816APDU(
        instructionClass: 0x00,
        instructionCode: 0xA4,
        p1Parameter: 0x00,
        p2Parameter: 0x00,
        data: Data(),
        expectedResponseLength: 0
    )
    nfcExpectUnsupported(nfcAwait { try await tag.sendMiFareISO7816Command(apdu) })
    switch nfcWait({ finish in tag.sendMiFareISO7816Command(apdu, resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("sendMiFareISO7816Command")
    }
    switch nfcWait({ finish in tag.sendMiFareCommand(commandPacket: Data([0x30]), resultHandler: finish) }) {
    case .failure(let error):
        precondition(nfcReaderError(error).code == .readerErrorUnsupportedFeature)
    case .success:
        preconditionFailure("sendMiFareCommand")
    }
}
