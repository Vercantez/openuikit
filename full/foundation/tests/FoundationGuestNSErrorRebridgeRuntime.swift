import Foundation

private enum RebridgeCustomError: Int, CustomNSError, LocalizedError {
    case denied = 17

    static let errorDomain = "OpenUIKit.Foundation.RebridgeCustom"

    var errorUserInfo: [String: Any] {
        ["kind": "typed", "attempt": 3]
    }

    var errorDescription: String? { "typed denial" }
}

private enum RebridgePlainError: Int, Error {
    case unavailable = 29
}

@inline(never)
private func bridgeErased(_ error: any Error) -> NSError {
    error as NSError
}

@main
private enum FoundationGuestNSErrorRebridgeRuntime {
    static func main() {
        let original = NSError(
            domain: "OpenUIKit.Foundation.Existing",
            code: 7,
            userInfo: ["kind": "existing", "attempt": 2]
        )
        let erased: any Error = original
        let preserved = bridgeErased(erased)
        precondition(preserved === original)
        precondition(preserved.domain == "OpenUIKit.Foundation.Existing")
        precondition(preserved.code == 7)
        precondition(preserved.userInfo["kind"] as? String == "existing")
        precondition(preserved.userInfo["attempt"] as? Int == 2)

        let custom = bridgeErased(RebridgeCustomError.denied)
        precondition(custom.domain == RebridgeCustomError.errorDomain)
        precondition(custom.code == 17)
        precondition(custom.userInfo["kind"] as? String == "typed")
        precondition(custom.userInfo["attempt"] as? Int == 3)
        precondition(custom.localizedDescription == "typed denial")

        let plain = bridgeErased(RebridgePlainError.unavailable)
        precondition(plain.domain.hasSuffix("RebridgePlainError"))
        precondition(plain.code == 29)

        print(
            "FOUNDATION_NSERROR_REBRIDGE_OK " +
            "existing=identity typed=custom-user-info plain=domain-code"
        )
    }
}
