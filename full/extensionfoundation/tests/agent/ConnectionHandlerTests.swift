import ExtensionFoundation

func testConnectionHandlerOnConnectionAccepts() {
    let handler = ConnectionHandler(onConnection: { connection in
        _ = connection
        return true
    })
    let connection = NSXPCConnection(serviceName: "com.example.host")
    precondition(handler.accept(connection: connection) == true)
}

func testConnectionHandlerOnConnectionRejects() {
    let handler = ConnectionHandler(onConnection: { _ in false })
    precondition(handler.accept(connection: NSXPCConnection()) == false)
}

func testConnectionHandlerSeesTheConnection() {
    final class Box: @unchecked Sendable {
        var name: String?
    }
    let box = Box()
    let handler = ConnectionHandler(onConnection: { connection in
        box.name = connection.serviceName
        return true
    })
    _ = handler.accept(connection: NSXPCConnection(serviceName: "seen.service"))
    precondition(box.name == "seen.service")
}

func testConnectionHandlerSessionRequestDoesNotAcceptNSXPC() {
    let handler = ConnectionHandler(onSessionRequest: { _ in
        XPCListener.IncomingSessionRequest.Decision()
    })
    precondition(handler.accept(connection: NSXPCConnection()) == false)
}
