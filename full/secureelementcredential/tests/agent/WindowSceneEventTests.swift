import Foundation
import SecureElementCredential

func testWindowSceneEventCases() {
    let presentation = CredentialSessionWindowSceneEvent.presentation
    let reader = CredentialSessionWindowSceneEvent.readerDetected
    precondition(presentation != reader)
}

func testWindowSceneEventEquality() {
    precondition(CredentialSessionWindowSceneEvent.presentation == .presentation)
    precondition(CredentialSessionWindowSceneEvent.readerDetected != .presentation)
}

func testWindowSceneEventHash() {
    var h1 = Hasher()
    var h2 = Hasher()
    CredentialSessionWindowSceneEvent.presentation.hash(into: &h1)
    CredentialSessionWindowSceneEvent.presentation.hash(into: &h2)
    precondition(h1.finalize() == h2.finalize())
    precondition(
        CredentialSessionWindowSceneEvent.presentation.hashValue
            != CredentialSessionWindowSceneEvent.readerDetected.hashValue
    )
}

func testWindowSceneEventInequality() {
    precondition(CredentialSessionWindowSceneEvent.presentation != .readerDetected)
    precondition(!(CredentialSessionWindowSceneEvent.readerDetected != .readerDetected))
}

func testWindowSceneEventDescription() {
    precondition(CredentialSessionWindowSceneEvent.presentation.description == "presentation")
    precondition(CredentialSessionWindowSceneEvent.readerDetected.description == "readerDetected")
}

func testWindowSceneEventEncode() {
    do {
        let data = try JSONEncoder().encode(CredentialSessionWindowSceneEvent.presentation)
        precondition(!data.isEmpty)
    } catch {
        preconditionFailure("encode failed: \(error)")
    }
}

func testWindowSceneEventDecode() {
    let original = CredentialSessionWindowSceneEvent.readerDetected
    do {
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CredentialSessionWindowSceneEvent.self, from: data)
        precondition(decoded == .readerDetected)
    } catch {
        preconditionFailure("decode failed: \(error)")
    }
}
