import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testEnumOptionSetAndConstantValues() {
    carPlayCheckEnum([
        CPAlertAction.Style.cancel,
        CPAlertAction.Style.default,
        CPAlertAction.Style.destructive,
    ])
    carPlayCheckEnum([
        CPAssistantCellActionType.playMedia,
        CPAssistantCellActionType.startCall,
    ])
    let barButtonTypes: [CPBarButton.`Type`] = [
        .image,
        .text,
    ]
    carPlayCheckEnum(barButtonTypes)
    carPlayCheckEnum([
        CPBarButtonStyle.none,
        CPBarButtonStyle.rounded,
    ])
    carPlayCheckEnum([
        CPInformationTemplateLayout.leading,
        CPInformationTemplateLayout.twoColumn,
    ])
    carPlayCheckEnum([
        CPInstrumentClusterSetting.disabled,
        CPInstrumentClusterSetting.enabled,
        CPInstrumentClusterSetting.unspecified,
        CPInstrumentClusterSetting.userPreference,
    ])
    carPlayCheckEnum([
        CPJunctionType.intersection,
        CPJunctionType.roundabout,
    ])
    carPlayCheckEnum([
        CPLaneStatus.good,
        CPLaneStatus.notGood,
        CPLaneStatus.preferred,
    ])
    carPlayCheckEnum([
        CPListImageRowItemCondensedElement.Shape.circular,
        CPListImageRowItemCondensedElement.Shape.roundedRectangle,
    ])
    carPlayCheckEnum([
        CPListImageRowItemImageGridElement.Shape.circular,
        CPListImageRowItemImageGridElement.Shape.roundedRectangle,
    ])
    carPlayCheckEnum([
        CPListItem.AssistantCellPosition.bottom,
        CPListItem.AssistantCellPosition.top,
    ])
    carPlayCheckEnum([
        CPListItem.AssistantCellVisibility.always,
        CPListItem.AssistantCellVisibility.off,
        CPListItem.AssistantCellVisibility.whileLimitedUIActive,
    ])
    carPlayCheckEnum([
        CPListItemAccessoryType.cloud,
        CPListItemAccessoryType.disclosureIndicator,
        CPListItemAccessoryType.none,
    ])
    carPlayCheckEnum([
        CPListItemPlayingIndicatorLocation.leading,
        CPListItemPlayingIndicatorLocation.trailing,
    ])
    carPlayCheckEnum([
        CPManeuverState.continue,
        CPManeuverState.execute,
        CPManeuverState.initial,
        CPManeuverState.prepare,
    ])
    carPlayCheckEnum([
        CPManeuverType.arriveAtDestination,
        CPManeuverType.arriveAtDestinationLeft,
        CPManeuverType.arriveAtDestinationRight,
        CPManeuverType.arriveEndOfDirections,
        CPManeuverType.arriveEndOfNavigation,
        CPManeuverType.changeFerry,
        CPManeuverType.changeHighway,
        CPManeuverType.changeHighwayLeft,
        CPManeuverType.changeHighwayRight,
        CPManeuverType.enterRoundabout,
        CPManeuverType.enter_Ferry,
        CPManeuverType.exitFerry,
        CPManeuverType.exitRoundabout,
        CPManeuverType.followRoad,
        CPManeuverType.highwayOffRampLeft,
        CPManeuverType.highwayOffRampRight,
        CPManeuverType.keepLeft,
        CPManeuverType.keepRight,
        CPManeuverType.leftTurn,
        CPManeuverType.leftTurnAtEnd,
        CPManeuverType.noTurn,
        CPManeuverType.offRamp,
        CPManeuverType.onRamp,
        CPManeuverType.rightTurn,
        CPManeuverType.rightTurnAtEnd,
        CPManeuverType.roundaboutExit1,
        CPManeuverType.roundaboutExit2,
        CPManeuverType.roundaboutExit3,
        CPManeuverType.roundaboutExit4,
        CPManeuverType.roundaboutExit5,
        CPManeuverType.roundaboutExit6,
        CPManeuverType.roundaboutExit7,
        CPManeuverType.roundaboutExit8,
        CPManeuverType.roundaboutExit9,
        CPManeuverType.roundaboutExit10,
        CPManeuverType.roundaboutExit11,
        CPManeuverType.roundaboutExit12,
        CPManeuverType.roundaboutExit13,
        CPManeuverType.roundaboutExit14,
        CPManeuverType.roundaboutExit15,
        CPManeuverType.roundaboutExit16,
        CPManeuverType.roundaboutExit17,
        CPManeuverType.roundaboutExit18,
        CPManeuverType.roundaboutExit19,
        CPManeuverType.sharpLeftTurn,
        CPManeuverType.sharpRightTurn,
        CPManeuverType.slightLeftTurn,
        CPManeuverType.slightRightTurn,
        CPManeuverType.startRoute,
        CPManeuverType.startRouteWithUTurn,
        CPManeuverType.straightAhead,
        CPManeuverType.uTurn,
        CPManeuverType.uTurnAtRoundabout,
        CPManeuverType.uTurnWhenPossible,
    ])
    carPlayCheckEnum([
        CPMessageLeadingItem.none,
        CPMessageLeadingItem.pin,
        CPMessageLeadingItem.star,
    ])
    carPlayCheckEnum([
        CPMessageTrailingItem.mute,
        CPMessageTrailingItem.none,
    ])
    carPlayCheckEnum([
        CPNavigationAlert.DismissalContext.systemDismissed,
        CPNavigationAlert.DismissalContext.timeout,
        CPNavigationAlert.DismissalContext.userDismissed,
    ])
    carPlayCheckEnum([
        CPNavigationSession.PauseReason.arrived,
        CPNavigationSession.PauseReason.loading,
        CPNavigationSession.PauseReason.locating,
        CPNavigationSession.PauseReason.proceedToRoute,
        CPNavigationSession.PauseReason.rerouting,
    ])
    carPlayCheckEnum([
        CPTextButtonStyle.cancel,
        CPTextButtonStyle.confirm,
        CPTextButtonStyle.normal,
    ])
    carPlayCheckEnum([
        CPTimeRemainingColor.default,
        CPTimeRemainingColor.green,
        CPTimeRemainingColor.orange,
        CPTimeRemainingColor.red,
    ])
    carPlayCheckEnum([
        CPTrafficSide.left,
        CPTrafficSide.right,
    ])
    carPlayCheckEnum([
        CPTripEstimateStyle.dark,
        CPTripEstimateStyle.light,
    ])

    carPlayExerciseOptionSet(CPContentStyle.light, CPContentStyle.dark)
    carPlayExerciseOptionSet(CPLimitableUserInterface.keyboard, CPLimitableUserInterface.lists)
    carPlayExerciseOptionSet(CPManeuverDisplayStyle.leadingSymbol, CPManeuverDisplayStyle.trailingSymbol)
    carPlayExerciseOptionSet(CPMapTemplate.PanDirection.left, CPMapTemplate.PanDirection.right)
    _ = CPManeuverDisplayStyle.symbolOnly
    _ = CPManeuverDisplayStyle.instructionOnly
    _ = CPMapTemplate.PanDirection.up
    _ = CPMapTemplate.PanDirection.down
    precondition(CPContentStyle.light.rawValue == 1)
    precondition(CPContentStyle.dark.rawValue == 2)

    precondition(CarPlayErrorDomain == "CarPlayErrorDomain")
    precondition(CPGridTemplateMaximumItems == 8)
    precondition(CPMaximumNumberOfGridImages == 9)
    precondition(CPNavigationAlertMinimumDuration == 5)
    precondition(CPButtonMaximumImageSize.width == 80)
    precondition(CPMaximumListSectionImageSize.width == 90)
    precondition(CPMaximumMessageItemImageSize.height == 90)
    precondition(CPMaximumMessageItemLeadingDetailTextImageSize.width == 90)
    precondition(CPNowPlayingButtonMaximumImageSize.height == 80)
}

func testNSStringFromCarPlayEnums() {
    let junction = NSStringFromCPJunctionType(.intersection)!
    let lane = NSStringFromCPLaneStatus(.preferred)!
    let maneuverName = NSStringFromCPManeuverType(.uTurn)!
    let traffic = NSStringFromCPTrafficSide(.left)!
    precondition(Set([junction, lane, maneuverName, traffic]).count == 4)
}
