@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

func testMCEnumRawValuesAndConstants() {
    precondition(MCErrorDomain == "MCErrorDomain")
    precondition(kMCSessionMinimumNumberOfPeers == 2)
    precondition(kMCSessionMaximumNumberOfPeers == 8)

    precondition(MCEncryptionPreference.optional.rawValue == 0)
    precondition(MCEncryptionPreference.required.rawValue == 1)
    precondition(MCEncryptionPreference.none.rawValue == 2)
    precondition(MCEncryptionPreference(rawValue: 0) == MCEncryptionPreference.optional)
    precondition(MCEncryptionPreference(rawValue: 1) == MCEncryptionPreference.required)
    precondition(MCEncryptionPreference(rawValue: 2) == MCEncryptionPreference.none)
    precondition(MCEncryptionPreference(rawValue: 99) == nil)
    precondition(MCEncryptionPreference.none != MCEncryptionPreference.optional)
    precondition(MCEncryptionPreference.optional.hashValue == MCEncryptionPreference.optional.hashValue)
    var encryptionHasher = Hasher()
    MCEncryptionPreference.required.hash(into: &encryptionHasher)
    _ = encryptionHasher.finalize()

    precondition(MCSessionSendDataMode.reliable.rawValue == 0)
    precondition(MCSessionSendDataMode.unreliable.rawValue == 1)
    precondition(MCSessionSendDataMode(rawValue: 0) == .reliable)
    precondition(MCSessionSendDataMode(rawValue: 1) == .unreliable)
    precondition(MCSessionSendDataMode(rawValue: -1) == nil)
    precondition(MCSessionSendDataMode.reliable != .unreliable)
    precondition(MCSessionSendDataMode.reliable.hashValue == MCSessionSendDataMode.reliable.hashValue)
    var sendModeHasher = Hasher()
    MCSessionSendDataMode.unreliable.hash(into: &sendModeHasher)
    _ = sendModeHasher.finalize()

    precondition(MCSessionState.notConnected.rawValue == 0)
    precondition(MCSessionState.connecting.rawValue == 1)
    precondition(MCSessionState.connected.rawValue == 2)
    precondition(MCSessionState(rawValue: 0) == .notConnected)
    precondition(MCSessionState(rawValue: 1) == .connecting)
    precondition(MCSessionState(rawValue: 2) == .connected)
    precondition(MCSessionState(rawValue: 3) == nil)
    precondition(MCSessionState.connected != .notConnected)
    precondition(MCSessionState.connecting.hashValue == MCSessionState.connecting.hashValue)
    var stateHasher = Hasher()
    MCSessionState.connected.hash(into: &stateHasher)
    _ = stateHasher.finalize()

    let codes: [(MCError.Code, Int)] = [
        (.unknown, 0),
        (.notConnected, 1),
        (.invalidParameter, 2),
        (.unsupported, 3),
        (.timedOut, 4),
        (.cancelled, 5),
        (.unavailable, 6),
    ]
    for (code, raw) in codes {
        precondition(code.rawValue == raw)
        precondition(MCError.Code(rawValue: raw) == code)
        precondition(MCError.Code(rawValue: raw) != nil)
    }
    precondition(MCError.Code(rawValue: 7) == nil)
    precondition(MCError.Code.unknown != .unavailable)
    precondition(MCError.Code.timedOut.hashValue == MCError.Code.timedOut.hashValue)
    var codeHasher = Hasher()
    MCError.Code.cancelled.hash(into: &codeHasher)
    _ = codeHasher.finalize()
}
