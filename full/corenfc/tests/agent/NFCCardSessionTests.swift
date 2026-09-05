import Foundation
@_spi(OpenUIKitHost) import CoreNFC

func testCardSessionUnsupported() {
    precondition(CardSession.isSupported == false)
    let eligible = nfcAwait { await CardSession.isEligible }
    switch eligible {
    case .success(let value):
        precondition(value == false)
    case .failure:
        preconditionFailure("isEligible must return false, not throw")
    }
    switch nfcAwait({ try await CardSession() }) {
    case .success:
        preconditionFailure("CardSession init must throw")
    case .failure(let error):
        precondition((error as? CardSession.Error) == .systemNotAvailable)
    }
}

func testCardSessionAPDU() {
    let apdu = CardSession.APDU(payload: Data([0x00, 0xA4]))
    precondition(apdu.payload == Data([0x00, 0xA4]))
    precondition(apdu.debugDescription.contains("2 bytes"))
    precondition(apdu == CardSession.APDU(payload: Data([0x00, 0xA4])))
    precondition(apdu != CardSession.APDU(payload: Data([0x00])))
    switch nfcAwait({ try await apdu.respond(response: Data([0x90, 0x00])) }) {
    case .success:
        preconditionFailure("APDU respond must fail closed")
    case .failure(let error):
        precondition((error as? CardSession.Error) == .systemNotAvailable)
    }
}

func testCardSessionEventStream() {
    let stream = CardSession.EventStream()
    let iterator: CardSession.EventStream.AsyncIterator = stream.makeAsyncIterator()
    let _: CardSession.EventStream.Element.Type = CardSession.Event.self
    let _: CardSession.EventStream.Iterator.Element.Type = CardSession.Event.self
    switch nfcAwait({ try await iterator.next() }) {
    case .success:
        preconditionFailure("event stream must throw")
    case .failure(let error):
        precondition((error as? CardSession.Error) == .systemNotAvailable)
    }
    switch nfcAwait({ try await iterator.next() }) {
    case .success(let value):
        precondition(value == nil)
    case .failure:
        preconditionFailure("second next must return nil")
    }
}

func testCardSessionEmulationFailClosed() {
    let session = CardSession.hostMakeUnsupportedSession()
    session.alertMessage = "present card"
    precondition(session.alertMessage == "present card")
    session.invalidate()
    let inProgress = nfcAwait { await session.isEmulationInProgress }
    switch inProgress {
    case .success(let value):
        precondition(value == false)
    case .failure:
        preconditionFailure("isEmulationInProgress")
    }
    switch nfcAwait({ try await session.startEmulation() }) {
    case .success:
        preconditionFailure("startEmulation must fail closed")
    case .failure(let error):
        precondition((error as? CardSession.Error) == .systemNotAvailable)
    }
    switch nfcAwait({ await session.stopEmulation(status: .failure) }) {
    case .success:
        break
    case .failure:
        preconditionFailure("stopEmulation is inert")
    }
    switch nfcAwait({ await session.stopEmulation(status: .success) }) {
    case .success:
        break
    case .failure:
        preconditionFailure("stopEmulation success status is still inert")
    }
    let stream = session.eventStream
    switch nfcAwait({ try await stream.makeAsyncIterator().next() }) {
    case .success:
        preconditionFailure("eventStream must throw")
    case .failure(let error):
        precondition((error as? CardSession.Error) == .systemNotAvailable)
    }
}

func testPresentmentIntentAssertion() {
    switch nfcAwait({ try await NFCPresentmentIntentAssertion.acquire() }) {
    case .success(let assertion):
        _ = assertion
        preconditionFailure("presentment acquire must throw")
    case .failure(let error):
        precondition((error as? NFCPresentmentIntentAssertion.Error) == .systemNotAvailable)
    }
    let assertion = NFCPresentmentIntentAssertion.hostMakeInvalidAssertion()
    precondition(assertion.isValid == false)
}
