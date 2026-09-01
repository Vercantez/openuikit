import Foundation

open class CPTravelEstimates: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let distanceRemaining: Measurement<UnitLength>
    public let distanceRemainingToDisplay: Measurement<UnitLength>
    public let timeRemaining: TimeInterval

    public init(
        distanceRemaining: Measurement<UnitLength>,
        distanceRemainingToDisplay: Measurement<UnitLength>,
        timeRemaining time: TimeInterval
    ) {
        self.distanceRemaining = distanceRemaining
        self.distanceRemainingToDisplay = distanceRemainingToDisplay
        self.timeRemaining = time
        super.init()
    }

    public convenience init(
        distanceRemaining distance: Measurement<UnitLength>,
        timeRemaining time: TimeInterval
    ) {
        self.init(
            distanceRemaining: distance,
            distanceRemainingToDisplay: distance,
            timeRemaining: time
        )
    }

}

open class CPRouteChoice: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let summaryVariants: [String]
    public let additionalInformationVariants: [String]?
    public let selectionSummaryVariants: [String]?
    public var userInfo: Any?

    public init(
        summaryVariants: [String],
        additionalInformationVariants: [String],
        selectionSummaryVariants: [String]
    ) {
        self.summaryVariants = summaryVariants
        self.additionalInformationVariants = additionalInformationVariants
        self.selectionSummaryVariants = selectionSummaryVariants
        super.init()
    }

}

open class CPTrip: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let origin: MKMapItem
    public let destination: MKMapItem
    public let routeChoices: [CPRouteChoice]
    public var destinationNameVariants: [String]?
    public var userInfo: Any?

    public init(origin: MKMapItem, destination: MKMapItem, routeChoices: [CPRouteChoice]) {
        self.origin = origin
        self.destination = destination
        self.routeChoices = routeChoices
        super.init()
    }

}

open class CPTripPreviewTextConfiguration: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let startButtonTitle: String?
    public let additionalRoutesButtonTitle: String?
    public let overviewButtonTitle: String?

    public init(
        startButtonTitle: String?,
        additionalRoutesButtonTitle: String?,
        overviewButtonTitle: String?
    ) {
        self.startButtonTitle = startButtonTitle
        self.additionalRoutesButtonTitle = additionalRoutesButtonTitle
        self.overviewButtonTitle = overviewButtonTitle
        super.init()
    }

}

open class CPLane: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public private(set) var angles: [Measurement<UnitAngle>]
    public private(set) var highlightedAngle: Measurement<UnitAngle>?
    public var primaryAngle: Measurement<UnitAngle>
    public var secondaryAngles: [Measurement<UnitAngle>]
    public var status: CPLaneStatus
    public let isPreferred: Bool

    public override init() {
        self.angles = []
        self.highlightedAngle = nil
        self.primaryAngle = Measurement(value: 0, unit: UnitAngle.degrees)
        self.secondaryAngles = []
        self.status = .notGood
        self.isPreferred = false
        super.init()
    }

    public init(angles: [Measurement<UnitAngle>]) {
        self.angles = angles
        self.highlightedAngle = nil
        self.primaryAngle = angles.first ?? Measurement(value: 0, unit: UnitAngle.degrees)
        self.secondaryAngles = Array(angles.dropFirst())
        self.status = .notGood
        self.isPreferred = false
        super.init()
    }

    public init(
        angles: [Measurement<UnitAngle>],
        highlightedAngle: Measurement<UnitAngle>,
        isPreferred preferred: Bool
    ) {
        self.angles = angles
        self.highlightedAngle = highlightedAngle
        self.primaryAngle = highlightedAngle
        self.secondaryAngles = angles.filter { $0 != highlightedAngle }
        self.status = preferred ? .preferred : .good
        self.isPreferred = preferred
        super.init()
    }

}

open class CPLaneGuidance: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var instructionVariants: [String]
    public var lanes: [CPLane]

    public override init() {
        self.instructionVariants = []
        self.lanes = []
        super.init()
    }

}

open class CPManeuver: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var attributedInstructionVariants: [NSAttributedString]
    public var cardBackgroundColor: UIColor?
    public var dashboardAttributedInstructionVariants: [NSAttributedString]
    public var dashboardInstructionVariants: [String]
    public var dashboardJunctionImage: UIImage?
    public var dashboardSymbolImage: UIImage?
    public var highwayExitLabel: String
    public var initialTravelEstimates: CPTravelEstimates?
    public var instructionVariants: [String]
    public var junctionElementAngles: Set<Measurement<UnitAngle>>?
    public var junctionExitAngle: Measurement<UnitAngle>?
    public var junctionImage: UIImage?
    public var junctionType: CPJunctionType
    public var linkedLaneGuidance: CPLaneGuidance
    public var maneuverType: CPManeuverType
    public var notificationAttributedInstructionVariants: [NSAttributedString]
    public var notificationInstructionVariants: [String]
    public var notificationSymbolImage: UIImage?
    public var roadFollowingManeuverVariants: [String]?
    public var symbolImage: UIImage?
    public var symbolSet: CPImageSet?
    public var trafficSide: CPTrafficSide
    public var userInfo: Any?

    public override init() {
        self.attributedInstructionVariants = []
        self.dashboardAttributedInstructionVariants = []
        self.dashboardInstructionVariants = []
        self.highwayExitLabel = ""
        self.instructionVariants = []
        self.junctionType = .intersection
        self.linkedLaneGuidance = CPLaneGuidance()
        self.maneuverType = .noTurn
        self.notificationAttributedInstructionVariants = []
        self.notificationInstructionVariants = []
        self.trafficSide = .right
        super.init()
    }

}

open class CPRouteInformation: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let maneuvers: [CPManeuver]
    public let laneGuidances: [CPLaneGuidance]
    public let currentManeuvers: [CPManeuver]
    public let currentLaneGuidance: CPLaneGuidance
    public let tripTravelEstimates: CPTravelEstimates
    public let maneuverTravelEstimates: CPTravelEstimates

    public init(
        maneuvers: [CPManeuver],
        laneGuidances: [CPLaneGuidance],
        currentManeuvers: [CPManeuver],
        currentLaneGuidance: CPLaneGuidance,
        trip tripTravelEstimates: CPTravelEstimates,
        maneuverTravelEstimates: CPTravelEstimates
    ) {
        self.maneuvers = maneuvers
        self.laneGuidances = laneGuidances
        self.currentManeuvers = currentManeuvers
        self.currentLaneGuidance = currentLaneGuidance
        self.tripTravelEstimates = tripTravelEstimates
        self.maneuverTravelEstimates = maneuverTravelEstimates
        super.init()
    }

    public convenience init(
        maneuvers: [CPManeuver],
        laneGuidances: [CPLaneGuidance],
        currentManeuvers: [CPManeuver],
        currentLaneGuidance: CPLaneGuidance,
        tripTravelEstimates: CPTravelEstimates,
        maneuverTravelEstimates: CPTravelEstimates
    ) {
        self.init(
            maneuvers: maneuvers,
            laneGuidances: laneGuidances,
            currentManeuvers: currentManeuvers,
            currentLaneGuidance: currentLaneGuidance,
            trip: tripTravelEstimates,
            maneuverTravelEstimates: maneuverTravelEstimates
        )
    }

}

@MainActor
open class CPNavigationAlert: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public enum DismissalContext: UInt, Equatable, Hashable, Sendable {
        case timeout = 0
        case userDismissed = 1
        case systemDismissed = 2
    }

    public private(set) var titleVariants: [String]
    public private(set) var subtitleVariants: [String]
    public let image: UIImage?
    public let imageSet: CPImageSet?
    public let primaryAction: CPAlertAction
    public let secondaryAction: CPAlertAction?
    public let duration: TimeInterval

    public init(
        titleVariants: [String],
        subtitleVariants: [String]?,
        image: UIImage?,
        primaryAction: CPAlertAction,
        secondaryAction: CPAlertAction?,
        duration: TimeInterval
    ) {
        self.titleVariants = titleVariants
        self.subtitleVariants = subtitleVariants ?? []
        self.image = image
        self.imageSet = nil
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.duration = max(duration, CPNavigationAlertMinimumDuration)
        super.init()
    }

    public init(
        titleVariants: [String],
        subtitleVariants: [String]?,
        imageSet: CPImageSet?,
        primaryAction: CPAlertAction,
        secondaryAction: CPAlertAction?,
        duration: TimeInterval
    ) {
        self.titleVariants = titleVariants
        self.subtitleVariants = subtitleVariants ?? []
        self.image = nil
        self.imageSet = imageSet
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.duration = max(duration, CPNavigationAlertMinimumDuration)
        super.init()
    }

    public func updateTitleVariants(_ newTitleVariants: [String], subtitleVariants newSubtitleVariants: [String]) {
        titleVariants = newTitleVariants
        subtitleVariants = newSubtitleVariants
    }

}

@MainActor
open class CPNavigationSession: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public enum PauseReason: UInt, Equatable, Hashable, Sendable {
        case arrived = 0
        case loading = 1
        case locating = 2
        case rerouting = 3
        case proceedToRoute = 4
    }

    public enum PortableTripState: Equatable, Sendable {
        case navigating
        case paused(PauseReason)
        case finished
        case cancelled
    }

    public let trip: CPTrip
    public var upcomingManeuvers: [CPManeuver]
    public var currentLaneGuidance: CPLaneGuidance?
    public var currentRoadNameVariants: [String]
    public var maneuverState: CPManeuverState
    public private(set) var portableTripState: PortableTripState
    public private(set) var estimatesByManeuver: [ObjectIdentifier: CPTravelEstimates]
    public private(set) var pauseDescription: String?
    public private(set) var pauseTurnCardColor: UIColor?

    public init(trip: CPTrip) {
        self.trip = trip
        self.upcomingManeuvers = []
        self.currentRoadNameVariants = []
        self.maneuverState = .initial
        self.portableTripState = .navigating
        self.estimatesByManeuver = [:]
        super.init()
    }

    public func add(_ laneGuidances: [CPLaneGuidance]) {
        if currentLaneGuidance == nil {
            currentLaneGuidance = laneGuidances.first
        }
    }

    public func add(_ maneuvers: [CPManeuver]) {
        upcomingManeuvers.append(contentsOf: maneuvers)
    }

    public func cancelTrip() {
        portableTripState = .cancelled
        upcomingManeuvers = []
    }

    public func finishTrip() {
        portableTripState = .finished
        upcomingManeuvers = []
        maneuverState = .execute
    }

    public func pauseTrip(for reason: PauseReason, description: String?) {
        pauseTrip(for: reason, description: description, turnCardColor: nil)
    }

    public func pauseTrip(for reason: PauseReason, description: String?, turnCardColor: UIColor?) {
        portableTripState = .paused(reason)
        pauseDescription = description
        pauseTurnCardColor = turnCardColor
    }

    public func resumeTrip(updatedRouteInformation routeInformation: CPRouteInformation) {
        portableTripState = .navigating
        upcomingManeuvers = routeInformation.maneuvers
        currentLaneGuidance = routeInformation.currentLaneGuidance
        pauseDescription = nil
        pauseTurnCardColor = nil
    }

    public func updateEstimates(_ estimates: CPTravelEstimates, for maneuver: CPManeuver) {
        estimatesByManeuver[ObjectIdentifier(maneuver)] = estimates
        maneuver.initialTravelEstimates = estimates
    }

}

open class CPPointOfInterest: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public class var pinImageSize: CGSize { CGSize(width: 40, height: 40) }
    public class var selectedPinImageSize: CGSize { CGSize(width: 50, height: 50) }

    public var location: MKMapItem
    public var title: String
    public var subtitle: String?
    public var summary: String?
    public var detailTitle: String?
    public var detailSubtitle: String?
    public var detailSummary: String?
    public var pinImage: UIImage?
    public var selectedPinImage: UIImage?
    public var primaryButton: CPTextButton?
    public var secondaryButton: CPTextButton?
    public var userInfo: Any?

    public init(
        location: MKMapItem,
        title: String,
        subtitle: String?,
        summary: String?,
        detailTitle: String?,
        detailSubtitle: String?,
        detailSummary: String?,
        pinImage: UIImage?,
        selectedPinImage: UIImage?
    ) {
        self.location = location
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.detailTitle = detailTitle
        self.detailSubtitle = detailSubtitle
        self.detailSummary = detailSummary
        self.pinImage = pinImage
        self.selectedPinImage = selectedPinImage
        super.init()
    }

    public convenience init(
        location: MKMapItem,
        title: String,
        subtitle: String?,
        summary: String?,
        detailTitle: String?,
        detailSubtitle: String?,
        detailSummary: String?,
        pinImage: UIImage?
    ) {
        self.init(
            location: location,
            title: title,
            subtitle: subtitle,
            summary: summary,
            detailTitle: detailTitle,
            detailSubtitle: detailSubtitle,
            detailSummary: detailSummary,
            pinImage: pinImage,
            selectedPinImage: nil
        )
    }

}

@MainActor
open class CPMapTemplate: CPTemplate {
    public struct PanDirection: OptionSet, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let right = PanDirection(rawValue: 1 << 0)
        public static let left = PanDirection(rawValue: 1 << 1)
        public static let up = PanDirection(rawValue: 1 << 2)
        public static let down = PanDirection(rawValue: 1 << 3)
    }

    public var automaticallyHidesNavigationBar = true
    public var hidesButtonsWithNavigationBar = true
    public var guidanceBackgroundColor = UIColor.black
    public var mapButtons: [CPMapButton] = []
    public weak var mapDelegate: (any CPMapTemplateDelegate)?
    public var tripEstimateStyle: CPTripEstimateStyle = .light
    public private(set) var currentNavigationAlert: CPNavigationAlert?
    public private(set) var isPanningInterfaceVisible = false
    public private(set) var portableTripPreviews: [CPTrip] = []
    public private(set) var portableSelectedTrip: CPTrip?
    public private(set) var portableTripEstimates: [ObjectIdentifier: CPTravelEstimates] = [:]
    public private(set) var portableNavigationSession: CPNavigationSession?

    public func showPanningInterface(animated: Bool) {
        isPanningInterfaceVisible = true
        mapDelegate?.mapTemplateDidShowPanningInterface(self)
        _ = animated
    }

    public func dismissPanningInterface(animated: Bool) {
        mapDelegate?.mapTemplateWillDismissPanningInterface(self)
        isPanningInterfaceVisible = false
        mapDelegate?.mapTemplateDidDismissPanningInterface(self)
        _ = animated
    }

    public func hideTripPreviews() {
        portableTripPreviews = []
        portableSelectedTrip = nil
    }

    public func showTripPreviews(_ tripPreviews: [CPTrip], textConfiguration: CPTripPreviewTextConfiguration?) {
        showTripPreviews(tripPreviews, selectedTrip: tripPreviews.first, textConfiguration: textConfiguration)
    }

    public func showTripPreviews(
        _ tripPreviews: [CPTrip],
        selectedTrip: CPTrip?,
        textConfiguration: CPTripPreviewTextConfiguration?
    ) {
        portableTripPreviews = tripPreviews
        portableSelectedTrip = selectedTrip
        _ = textConfiguration
    }

    public func showRouteChoicesPreview(for tripPreview: CPTrip, textConfiguration: CPTripPreviewTextConfiguration?) {
        portableTripPreviews = [tripPreview]
        portableSelectedTrip = tripPreview
        _ = textConfiguration
    }

    public func present(navigationAlert: CPNavigationAlert, animated: Bool) {
        mapDelegate?.mapTemplate(self, willShow: navigationAlert)
        currentNavigationAlert = navigationAlert
        mapDelegate?.mapTemplate(self, didShow: navigationAlert)
        _ = animated
    }

    public func dismissNavigationAlert(animated: Bool) async -> Bool {
        guard let alert = currentNavigationAlert else { return false }
        mapDelegate?.mapTemplate(self, willDismiss: alert, dismissalContext: .systemDismissed)
        currentNavigationAlert = nil
        mapDelegate?.mapTemplate(self, didDismiss: alert, dismissalContext: .systemDismissed)
        _ = animated
        return true
    }

    public func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
        let session = CPNavigationSession(trip: trip)
        portableNavigationSession = session
        if let choice = trip.routeChoices.first {
            mapDelegate?.mapTemplate(self, startedTrip: trip, using: choice)
        }
        return session
    }

    public func updateEstimates(_ estimates: CPTravelEstimates, for trip: CPTrip) {
        portableTripEstimates[ObjectIdentifier(trip)] = estimates
    }

    public func update(
        _ estimates: CPTravelEstimates,
        for trip: CPTrip,
        with timeRemainingColor: CPTimeRemainingColor
    ) {
        portableTripEstimates[ObjectIdentifier(trip)] = estimates
        _ = timeRemainingColor
    }

}
