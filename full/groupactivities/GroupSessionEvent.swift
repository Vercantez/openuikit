import Foundation

/// System-facing notice describing a session action.
public struct GroupSessionEvent: Equatable, Sendable {
    public struct Action: Equatable, Sendable {
        enum Kind: Equatable, Sendable {
            case play
            case pause
            case seek
            case skip(String)
            case updatedQueue
            case updatedQueueChange(QueueChange)
        }

        let kind: Kind

        public struct QueueChange: Equatable, Sendable {
            public struct Item: Equatable, Sendable {
                enum Kind: Equatable, Sendable {
                    case song(String)
                    case container(String)
                }

                let kind: Kind

                public static func song(_ name: String) -> Item {
                    Item(kind: .song(name))
                }

                public static func container(_ name: String) -> Item {
                    Item(kind: .container(name))
                }
            }

            enum Kind: Equatable, Sendable {
                case added(Item)
                case setUpNext(Item)
            }

            let kind: Kind

            public static func added(_ item: Item) -> QueueChange {
                QueueChange(kind: .added(item))
            }

            public static func setUpNext(_ item: Item) -> QueueChange {
                QueueChange(kind: .setUpNext(item))
            }
        }

        public static let play = Action(kind: .play)
        public static let pause = Action(kind: .pause)
        public static let seek = Action(kind: .seek)
        public static let updatedQueue = Action(kind: .updatedQueue)

        public static func skip(item: String) -> Action {
            Action(kind: .skip(item))
        }

        public static func updatedQueue(_ change: QueueChange) -> Action {
            Action(kind: .updatedQueueChange(change))
        }
    }

    public let originator: Participant
    public let action: Action
    public let url: URL?

    public init(originator: Participant, action: Action, url: URL?) {
        self.originator = originator
        self.action = action
        self.url = url
    }
}
