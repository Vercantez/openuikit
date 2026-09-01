import CoreNFC
import Dispatch
import Foundation

private func requireUnsupported(_ error: Error?) {
    guard let error = error as? NFCReaderError else {
        fatalError("expected NFCReaderError, got \(String(describing: error))")
    }
    precondition(error.code == .readerErrorUnsupportedFeature)
    precondition(error.errorCode == NFCReaderError.readerErrorUnsupportedFeature.rawValue)
    precondition(NFCReaderError.errorDomain == NFCErrorDomain)
}

private final class NDEFDelegate: NSObject, NFCNDEFReaderSessionDelegate, @unchecked Sendable {
    var invalidation: ((any Error) -> Void)?

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        _ = (session, messages)
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        invalidation?(error)
    }
}

private final class TagDelegate: NSObject, NFCTagReaderSessionDelegate, @unchecked Sendable {
    var invalidation: ((any Error) -> Void)?

    func tagReaderSession(
        _ session: NFCTagReaderSession,
        didInvalidateWithError error: any Error
    ) {
        invalidation?(error)
    }
}

private final class VASDelegate: NSObject, NFCVASReaderSessionDelegate, @unchecked Sendable {
    var invalidation: ((any Error) -> Void)?

    func readerSession(_ session: NFCVASReaderSession, didInvalidateWithError error: any Error) {
        invalidation?(error)
    }
}

private final class ProbeMiFareTag: NSObject, NFCMiFareTag {}
private final class ProbeFeliCaTag: NSObject, NFCFeliCaTag {}
private final class ProbeISO7816Tag: NSObject, NFCISO7816Tag {}
private final class ProbeISO15693Tag: NSObject, NFCISO15693Tag {}

enum CoreNFCRuntime {
    static func run() async {
        precondition(NFCErrorDomain == "NFCErrorDomain")
        precondition(NFCISO15693TagResponseErrorKey == "NFCISO15693TagResponseErrorKey")
        precondition(
            NFCTagResponseUnexpectedLengthErrorKey == "NFCTagResponseUnexpectedLengthErrorKey"
        )

        precondition(NFCTypeNameFormat.nfcWellKnown.rawValue == 0x01)
        precondition(NFCNDEFStatus.readWrite.rawValue == 2)
        precondition(NFCMiFareFamily.desfire.rawValue == 4)
        precondition(NFCFeliCaEncryptionId.aes == .AES)
        precondition(NFCFeliCaPollingRequestCode.noRequest.rawValue == 0)
        precondition(NFCFeliCaPollingTimeSlot.max16.rawValue == 0x0F)
        precondition(NFCVASCommandConfiguration.Mode.normal.rawValue == 1)
        precondition(NFCVASResponse.ErrorCode.success.rawValue == 0x9000)

        let flags: NFCISO15693RequestFlag = [.highDataRate, .address]
        precondition(flags.contains(.highDataRate))
        precondition(!flags.contains(.select))
        precondition(flags.union(.option).contains(.option))
        precondition(NFCISO15693RequestFlag.RequestFlagAddress == .address)
        precondition(NFCISO15693ResponseFlag.error.rawValue == 1)

        var polling: NFCTagReaderSession.PollingOption = [.iso14443, .iso15693]
        precondition(polling.contains(.iso14443))
        polling.insert(.iso18092)
        precondition(polling.contains(.iso18092))
        precondition(NFCTagReaderSession.PollingOption.pace.rawValue == 1 << 3)

        let error = NFCReaderError(.readerErrorUnsupportedFeature)
        precondition(error != NFCReaderError(.readerErrorRadioDisabled))
        precondition(error.localizedDescription.contains("1"))
        precondition(NFCReaderError.Code.readerErrorUnsupportedFeature ~= error)

        guard let uriPayload = NFCNDEFPayload.wellKnownTypeURIPayload(
            string: "https://www.example.com/nfc"
        ) else {
            fatalError("URI payload encoding failed")
        }
        precondition(uriPayload.typeNameFormat == .nfcWellKnown)
        precondition(
            uriPayload.wellKnownTypeURIPayload()?.absoluteString == "https://www.example.com/nfc"
        )

        guard let urlPayload = NFCNDEFPayload.wellKnownTypeURIPayload(
            url: URL(string: "https://openuikit.dev")!
        ) else {
            fatalError("URL payload encoding failed")
        }
        precondition(urlPayload.wellKnownTypeURIPayload()?.host == "openuikit.dev")

        guard let textPayload = NFCNDEFPayload.wellKnownTypeTextPayload(
            string: "hello",
            locale: Locale(identifier: "en")
        ) else {
            fatalError("text payload encoding failed")
        }
        let decodedText = textPayload.wellKnownTypeTextPayload()
        precondition(decodedText.0 == "hello")
        precondition(decodedText.1?.identifier.hasPrefix("en") == true)
        precondition(
            NFCNDEFPayload.wellKnowTypeTextPayload(
                string: "hello",
                locale: Locale(identifier: "en")
            ) != nil
        )

        let message = NFCNDEFMessage(records: [uriPayload, textPayload])
        precondition(message.records.count == 2)
        precondition(message.length > 0)
        // NFC Forum URI record: https://www.example.com  (prefix 0x02 + "example.com")
        let forumURI = Data([
            0xD1, 0x01, 0x0C, 0x55, 0x02,
            0x65, 0x78, 0x61, 0x6D, 0x70, 0x6C, 0x65, 0x2E, 0x63, 0x6F, 0x6D,
        ])
        guard let parsedURI = NFCNDEFMessage(data: forumURI) else {
            fatalError("NDEF URI parse failed")
        }
        precondition(parsedURI.records.count == 1)
        precondition(parsedURI.records[0].wellKnownTypeURIPayload()?.host == "www.example.com")
        precondition(parsedURI.length == forumURI.count)
        let named = NFCNDEFMessage(NDEFRecords: [textPayload])
        precondition(named.records.count == 1)

        let chunked = NFCNDEFPayload(
            format: .media,
            type: Data("text/plain".utf8),
            identifier: Data([0x01]),
            payload: Data(repeating: 0x41, count: 40),
            chunkSize: 16
        )
        let chunkedMessage = NFCNDEFMessage(records: [chunked])
        precondition(chunkedMessage.length > 40)

        guard let apdu = NFCISO7816APDU(
            data: Data([
                0x00, 0xA4, 0x04, 0x00, 0x07, 0xD2, 0x76, 0x00, 0x00, 0x85, 0x01, 0x01, 0x00,
            ])
        ) else {
            fatalError("APDU parse failed")
        }
        precondition(apdu.instructionClass == 0x00)
        precondition(apdu.instructionCode == 0xA4)
        precondition(apdu.p1Parameter == 0x04)
        precondition(apdu.data?.count == 7)
        precondition(apdu.expectedResponseLength == 256)
        let constructed = NFCISO7816APDU(
            instructionClass: 0x00,
            instructionCode: 0xB0,
            p1Parameter: 0,
            p2Parameter: 0,
            data: Data(),
            expectedResponseLength: -1
        )
        precondition(constructed.data == nil)
        let response = NFCISO7816ResponseAPDU(
            payload: Data([0x90]),
            statusWord1: 0x90,
            statusWord2: 0x00
        )
        precondition(response.statusWord1 == 0x90)

        let config = NFCISO15693CustomCommandConfiguration(
            manufacturerCode: 4,
            customCommandCode: 0xA0,
            requestParameters: Data([0x01]),
            maximumRetries: 2,
            retryInterval: 0.1
        )
        precondition(config.manufacturerCode == 4)
        precondition(config.maximumRetries == 2)
        let readConfig = NFCISO15693ReadMultipleBlocksConfiguration(
            range: NSRange(location: 0, length: 4),
            chunkSize: 2
        )
        precondition(readConfig.chunkSize == 2)

        let vas = NFCVASCommandConfiguration(
            vasMode: .normal,
            passTypeIdentifier: "pass.com.example.nfc",
            url: URL(string: "https://example.com")
        )
        precondition(vas.mode == .normal)
        let vasAlias = NFCVASCommandConfiguration(
            VASMode: .urlOnly,
            passTypeIdentifier: "pass.com.example.nfc",
            url: nil
        )
        precondition(vasAlias.mode == .urlOnly)
        let vasResponse = NFCVASResponse(
            status: .success,
            vasData: Data([0x01]),
            mobileToken: Data([0x02])
        )
        precondition(vasResponse.status == .success)

        precondition(!NFCReaderSession.readingAvailable)
        precondition(!NFCNDEFReaderSession.readingAvailable)
        precondition(!CardSession.isSupported)
        let cardEligible = await CardSession.isEligible
        precondition(cardEligible == false)

        let ndefDelegate = NDEFDelegate()
        let ndefSession = NFCNDEFReaderSession(
            delegate: ndefDelegate,
            queue: DispatchQueue(label: "corenfc.ndef"),
            invalidateAfterFirstRead: true
        )
        precondition(!ndefSession.isReady)
        ndefSession.alertMessage = "Hold near tag"
        precondition(ndefSession.alertMessage == "Hold near tag")
        let ndefError = await withCheckedContinuation { continuation in
            ndefDelegate.invalidation = { error in
                continuation.resume(returning: error)
            }
            ndefSession.begin()
        }
        requireUnsupported(ndefError)
        do {
            try await ndefSession.connect(to: ProbeMiFareTag())
            fatalError("NDEF connect must fail closed")
        } catch {
            requireUnsupported(error)
        }

        let tagDelegate = TagDelegate()
        guard let tagSession = NFCTagReaderSession(
            pollingOption: [.iso14443, .iso15693],
            delegate: tagDelegate,
            queue: DispatchQueue(label: "corenfc.tag")
        ) else {
            fatalError("expected non-empty polling option to construct a fail-closed session")
        }
        let tagError = await withCheckedContinuation { continuation in
            tagDelegate.invalidation = { error in
                continuation.resume(returning: error)
            }
            tagSession.begin()
        }
        requireUnsupported(tagError)
        let connectError = await withCheckedContinuation { continuation in
            tagSession.connect(to: .miFare(ProbeMiFareTag())) { error in
                continuation.resume(returning: error)
            }
        }
        requireUnsupported(connectError)
        do {
            try await tagSession.connect(to: .iso7816(ProbeISO7816Tag()))
            fatalError("tag connect must fail closed")
        } catch {
            requireUnsupported(error)
        }
        precondition(NFCTagReaderSession(pollingOption: [], delegate: tagDelegate) == nil)

        let payment = NFCPaymentTagReaderSession(delegate: tagDelegate, queue: nil)
        precondition(!payment.isReady)

        let vasDelegate = VASDelegate()
        let vasSession = NFCVASReaderSession(
            vasCommandConfigurations: [vas],
            delegate: vasDelegate,
            queue: nil
        )
        let vasError = await withCheckedContinuation { continuation in
            vasDelegate.invalidation = { error in
                continuation.resume(returning: error)
            }
            vasSession.begin()
        }
        requireUnsupported(vasError)

        let miFare = NFCTag.miFare(ProbeMiFareTag())
        let feliCa = NFCTag.feliCa(ProbeFeliCaTag())
        let iso7816 = NFCTag.iso7816(ProbeISO7816Tag())
        let iso15693 = NFCTag.iso15693(ProbeISO15693Tag())
        precondition(!miFare.isAvailable)
        precondition(!feliCa.isAvailable)
        precondition(!iso7816.isAvailable)
        precondition(!iso15693.isAvailable)

        do {
            _ = try await ProbeMiFareTag().sendMiFareCommand(commandPacket: Data([0x30, 0x00]))
            fatalError("miFare command must fail closed")
        } catch {
            requireUnsupported(error)
        }
        do {
            _ = try await ProbeISO15693Tag().readSingleBlock(
                requestFlags: .highDataRate,
                blockNumber: 0
            )
            fatalError("iso15693 read must fail closed")
        } catch {
            requireUnsupported(error)
        }

        do {
            _ = try await CardSession()
            fatalError("CardSession init must fail closed")
        } catch let error as CardSession.Error {
            precondition(error == .systemNotAvailable)
            precondition(error != .radioDisabled)
        } catch {
            fatalError("expected CardSession.Error")
        }
        do {
            _ = try await NFCPresentmentIntentAssertion.acquire()
            fatalError("presentment acquire must fail closed")
        } catch let error as NFCPresentmentIntentAssertion.Error {
            precondition(error == .systemNotAvailable)
        } catch {
            fatalError("expected presentment error")
        }

        let sceneEvent = NFCWindowSceneEvent.readerDetected
        precondition(sceneEvent != .presentation)
        precondition(sceneEvent.description == "readerDetected")
        let encoded: Data
        do {
            encoded = try JSONEncoder().encode(sceneEvent)
        } catch {
            fatalError("NFCWindowSceneEvent encode failed")
        }
        let decoded: NFCWindowSceneEvent
        do {
            decoded = try JSONDecoder().decode(NFCWindowSceneEvent.self, from: encoded)
        } catch {
            fatalError("NFCWindowSceneEvent decode failed")
        }
        precondition(decoded == .readerDetected)

        let _: EncryptionId = .aes
        let _: PollingRequestCode = .systemCode
        let _: PollingTimeSlot = .max4
        let _: RequestFlag = .address
        let _: VASErrorCode = .success
        let _: VASMode = .normal

        print("CORENFC_AGENT_RUNTIME_OK")
    }
}

let _nfcRuntimeLock = DispatchSemaphore(value: 0)
Task {
    await CoreNFCRuntime.run()
    _nfcRuntimeLock.signal()
}
_nfcRuntimeLock.wait()
