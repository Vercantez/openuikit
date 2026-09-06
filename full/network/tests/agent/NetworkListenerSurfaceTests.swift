import Foundation
import Network

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testListenerGroupAndRegistrationHandlers() {
    let listener = try! NWListener(using: .tcp, on: .any)
    var groupSeen = false
    listener.newConnectionGroupHandler = { _ in groupSeen = true }
    var registrationSeen = false
    listener.serviceRegistrationUpdateHandler = { _ in registrationSeen = true }
    listener.newConnectionGroupHandler?(
        NWConnectionGroup(with: NWMultiplexGroup(with: .unix(path: "/tmp/x")), using: .tcp)
    )
    listener.serviceRegistrationUpdateHandler?(.add(.unix(path: "/tmp/x")))
    expect(groupSeen, "newConnectionGroupHandler")
    expect(registrationSeen, "serviceRegistrationUpdateHandler")
    listener.cancel()
}
