import Foundation

open class GKGameSession: NSObject {
    public internal(set) var identifier: String = ""
    public internal(set) var title: String = ""
    public internal(set) var lastModifiedDate: Date = Date()
    public internal(set) var lastModifiedPlayer: GKCloudPlayer = GKCloudPlayer()
    public internal(set) var maxNumberOfConnectedPlayers: Int = 0
    public internal(set) var owner: GKCloudPlayer = GKCloudPlayer()
    public internal(set) var players: [GKCloudPlayer] = []
    public internal(set) var badgedPlayers: [GKCloudPlayer] = []

    private static var listeners: [ObjectIdentifier: any GKGameSessionEventListener] = [:]

    public class func add(listener: any GKGameSessionEventListener) {
        listeners[ObjectIdentifier(listener as AnyObject)] = listener
    }

    public class func remove(listener: any GKGameSessionEventListener) {
        listeners.removeValue(forKey: ObjectIdentifier(listener as AnyObject))
    }

    public class var registeredListenerCount: Int { listeners.count }

    public func players(with state: GKConnectionState) -> [GKCloudPlayer] {
        _ = state
        return []
    }

    public func getShareURL(completionHandler: @escaping (URL?, (any Error)?) -> Void) {
        GameKitHost.failSession(completionHandler)
    }

    public func loadData(completionHandler: @escaping (Data?, (any Error)?) -> Void) {
        GameKitHost.failSession(completionHandler)
    }

    public func save(_ data: Data, completionHandler: @escaping (Data?, (any Error)?) -> Void) {
        _ = data
        GameKitHost.failSession(completionHandler)
    }

    public class func createSession(
        inContainer containerName: String?,
        withTitle title: String,
        maxConnectedPlayers maxPlayers: Int
    ) async throws -> GKGameSession {
        _ = (containerName, title, maxPlayers)
        throw GameKitHost.sessionError()
    }

    public class func load(withIdentifier identifier: String) async throws -> GKGameSession {
        _ = identifier
        throw GameKitHost.sessionError(.invalidSession)
    }

    public class func loadSessions(inContainer containerName: String?) async throws -> [GKGameSession] {
        _ = containerName
        throw GameKitHost.sessionError()
    }

    public class func remove(withIdentifier identifier: String) async throws {
        _ = identifier
        throw GameKitHost.sessionError(.invalidSession)
    }

    public func clearBadge(for players: [GKCloudPlayer]) async throws {
        _ = players
        throw GameKitHost.sessionError()
    }

    public func send(_ data: Data, with transport: GKTransportType) async throws {
        _ = (data, transport)
        throw GameKitHost.sessionError(.sendDataNotConnected)
    }

    public func sendMessage(
        withLocalizedFormatKey key: String,
        arguments: [String],
        data: Data?,
        to players: [GKCloudPlayer],
        badgePlayers: Bool
    ) async throws {
        _ = (key, arguments, data, players, badgePlayers)
        throw GameKitHost.sessionError(.sendDataNotConnected)
    }

    public func setConnectionState(_ state: GKConnectionState) async throws {
        _ = state
        throw GameKitHost.sessionError()
    }
}

open class GKSavedGame: NSObject {
    public internal(set) var deviceName: String?
    public internal(set) var modificationDate: Date?
    public internal(set) var name: String?

    public func loadData(completionHandler handler: ((Data?, (any Error)?) -> Void)? = nil) {
        GameKitHost.fail(handler)
    }
}
