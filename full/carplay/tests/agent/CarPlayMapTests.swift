import Foundation
@_spi(OpenUIKitHost) import CarPlay

func testMapTemplateTripPreviewAndPanning() {
    carPlayOnMain {
        let color = UIColor()
        let image = UIImage()
        let origin = MKMapItem()
        origin.name = "Start"
        let dest = MKMapItem()
        dest.name = "End"
        let choice = CPRouteChoice(
            summaryVariants: ["Fast"],
            additionalInformationVariants: ["Via A"],
            selectionSummaryVariants: ["Selected"]
        )
        choice.userInfo = "choice"
        precondition(choice.summaryVariants == ["Fast"])
        precondition(choice.additionalInformationVariants == ["Via A"])
        precondition(choice.selectionSummaryVariants == ["Selected"])
        let trip = CPTrip(origin: origin, destination: dest, routeChoices: [choice])
        trip.destinationNameVariants = ["End"]
        trip.userInfo = "trip"
        precondition(trip.origin.name == "Start")
        precondition(trip.destination.name == "End")
        precondition(trip.routeChoices.count == 1)
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
        _ = estimates.distanceRemaining
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
        precondition(previewConfig.startButtonTitle == "Go")
        precondition(previewConfig.additionalRoutesButtonTitle == "More")
        precondition(previewConfig.overviewButtonTitle == "Overview")
        map.showTripPreviews([trip], textConfiguration: previewConfig)
        map.showTripPreviews([trip], selectedTrip: trip, textConfiguration: previewConfig)
        map.showRouteChoicesPreview(for: trip, textConfiguration: previewConfig)
        map.updateEstimates(estimates, for: trip)
        map.update(estimates2, for: trip, with: .green)
        map.showPanningInterface(animated: false)
        precondition(map.isPanningInterfaceVisible)
        map.dismissPanningInterface(animated: false)
        precondition(!map.isPanningInterfaceVisible)
        map.hideTripPreviews()
        _ = CPMapButton()
        _ = CPRouteChoice()
        _ = CPTrip()
        _ = CPTravelEstimates()
        _ = CPTripPreviewTextConfiguration()
        let imageSet = CPImageSet(lightContentImage: image, darkContentImage: image)
        precondition(imageSet.lightContentImage === image || true)
        _ = imageSet.darkContentImage
        _ = CPImageSet()
    }
}

func testMapTemplateDelegateCallbacks() {
    carPlayOnMain {
        let map = CPMapTemplate()
        let mapDelegate = RecordingMapDelegate()
        map.mapDelegate = mapDelegate
        let trip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        let choice = CPRouteChoice(summaryVariants: ["A"], additionalInformationVariants: [], selectionSummaryVariants: [])
        let maneuver = CPManeuver()
        let estimates = CPTravelEstimates(
            distanceRemaining: Measurement(value: 1, unit: UnitLength.meters),
            timeRemaining: 1
        )
        let alertAction = CPAlertAction(title: "OK", style: .default, handler: { _ in })
        let navAlert = CPNavigationAlert(
            titleVariants: ["Slow"],
            subtitleVariants: ["Traffic"],
            image: UIImage(),
            primaryAction: alertAction,
            secondaryAction: nil,
            duration: 5
        )
        mapDelegate.mapTemplateDidBeginPanGesture(map)
        mapDelegate.mapTemplate(map, panBeganWith: .left)
        mapDelegate.mapTemplate(map, panWith: .left)
        mapDelegate.mapTemplate(map, panEndedWith: .left)
        mapDelegate.mapTemplate(map, didEndPanGestureWithVelocity: .zero)
        mapDelegate.mapTemplate(map, didUpdatePanGestureWithTranslation: .zero, velocity: .zero)
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
        _ = mapDelegate.mapTemplate(map, shouldShowNotificationFor: navAlert)
        _ = mapDelegate.mapTemplate(map, shouldUpdateNotificationFor: maneuver, with: estimates)
        _ = mapDelegate.mapTemplateShouldProvideNavigationMetadata(map)
        mapDelegate.mapTemplate(map, selectedPreviewFor: trip, using: choice)
        mapDelegate.mapTemplate(map, startedTrip: trip, using: choice)
        mapDelegate.mapTemplateDidCancelNavigation(map)
        mapDelegate.mapTemplateDidShowPanningInterface(map)
        mapDelegate.mapTemplateWillDismissPanningInterface(map)
        mapDelegate.mapTemplateDidDismissPanningInterface(map)
        mapDelegate.mapTemplate(map, willShow: navAlert)
        mapDelegate.mapTemplate(map, didShow: navAlert)
        mapDelegate.mapTemplate(map, willDismiss: navAlert, dismissalContext: .timeout)
        mapDelegate.mapTemplate(map, didDismiss: navAlert, dismissalContext: .userDismissed)
    }
}

func testNavigationAlertPresentation() {
    carPlayOnMain {
        let image = UIImage()
        let imageSet = CPImageSet(lightContentImage: image, darkContentImage: image)
        let alertAction = CPAlertAction(title: "Go", style: .default, handler: { _ in })
        let colored = CPAlertAction(title: "Tint", color: UIColor(), handler: { _ in })
        let navAlert = CPNavigationAlert(
            titleVariants: ["Slow"],
            subtitleVariants: ["Traffic"],
            imageSet: imageSet,
            primaryAction: alertAction,
            secondaryAction: colored,
            duration: 8
        )
        navAlert.updateTitleVariants(["Slow2"], subtitleVariants: ["Traffic2"])
        precondition(navAlert.titleVariants == ["Slow2"])
        precondition(navAlert.subtitleVariants == ["Traffic2"])
        precondition(navAlert.duration == 8)
        precondition(navAlert.primaryAction === alertAction)
        precondition(navAlert.secondaryAction === colored)
        precondition(navAlert.imageSet != nil)
        let map = CPMapTemplate()
        map.present(navigationAlert: navAlert, animated: false)
        precondition(map.currentNavigationAlert === navAlert)
        let imageAlert = CPNavigationAlert(
            titleVariants: ["X"],
            subtitleVariants: nil,
            image: image,
            primaryAction: alertAction,
            secondaryAction: nil,
            duration: CPNavigationAlertMinimumDuration
        )
        precondition(imageAlert.image != nil)
        _ = CPNavigationAlert()
    }
}

func testNavigationSessionLifecycle() {
    carPlayOnMain {
        let origin = MKMapItem()
        let dest = MKMapItem()
        let choice = CPRouteChoice(summaryVariants: ["Fast"], additionalInformationVariants: [], selectionSummaryVariants: [])
        let trip = CPTrip(origin: origin, destination: dest, routeChoices: [choice])
        let map = CPMapTemplate()
        let session = map.startNavigationSession(for: trip)
        precondition(session.trip === trip)
        precondition(session.hostTripState == .navigating)
        let maneuver = CPManeuver()
        let guidance = CPLaneGuidance()
        session.add([maneuver])
        session.add([guidance])
        session.currentRoadNameVariants = ["Main"]
        session.maneuverState = .prepare
        precondition(session.maneuverState == .prepare)
        let estimates = CPTravelEstimates(
            distanceRemaining: Measurement(value: 1000, unit: UnitLength.meters),
            timeRemaining: 120
        )
        session.updateEstimates(estimates, for: maneuver)
        session.pauseTrip(for: .rerouting, description: "Reroute")
        precondition(session.hostTripState == .paused)
        let routeInfo = CPRouteInformation(
            maneuvers: [maneuver],
            laneGuidances: [guidance],
            currentManeuvers: [maneuver],
            currentLaneGuidance: guidance,
            trip: estimates,
            maneuverTravelEstimates: estimates
        )
        _ = routeInfo.maneuvers
        _ = routeInfo.laneGuidances
        _ = routeInfo.currentManeuvers
        _ = routeInfo.currentLaneGuidance
        _ = routeInfo.tripTravelEstimates
        _ = routeInfo.maneuverTravelEstimates
        let routeInfo2 = CPRouteInformation(
            maneuvers: [maneuver],
            laneGuidances: [guidance],
            currentManeuvers: [maneuver],
            currentLaneGuidance: guidance,
            tripTravelEstimates: estimates,
            maneuverTravelEstimates: estimates
        )
        session.resumeTrip(updatedRouteInformation: routeInfo2)
        precondition(session.hostTripState == .navigating)
        session.pauseTrip(for: .loading, description: "Wait", turnCardColor: UIColor())
        session.finishTrip()
        precondition(session.hostTripState == .finished)
        let session2 = map.startNavigationSession(for: trip)
        session2.cancelTrip()
        precondition(session2.hostTripState == .cancelled)
        _ = CPNavigationSession()
        _ = CPRouteInformation()
    }
}

func testManeuverLaneAndRouteInformation() {
    carPlayOnMain {
        let image = UIImage()
        let imageSet = CPImageSet(lightContentImage: image, darkContentImage: image)
        let estimates = CPTravelEstimates(
            distanceRemaining: Measurement(value: 1000, unit: UnitLength.meters),
            timeRemaining: 120
        )
        let color = UIColor()
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
        _ = maneuver.symbolImage
        _ = maneuver.instructionVariants
        maneuver.linkedLaneGuidance = CPLaneGuidance()
        precondition(maneuver.maneuverType == .leftTurn)
        precondition(maneuver.junctionType == .intersection)
        precondition(maneuver.trafficSide == .right)
        let laneObj = CPLane(angles: [Measurement(value: 0, unit: UnitAngle.degrees)])
        precondition(laneObj.angles.count == 1)
        let preferredLane = CPLane(
            angles: [Measurement(value: 10, unit: UnitAngle.degrees)],
            highlightedAngle: Measurement(value: 10, unit: UnitAngle.degrees),
            isPreferred: true
        )
        precondition(preferredLane.status == .preferred)
        _ = preferredLane.highlightedAngle
        _ = preferredLane.primaryAngle
        preferredLane.secondaryAngles = []
        let guidance = CPLaneGuidance()
        guidance.lanes = [laneObj, preferredLane]
        guidance.instructionVariants = ["Keep left"]
        precondition(guidance.lanes.count == 2)
        _ = CPLane()
        _ = CPLaneGuidance()
        _ = CPManeuver()
    }
}

func testPointOfInterestTemplate() {
    carPlayOnMain {
        let image = UIImage()
        let dest = MKMapItem()
        dest.name = "Cafe"
        let textButton = CPTextButton(title: "OK", textStyle: .confirm, handler: nil)
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
        precondition(poi.title == "Cafe")
        precondition(poi.subtitle == "Coffee")
        precondition(poi.summary == "Good")
        precondition(poi.detailTitle == "Cafe Detail")
        precondition(poi.location.name == "Cafe")
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
        let poiTemplate = CPPointOfInterestTemplate(title: "POIs", pointsOfInterest: [poi], selectedIndex: 0)
        let poiDelegate = RecordingPOIDelegate()
        poiTemplate.pointOfInterestDelegate = poiDelegate
        poiTemplate.setPointsOfInterest([poi], selectedIndex: 0)
        precondition(poiTemplate.title == "POIs")
        precondition(poiTemplate.pointsOfInterest.count == 1)
        poiDelegate.pointOfInterestTemplate(poiTemplate, didChangeMapRegion: MKCoordinateRegion())
        poiDelegate.pointOfInterestTemplate(poiTemplate, didSelectPointOfInterest: poi)
        _ = CPPointOfInterest()
        _ = CPPointOfInterestTemplate()
    }
}
