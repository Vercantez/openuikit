import Foundation

// In-process MIDI Network session. Contacts and connections are stored locally.
// Enabling the session does not advertise Bonjour or claim Apple MIDINetworkDriver success.

public final class MIDINetworkHost: NSObject {
    public let name: String
    public let address: String
    public let port: UInt
    public let netServiceName: String?
    public let netServiceDomain: String?

    public convenience init(name: String, address: String, port: UInt) {
        self.init(name: name, address: address, port: port, netServiceName: nil, netServiceDomain: nil)
    }

    public convenience init(name: String, netServiceName: String, netServiceDomain: String) {
        self.init(name: name, address: "", port: 0, netServiceName: netServiceName, netServiceDomain: netServiceDomain)
    }

    public convenience init(name: String, netService: NetService) {
        self.init(name: name, address: "", port: 0, netServiceName: netService.name, netServiceDomain: netService.domain)
    }

    private init(name: String, address: String, port: UInt, netServiceName: String?, netServiceDomain: String?) {
        self.name = name
        self.address = address
        self.port = port
        self.netServiceName = netServiceName
        self.netServiceDomain = netServiceDomain
        super.init()
    }

    public func hasSameAddress(as other: MIDINetworkHost) -> Bool {
        if let left = netServiceName, let right = other.netServiceName {
            return left == right && netServiceDomain == other.netServiceDomain
        }
        return address == other.address && port == other.port
    }
}

public final class MIDINetworkConnection: NSObject {
    public let host: MIDINetworkHost
    public convenience init(host: MIDINetworkHost) {
        self.init(storedHost: host)
    }
    private init(storedHost: MIDINetworkHost) {
        self.host = storedHost
        super.init()
    }
}

public final class MIDINetworkSession: NSObject {
    public var isEnabled: Bool = false
    public var connectionPolicy: MIDINetworkConnectionPolicy = .noOne
    public var localName: String { "OpenUIKit-CoreMIDI" }
    public var networkName: String { isEnabled ? localName : "" }
    public var networkPort: UInt { isEnabled ? 5004 : 0 }

    private var storedContacts: Set<MIDINetworkHost> = []
    private var storedConnections: Set<MIDINetworkConnection> = []

    private static let sharedSession = MIDINetworkSession()
    public class func `default`() -> MIDINetworkSession { sharedSession }

    public func contacts() -> Set<MIDINetworkHost> { storedContacts }
    public func connections() -> Set<MIDINetworkConnection> { storedConnections }

    public func addContact(_ contact: MIDINetworkHost) -> Bool {
        let inserted = storedContacts.insert(contact).inserted
        return inserted
    }

    public func removeContact(_ contact: MIDINetworkHost) -> Bool {
        storedContacts.remove(contact) != nil
    }

    public func addConnection(_ connection: MIDINetworkConnection) -> Bool {
        storedConnections.insert(connection).inserted
    }

    public func removeConnection(_ connection: MIDINetworkConnection) -> Bool {
        storedConnections.remove(connection) != nil
    }

    public func sourceEndpoint() -> MIDIEndpointRef { 0 }
    public func destinationEndpoint() -> MIDIEndpointRef { 0 }
}
