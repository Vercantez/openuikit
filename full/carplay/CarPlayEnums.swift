import Foundation

public enum CPAssistantCellActionType: Int, Sendable, Hashable {
    case playMedia = 0
    case startCall = 1
}


public enum CPBarButtonStyle: Int, Sendable, Hashable {
    case none = 0
    case rounded = 1
}


public enum CPInformationTemplateLayout: Int, Sendable, Hashable {
    case leading = 0
    case twoColumn = 1
}


public enum CPInstrumentClusterSetting: Int, Sendable, Hashable {
    case disabled = 2
    case enabled = 1
    case unspecified = 0
    case userPreference = 3
}


public enum CPJunctionType: Int, Sendable, Hashable {
    case intersection = 0
    case roundabout = 1
}


public enum CPLaneStatus: Int, Sendable, Hashable {
    case good = 1
    case notGood = 0
    case preferred = 2
}


public enum CPListItemAccessoryType: Int, Sendable, Hashable {
    case cloud = 2
    case disclosureIndicator = 1
    case none = 0
}


public enum CPListItemPlayingIndicatorLocation: Int, Sendable, Hashable {
    case leading = 0
    case trailing = 1
}


public enum CPManeuverState: Int, Sendable, Hashable {
    case `continue` = 0
    case execute = 3
    case initial = 1
    case prepare = 2
}


public enum CPManeuverType: Int, Sendable, Hashable {
    case arriveAtDestination = 12
    case arriveAtDestinationLeft = 24
    case arriveAtDestinationRight = 25
    case arriveEndOfDirections = 27
    case arriveEndOfNavigation = 10
    case changeFerry = 17
    case changeHighway = 51
    case changeHighwayLeft = 52
    case changeHighwayRight = 53
    case enterRoundabout = 6
    case enter_Ferry = 15
    case exitFerry = 16
    case exitRoundabout = 7
    case followRoad = 5
    case highwayOffRampLeft = 22
    case highwayOffRampRight = 23
    case keepLeft = 13
    case keepRight = 14
    case leftTurn = 1
    case leftTurnAtEnd = 20
    case noTurn = 0
    case offRamp = 8
    case onRamp = 9
    case rightTurn = 2
    case rightTurnAtEnd = 21
    case roundaboutExit1 = 28
    case roundaboutExit10 = 37
    case roundaboutExit11 = 38
    case roundaboutExit12 = 39
    case roundaboutExit13 = 40
    case roundaboutExit14 = 41
    case roundaboutExit15 = 42
    case roundaboutExit16 = 43
    case roundaboutExit17 = 44
    case roundaboutExit18 = 45
    case roundaboutExit19 = 46
    case roundaboutExit2 = 29
    case roundaboutExit3 = 30
    case roundaboutExit4 = 31
    case roundaboutExit5 = 32
    case roundaboutExit6 = 33
    case roundaboutExit7 = 34
    case roundaboutExit8 = 35
    case roundaboutExit9 = 36
    case sharpLeftTurn = 47
    case sharpRightTurn = 48
    case slightLeftTurn = 49
    case slightRightTurn = 50
    case startRoute = 11
    case startRouteWithUTurn = 18
    case straightAhead = 3
    case uTurn = 4
    case uTurnAtRoundabout = 19
    case uTurnWhenPossible = 26
}


public enum CPMessageLeadingItem: Int, Sendable, Hashable {
    case none = 0
    case pin = 1
    case star = 2
}


public enum CPMessageTrailingItem: Int, Sendable, Hashable {
    case mute = 1
    case none = 0
}


public enum CPTextButtonStyle: Int, Sendable, Hashable {
    case cancel = 1
    case confirm = 2
    case normal = 0
}


public enum CPTimeRemainingColor: Int, Sendable, Hashable {
    case `default` = 0
    case green = 1
    case orange = 2
    case red = 3
}


public enum CPTrafficSide: Int, Sendable, Hashable {
    case left = 1
    case right = 0
}


public enum CPTripEstimateStyle: Int, Sendable, Hashable {
    case dark = 1
    case light = 0
}


public struct CPContentStyle: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let light = CPContentStyle(rawValue: 1)
    public static let dark = CPContentStyle(rawValue: 2)
}


public struct CPLimitableUserInterface: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let keyboard = CPLimitableUserInterface(rawValue: 1)
    public static let lists = CPLimitableUserInterface(rawValue: 2)
}


public struct CPManeuverDisplayStyle: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let leadingSymbol = CPManeuverDisplayStyle(rawValue: 1)
    public static let trailingSymbol = CPManeuverDisplayStyle(rawValue: 2)
    public static let symbolOnly = CPManeuverDisplayStyle(rawValue: 3)
    public static let instructionOnly = CPManeuverDisplayStyle(rawValue: 4)
}


