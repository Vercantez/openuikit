// Generated typealiases and Swift overlay enums.

public enum INMediaDestination: Hashable, Sendable {
    case library
    case playlist(String)

    public var playlistName: String? {
        if case .playlist(let name) = self { return name }
        return nil
    }

    public var description: String {
        switch self {
        case .library: return "library"
        case .playlist(let name): return "playlist:\(name)"
        }
    }

    public var debugDescription: String { description }

    public typealias ReferenceType = INMediaDestinationReference
}

extension INShortcut { public typealias ReferenceType = INShortcutReference }

public typealias INDailyRoutineSituation = INDailyRoutineRelevanceProvider.Situation
