@_spi(OpenUIKitHost) import ExtensionFoundation

private struct RejectingConfiguration: AppExtensionConfiguration {
    func accept(connection: NSXPCConnection) -> Bool {
        _ = connection
        return false
    }
}

private struct ProbeExtension: AppExtension {
    typealias Configuration = RejectingConfiguration

    var configuration: RejectingConfiguration {
        RejectingConfiguration()
    }

    init() {}
}

private struct AcceptingExtension: AppExtension {
    var configuration: ConnectionHandler {
        ConnectionHandler(onConnection: { _ in true })
    }

    init() {}
}

func testAppExtensionInitAndConfiguration() {
    let probe = ProbeExtension()
    precondition(probe.configuration.accept(connection: NSXPCConnection()) == false)
}

func testAppExtensionAssociatedConfigurationType() {
    let sample = ProbeExtension()
    func typeName<T>(_ value: T) -> String {
        String(describing: T.self)
    }
    precondition(typeName(sample.configuration) == "RejectingConfiguration")
}

func testAppExtensionMainThrows() {
    do {
        try ProbeExtension.main()
        preconditionFailure("main must throw")
    } catch let error as ExtensionFoundationHostError {
        precondition(error == .extensionProcessUnavailable)
        precondition(error.errorCode == 1)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAppExtensionWithConnectionHandlerConfiguration() {
    let ext = AcceptingExtension()
    precondition(ext.configuration.accept(connection: NSXPCConnection()) == true)
    precondition(ext.configuration.host_usesConnectionHandler == true)
    precondition(ext.configuration.host_usesSessionHandler == false)
}

func testConnectionHandlerHostSessionDecision() {
    let handler = ConnectionHandler(onSessionRequest: { request in
        _ = request
        return XPCListener.IncomingSessionRequest.Decision()
    })
    precondition(handler.host_usesSessionHandler == true)
    let decision = handler.host_decideSession(XPCListener.IncomingSessionRequest())
    precondition(decision != nil)
}

func testAppExtensionConfigurationProtocolWitness() {
    let configuration: any AppExtensionConfiguration = RejectingConfiguration()
    precondition(configuration.accept(connection: NSXPCConnection()) == false)
}
