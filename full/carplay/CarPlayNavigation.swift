import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(MapKit)
import MapKit
#endif

open class CPTravelEstimates: NSObject {
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

open class CPRouteChoice: NSObject {
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

#if canImport(MapKit)
open class CPTrip: NSObject {
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
#endif

open class CPTripPreviewTextConfiguration: NSObject {
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

open class CPLane: NSObject {
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

open class CPLaneGuidance: NSObject {
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

open class CPManeuver: NSObject {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var attributedInstructionVariants: [NSAttributedString]
    public var dashboardAttributedInstructionVariants: [NSAttributedString]
    public var dashboardInstructionVariants: [String]
    public var highwayExitLabel: String
    public var initialTravelEstimates: CPTravelEstimates?
    public var instructionVariants: [String]
    public var junctionElementAngles: Set<Measurement<UnitAngle>>?
    public var junctionExitAngle: Measurement<UnitAngle>?
    public var junctionType: CPJunctionType
    public var linkedLaneGuidance: CPLaneGuidance
    public var maneuverType: CPManeuverType
    public var notificationAttributedInstructionVariants: [NSAttributedString]
    public var notificationInstructionVariants: [String]
    public var roadFollowingManeuverVariants: [String]?
    public var trafficSide: CPTrafficSide
    public var userInfo: Any?

    #if canImport(UIKit)
    public var cardBackgroundColor: UIColor?
    public var dashboardJunctionImage: UIImage?
    public var dashboardSymbolImage: UIImage?
    public var junctionImage: UIImage?
    public var notificationSymbolImage: UIImage?
    public var symbolImage: UIImage?
    public var symbolSet: CPImageSet?
    #endif

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

open class CPRouteInformation: NSObject {
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
open class CPNavigationAlert: NSObject {
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
    public let primaryAction: CPAlertAction
    public let secondaryAction: CPAlertAction?
    public let duration: TimeInterval

    #if canImport(UIKit)
    public let image: UIImage?
    public let imageSet: CPImageSet?
    #endif

    @_spi(OpenUIKitHost)
    public init(
        hostTitleVariants titleVariants: [String],
        subtitleVariants: [String]?,
        primaryAction: CPAlertAction,
        secondaryAction: CPAlertAction?,
        duration: TimeInterval
    ) {
        self.titleVariants = titleVariants
        self.subtitleVariants = subtitleVariants ?? []
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.duration = duration
        #if canImport(UIKit)
        self.image = nil
        self.imageSet = nil
        #endif
        super.init()
    }

    #if canImport(UIKit)
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
        self.duration = duration
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
        self.duration = duration
        super.init()
    }
    #endif

    public func updateTitleVariants(_ newTitleVariants: [String], subtitleVariants newSubtitleVariants: [String]) {
        titleVariants = newTitleVariants
        subtitleVariants = newSubtitleVariants
    }
}

#if canImport(MapKit)
@MainActor
open class CPNavigationSession: NSObject {
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

    @_spi(OpenUIKitHost)
    public enum HostTripState: Equatable, Sendable {
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
    public private(set) var estimatesByManeuver: [ObjectIdentifier: CPTravelEstimates]
    public private(set) var pauseDescription: String?

    @_spi(OpenUIKitHost)
    public private(set) var hostTripState: HostTripState

    #if canImport(UIKit)
    public private(set) var pauseTurnCardColor: UIColor?
    #endif

    public init(trip: CPTrip) {
        self.trip = trip
        self.upcomingManeuvers = []
        self.currentRoadNameVariants = []
        self.maneuverState = .initial
        self.hostTripState = .navigating
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
        hostTripState = .cancelled
        upcomingManeuvers = []
    }

    public func finishTrip() {
        hostTripState = .finished
        upcomingManeuvers = []
        maneuverState = .execute
    }

    public func pauseTrip(for reason: PauseReason, description: String?) {
        hostTripState = .paused(reason)
        pauseDescription = description
        #if canImport(UIKit)
        pauseTurnCardColor = nil
        #endif
    }

    #if canImport(UIKit)
    public func pauseTrip(for reason: PauseReason, description: String?, turnCardColor: UIColor?) {
        hostTripState = .paused(reason)
        pauseDescription = description
        pauseTurnCardColor = turnCardColor
    }
    #endif

    public func resumeTrip(updatedRouteInformation routeInformation: CPRouteInformation) {
        hostTripState = .navigating
        upcomingManeuvers = routeInformation.maneuvers
        currentLaneGuidance = routeInformation.currentLaneGuidance
        pauseDescription = nil
        #if canImport(UIKit)
        pauseTurnCardColor = nil
        #endif
    }

    public func updateEstimates(_ estimates: CPTravelEstimates, for maneuver: CPManeuver) {
        estimatesByManeuver[ObjectIdentifier(maneuver)] = estimates
        maneuver.initialTravelEstimates = estimates
    }
}

open class CPPointOfInterest: NSObject {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public class var pinImageSize: CGSize { .zero }
    public class var selectedPinImageSize: CGSize { .zero }

    public var location: MKMapItem
    public var title: String
    public var subtitle: String?
    public var summary: String?
    public var detailTitle: String?
    public var detailSubtitle: String?
    public var detailSummary: String?
    public var primaryButton: CPTextButton?
    public var secondaryButton: CPTextButton?
    public var userInfo: Any?

    #if canImport(UIKit)
    public var pinImage: UIImage?
    public var selectedPinImage: UIImage?

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
    #else
    @_spi(OpenUIKitHost)
    public init(
        location: MKMapItem,
        title: String,
        subtitle: String?,
        summary: String?,
        detailTitle: String?,
        detailSubtitle: String?,
        detailSummary: String?
    ) {
        self.location = location
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.detailTitle = detailTitle
        self.detailSubtitle = detailSubtitle
        self.detailSummary = detailSummary
        super.init()
    }
    #endif
}
#endif

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
    public weak var mapDelegate: (any CPMapTemplateDelegate)?
    public var tripEstimateStyle: CPTripEstimateStyle = .light
    public private(set) var currentNavigationAlert: CPNavigationAlert?
    public private(set) var isPanningInterfaceVisible = false

    #if canImport(UIKit)
    public var guidanceBackgroundColor = UIColor.black
    public var mapButtons: [CPMapButton] = []
    #endif

    #if canImport(MapKit)
    @_spi(OpenUIKitHost)
    public private(set) var hostTripPreviews: [CPTrip] = []
    @_spi(OpenUIKitHost)
    public private(set) var hostSelectedTrip: CPTrip?
    @_spi(OpenUIKitHost)
    public private(set) var hostTripEstimates: [ObjectIdentifier: CPTravelEstimates] = [:]
    @_spi(OpenUIKitHost)
    public private(set) var hostNavigationSession: CPNavigationSession?
    #endif

    public func showPanningInterface(animated: Bool) {
        guard CarPlayHostSessionState.isConnected else { return }
        isPanningInterfaceVisible = true
        mapDelegate?.mapTemplateDidShowPanningInterface(self)
        _ = animated
    }

    public func dismissPanningInterface(animated: Bool) {
        guard CarPlayHostSessionState.isConnected else { return }
        mapDelegate?.mapTemplateWillDismissPanningInterface(self)
        isPanningInterfaceVisible = false
        mapDelegate?.mapTemplateDidDismissPanningInterface(self)
        _ = animated
    }

    public func present(navigationAlert: CPNavigationAlert, animated: Bool) {
        guard CarPlayHostSessionState.isConnected else { return }
        mapDelegate?.mapTemplate(self, willShow: navigationAlert)
        currentNavigationAlert = navigationAlert
        mapDelegate?.mapTemplate(self, didShow: navigationAlert)
        _ = animated
    }

    public func dismissNavigationAlert(animated: Bool) async -> Bool {
        guard CarPlayHostSessionState.isConnected else { return false }
        guard let alert = currentNavigationAlert else { return false }
        mapDelegate?.mapTemplate(self, willDismiss: alert, dismissalContext: .systemDismissed)
        currentNavigationAlert = nil
        mapDelegate?.mapTemplate(self, didDismiss: alert, dismissalContext: .systemDismissed)
        _ = animated
        return true
    }

    #if canImport(MapKit)
    public func hideTripPreviews() {
        guard CarPlayHostSessionState.isConnected else { return }
        hostTripPreviews = []
        hostSelectedTrip = nil
    }

    public func showTripPreviews(_ tripPreviews: [CPTrip], textConfiguration: CPTripPreviewTextConfiguration?) {
        guard CarPlayHostSessionState.isConnected else { return }
        showTripPreviews(tripPreviews, selectedTrip: tripPreviews.first, textConfiguration: textConfiguration)
    }

    public func showTripPreviews(
        _ tripPreviews: [CPTrip],
        selectedTrip: CPTrip?,
        textConfiguration: CPTripPreviewTextConfiguration?
    ) {
        guard CarPlayHostSessionState.isConnected else { return }
        hostTripPreviews = tripPreviews
        hostSelectedTrip = selectedTrip
        _ = textConfiguration
    }

    public func showRouteChoicesPreview(for tripPreview: CPTrip, textConfiguration: CPTripPreviewTextConfiguration?) {
        guard CarPlayHostSessionState.isConnected else { return }
        hostTripPreviews = [tripPreview]
        hostSelectedTrip = tripPreview
        _ = textConfiguration
    }

    public func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
        let session = CPNavigationSession(trip: trip)
        guard CarPlayHostSessionState.isConnected else { return session }
        hostNavigationSession = session
        if let choice = trip.routeChoices.first {
            mapDelegate?.mapTemplate(self, startedTrip: trip, using: choice)
        }
        return session
    }

    public func updateEstimates(_ estimates: CPTravelEstimates, for trip: CPTrip) {
        guard CarPlayHostSessionState.isConnected else { return }
        hostTripEstimates[ObjectIdentifier(trip)] = estimates
    }

    public func update(
        _ estimates: CPTravelEstimates,
        for trip: CPTrip,
        with timeRemainingColor: CPTimeRemainingColor
    ) {
        guard CarPlayHostSessionState.isConnected else { return }
        hostTripEstimates[ObjectIdentifier(trip)] = estimates
        _ = timeRemainingColor
    }
    #endif
}
