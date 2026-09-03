import Foundation
import Dispatch
@_spi(OpenUIKitHost) import CoreNFC

func runtimeFail(_ message: String) -> Never {
    fputs("CORENFC_AGENT_RUNTIME_FAIL: \(message)\n", stderr)
    exit(1)
}

func runtimeCheck(_ condition: Bool, _ message: String) {
    if !condition {
        runtimeFail(message)
    }
}

final class NDEFDelegate: NSObject, NFCNDEFReaderSessionDelegate {
    let lock = NSLock()
    var invalidation: (any Error)?

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        lock.lock()
        invalidation = error
        lock.unlock()
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        _ = messages
    }
}

final class TagDelegate: NSObject, NFCTagReaderSessionDelegate {
    let lock = NSLock()
    var invalidation: (any Error)?

    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: any Error) {
        lock.lock()
        invalidation = error
        lock.unlock()
    }

    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        _ = tags
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {}
}

final class VASDelegate: NSObject, NFCVASReaderSessionDelegate {
    func readerSession(_ session: NFCVASReaderSession, didInvalidateWithError error: any Error) {
        _ = error
    }

    func readerSession(_ session: NFCVASReaderSession, didReceive responses: [NFCVASResponse]) {
        _ = responses
    }
}

func waitUntil(_ timeoutNanoseconds: UInt64, _ predicate: () -> Bool) {
    let deadline = DispatchTime.now() + .nanoseconds(Int(timeoutNanoseconds))
    while !predicate() {
        if DispatchTime.now() > deadline {
            runtimeFail("timed out waiting for fail-closed callback")
        }
        Thread.sleep(forTimeInterval: 0.01)
    }
}

func assertEnums() {
    runtimeCheck(NFCTypeNameFormat.empty.rawValue == 0, "TNF empty")
    runtimeCheck(NFCTypeNameFormat.nfcWellKnown.rawValue == 1, "TNF well known")
    runtimeCheck(NFCTypeNameFormat(rawValue: 2) == .media, "TNF round-trip")
    runtimeCheck(NFCNDEFStatus.notSupported != .readWrite, "NDEF status inequality")
    runtimeCheck(NFCNDEFStatus(rawValue: 3) == .readOnly, "NDEF status raw")
    runtimeCheck(NFCMiFareFamily(rawValue: 4) == .desfire, "MiFare family")
    runtimeCheck(NFCFeliCaEncryptionId.aes == .AES, "FeliCa AES alias")
    runtimeCheck(NFCFeliCaEncryptionId.aes_des.rawValue == 65, "FeliCa AES_DES raw")
    runtimeCheck(NFCFeliCaPollingRequestCode.PollingRequestCodeNoRequest == .noRequest, "polling alias")
    runtimeCheck(NFCFeliCaPollingTimeSlot.max16.rawValue == 15, "time slot max16")
    runtimeCheck(NFCVASCommandConfiguration.Mode.VASModeNormal == .normal, "VAS mode alias")
    runtimeCheck(NFCVASResponse.ErrorCode.success.rawValue == 36864, "VAS success SW")
    var hasher = Hasher()
    hasher.combine(NFCTypeNameFormat.unknown)
    _ = hasher.finalize()
}

func assertOptionSets() {
    var polling: NFCTagReaderSession.PollingOption = [.iso14443, .iso15693]
    runtimeCheck(polling.contains(.iso14443), "polling contains iso14443")
    runtimeCheck(!polling.contains(.iso18092), "polling lacks iso18092")
    polling.insert(.pace)
    runtimeCheck(polling.contains(.pace), "polling insert pace")
    let flags: NFCISO15693RequestFlag = [.highDataRate, .address]
    runtimeCheck(flags.contains(.address), "15693 address flag")
    runtimeCheck(flags.union(.option).contains(.option), "15693 union")
    runtimeCheck(NFCISO15693RequestFlag().isEmpty, "15693 empty")
    runtimeCheck(
        NFCISO15693ResponseFlag.error.intersection(.finalResponse).isEmpty,
        "15693 response disjoint"
    )
}

func assertErrors() {
    runtimeCheck(NFCErrorDomain == "NFCErrorDomain", "error domain spelling")
    let error = NFCReaderError(.readerErrorUnsupportedFeature)
    runtimeCheck(error.errorCode == 1, "unsupported feature code")
    runtimeCheck(error.code == .readerErrorUnsupportedFeature, "error code property")
    runtimeCheck(NFCReaderError.errorDomain == NFCErrorDomain, "CustomNSError domain")
    runtimeCheck(
        NFCReaderError.readerSessionInvalidationErrorUserCanceled.rawValue == 200,
        "user canceled band"
    )
    runtimeCheck(
        NFCReaderError.ndefReaderSessionErrorZeroLengthMessage.rawValue == 403,
        "zero length band"
    )
    runtimeCheck(error == NFCReaderError(.readerErrorUnsupportedFeature), "error equality")
    runtimeCheck((NFCReaderError.Code.readerErrorRadioDisabled ~= error) == false, "pattern mismatch")
    runtimeCheck(NFCReaderError.Code.readerErrorUnsupportedFeature ~= error, "pattern match")
}

func assertNDEF() {
    let locale = Locale(identifier: "en-US")
    guard let text = NFCNDEFPayload.wellKnownTypeTextPayload(string: "hello", locale: locale) else {
        runtimeFail("text payload factory")
    }
    runtimeCheck(text.typeNameFormat == .nfcWellKnown, "text TNF")
    runtimeCheck(text.type == Data([0x54]), "text type T")
    let decoded = text.wellKnownTypeTextPayload()
    runtimeCheck(decoded.0 == "hello", "text round-trip")
    runtimeCheck(decoded.1?.language.languageCode?.identifier == "en" || decoded.1?.identifier.hasPrefix("en") == true, "text locale")

    guard let typo = NFCNDEFPayload.wellKnowTypeTextPayload(string: "hello", locale: locale) else {
        runtimeFail("typo text factory")
    }
    runtimeCheck(typo.payload == text.payload, "typo alias matches")

    guard let uri = NFCNDEFPayload.wellKnownTypeURIPayload(string: "https://example.com/nfc") else {
        runtimeFail("uri payload factory")
    }
    runtimeCheck(uri.wellKnownTypeURIPayload()?.absoluteString == "https://example.com/nfc", "uri round-trip")
    guard let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(url: URL(string: "https://www.example.com/")!) else {
        runtimeFail("url payload factory")
    }
    runtimeCheck(urlPayload.payload.first == 2, "https://www. prefix code")

    let empty = NFCNDEFPayload(format: .empty, type: Data(), identifier: Data(), payload: Data())
    let message = NFCNDEFMessage(records: [text, uri, empty])
    runtimeCheck(message.records.count == 3, "message records")
    runtimeCheck(message.length > 0, "message length")
    let labeled = NFCNDEFMessage(NDEFRecords: [text])
    runtimeCheck(labeled.records.count == 1, "NDEFRecords label")

    let encoded = message.encodedData()
    guard let parsed = NFCNDEFMessage(data: encoded) else {
        runtimeFail("message parse")
    }
    runtimeCheck(parsed.records.count == 3, "parsed record count")
    runtimeCheck(parsed.records[0].wellKnownTypeTextPayload().0 == "hello", "parsed text")
    runtimeCheck(NFCNDEFMessage(data: Data()) == nil, "empty data is nil")
}

func assertAPDU() {
    let apdu = NFCISO7816APDU(
        instructionClass: 0x00,
        instructionCode: 0xA4,
        p1Parameter: 0x04,
        p2Parameter: 0x00,
        data: Data([0x01, 0x02]),
        expectedResponseLength: 256
    )
    runtimeCheck(apdu.instructionCode == 0xA4, "INS")
    runtimeCheck(apdu.data?.count == 2, "APDU data")
    let bytes = apdu.encodedBytes()
    guard let parsed = NFCISO7816APDU(data: bytes) else {
        runtimeFail("APDU parse")
    }
    runtimeCheck(parsed.p1Parameter == 0x04, "parsed P1")
    runtimeCheck(parsed.expectedResponseLength == 256, "Le 0 -> 256")
    runtimeCheck(NFCISO7816APDU(data: Data([0x00])) == nil, "short APDU nil")
    let response = NFCISO7816ResponseAPDU(statusWord1: 0x90, statusWord2: 0x00, payload: nil)
    runtimeCheck(response.statusWord1 == 0x90, "response SW1")
}

func assertConfigurations() {
    let custom = NFCISO15693CustomCommandConfiguration(
        manufacturerCode: 0x04,
        customCommandCode: 0xA0,
        requestParameters: Data([0xFF])
    )
    runtimeCheck(custom.manufacturerCode == 4, "manufacturer")
    runtimeCheck(custom.requestParameters.count == 1, "request params")
    let ranged = NFCISO15693ReadMultipleBlocksConfiguration(
        range: NSRange(location: 0, length: 4),
        chunkSize: 2,
        maximumRetries: 1,
        retryInterval: 0.1
    )
    runtimeCheck(ranged.chunkSize == 2, "chunk size")
    runtimeCheck(ranged.maximumRetries == 1, "retries")
    let vas = NFCVASCommandConfiguration(
        vasMode: .normal,
        passTypeIdentifier: "pass.com.example.nfc",
        url: URL(string: "https://example.com")
    )
    runtimeCheck(vas.mode == .normal, "VAS mode")
    let vas2 = NFCVASCommandConfiguration(
        VASMode: .urlOnly,
        passTypeIdentifier: "pass.com.example.nfc",
        url: nil
    )
    runtimeCheck(vas2.url == nil, "VAS url only")
    let response = NFCVASResponse(status: .success, vasData: Data([1]), mobileToken: Data([2]))
    runtimeCheck(response.status == .success, "VAS response")
}

func assertSessions() {
    runtimeCheck(NFCReaderSession.readingAvailable == false, "readingAvailable false")
    runtimeCheck(CardSession.isSupported == false, "card isSupported false")

    let ndefDelegate = NDEFDelegate()
    let ndef = NFCNDEFReaderSession(
        delegate: ndefDelegate,
        queue: CoreNFCHostControl.sessionQueue,
        invalidateAfterFirstRead: true
    )
    runtimeCheck(ndef.isReady == false, "ndef not ready")
    runtimeCheck(ndef.invalidateAfterFirstRead, "first read flag")
    ndef.alertMessage = "hold near tag"
    runtimeCheck(ndef.alertMessage == "hold near tag", "alert message")
    ndef.begin()
    waitUntil(2_000_000_000) {
        ndefDelegate.lock.lock()
        defer { ndefDelegate.lock.unlock() }
        return ndefDelegate.invalidation != nil
    }
    if let reader = ndefDelegate.invalidation as? NFCReaderError {
        runtimeCheck(reader.code == .readerErrorUnsupportedFeature, "ndef invalidation code")
    } else {
        runtimeFail("ndef invalidation type")
    }

    let tagDelegate = TagDelegate()
    runtimeCheck(
        NFCTagReaderSession(pollingOption: .iso14443, delegate: tagDelegate, queue: nil) == nil,
        "tag session init nil"
    )
    let hostSession = NFCTagReaderSession.hostMakeSession(
        pollingOption: [.iso14443, .iso15693],
        delegate: tagDelegate
    )
    runtimeCheck(hostSession.connectedTag == nil, "no connected tag")
    runtimeCheck(hostSession.pollingOption.contains(.iso15693), "host polling")

    let payment = NFCPaymentTagReaderSession(delegate: tagDelegate, queue: nil)
    runtimeCheck(payment.delegate === tagDelegate, "payment delegate")

    let vasDelegate = VASDelegate()
    let vas = NFCVASReaderSession(
        vasCommandConfigurations: [],
        delegate: vasDelegate,
        queue: nil
    )
    runtimeCheck(vas.commandConfigurations.isEmpty, "VAS configs")
    let vas2 = NFCVASReaderSession(
        VASCommandConfigurations: [],
        delegate: vasDelegate,
        queue: DispatchQueue.main
    )
    _ = vas2

}

func assertTagsAndValues() {
    let host = CoreNFCHostNDEFTag()
    runtimeCheck(host.isAvailable == false, "host tag unavailable")
    let tag = NFCTag.iso15693(host)
    runtimeCheck(tag.isAvailable == false, "NFCTag isAvailable")
    _ = NFCTag.feliCa(host)
    _ = NFCTag.miFare(host)
    _ = NFCTag.iso7816(host)

    let info = NFCISO15693SystemInfo(
        uniqueIdentifier: Data([0x01]),
        dataStorageFormatIdentifier: 0,
        applicationFamilyIdentifier: 0,
        blockSize: 4,
        totalBlocks: 16,
        icReference: 0
    )
    runtimeCheck(info.totalBlocks == 16, "system info")
    let flags = NFCFeliCaStatusFlag(statusFlag1: 0, statusFlag2: 0)
    runtimeCheck(flags.statusFlag1 == 0, "status flag")
    let polling = NFCFeliCaPollingResponse(manufactureParameter: Data([0x01]), requestData: nil)
    runtimeCheck(polling.requestData == nil, "polling response")
}

func assertCardAndPresentment() async {
    do {
        _ = try await CardSession()
        runtimeFail("CardSession init should throw")
    } catch let error as CardSession.Error {
        runtimeCheck(error == .systemNotAvailable, "card init error")
    } catch {
        runtimeFail("card init unexpected \(error)")
    }

    let eligible = await CardSession.isEligible
    runtimeCheck(eligible == false, "card ineligible")

    do {
        _ = try await NFCPresentmentIntentAssertion.acquire()
        runtimeFail("presentment acquire should throw")
    } catch let error as NFCPresentmentIntentAssertion.Error {
        runtimeCheck(error == .systemNotAvailable, "presentment error")
    } catch {
        runtimeFail("presentment unexpected \(error)")
    }

    let stream = CardSession.EventStream()
    let iterator = stream.makeAsyncIterator()
    do {
        _ = try await iterator.next()
        runtimeFail("event stream should throw")
    } catch let error as CardSession.Error {
        runtimeCheck(error == .systemNotAvailable, "stream error")
    } catch {
        runtimeFail("stream unexpected \(error)")
    }

    let apdu = CardSession.APDU(payload: Data([0x00, 0xA4]))
    runtimeCheck(apdu.debugDescription.contains("2 bytes"), "apdu debug")
    runtimeCheck(apdu == CardSession.APDU(payload: Data([0x00, 0xA4])), "apdu equality")
}

func coreNFCRuntimeMain() {
    assertEnums()
    assertOptionSets()
    assertErrors()
    assertNDEF()
    assertAPDU()
    assertConfigurations()
    assertSessions()
    assertTagsAndValues()

    let semaphore = DispatchSemaphore(value: 0)
    Task {
        await assertCardAndPresentment()
        semaphore.signal()
    }
    if semaphore.wait(timeout: .now() + 5) == .timedOut {
        runtimeFail("async assertions timed out")
    }
    print("CORENFC_AGENT_RUNTIME_OK")
}

coreNFCRuntimeMain()
