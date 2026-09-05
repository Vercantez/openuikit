import Foundation
@_spi(OpenUIKitHost) import CarPlay

final class RecordingInterfaceDelegate: NSObject, CPInterfaceControllerDelegate {
    var events: [String] = []
    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) { events.append("willAppear:\(aTemplate)") }
    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) { events.append("didAppear") }
    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) { events.append("willDisappear") }
    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) { events.append("didDisappear") }
}

final class RecordingSceneDelegate: NSObject, CPTemplateApplicationSceneDelegate {
    var connected = false
    var disconnected = false
    var style: UIUserInterfaceStyle = .unspecified
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController, to window: CPWindow) { connected = true }
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {}
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) { disconnected = true }
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {}
    func contentStyleDidChange(_ contentStyle: UIUserInterfaceStyle) { style = contentStyle }
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect maneuver: CPManeuver) {}
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didSelect navigationAlert: CPNavigationAlert) {}
}

final class RecordingTabDelegate: NSObject, CPTabBarTemplateDelegate {
    var selected: CPTemplate?
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) { selected = selectedTemplate }
}

final class RecordingNowPlayingObserver: NSObject, CPNowPlayingTemplateObserver {
    var upNext = 0
    var album = 0
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) { upNext += 1 }
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) { album += 1 }
}

final class RecordingSessionDelegate: NSObject, CPSessionConfigurationDelegate {
    var style: CPContentStyle = []
    var limited: CPLimitableUserInterface = []
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, contentStyleChanged contentStyle: CPContentStyle) { style = contentStyle }
    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) { limited = limitedUserInterfaces }
}

final class RecordingSearchDelegate: NSObject, CPSearchTemplateDelegate {
    func searchTemplate(_ searchTemplate: CPSearchTemplate, selectedResult item: CPListItem) async {}
    func searchTemplate(_ searchTemplate: CPSearchTemplate, updatedSearchText searchText: String) async -> [CPListItem] {
        [CPListItem(text: searchText, detailText: "hit")]
    }
    func searchTemplateSearchButtonPressed(_ searchTemplate: CPSearchTemplate) {}
}

final class RecordingMapDelegate: NSObject, CPMapTemplateDelegate {}
final class RecordingPOIDelegate: NSObject, CPPointOfInterestTemplateDelegate {
    func pointOfInterestTemplate(_ pointOfInterestTemplate: CPPointOfInterestTemplate, didChangeMapRegion region: MKCoordinateRegion) {}
}
final class RecordingListDelegate: NSObject, CPListTemplateDelegate {
    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem) async {}
}
final class RecordingClusterDelegate: NSObject, CPInstrumentClusterControllerDelegate {
    func instrumentClusterControllerDidConnect(_ instrumentClusterWindow: UIWindow) {}
    func instrumentClusterControllerDidDisconnectWindow(_ instrumentClusterWindow: UIWindow) {}
}
final class RecordingDashDelegate: NSObject, CPTemplateApplicationDashboardSceneDelegate {}
final class RecordingClusterSceneDelegate: NSObject, CPTemplateApplicationInstrumentClusterSceneDelegate {}
final class RecordingAppDelegate: NSObject, CPApplicationDelegate {
    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {}
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {}
}

func exerciseOptionSet<T: OptionSet>(_ a: T, _ b: T) where T.Element == T {
    let x = T()
    precondition(x.isEmpty)
    _ = T([a, b])
    _ = a.union(b)
    _ = a.intersection(b)
    _ = a.symmetricDifference(b)
    _ = a.subtracting(b)
    _ = a.isSubset(of: b)
    _ = a.isSuperset(of: b)
    _ = a.isDisjoint(with: b)
    _ = a.isStrictSubset(of: a.union(b))
    _ = a.union(b).isStrictSuperset(of: a)
    _ = a.contains(a)
    _ = a != b || a == b
    var y = a
    y.formUnion(b)
    y.formIntersection(a)
    y.formSymmetricDifference(b)
    y.subtract(a)
    _ = y.insert(a)
    _ = y.remove(a)
    _ = y.update(with: b)
}

func hashValue<T: Hashable>(_ value: T) -> Int {
    var hasher = Hasher()
    value.hash(into: &hasher)
    return hasher.finalize()
}

final class HostNSCoder: NSCoder {
    override var allowsKeyedCoding: Bool { true }
}

func failClosedCoder() -> NSCoder {
    HostNSCoder()
}

@MainActor
func runCarPlayRuntime() async throws {
    do {
        let values: [CPAlertAction.Style] = [
            .cancel,
            .default,
            .destructive,
        ]
        precondition(values.count == 3)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPAlertAction.Style(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPAssistantCellActionType] = [
            .playMedia,
            .startCall,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPAssistantCellActionType(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPBarButton.`Type`] = [
            .image,
            .text,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = value.rawValue == 0 || value.rawValue == 1
        }
    }
    do {
        let values: [CPBarButtonStyle] = [
            .none,
            .rounded,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPBarButtonStyle(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPInformationTemplateLayout] = [
            .leading,
            .twoColumn,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPInformationTemplateLayout(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPInstrumentClusterSetting] = [
            .disabled,
            .enabled,
            .unspecified,
            .userPreference,
        ]
        precondition(values.count == 4)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPInstrumentClusterSetting(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPJunctionType] = [
            .intersection,
            .roundabout,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPJunctionType(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPLaneStatus] = [
            .good,
            .notGood,
            .preferred,
        ]
        precondition(values.count == 3)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPLaneStatus(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPListImageRowItemCondensedElement.Shape] = [
            .circular,
            .roundedRectangle,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPListImageRowItemCondensedElement.Shape(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPListImageRowItemImageGridElement.Shape] = [
            .circular,
            .roundedRectangle,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPListImageRowItemImageGridElement.Shape(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPListItem.AssistantCellPosition] = [
            .bottom,
            .top,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPListItem.AssistantCellPosition(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPListItem.AssistantCellVisibility] = [
            .always,
            .off,
            .whileLimitedUIActive,
        ]
        precondition(values.count == 3)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPListItem.AssistantCellVisibility(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPListItemAccessoryType] = [
            .cloud,
            .disclosureIndicator,
            .none,
        ]
        precondition(values.count == 3)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPListItemAccessoryType(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPListItemPlayingIndicatorLocation] = [
            .leading,
            .trailing,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPListItemPlayingIndicatorLocation(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPManeuverState] = [
            .continue,
            .execute,
            .initial,
            .prepare,
        ]
        precondition(values.count == 4)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPManeuverState(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPManeuverType] = [
            .arriveAtDestination,
            .arriveAtDestinationLeft,
            .arriveAtDestinationRight,
            .arriveEndOfDirections,
            .arriveEndOfNavigation,
            .changeFerry,
            .changeHighway,
            .changeHighwayLeft,
            .changeHighwayRight,
            .enterRoundabout,
            .enter_Ferry,
            .exitFerry,
            .exitRoundabout,
            .followRoad,
            .highwayOffRampLeft,
            .highwayOffRampRight,
            .keepLeft,
            .keepRight,
            .leftTurn,
            .leftTurnAtEnd,
            .noTurn,
            .offRamp,
            .onRamp,
            .rightTurn,
            .rightTurnAtEnd,
            .roundaboutExit1,
            .roundaboutExit10,
            .roundaboutExit11,
            .roundaboutExit12,
            .roundaboutExit13,
            .roundaboutExit14,
            .roundaboutExit15,
            .roundaboutExit16,
            .roundaboutExit17,
            .roundaboutExit18,
            .roundaboutExit19,
            .roundaboutExit2,
            .roundaboutExit3,
            .roundaboutExit4,
            .roundaboutExit5,
            .roundaboutExit6,
            .roundaboutExit7,
            .roundaboutExit8,
            .roundaboutExit9,
            .sharpLeftTurn,
            .sharpRightTurn,
            .slightLeftTurn,
            .slightRightTurn,
            .startRoute,
            .startRouteWithUTurn,
            .straightAhead,
            .uTurn,
            .uTurnAtRoundabout,
            .uTurnWhenPossible,
        ]
        precondition(values.count == 54)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPManeuverType(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPMessageLeadingItem] = [
            .none,
            .pin,
            .star,
        ]
        precondition(values.count == 3)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPMessageLeadingItem(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPMessageTrailingItem] = [
            .mute,
            .none,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPMessageTrailingItem(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPNavigationAlert.DismissalContext] = [
            .systemDismissed,
            .timeout,
            .userDismissed,
        ]
        precondition(values.count == 3)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPNavigationAlert.DismissalContext(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPNavigationSession.PauseReason] = [
            .arrived,
            .loading,
            .locating,
            .proceedToRoute,
            .rerouting,
        ]
        precondition(values.count == 5)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPNavigationSession.PauseReason(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPTextButtonStyle] = [
            .cancel,
            .confirm,
            .normal,
        ]
        precondition(values.count == 3)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPTextButtonStyle(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPTimeRemainingColor] = [
            .default,
            .green,
            .orange,
            .red,
        ]
        precondition(values.count == 4)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPTimeRemainingColor(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPTrafficSide] = [
            .left,
            .right,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPTrafficSide(rawValue: value.rawValue) == value
        }
    }
    do {
        let values: [CPTripEstimateStyle] = [
            .dark,
            .light,
        ]
        precondition(values.count == 2)
        for value in values {
            _ = hashValue(value)
            _ = value != values[0]
            _ = CPTripEstimateStyle(rawValue: value.rawValue) == value
        }
    }

    exerciseOptionSet(CPContentStyle.light, CPContentStyle.dark)
    exerciseOptionSet(CPLimitableUserInterface.keyboard, CPLimitableUserInterface.lists)
    exerciseOptionSet(CPManeuverDisplayStyle.leadingSymbol, CPManeuverDisplayStyle.trailingSymbol)
    exerciseOptionSet(CPMapTemplate.PanDirection.left, CPMapTemplate.PanDirection.right)
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
    precondition(CPListItem.maximumImageSize.width == 90)
    precondition(CPListTemplate.maximumItemCount == 12)
    precondition(CPListTemplate.maximumSectionCount == 12)
    precondition(CPAlertTemplate.maximumActionCount == 2)
    precondition(CPTabBarTemplate.maximumTabCount == 5)
    precondition(CPTabBarTemplate.someVehiclesMaximumTabCount == 4)
    precondition(CPGridTemplateMaximumItems == 8)

    let junction = NSStringFromCPJunctionType(.intersection)!
    let lane = NSStringFromCPLaneStatus(.preferred)!
    let maneuverName = NSStringFromCPManeuverType(.uTurn)!
    let traffic = NSStringFromCPTrafficSide(.left)!
    precondition(Set([junction, lane, maneuverName, traffic]).count == 4)

    _ = UISceneSession.Role.carTemplateApplication
    _ = UISceneSession.Role.CPTemplateApplicationDashboardSceneSessionRoleApplication
    _ = UISceneSession.Role.CPTemplateApplicationInstrumentClusterSceneSessionRoleApplication

    let image = UIImage(size: CPListItem.maximumImageSize)
    let color = UIColor()

    var alertFired = false
    let alertAction = CPAlertAction(title: "Go", style: .default) { action in
        alertFired = true
        precondition(action.title == "Go")
    }
    alertAction.color = color
    alertAction.openuikit_invokeHandler()
    precondition(alertFired)
    let colored = CPAlertAction(title: "Tint", color: color, handler: { _ in })
    precondition(colored.title == "Tint")
    precondition(CPAlertAction(coder: failClosedCoder()) == nil)

    var barFired = false
    let bar = CPBarButton(title: "Back") { _ in barFired = true }
    bar.buttonStyle = .rounded
    bar.isEnabled = true
    bar.openuikit_invokeHandler()
    precondition(barFired)
    let barImage = CPBarButton(image: image) { _ in }
    precondition(barImage.buttonType == .image)
    let barType = CPBarButton(type: .text) { _ in }
    precondition(barType.buttonType == .text)
    precondition(CPBarButton(coder: failClosedCoder()) == nil)

    var buttonFired = false
    let button = CPButton(image: image) { _ in buttonFired = true }
    button.title = "Btn"
    button.openuikit_invokeHandler()
    precondition(buttonFired)

    let contact = CPContact(name: "Ada", image: image)
    contact.subtitle = "Engineer"
    contact.informativeText = "Info"
    let call = CPContactCallButton { _ in }
    let directions = CPContactDirectionsButton { _ in }
    let messageBtn = CPContactMessageButton(phoneOrEmail: "ada@example.com")
    contact.actions = [call, directions, messageBtn]
    call.openuikit_invokeHandler()
    let contactTemplate = CPContactTemplate(contact: contact)
    contactTemplate.userInfo = "contact"
    contactTemplate.tabTitle = "People"
    contactTemplate.tabImage = image
    contactTemplate.showsTabBadge = true
    contactTemplate.tabSystemItem = .contacts
    contactTemplate.leadingNavigationBarButtons = [bar]
    contactTemplate.trailingNavigationBarButtons = [barImage]
    contactTemplate.backButton = bar
    precondition(contactTemplate.contact.name == "Ada")

    let dashButton = CPDashboardButton(titleVariants: ["Home"], subtitleVariants: ["Now"], image: image) { _ in }
    dashButton.openuikit_invokeHandler()
    let dash = CPDashboardController()
    dash.shortcutButtons = [dashButton]
    precondition(!dash.openuikit_vehiclePresentationActive)
    precondition(CPDashboardButton(coder: failClosedCoder()) == nil)

    var gridFired = false
    let gridButton = CPGridButton(titleVariants: ["A"], image: image) { _ in gridFired = true }
    gridButton.updateTitleVariants(["B"])
    gridButton.updateImage(image)
    gridButton.openuikit_invokeHandler()
    precondition(gridFired)
    let msgCfg = CPMessageGridItemConfiguration(conversationIdentifier: "c1", unread: true)
    precondition(msgCfg.isUnread)
    let gridButton2 = CPGridButton(titleVariants: ["C"], image: image, messageConfiguration: msgCfg, handler: nil)
    precondition(gridButton2.messageConfiguration?.conversationIdentifier == "c1")
    let tooMany = (0..<10).map { CPGridButton(titleVariants: ["\($0)"], image: image, handler: nil) }
    let grid = CPGridTemplate(title: "Grid", gridButtons: tooMany)
    precondition(grid.gridButtons.count == 8)
    grid.updateGridButtons(Array(tooMany.prefix(3)))
    grid.updateTitle("Grid2")
    precondition(grid.title == "Grid2")
    _ = CPGridTemplate.maximumGridButtonImageSize

    let imageSet = CPImageSet(lightContentImage: image, darkContentImage: image)
    precondition(CPImageSet(coder: failClosedCoder()) == nil)

    let infoItem = CPInformationItem(title: "T", detail: "D")
    let rating = CPInformationRatingItem(rating: 4, maximumRating: 5, title: "Rate", detail: "Good")
    precondition(rating.title == "Rate")
    var textFired = false
    let textButton = CPTextButton(title: "OK", textStyle: .confirm) { _ in textFired = true }
    textButton.openuikit_invokeHandler()
    precondition(textFired)
    let info = CPInformationTemplate(title: "Info", layout: .twoColumn, items: [infoItem, rating], actions: [textButton])
    precondition(info.items.count == 2)

    let cluster = CPInstrumentClusterController()
    let clusterDelegate = RecordingClusterDelegate()
    cluster.delegate = clusterDelegate
    cluster.inactiveDescriptionVariants = ["Parked"]
    cluster.attributedInactiveDescriptionVariants = [NSAttributedString(string: "Parked")]
    cluster.compassSetting = .disabled
    cluster.speedLimitSetting = .userPreference
    precondition(!cluster.openuikit_vehiclePresentationActive)

    var handlerCompleted = false
    let listItem = CPListItem(text: "Library", detailText: "Podcasts", image: image, accessoryImage: image, accessoryType: .disclosureIndicator)
    listItem.handler = { item, completion in
        precondition(item.text == "Albums")
        completion()
        handlerCompleted = true
    }
    listItem.isEnabled = true
    listItem.userInfo = "row-1"
    listItem.setText("Albums")
    listItem.setDetailText("On this device")
    listItem.setImage(image)
    listItem.setAccessoryImage(image)
    listItem.isPlaying = true
    listItem.playbackProgress = 0.5
    listItem.playingIndicatorLocation = .trailing
    listItem.isExplicitContent = true
    listItem.showsExplicitLabel = true
    precondition(listItem.text == "Albums")
    precondition(listItem.showsDisclosureIndicator)
    listItem.openuikit_invokeHandler()
    precondition(handlerCompleted)
    let listItem2 = CPListItem(text: "B", detailText: "C", image: image)
    let listItem3 = CPListItem(text: "D", detailText: "E", image: image, showsDisclosureIndicator: true)
    precondition(listItem3.showsDisclosureIndicator)

    let assistant = CPAssistantCellConfiguration(position: .top, visibility: .always, assistantAction: .playMedia)
    let headerButton = CPButton(image: image)
    let section = CPListSection(
        items: [listItem, listItem2],
        header: "Media",
        headerSubtitle: "Sub",
        headerImage: image,
        headerButton: headerButton,
        sectionIndexTitle: "M"
    )
    precondition(section.item(at: 0).text == "Albums")
    precondition(section.index(of: listItem) == 0)
    let protocolSection = CPListSection(items: [listItem3], header: "Also", sectionIndexTitle: "A")
    let plainSection = CPListSection(items: [listItem])
    _ = CPListSection(items: [listItem] as [CPListItem])
    _ = CPListSection(coder: failClosedCoder()) == nil || true

    let list = CPListTemplate(title: "Home", sections: [section, protocolSection, plainSection], assistantCellConfiguration: assistant, headerGridButtons: [gridButton])
    let listDelegate = RecordingListDelegate()
    list.delegate = listDelegate
    list.emptyViewTitleVariants = ["Empty"]
    list.emptyViewSubtitleVariants = ["None"]
    list.showsSpinnerWhileEmpty = true
    precondition(list.itemCount == 4)
    precondition(list.indexPath(for: listItem)?[1] == 0)
    list.updateSections([section])
    await list.openuikit_select(listItem)

    let overflowItems = (0..<20).map { CPListItem(text: "\($0)", detailText: nil) }
    let overflow = CPListTemplate(title: "Overflow", sections: [CPListSection(items: overflowItems)])
    precondition(overflow.itemCount == CPListTemplate.maximumItemCount)
    _ = CPListTemplate.maximumGridButtonImageSize
    _ = CPListTemplate.maximumHeaderGridButtonCount
    _ = CPListTemplate(title: "A", sections: [section], assistantCellConfiguration: assistant)

    let card = CPListImageRowItemCardElement(image: image, showsImageFullHeight: true, title: "Card", subtitle: "S", tintColor: color)
    let condensed = CPListImageRowItemCondensedElement(image: image, imageShape: .circular, title: "C", subtitle: "s", accessorySymbolName: "star")
    let gridEl = CPListImageRowItemGridElement(image: image)
    let imageGrid = CPListImageRowItemImageGridElement(image: image, imageShape: .roundedRectangle, title: "G", accessorySymbolName: nil)
    let rowEl = CPListImageRowItemRowElement(image: image, title: "R", subtitle: "r")
    _ = CPListImageRowItemCardElement.maximumFullHeightImageSize
    _ = CPListImageRowItemElement.maximumImageSize
    var rowHandler = false
    let rowItem = CPListImageRowItem(text: "Row", images: [image, image], imageTitles: ["1", "2"])
    rowItem.listImageRowHandler = { _, _, completion in
        rowHandler = true
        completion()
    }
    rowItem.handler = { _, completion in completion() }
    rowItem.openuikit_invokeRowHandler(index: 0)
    rowItem.openuikit_invokeHandler()
    precondition(rowHandler)
    rowItem.update([image])
    _ = CPListImageRowItem(text: "c", cardElements: [card], allowsMultipleLines: true)
    _ = CPListImageRowItem(text: "d", condensedElements: [condensed], allowsMultipleLines: false)
    _ = CPListImageRowItem(text: "e", elements: [rowEl], allowsMultipleLines: true)
    _ = CPListImageRowItem(text: "f", gridElements: [gridEl], allowsMultipleLines: false)
    _ = CPListImageRowItem(text: "g", imageGridElements: [imageGrid], allowsMultipleLines: true)
    _ = CPListImageRowItem(text: "h", images: [image])
    _ = CPListImageRowItem.maximumImageSize
    _ = condensed.imageShape != .roundedRectangle
    _ = imageGrid.imageShape == .roundedRectangle

    let leading = CPMessageListItemLeadingConfiguration(leadingItem: .pin, leadingImage: image, unread: true)
    precondition(leading.isUnread)
    let trailing = CPMessageListItemTrailingConfiguration(trailingItem: .mute, trailingImage: image)
    let messageItem = CPMessageListItem(
        conversationIdentifier: "cid",
        text: "Hello",
        leadingConfiguration: leading,
        trailingConfiguration: trailing,
        detailText: "Today",
        trailingText: "1"
    )
    messageItem.leadingDetailTextImage = image
    messageItem.userInfo = 7
    let messageItem2 = CPMessageListItem(
        fullName: "Ada",
        phoneOrEmailAddress: "a@b.c",
        leadingConfiguration: leading,
        trailingConfiguration: trailing,
        detailText: nil,
        trailingText: nil
    )
    precondition(messageItem2.text == "Ada")
    let compose = CPMessageComposeBarButton(image: image)
    precondition(compose.buttonType == .image)

    let sceneDelegate = RecordingSceneDelegate()
    let scene = CPTemplateApplicationScene()
    scene.delegate = sceneDelegate
    scene.openuikit_connectSimulatedSession(style: .dark)
    precondition(sceneDelegate.connected)
    precondition(scene.contentStyle == .dark)
    let controller = scene.interfaceController
    precondition(controller.hostSessionConnected)
    precondition(controller.carTraitCollection.userInterfaceStyle == .dark)
    controller.prefersDarkUserInterfaceStyle = true
    let ifaceDelegate = RecordingInterfaceDelegate()
    controller.delegate = ifaceDelegate

    let root = CPListTemplate(title: "Root", sections: [])
    let child = CPListTemplate(title: "Child", sections: [])
    let child2 = CPListTemplate(title: "Child2", sections: [])
    let child3 = CPListTemplate(title: "Child3", sections: [])
    let child4 = CPListTemplate(title: "Child4", sections: [])
    let child5 = CPListTemplate(title: "Child5", sections: [])

    do {
        _ = try await controller.setRootTemplate(root, animated: false)
    } catch {
        preconditionFailure("setRoot should succeed")
    }
    precondition(controller.rootTemplate === root)
    precondition(controller.topTemplate === root)
    precondition(controller.templates.count == 1)
    _ = try await controller.pushTemplate(child, animated: false)
    _ = try await controller.pushTemplate(child2, animated: false)
    _ = try await controller.pushTemplate(child3, animated: false)
    _ = try await controller.pushTemplate(child4, animated: false)
    precondition(controller.templates.count == 5)
    do {
        _ = try await controller.pushTemplate(child5, animated: false)
        preconditionFailure("stack limit should throw")
    } catch let error as CarPlayHostError {
        precondition(error == .templateHierarchyExceeded)
    } catch {
        let ns = error as NSError
        precondition(ns.domain == CarPlayErrorDomain)
        precondition(ns.code == 2)
    }
    precondition(controller.templates.count == 5)
    _ = try await controller.pop(to: child2, animated: false)
    precondition(controller.topTemplate === child2)
    _ = try await controller.popTemplate(animated: false)
    precondition(controller.topTemplate === child)
    _ = try await controller.popToRootTemplate(animated: false)
    precondition(controller.topTemplate === root)

    let presentable = CPAlertTemplate(titleVariants: ["Hi"], actions: [
        CPAlertAction(title: "A", style: .default, handler: { _ in }),
        CPAlertAction(title: "B", style: .cancel, handler: { _ in }),
        CPAlertAction(title: "C", style: .destructive, handler: { _ in }),
    ])
    precondition(presentable.actions.count == 2)
    _ = try await controller.presentTemplate(presentable, animated: false)
    precondition(controller.presentedTemplate === presentable)
    do {
        _ = try await controller.presentTemplate(child, animated: false)
        preconditionFailure("non-presentable should throw")
    } catch {
        let ns = error as NSError
        precondition(ns.domain == CarPlayErrorDomain)
    }
    _ = try await controller.dismissTemplate(animated: false)
    precondition(controller.presentedTemplate == nil)

    func exerciseVoidControllerAPIs(
        _ controller: CPInterfaceController,
        root: CPTemplate,
        child: CPTemplate,
        presentable: CPTemplate,
        sheet: CPTemplate,
        voice: CPTemplate
    ) {
        controller.setRootTemplate(root, animated: false)
        controller.pushTemplate(child, animated: false)
        controller.popTemplate(animated: false)
        controller.pushTemplate(child, animated: false)
        controller.pop(to: root, animated: false)
        controller.presentTemplate(presentable, animated: false)
        controller.dismissTemplate(animated: false)
        controller.presentTemplate(sheet, animated: false)
        controller.dismissTemplate(animated: false)
        controller.presentTemplate(voice, animated: false)
        controller.dismissTemplate(animated: false)
        controller.setRootTemplate(root, animated: false)
    }

    let sheet = CPActionSheetTemplate(title: "Sheet", message: "Msg", actions: [
        CPAlertAction(title: "One", style: .default, handler: { _ in }),
    ])
    let voiceState = CPVoiceControlState(identifier: "listen", titleVariants: ["Listening"], image: image, repeats: true)
    precondition(CPVoiceControlState(coder: failClosedCoder()) == nil)
    let voice = CPVoiceControlTemplate(voiceControlStates: [voiceState])
    voice.activateVoiceControlState(withIdentifier: "listen")
    precondition(voice.activeStateIdentifier == "listen")
    exerciseVoidControllerAPIs(controller, root: root, child: child, presentable: presentable, sheet: sheet, voice: voice)

    let tabA = CPListTemplate(title: "TabA", sections: [])
    tabA.tabTitle = "A"
    let tabB = CPListTemplate(title: "TabB", sections: [])
    let tabC = CPListTemplate(title: "TabC", sections: [])
    let tabD = CPListTemplate(title: "TabD", sections: [])
    let tabE = CPListTemplate(title: "TabE", sections: [])
    let tabF = CPListTemplate(title: "TabF", sections: [])
    let tabDelegate = RecordingTabDelegate()
    let tabs = CPTabBarTemplate(templates: [tabA, tabB, tabC, tabD, tabE, tabF])
    tabs.delegate = tabDelegate
    precondition(tabs.templates.count == 5)
    tabs.select(tabB)
    precondition(tabs.selectedTemplate === tabB)
    tabs.selectTemplate(at: 0)
    tabs.updateTemplates([tabA, tabB])
    func setRootSync(_ template: CPTemplate) {
        controller.setRootTemplate(template, animated: false)
    }
    setRootSync(tabs)

    let window = scene.carWindow
    precondition(window.templateApplicationScene === scene)
    _ = window.mapButtonSafeAreaLayoutGuide
    _ = window.frame

    sceneDelegate.templateApplicationScene(scene, didSelect: CPManeuver())
    sceneDelegate.templateApplicationScene(scene, didSelect: CPNavigationAlert(
        titleVariants: ["Alert"],
        subtitleVariants: ["Sub"],
        image: image,
        primaryAction: alertAction,
        secondaryAction: nil,
        duration: CPNavigationAlertMinimumDuration
    ))
    scene.openuikit_disconnectSimulatedSession()
    precondition(sceneDelegate.disconnected)
    do {
        _ = try await controller.pushTemplate(child, animated: false)
        preconditionFailure("disconnected push should throw")
    } catch let error as CarPlayHostError {
        precondition(error == .notConnected)
    } catch {
        precondition((error as NSError).domain == CarPlayErrorDomain)
    }
    scene.openuikit_connectSimulatedSession(style: .light)

    let origin = MKMapItem()
    origin.name = "Start"
    let dest = MKMapItem()
    dest.name = "End"
    let choice = CPRouteChoice(summaryVariants: ["Fast"], additionalInformationVariants: ["Via A"], selectionSummaryVariants: ["Selected"])
    choice.userInfo = "choice"
    precondition(CPRouteChoice(coder: failClosedCoder()) == nil)
    let trip = CPTrip(origin: origin, destination: dest, routeChoices: [choice])
    trip.destinationNameVariants = ["End"]
    trip.userInfo = "trip"
    precondition(CPTrip(coder: failClosedCoder()) == nil)
    let estimates = CPTravelEstimates(
        distanceRemaining: Measurement(value: 1000, unit: UnitLength.meters),
        timeRemaining: 120
    )
    precondition(estimates.timeRemaining == 120)
    let estimates2 = CPTravelEstimates(
        distanceRemaining: Measurement(value: 500, unit: UnitLength.meters),
        distanceRemainingToDisplay: Measurement(value: 0.5, unit: UnitLength.kilometers),
        timeRemaining: 60
    )
    precondition(estimates2.distanceRemainingToDisplay.value == 0.5)
    precondition(CPTravelEstimates(coder: failClosedCoder()) == nil)

    let maneuver = CPManeuver()
    maneuver.instructionVariants = ["Turn left"]
    maneuver.attributedInstructionVariants = [NSAttributedString(string: "Turn left")]
    maneuver.maneuverType = .leftTurn
    maneuver.junctionType = .intersection
    maneuver.trafficSide = .right
    maneuver.symbolImage = image
    maneuver.symbolSet = imageSet
    maneuver.junctionImage = image
    maneuver.dashboardSymbolImage = image
    maneuver.dashboardJunctionImage = image
    maneuver.dashboardInstructionVariants = ["Dash"]
    maneuver.dashboardAttributedInstructionVariants = [NSAttributedString(string: "Dash")]
    maneuver.notificationSymbolImage = image
    maneuver.notificationInstructionVariants = ["Note"]
    maneuver.notificationAttributedInstructionVariants = [NSAttributedString(string: "Note")]
    maneuver.roadFollowingManeuverVariants = ["Main St"]
    maneuver.highwayExitLabel = "12A"
    maneuver.cardBackgroundColor = color
    maneuver.initialTravelEstimates = estimates
    maneuver.userInfo = "m"
    maneuver.junctionExitAngle = Measurement(value: 90, unit: UnitAngle.degrees)
    maneuver.junctionElementAngles = [Measurement(value: 0, unit: UnitAngle.degrees)]
    maneuver.linkedLaneGuidance = CPLaneGuidance()
    precondition(CPManeuver(coder: failClosedCoder()) == nil)

    let laneObj = CPLane(angles: [Measurement(value: 0, unit: UnitAngle.degrees)])
    let preferredLane = CPLane(
        angles: [Measurement(value: 10, unit: UnitAngle.degrees)],
        highlightedAngle: Measurement(value: 10, unit: UnitAngle.degrees),
        isPreferred: true
    )
    precondition(preferredLane.status == .preferred)
    precondition(CPLane(coder: failClosedCoder()) == nil)
    let guidance = CPLaneGuidance()
    guidance.lanes = [laneObj, preferredLane]
    guidance.instructionVariants = ["Keep left"]

    let mapDelegate = RecordingMapDelegate()
    let map = CPMapTemplate()
    map.mapDelegate = mapDelegate
    map.guidanceBackgroundColor = color
    map.tripEstimateStyle = .dark
    map.automaticallyHidesNavigationBar = true
    map.hidesButtonsWithNavigationBar = true
    var mapBtnFired = false
    let mapButton = CPMapButton { _ in mapBtnFired = true }
    mapButton.image = image
    mapButton.focusedImage = image
    mapButton.isEnabled = true
    mapButton.isHidden = false
    mapButton.openuikit_invokeHandler()
    precondition(mapBtnFired)
    map.mapButtons = [mapButton]
    let previewConfig = CPTripPreviewTextConfiguration(
        startButtonTitle: "Go",
        additionalRoutesButtonTitle: "More",
        overviewButtonTitle: "Overview"
    )
    precondition(CPTripPreviewTextConfiguration(coder: failClosedCoder()) == nil)
    map.showTripPreviews([trip], textConfiguration: previewConfig)
    map.showTripPreviews([trip], selectedTrip: trip, textConfiguration: previewConfig)
    map.showRouteChoicesPreview(for: trip, textConfiguration: previewConfig)
    map.updateEstimates(estimates, for: trip)
    map.update(estimates2, for: trip, with: .green)
    map.showPanningInterface(animated: false)
    precondition(map.isPanningInterfaceVisible)
    map.dismissPanningInterface(animated: false)
    precondition(!map.isPanningInterfaceVisible)
    mapDelegate.mapTemplateDidBeginPanGesture(map)
    mapDelegate.mapTemplate(map, panBeganWith: .left)
    mapDelegate.mapTemplate(map, panWith: .left)
    mapDelegate.mapTemplate(map, panEndedWith: .left)
    mapDelegate.mapTemplate(map, didEndPanGestureWithVelocity: .zero)
    mapDelegate.mapTemplateDidBeginZoomGesture(map)
    mapDelegate.mapTemplate(map, didUpdateZoomGestureWithCenter: .zero, scale: 1, velocity: 0)
    mapDelegate.mapTemplate(map, didEndZoomGestureWithVelocity: 0)
    mapDelegate.mapTemplateDidBeginRotationGesture(map)
    mapDelegate.mapTemplate(map, didRotateWithCenter: .zero, rotation: 0, velocity: 0)
    mapDelegate.mapTemplate(map, rotationDidEndWithVelocity: 0)
    mapDelegate.mapTemplateDidBeginPitchGesture(map)
    mapDelegate.mapTemplate(map, pitchWithCenter: .zero)
    mapDelegate.mapTemplate(map, pitchEndedWithCenter: .zero)
    _ = mapDelegate.mapTemplate(map, displayStyleFor: maneuver)
    _ = mapDelegate.mapTemplate(map, shouldShowNotificationFor: maneuver)
    _ = mapDelegate.mapTemplateShouldProvideNavigationMetadata(map)
    map.hideTripPreviews()
    let session = map.startNavigationSession(for: trip)
    precondition(session.trip === trip)
    precondition(session.hostTripState == .navigating)
    session.add([maneuver])
    session.add([guidance])
    session.currentRoadNameVariants = ["Main"]
    session.maneuverState = .prepare
    session.updateEstimates(estimates, for: maneuver)
    session.pauseTrip(for: .rerouting, description: "Reroute")
    precondition(session.hostTripState == .paused)
    let routeInfo = CPRouteInformation(
        maneuvers: [maneuver],
        laneGuidances: [guidance],
        currentManeuvers: [maneuver],
        currentLaneGuidance: guidance,
        trip: estimates,
        maneuverTravelEstimates: estimates2
    )
    let routeInfo2 = CPRouteInformation(
        maneuvers: [maneuver],
        laneGuidances: [guidance],
        currentManeuvers: [maneuver],
        currentLaneGuidance: guidance,
        tripTravelEstimates: estimates,
        maneuverTravelEstimates: estimates2
    )
    _ = routeInfo2.maneuvers
    session.resumeTrip(updatedRouteInformation: routeInfo)
    precondition(session.hostTripState == .navigating)
    session.pauseTrip(for: .loading, description: "Wait", turnCardColor: color)
    session.finishTrip()
    precondition(session.hostTripState == .finished)
    let session2 = map.startNavigationSession(for: trip)
    session2.cancelTrip()
    precondition(session2.hostTripState == .cancelled)

    let navAlert = CPNavigationAlert(
        titleVariants: ["Slow"],
        subtitleVariants: ["Traffic"],
        imageSet: imageSet,
        primaryAction: alertAction,
        secondaryAction: colored,
        duration: 8
    )
    navAlert.updateTitleVariants(["Slow2"], subtitleVariants: ["Traffic2"])
    map.present(navigationAlert: navAlert, animated: false)
    precondition(map.currentNavigationAlert === navAlert)
    _ = await map.dismissNavigationAlert(animated: false)
    precondition(map.currentNavigationAlert == nil)
    _ = CPNavigationAlert(
        titleVariants: ["X"],
        subtitleVariants: nil,
        image: image,
        primaryAction: alertAction,
        secondaryAction: nil,
        duration: 5
    )
    precondition(CPNavigationAlert(coder: failClosedCoder()) == nil)
    precondition(CPMapButton(coder: failClosedCoder()) == nil)

    let poi = CPPointOfInterest(
        location: dest,
        title: "Cafe",
        subtitle: "Coffee",
        summary: "Good",
        detailTitle: "Cafe Detail",
        detailSubtitle: "Open",
        detailSummary: "Hours",
        pinImage: image,
        selectedPinImage: image
    )
    poi.primaryButton = textButton
    poi.secondaryButton = CPTextButton(title: "Call", textStyle: .normal, handler: nil)
    poi.userInfo = "poi"
    _ = CPPointOfInterest.pinImageSize
    _ = CPPointOfInterest.selectedPinImageSize
    _ = CPPointOfInterest(
        location: dest,
        title: "Cafe2",
        subtitle: nil,
        summary: nil,
        detailTitle: nil,
        detailSubtitle: nil,
        detailSummary: nil,
        pinImage: nil
    )
    precondition(CPPointOfInterest(coder: failClosedCoder()) == nil)
    let poiTemplate = CPPointOfInterestTemplate(title: "POIs", pointsOfInterest: [poi], selectedIndex: 0)
    let poiDelegate = RecordingPOIDelegate()
    poiTemplate.pointOfInterestDelegate = poiDelegate
    poiTemplate.setPointsOfInterest([poi], selectedIndex: 0)
    poiTemplate.pointOfInterestDelegate?.pointOfInterestTemplate(poiTemplate, didChangeMapRegion: MKCoordinateRegion())

    let search = CPSearchTemplate()
    let searchDelegate = RecordingSearchDelegate()
    search.delegate = searchDelegate
    let hits = await search.openuikit_updateSearchText("abc")
    precondition(hits.first?.text == "abc")
    await search.openuikit_selectResult(listItem)
    search.openuikit_pressSearchButton()

    let now = CPNowPlayingTemplate.shared
    precondition(now === CPNowPlayingTemplate.shared)
    precondition(now.mpNowPlayingBridgeDeclared)
    let observer = RecordingNowPlayingObserver()
    now.add(observer)
    now.isAlbumArtistButtonEnabled = true
    now.isUpNextButtonEnabled = true
    now.upNextTitle = "Up Next"
    let npMore = CPNowPlayingMoreButton()
    let npRate = CPNowPlayingPlaybackRateButton()
    let npRepeat = CPNowPlayingRepeatButton()
    let npShuffle = CPNowPlayingShuffleButton()
    let npAdd = CPNowPlayingAddToLibraryButton()
    let npImage = CPNowPlayingImageButton(image: image) { _ in }
    npImage.openuikit_invokeHandler()
    now.updateNowPlayingButtons([npMore, npRate, npRepeat, npShuffle, npAdd, npImage])
    precondition(now.nowPlayingButtons.count == 6)
    now.openuikit_notifyUpNext()
    now.openuikit_notifyAlbumArtist()
    precondition(observer.upNext == 1)
    now.remove(observer)
    let clockUp = CPNowPlayingSportsClock(elapsedTime: 12, paused: false)
    precondition(clockUp.countsUp)
    let clockDown = CPNowPlayingSportsClock(timeRemaining: 5, paused: true)
    precondition(!clockDown.countsUp)
    precondition(CPNowPlayingSportsClock(coder: failClosedCoder()) == nil)
    let status = CPNowPlayingSportsEventStatus(
        eventStatusText: ["Q2"],
        eventStatusImage: image,
        eventClock: clockDown
    )
    precondition(CPNowPlayingSportsEventStatus(coder: failClosedCoder()) == nil)
    let logo = CPNowPlayingSportsTeamLogo(teamLogo: image)
    let initials = CPNowPlayingSportsTeamLogo(teamInitials: "AA")
    precondition(initials.initials == "AA")
    precondition(CPNowPlayingSportsTeamLogo(coder: failClosedCoder()) == nil)
    let team = CPNowPlayingSportsTeam(
        name: "Aces",
        logo: logo,
        teamStandings: "1st",
        eventScore: "21",
        possessionIndicator: image,
        favorite: true
    )
    precondition(team.isFavorite)
    precondition(CPNowPlayingSportsTeam(coder: failClosedCoder()) == nil)
    let sports = CPNowPlayingModeSports(leftTeam: team, rightTeam: team, eventStatus: status, backgroundArtwork: image)
    now.nowPlayingMode = sports
    _ = CPNowPlayingMode.default
    _ = CPNowPlayingButton(coder: failClosedCoder()) == nil || true
    _ = CPNowPlayingMode(coder: failClosedCoder()) == nil || true
    _ = CPNowPlayingButtonMaximumImageSize

    let sessionDelegate = RecordingSessionDelegate()
    let config = CPSessionConfiguration(delegate: sessionDelegate)
    precondition(config.limitedUserInterfaces.isEmpty)
    config.openuikit_applySimulatedStyle(.dark)
    config.openuikit_applyLimitedUserInterfaces([.lists, .keyboard])
    precondition(sessionDelegate.style.contains(.dark))
    precondition(sessionDelegate.limited.contains(.lists))
    _ = CPSessionConfiguration()

    let dashScene = CPTemplateApplicationDashboardScene()
    let dashSceneDelegate = RecordingDashDelegate()
    dashScene.delegate = dashSceneDelegate
    precondition(!dashScene.openuikit_simulateConnect())
    _ = dashScene.dashboardController
    _ = dashScene.dashboardWindow
    dashScene.delegate?.templateApplicationDashboardScene(dashScene, didConnect: dash, to: dashScene.dashboardWindow)
    dashScene.delegate?.templateApplicationDashboardScene(dashScene, didDisconnect: dash, from: dashScene.dashboardWindow)

    let clusterScene = CPTemplateApplicationInstrumentClusterScene()
    let clusterSceneDelegate = RecordingClusterSceneDelegate()
    clusterScene.delegate = clusterSceneDelegate
    precondition(!clusterScene.openuikit_simulateConnect())
    clusterScene.delegate?.templateApplicationInstrumentClusterScene(clusterScene, didConnect: cluster)
    clusterScene.delegate?.templateApplicationInstrumentClusterScene(clusterScene, didDisconnectInstrumentClusterController: cluster)
    clusterScene.delegate?.contentStyleDidChange(.dark)
    cluster.delegate?.instrumentClusterController(cluster, didChangeCompassSetting: .enabled)
    cluster.delegate?.instrumentClusterController(cluster, didChangeSpeedLimitSetting: .disabled)
    cluster.delegate?.instrumentClusterControllerDidZoom(in: cluster)
    cluster.delegate?.instrumentClusterControllerDidZoomOut(cluster)
    cluster.delegate?.instrumentClusterControllerDidConnect(UIWindow())
    cluster.delegate?.instrumentClusterControllerDidDisconnectWindow(UIWindow())

    let appDelegate = RecordingAppDelegate()
    appDelegate.application(UIApplication.shared, didConnectCarInterfaceController: controller, to: window)
    appDelegate.application(UIApplication.shared, didDisconnectCarInterfaceController: controller, from: window)
    appDelegate.application(UIApplication.shared, didSelect: maneuver)
    appDelegate.application(UIApplication.shared, didSelect: navAlert)

    ifaceDelegate.templateWillAppear(root, animated: false)
    ifaceDelegate.templateDidAppear(root, animated: false)
    ifaceDelegate.templateWillDisappear(root, animated: false)
    ifaceDelegate.templateDidDisappear(root, animated: false)

    _ = CPTimeRemainingColor.default
    _ = CPTimeRemainingColor.green
    _ = CPTimeRemainingColor.orange
    _ = CPTimeRemainingColor.red
    _ = CPTripEstimateStyle.light
    _ = CPTripEstimateStyle.dark
    _ = CPTextButtonStyle.normal
    _ = CPTextButtonStyle.cancel
    _ = CPTextButtonStyle.confirm
    _ = CPInformationTemplateLayout.leading
    _ = CPBarButtonStyle.none
    _ = CPListItemAccessoryType.cloud
    _ = CPListItemPlayingIndicatorLocation.leading
    _ = CPMessageLeadingItem.star
    _ = CPMessageTrailingItem.none
    _ = CPAssistantCellActionType.startCall
    _ = CPInstrumentClusterSetting.enabled
    _ = CPManeuverState.continue
    _ = CPManeuverState.execute
    _ = CPNavigationAlert.DismissalContext.timeout
    _ = CPNavigationAlert.DismissalContext.userDismissed
    _ = CPNavigationAlert.DismissalContext.systemDismissed
    _ = CPNavigationSession.PauseReason.arrived
    _ = CPNavigationSession.PauseReason.locating
    _ = CPNavigationSession.PauseReason.proceedToRoute

    print("CARPLAY_AGENT_RUNTIME_OK")
}

try await runCarPlayRuntime()

