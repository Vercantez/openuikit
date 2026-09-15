import Foundation
import Network

private func storageExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testProxyConfigurationDomainStorage() {
    var proxy = ProxyConfiguration()
    storageExpect(proxy.matchDomains.isEmpty, "matchDomains default empty")
    storageExpect(proxy.excludedDomains.isEmpty, "excludedDomains default empty")
    storageExpect(proxy.allowFailover == false, "allowFailover default false")
    proxy.matchDomains = ["example.com"]
    proxy.excludedDomains = ["internal.example.com"]
    proxy.allowFailover = true
    storageExpect(proxy.matchDomains == ["example.com"], "matchDomains round-trip")
    storageExpect(proxy.excludedDomains == ["internal.example.com"], "excludedDomains round-trip")
    storageExpect(proxy.allowFailover == true, "allowFailover round-trip")
    proxy.applyCredential(username: "user", password: "secret")
    storageExpect(proxy.credentialUsername == "user", "credential username stored")
    storageExpect(proxy.credentialPassword == "secret", "credential password stored")
}

func testConnectionGroupMessageExtractAndReply() {
    let message = NWConnectionGroup.Message.default
    storageExpect(message.extractConnection() == nil, "extractConnection fail-closed nil")
    message.reply(content: nil)
    message.reply(content: Data([1, 2, 3]), message: .default)
}

func testConnectionGroupReceiveHandlerAndReinsert() {
    let group = NWConnectionGroup(
        with: NWMultiplexGroup(with: .unix(path: "/tmp/openuikit-storage.sock")),
        using: .udp
    )
    var seen: (NWConnectionGroup.Message, Data?, Bool)?
    group.setReceiveHandler(handler: { message, data, complete in
        seen = (message, data, complete)
    })
    group.setReceiveHandler(maximumMessageSize: 1024, rejectOversizedMessages: false, handler: nil)
    storageExpect(seen == nil, "fail-closed group never drives the handler")
    let extracted = group.extract(connectionTo: nil, using: nil)
    storageExpect(extracted == nil, "extract fail-closed nil")
    let connection = NWConnection(to: .unix(path: "/tmp/x"), using: .udp)
    storageExpect(group.reinsert(connection: connection) == false, "reinsert fail-closed false")
}

func testFramerImplementationLabel() {
    storageExpect(
        LengthPrefixedHostFramerImplementation.label.contains("LengthPrefixedHostFramerImplementation"),
        "host framer label"
    )
    storageExpect(
        NWProtocolFramer.Definition(implementation: LengthPrefixedHostFramerImplementation.self)
            .implementation.label.contains("LengthPrefixedHostFramerImplementation"),
        "definition implementation label"
    )
}
