import Foundation
import FoundationNetworking
import IdentityLookup

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then IdentityLookup with that `-I` / `-L`.
// The host gate does not compile this file.

func identityLookupDependencyIdentityProbe() {
    let data = Data("identity-lookup".utf8)
    let url = URL(string: "https://example.invalid/identity-lookup")!
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    precondition(type(of: data) == Data.self)
    precondition(type(of: url) == URL.self)
    precondition(type(of: date) == Date.self)
    precondition(!String(reflecting: type(of: data)).hasPrefix("IdentityLookup."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("IdentityLookup."))
    precondition(!String(reflecting: type(of: date)).hasPrefix("IdentityLookup."))

    let communication = ILMessageCommunication(
        sender: "+15555550199",
        dateReceived: date,
        messageBody: String(data: data, encoding: .utf8)
    )
    precondition(communication.dateReceived == date)
    precondition(communication.messageBody == "identity-lookup")

    let context = LiveCallerIDLookupExtensionContext(
        serviceURL: url,
        tokenIssuerURL: url,
        userTierToken: data
    )
    precondition(context.serviceURL == url)
    precondition(context.userTierToken == data)

    let response = HTTPURLResponse(
        url: url,
        statusCode: 200,
        httpVersion: "HTTP/1.1",
        headerFields: ["Content-Type": "application/octet-stream"]
    )!
    let network = ILNetworkResponse(urlResponse: response, data: data)
    precondition(network.data == data)
    precondition(network.urlResponse.url == url)
}

#if IDENTITYLOOKUP_IDENTITY_MAIN
identityLookupDependencyIdentityProbe()
print("IDENTITYLOOKUP_DEPENDENCY_IDENTITY_OK")
#endif
