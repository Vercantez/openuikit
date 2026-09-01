@_spi(OpenUIKitHost) import CarPlay
import Foundation

@MainActor
enum CarPlayRuntimeProbe {
    static func run() async {
        precondition(CarPlayErrorDomain == "CarPlayErrorDomain")
        _ = CPButtonMaximumImageSize
        _ = CPGridTemplateMaximumItems
        _ = CPMaximumListSectionImageSize
        _ = CPNavigationAlertMinimumDuration
        _ = CPListTemplate.maximumItemCount
        _ = CPTabBarTemplate.maximumTabCount
        _ = CPAlertTemplate.maximumActionCount
        _ = NSStringFromCPJunctionType(.roundabout)
        _ = NSStringFromCPLaneStatus(.preferred)
        _ = NSStringFromCPTrafficSide(.left)
        _ = NSStringFromCPManeuverType(.keepLeft)

        let light = CPContentStyle.light
        let dark = CPContentStyle.dark
        precondition(light.contains(.light))
        precondition(!light.contains(.dark))
        precondition(light.union(dark) == [.light, .dark])
        precondition(CPLimitableUserInterface.keyboard.contains(.keyboard))
        precondition(CPLimitableUserInterface.lists.contains(.lists))
        precondition(CPManeuverDisplayStyle.leadingSymbol.contains(.leadingSymbol))
        precondition(CPManeuverDisplayStyle.trailingSymbol.contains(.trailingSymbol))
        precondition(CPManeuverDisplayStyle.symbolOnly.contains(.symbolOnly))
        precondition(CPManeuverDisplayStyle.instructionOnly.contains(.instructionOnly))
        precondition(CPMapTemplate.PanDirection.left.contains(.left))

        precondition(CPAlertAction.Style.cancel != .destructive)
        precondition(CPAlertAction.Style.default != .cancel)
        precondition(CPManeuverType.leftTurn != .rightTurn)
        precondition(CPBarButtonStyle.none != .rounded)
        precondition(CPInformationTemplateLayout.leading != .twoColumn)
        precondition(CPListItemAccessoryType.none != .disclosureIndicator)
        precondition(CPListItemPlayingIndicatorLocation.leading != .trailing)
        precondition(CPTextButtonStyle.normal != .confirm)
        precondition(CPTimeRemainingColor.green != .red)
        precondition(CPTrafficSide.left != .right)
        precondition(CPTripEstimateStyle.light != .dark)
        precondition(CPManeuverState.initial != .execute)
        precondition(CPJunctionType.intersection != .roundabout)
        precondition(CPLaneStatus.notGood != .preferred)
        precondition(CPInstrumentClusterSetting.unspecified != .enabled)
        precondition(CPAssistantCellActionType.playMedia != .startCall)
        precondition(CPMessageLeadingItem.none != .star)
        precondition(CPMessageTrailingItem.none != .mute)

        let item = CPListItem(text: "Living Room", detailText: "On")
        item.setDetailText("Off")
        item.setText("Kitchen")
        item.isPlaying = true
        item.playbackProgress = 0.25
        item.accessoryType = .disclosureIndicator
        precondition(item.showsDisclosureIndicator)
        precondition(item.detailText == "Off")
        precondition(item.text == "Kitchen")

        var selected = false
        item.handler = { selectable, completion in
            selected = true
            precondition(selectable === item)
            completion()
        }
        item.invokeSelectionHandler()
        precondition(selected)

        let section = CPListSection(
            items: [item],
            header: "Areas",
            sectionIndexTitle: "A"
        )
        precondition(section.items.count == 1)
        precondition(section.index(of: item) == 0)
        precondition(section.item(at: 0) === item)

        let list = CPListTemplate(title: "Home", sections: [section])
        precondition(list.itemCount == 1)
        precondition(list.sectionCount == 1)
        precondition(list.indexPath(for: item) == IndexPath(indexes: [0, 0]))
        list.updateSections([section])

        let nowPlaying = CPNowPlayingTemplate.shared
        nowPlaying.updateNowPlayingButtons([
            CPNowPlayingPlaybackRateButton(),
            CPNowPlayingShuffleButton(),
            CPNowPlayingRepeatButton(),
            CPNowPlayingMoreButton(),
            CPNowPlayingAddToLibraryButton(),
        ])
        precondition(nowPlaying.nowPlayingButtons.count == 5)

        var upNext = false
        let observer = NowPlayingObserver { upNext = true }
        nowPlaying.add(observer)
        nowPlaying.notifyUpNextTapped()
        precondition(upNext)
        nowPlaying.remove(observer)

        let tabs = CPTabBarTemplate(templates: [list, nowPlaying])
        precondition(tabs.templates.count == 2)
        tabs.selectTemplate(at: 1)
        precondition(tabs.selectedTemplate === nowPlaying)
        tabs.select(list)
        precondition(tabs.selectedTemplate === list)

        let controller = CPInterfaceController()
        let delegate = RecordingDelegate()
        controller.delegate = delegate
        precondition(!controller.isHostVehicleSessionConnected)
        precondition(controller.templates.isEmpty)
        precondition(controller.presentedTemplate == nil)

        invokeSyncPush(controller, list)
        invokeSyncPresent(controller, CPAlertTemplate(titleVariants: ["Nope"], actions: []))
        precondition(controller.templates.isEmpty)
        precondition(controller.presentedTemplate == nil)

        await expectDisconnected {
            _ = try await controller.pushTemplate(list, animated: false)
        }
        await expectDisconnected {
            _ = try await controller.setRootTemplate(tabs, animated: false)
        }
        await expectDisconnected {
            _ = try await controller.presentTemplate(
                CPAlertTemplate(titleVariants: ["Nope"], actions: []),
                animated: false
            )
        }
        await expectDisconnected {
            _ = try await controller.popTemplate(animated: false)
        }
        await expectDisconnected {
            _ = try await controller.dismissTemplate(animated: false)
        }

        let map = CPMapTemplate()
        map.showPanningInterface(animated: false)
        precondition(!map.isPanningInterfaceVisible)
        let hostAlert = CPNavigationAlert(
            hostTitleVariants: ["Traffic"],
            subtitleVariants: ["Delay"],
            primaryAction: CPAlertAction(title: "OK", style: .default) { _ in },
            secondaryAction: nil,
            duration: 1
        )
        map.present(navigationAlert: hostAlert, animated: false)
        precondition(map.currentNavigationAlert == nil)
        let disconnectedDismiss = await map.dismissNavigationAlert(animated: false)
        precondition(!disconnectedDismiss)

        controller.connectHostVehicleSession(rootTemplate: tabs)
        precondition(controller.isHostVehicleSessionConnected)
        precondition(controller.rootTemplate === tabs)
        precondition(controller.topTemplate === tabs)
        precondition(controller.templates.count == 1)
        precondition(delegate.events == ["willAppear", "didAppear"])

        invokeSyncPush(controller, list)
        precondition(controller.topTemplate === list)
        precondition(controller.templates.count == 2)
        precondition(delegate.events.suffix(4) == ["willDisappear", "willAppear", "didDisappear", "didAppear"])

        var actionFired = false
        let alert = CPAlertTemplate(
            titleVariants: ["No server"],
            actions: [
                CPAlertAction(title: "OK", style: .default) { action in
                    actionFired = true
                    precondition(action.style == .default)
                    precondition(action.title == "OK")
                },
                CPAlertAction(title: "Cancel", style: .cancel) { _ in },
            ]
        )
        invokeSyncPresent(controller, alert)
        precondition(controller.presentedTemplate === alert)
        alert.actions[0].invokeHandler()
        precondition(actionFired)
        invokeSyncDismiss(controller)
        precondition(controller.presentedTemplate == nil)

        invokeSyncPopToRoot(controller)
        precondition(controller.topTemplate === tabs)

        let pushed: Bool
        do {
            pushed = try await controller.pushTemplate(list, animated: false)
        } catch {
            preconditionFailure("connected async push threw \(error)")
        }
        precondition(pushed)
        precondition(controller.topTemplate === list)
        let popped: Bool
        do {
            popped = try await controller.popTemplate(animated: false)
        } catch {
            preconditionFailure("connected async pop threw \(error)")
        }
        precondition(popped)
        precondition(controller.topTemplate === tabs)

        map.showPanningInterface(animated: false)
        precondition(map.isPanningInterfaceVisible)
        map.dismissPanningInterface(animated: false)
        precondition(!map.isPanningInterfaceVisible)
        map.present(navigationAlert: hostAlert, animated: false)
        precondition(map.currentNavigationAlert === hostAlert)
        hostAlert.updateTitleVariants(["Clear"], subtitleVariants: [])
        precondition(hostAlert.titleVariants == ["Clear"])
        let dismissed = await map.dismissNavigationAlert(animated: false)
        precondition(dismissed)
        precondition(map.currentNavigationAlert == nil)

        controller.disconnectHostVehicleSession()
        precondition(!controller.isHostVehicleSessionConnected)
        precondition(controller.templates.isEmpty)
        invokeSyncPush(controller, list)
        precondition(controller.templates.isEmpty)
        map.showPanningInterface(animated: false)
        precondition(!map.isPanningInterfaceVisible)

        let info = CPInformationTemplate(
            title: "Charging",
            layout: .twoColumn,
            items: [
                CPInformationItem(title: "Status", detail: "80%"),
                CPInformationRatingItem(rating: 4, maximumRating: 5, title: "Score", detail: "Good"),
            ],
            actions: [CPTextButton(title: "Done", textStyle: .confirm)]
        )
        precondition(info.items.count == 2)
        precondition(info.actions.count == 1)
        info.actions[0].invokeHandler()

        let sheet = CPActionSheetTemplate(
            title: "Power",
            message: "Choose",
            actions: [CPAlertAction(title: "Off", style: .destructive) { _ in }]
        )
        precondition(sheet.actions.count == 1)

        let search = CPSearchTemplate()
        search.delegate = SearchDelegate()
        _ = search

        let estimates = CPTravelEstimates(
            distanceRemaining: Measurement(value: 400, unit: UnitLength.meters),
            timeRemaining: 60
        )
        precondition(estimates.timeRemaining == 60)
        let choice = CPRouteChoice(
            summaryVariants: ["Fastest"],
            additionalInformationVariants: ["12 min"],
            selectionSummaryVariants: ["Take Main St"]
        )
        precondition(choice.summaryVariants == ["Fastest"])
        let lane = CPLane(angles: [Measurement(value: 0, unit: UnitAngle.degrees)])
        precondition(lane.status == .notGood)
        let guidance = CPLaneGuidance()
        guidance.lanes = [lane]
        let maneuver = CPManeuver()
        maneuver.maneuverType = .leftTurn
        maneuver.instructionVariants = ["Turn left"]
        maneuver.junctionType = .intersection
        precondition(maneuver.maneuverType == .leftTurn)
        let routeInformation = CPRouteInformation(
            maneuvers: [maneuver],
            laneGuidances: [guidance],
            currentManeuvers: [maneuver],
            currentLaneGuidance: guidance,
            trip: estimates,
            maneuverTravelEstimates: estimates
        )
        precondition(routeInformation.maneuvers.count == 1)
        _ = CPTripPreviewTextConfiguration(
            startButtonTitle: "Go",
            additionalRoutesButtonTitle: "Other",
            overviewButtonTitle: "Overview"
        )

        let sessionConfiguration = CPSessionConfiguration(delegate: SessionDelegate())
        precondition(sessionConfiguration.limitedUserInterfaces.isEmpty)
        precondition(sessionConfiguration.contentStyle.isEmpty)

        let scene = CPTemplateApplicationScene()
        precondition(!scene.interfaceController.isHostVehicleSessionConnected)
        _ = scene.carWindow
        _ = CPTemplateApplicationDashboardScene()
        _ = CPTemplateApplicationInstrumentClusterScene()
        _ = CPInstrumentClusterController()
        _ = CPDashboardController()
        _ = CPNowPlayingSportsClock(elapsedTime: 12, paused: true)
        _ = CPNowPlayingSportsTeamLogo(teamInitials: "SF")
        _ = CPAssistantCellConfiguration(
            position: .top,
            visibility: .always,
            assistantAction: .playMedia
        )
        _ = CPMessageComposeBarButton()
        _ = CPBarButton(title: "Back")
        _ = CPBarButton(type: .text)

        if let coder = try? NSKeyedUnarchiver(forReadingFrom: Data()) {
            precondition(CPListItem(coder: coder) == nil)
            precondition(CPAlertAction(coder: coder) == nil)
            precondition(CPTemplate(coder: coder) == nil)
            precondition(CPTravelEstimates(coder: coder) == nil)
        }

        print("CARPLAY_AGENT_RUNTIME_OK")
    }
}

@MainActor
private func expectDisconnected(_ body: () async throws -> Void) async {
    do {
        try await body()
        preconditionFailure("disconnected async API must throw")
    } catch let error as CarPlayHostError {
        precondition(error == .vehicleSessionDisconnected)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

@MainActor
private func invokeSyncPush(_ controller: CPInterfaceController, _ template: CPTemplate) {
    controller.pushTemplate(template, animated: false)
}

@MainActor
private func invokeSyncPresent(_ controller: CPInterfaceController, _ template: CPTemplate) {
    controller.presentTemplate(template, animated: false)
}

@MainActor
private func invokeSyncDismiss(_ controller: CPInterfaceController) {
    controller.dismissTemplate(animated: false)
}

@MainActor
private func invokeSyncPopToRoot(_ controller: CPInterfaceController) {
    controller.popToRootTemplate(animated: false)
}

@MainActor
private final class RecordingDelegate: NSObject, CPInterfaceControllerDelegate {
    var events: [String] = []

    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        events.append("willAppear")
        _ = aTemplate
        _ = animated
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        events.append("didAppear")
        _ = aTemplate
        _ = animated
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        events.append("willDisappear")
        _ = aTemplate
        _ = animated
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        events.append("didDisappear")
        _ = aTemplate
        _ = animated
    }
}

@MainActor
private final class SessionDelegate: NSObject, CPSessionConfigurationDelegate {}

@MainActor
private final class SearchDelegate: NSObject, CPSearchTemplateDelegate {
    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem) async {
        _ = searchTemplate
        _ = item
    }

    func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String) async -> [CPListItem] {
        _ = searchTemplate
        _ = searchText
        return []
    }
}

@MainActor
private final class NowPlayingObserver: NSObject, CPNowPlayingTemplateObserver {
    let onUpNext: () -> Void

    init(onUpNext: @escaping () -> Void) {
        self.onUpNext = onUpNext
    }

    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        _ = nowPlayingTemplate
        onUpNext()
    }
}

await CarPlayRuntimeProbe.run()
