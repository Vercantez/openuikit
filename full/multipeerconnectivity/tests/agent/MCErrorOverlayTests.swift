@_spi(OpenUIKitHost) import MultipeerConnectivity
import Foundation

func testMCErrorStructAndNSErrorBridging() {
    precondition(MCError.errorDomain == MCErrorDomain)
    precondition(MCError.unknown == .unknown)
    precondition(MCError.notConnected == .notConnected)
    precondition(MCError.invalidParameter == .invalidParameter)
    precondition(MCError.unsupported == .unsupported)
    precondition(MCError.timedOut == .timedOut)
    precondition(MCError.cancelled == .cancelled)
    precondition(MCError.unavailable == .unavailable)

    let typed = MCError(.unavailable, userInfo: ["k": "v"])
    precondition(typed.code == .unavailable)
    precondition(typed.errorCode == 6)
    precondition(typed.errorUserInfo["k"] as? String == "v")
    precondition(typed.userInfo["k"] as? String == "v")
    precondition(typed.localizedDescription.isEmpty == false)
    precondition(typed != MCError(.notConnected))
    precondition(typed == MCError(.unavailable, userInfo: ["k": "v"]))
    precondition(typed.hashValue == MCError(.unavailable, userInfo: ["other": 1]).hashValue)

    var hasher = Hasher()
    typed.hash(into: &hasher)
    _ = hasher.finalize()

    do {
        throw MCError(.unavailable)
    } catch {
        precondition(MCError.Code.unavailable ~= error)
        let nsError = error as NSError
        precondition(nsError.domain == MCErrorDomain)
        precondition(nsError.code == MCError.Code.unavailable.rawValue)
    }

    do {
        throw MCError(.notConnected)
    } catch {
        precondition(!(MCError.Code.unavailable ~= error))
        precondition(MCError.Code.notConnected ~= error)
    }
}
