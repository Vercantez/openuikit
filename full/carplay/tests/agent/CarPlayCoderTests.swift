import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testCoderInitsReturnNil() {
    carPlayOnMain {
        let coder = carPlayFailClosedCoder()
        precondition(CPAlertAction(coder: coder) == nil)
        precondition(CPAssistantCellConfiguration(coder: coder) == nil)
        precondition(CPBarButton(coder: coder) == nil)
        precondition(CPContact(coder: coder) == nil)
        precondition(CPDashboardButton(coder: coder) == nil)
        precondition(CPGridButton(coder: coder) == nil)
        precondition(CPImageSet(coder: coder) == nil)
        precondition(CPInformationItem(coder: coder) == nil)
        precondition(CPLane(coder: coder) == nil)
        precondition(CPLaneGuidance(coder: coder) == nil)
        precondition(CPListSection(coder: coder) == nil)
        precondition(CPManeuver(coder: coder) == nil)
        precondition(CPMapButton(coder: coder) == nil)
        precondition(CPNavigationAlert(coder: coder) == nil)
        precondition(CPNowPlayingButton(coder: coder) == nil)
        precondition(CPNowPlayingMode(coder: coder) == nil)
        precondition(CPNowPlayingSportsClock(coder: coder) == nil)
        precondition(CPNowPlayingSportsEventStatus(coder: coder) == nil)
        precondition(CPNowPlayingSportsTeam(coder: coder) == nil)
        precondition(CPNowPlayingSportsTeamLogo(coder: coder) == nil)
        precondition(CPPointOfInterest(coder: coder) == nil)
        precondition(CPRouteChoice(coder: coder) == nil)
        precondition(CPTemplate(coder: coder) == nil)
        precondition(CPTravelEstimates(coder: coder) == nil)
        precondition(CPTrip(coder: coder) == nil)
        precondition(CPTripPreviewTextConfiguration(coder: coder) == nil)
        precondition(CPVoiceControlState(coder: coder) == nil)
    }
}
