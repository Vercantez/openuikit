import Foundation

public enum CPAssistantCellActionType: Int, Equatable, Hashable, Sendable {
    case playMedia = 0
    case startCall = 1
}

public enum CPBarButtonStyle: UInt, Equatable, Hashable, Sendable {
    case none = 0
    case rounded = 1
}

public enum CPInformationTemplateLayout: Int, Equatable, Hashable, Sendable {
    case leading = 0
    case twoColumn = 1
}

public enum CPInstrumentClusterSetting: UInt, Equatable, Hashable, Sendable {
    case unspecified = 0
    case enabled = 1
    case disabled = 2
    case userPreference = 3
}

public enum CPJunctionType: Int, Equatable, Hashable, Sendable {
    case intersection = 0
    case roundabout = 1
}

public enum CPLaneStatus: Int, Equatable, Hashable, Sendable {
    case notGood = 0
    case good = 1
    case preferred = 2
}

public enum CPListItemAccessoryType: Int, Equatable, Hashable, Sendable {
    case none = 0
    case cloud = 1
    case disclosureIndicator = 2
}

public enum CPListItemPlayingIndicatorLocation: Int, Equatable, Hashable, Sendable {
    case leading = 0
    case trailing = 1
}

public enum CPManeuverState: Int, Equatable, Hashable, Sendable {
    case `continue` = 0
    case initial = 1
    case prepare = 2
    case execute = 3
}

public enum CPManeuverType: Int, Equatable, Hashable, Sendable {
    case noTurn = 0
    case leftTurn = 1
    case rightTurn = 2
    case straightAhead = 3
    case uTurn = 4
    case followRoad = 5
    case enterRoundabout = 6
    case exitRoundabout = 7
    case offRamp = 8
    case onRamp = 9
    case arriveEndOfNavigation = 10
    case startRoute = 11
    case arriveAtDestination = 12
    case keepLeft = 13
    case keepRight = 14
    case enter_Ferry = 15
    case exitFerry = 16
    case changeFerry = 17
    case startRouteWithUTurn = 18
    case uTurnAtRoundabout = 19
    case leftTurnAtEnd = 20
    case rightTurnAtEnd = 21
    case highwayOffRampLeft = 22
    case highwayOffRampRight = 23
    case arriveAtDestinationLeft = 24
    case arriveAtDestinationRight = 25
    case uTurnWhenPossible = 26
    case arriveEndOfDirections = 27
    case roundaboutExit1 = 28
    case roundaboutExit2 = 29
    case roundaboutExit3 = 30
    case roundaboutExit4 = 31
    case roundaboutExit5 = 32
    case roundaboutExit6 = 33
    case roundaboutExit7 = 34
    case roundaboutExit8 = 35
    case roundaboutExit9 = 36
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
    case sharpLeftTurn = 47
    case sharpRightTurn = 48
    case slightLeftTurn = 49
    case slightRightTurn = 50
    case changeHighway = 51
    case changeHighwayLeft = 52
    case changeHighwayRight = 53
}

public enum CPMessageLeadingItem: Int, Equatable, Hashable, Sendable {
    case none = 0
    case pin = 1
    case star = 2
}

public enum CPMessageTrailingItem: Int, Equatable, Hashable, Sendable {
    case none = 0
    case mute = 1
}

public enum CPTextButtonStyle: UInt, Equatable, Hashable, Sendable {
    case normal = 0
    case cancel = 1
    case confirm = 2
}

public enum CPTimeRemainingColor: UInt, Equatable, Hashable, Sendable {
    case `default` = 0
    case green = 1
    case orange = 2
    case red = 3
}

public enum CPTrafficSide: Int, Equatable, Hashable, Sendable {
    case right = 0
    case left = 1
}

public enum CPTripEstimateStyle: UInt, Equatable, Hashable, Sendable {
    case light = 0
    case dark = 1
}

public func NSStringFromCPJunctionType(_ junctionType: CPJunctionType) -> String {
    switch junctionType {
    case .intersection: return "CPJunctionTypeIntersection"
    case .roundabout: return "CPJunctionTypeRoundabout"
    }
}

public func NSStringFromCPLaneStatus(_ laneStatus: CPLaneStatus) -> String {
    switch laneStatus {
    case .notGood: return "CPLaneStatusNotGood"
    case .good: return "CPLaneStatusGood"
    case .preferred: return "CPLaneStatusPreferred"
    }
}

public func NSStringFromCPManeuverType(_ maneuverType: CPManeuverType) -> String {
    String(describing: maneuverType)
}

public func NSStringFromCPTrafficSide(_ trafficSide: CPTrafficSide) -> String {
    switch trafficSide {
    case .right: return "CPTrafficSideRight"
    case .left: return "CPTrafficSideLeft"
    }
}
