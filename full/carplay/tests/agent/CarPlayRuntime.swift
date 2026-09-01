@_spi(OpenUIKitHost) import CarPlay
import Foundation

@MainActor
enum CarPlayRuntimeProbe {
    static func run() {
        precondition(CarPlayErrorDomain == "CarPlayErrorDomain")
        precondition(CPGridTemplateMaximumItems == 8)
        precondition(CPMaximumNumberOfGridImages == 9)
        precondition(CPNavigationAlertMinimumDuration == 5)
        precondition(CPButtonMaximumImageSize.width == 44)
        precondition(CarPlayPortable.supportsVehicleSession == false)
        precondition(CarPlayPortable.hasTemplateEntitlement == false)

        let light = CPContentStyle.light
        let dark = CPContentStyle.dark
        precondition(light.contains(.light))
        precondition(!light.contains(.dark))
        precondition(light.union(dark) == [.light, .dark])
        precondition(CPLimitableUserInterface.keyboard.contains(.keyboard))
        precondition(CPManeuverDisplayStyle.leadingSymbol.contains(.leadingSymbol))

        precondition(CPAlertAction.Style.cancel != .destructive)
        precondition(CPManeuverType.leftTurn != .rightTurn)
        precondition(NSStringFromCPJunctionType(.roundabout) == "CPJunctionTypeRoundabout")
        precondition(NSStringFromCPLaneStatus(.preferred) == "CPLaneStatusPreferred")
        precondition(NSStringFromCPTrafficSide(.left) == "CPTrafficSideLeft")
        _ = NSStringFromCPManeuverType(.keepLeft)

        let image = UIImage(portableName: "list-item")
        let item = CPListItem(
            text: "Living Room",
            detailText: "On",
            image: image,
            showsDisclosureIndicator: true
        )
        item.setDetailText("Off")
        item.isPlaying = true
        item.playbackProgress = 0.25
        precondition(item.showsDisclosureIndicator)
        precondition(item.detailText == "Off")
        precondition(CPListItem.maximumImageSize.width == 90)

        var selected = false
        item.handler = { selectable, completion in
            selected = true
            precondition(selectable === item)
            completion()
        }
        item.portableSelect()
        precondition(selected)

        let section = CPListSection(
            items: [item],
            header: "Areas",
            sectionIndexTitle: "A"
        )
        precondition(section.items.count == 1)
        precondition(section.index(of: item) == 0)

        let list = CPListTemplate(title: "Home", sections: [section])
        precondition(list.itemCount == 1)
        precondition(list.sectionCount == 1)
        precondition(list.indexPath(for: item) == IndexPath(indexes: [0, 0]))
        precondition(CPListTemplate.maximumItemCount == 12)
        precondition(CPListTemplate.maximumSectionCount == 12)

        let gridButton = CPGridButton(
            titleVariants: ["Play"],
            image: image
        ) { button in
            button.updateTitleVariants(["Playing"])
        }
        gridButton.portableInvoke()
        precondition(gridButton.titleVariants == ["Playing"])

        let grid = CPGridTemplate(title: "Library", gridButtons: [gridButton])
        precondition(grid.gridButtons.count == 1)
        grid.updateTitle("Albums")
        precondition(grid.title == "Albums")

        let nowPlaying = CPNowPlayingTemplate.shared
        nowPlaying.updateNowPlayingButtons([
            CPNowPlayingPlaybackRateButton(),
            CPNowPlayingShuffleButton(),
        ])
        precondition(nowPlaying.nowPlayingButtons.count == 2)

        let tabs = CPTabBarTemplate(templates: [list, grid, nowPlaying])
        precondition(tabs.templates.count == 3)
        tabs.selectTemplate(at: 1)
        precondition(tabs.selectedTemplate === grid)

        let controller = CPInterfaceController(portableRoot: tabs)
        precondition(controller.rootTemplate === tabs)
        precondition(controller.templates.count == 1)
        precondition(controller.portableConnectedToVehicle == false)

        controller.pushTemplate(list, animated: false)
        precondition(controller.topTemplate === list)
        precondition(controller.templates.count == 2)

        let alert = CPAlertTemplate(
            titleVariants: ["No server"],
            actions: [
                CPAlertAction(title: "OK", style: .default) { action in
                    precondition(action.style == .default)
                },
            ]
        )
        controller.presentTemplate(alert, animated: false)
        precondition(controller.presentedTemplate === alert)
        alert.actions[0].portableInvoke()
        controller.dismissTemplate(animated: false)
        precondition(controller.presentedTemplate == nil)

        controller.popToRootTemplate(animated: false)
        precondition(controller.topTemplate === tabs)

        let origin = MKMapItem(portableName: "Home")
        let destination = MKMapItem(portableName: "Work")
        let choice = CPRouteChoice(
            summaryVariants: ["Fastest"],
            additionalInformationVariants: ["12 min"],
            selectionSummaryVariants: ["Take Main St"]
        )
        let trip = CPTrip(origin: origin, destination: destination, routeChoices: [choice])
        let map = CPMapTemplate()
        let session = map.startNavigationSession(for: trip)
        let maneuver = CPManeuver()
        maneuver.maneuverType = .leftTurn
        maneuver.instructionVariants = ["Turn left"]
        session.add([maneuver])
        let estimates = CPTravelEstimates(
            distanceRemaining: Measurement(value: 400, unit: UnitLength.meters),
            timeRemaining: 60
        )
        session.updateEstimates(estimates, for: maneuver)
        session.pauseTrip(for: CPNavigationSession.PauseReason.rerouting, description: "Finding a better route")
        precondition(session.portableTripState == CPNavigationSession.PortableTripState.paused(.rerouting))
        session.finishTrip()
        precondition(session.portableTripState == CPNavigationSession.PortableTripState.finished)

        let poi = CPPointOfInterest(
            location: destination,
            title: "Office",
            subtitle: nil,
            summary: nil,
            detailTitle: nil,
            detailSubtitle: nil,
            detailSummary: nil,
            pinImage: image
        )
        let poiTemplate = CPPointOfInterestTemplate(
            title: "Places",
            pointsOfInterest: [poi],
            selectedIndex: 0
        )
        precondition(poiTemplate.pointsOfInterest.count == 1)

        let info = CPInformationTemplate(
            title: "Charging",
            layout: .twoColumn,
            items: [CPInformationItem(title: "Status", detail: "80%")],
            actions: [CPTextButton(title: "Done", textStyle: .confirm)]
        )
        precondition(info.items.count == 1)

        let sessionConfiguration = CPSessionConfiguration(delegate: SessionDelegate())
        precondition(sessionConfiguration.limitedUserInterfaces.isEmpty)
        precondition(sessionConfiguration.contentStyle.isEmpty)

        let scene = CPTemplateApplicationScene()
        precondition(scene.interfaceController.portableConnectedToVehicle == false)
        _ = scene.carWindow.mapButtonSafeAreaLayoutGuide

        let cluster = CPInstrumentClusterController()
        precondition(cluster.instrumentClusterWindow == nil)

        print("CARPLAY_AGENT_RUNTIME_OK")
    }
}

@MainActor
private final class SessionDelegate: NSObject, CPSessionConfigurationDelegate {}

await MainActor.run {
    CarPlayRuntimeProbe.run()
}
