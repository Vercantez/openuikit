import Foundation

open class CPAlertAction: NSObject, @unchecked Sendable {
    public enum Style: Int, Sendable, Hashable {
        case cancel = 1
        case `default` = 0
        case destructive = 2
    }
    public var color: UIColor? = nil
    public var handler: CPAlertActionHandler = { _ in }
    public var style: CPAlertAction.Style = .`default`
    public var title: String = ""
    public override init() { super.init() }
    public init(title: String, color: UIColor, handler: @escaping CPAlertActionHandler) {
        super.init()
        self.title = title
        self.color = color
        self.handler = handler
    }
    public init(title: String, style: CPAlertAction.Style, handler: @escaping CPAlertActionHandler) {
        super.init()
        self.title = title
        self.style = style
        self.handler = handler
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPAssistantCellConfiguration: NSObject, @unchecked Sendable {
    public var assistantAction: CPAssistantCellActionType = .playMedia
    public var position: CPListItem.AssistantCellPosition = .top
    public var visibility: CPListItem.AssistantCellVisibility = .off
    public override init() { super.init() }
    public init(position: CPListItem.AssistantCellPosition, visibility: CPListItem.AssistantCellVisibility, assistantAction: CPAssistantCellActionType) {
        super.init()
        self.position = position
        self.visibility = visibility
        self.assistantAction = assistantAction
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPBarButton: NSObject, @unchecked Sendable {
    public enum `Type`: Int, Sendable, Hashable {
        case image = 1
        case text = 0
    }
    public var buttonStyle: CPBarButtonStyle = .none
    public var buttonType: CPBarButton.`Type` = .text
    public var isEnabled: Bool = true
    public var image: UIImage? = nil
    public var title: String? = nil
    var storedHandler: CPBarButtonHandler? = nil
    public override init() { super.init() }
    public init(image: UIImage, handler: CPBarButtonHandler? = nil) {
        super.init()
        self.image = image
        self.buttonType = .image
        self.storedHandler = handler
    }
    public init(title: String, handler: CPBarButtonHandler? = nil) {
        super.init()
        self.title = title
        self.buttonType = .text
        self.storedHandler = handler
    }
    public init(type: CPBarButton.`Type`, handler: CPBarButtonHandler? = nil) {
        super.init()
        self.buttonType = type
        self.storedHandler = handler
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPButton: NSObject, @unchecked Sendable {
    public var isEnabled: Bool = true
    public var image: UIImage? = nil
    public var title: String? = nil
    var storedHandler: ((CPButton) -> Void)? = nil
    public override init() { super.init() }
    public init(image: UIImage, handler: ((CPButton) -> Void)? = nil) {
        super.init()
        self.image = image
        self.storedHandler = handler
    }
}

open class CPContact: NSObject, @unchecked Sendable {
    public var actions: [CPButton]? = nil
    public var image: UIImage = UIImage()
    public var informativeText: String? = nil
    public var name: String = ""
    public var subtitle: String? = nil
    public override init() { super.init() }
    public init(name: String, image: UIImage) {
        super.init()
        self.name = name
        self.image = image
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPContactCallButton: CPButton, @unchecked Sendable {
    public override init() { super.init() }
    public init(handler: ((CPButton) -> Void)? = nil) {
        super.init()
        self.storedHandler = handler
    }
}

open class CPContactDirectionsButton: CPButton, @unchecked Sendable {
    public override init() { super.init() }
    public init(handler: ((CPButton) -> Void)? = nil) {
        super.init()
        self.storedHandler = handler
    }
}

open class CPContactMessageButton: CPButton, @unchecked Sendable {
    public var phoneOrEmail: String = ""
    public override init() { super.init() }
    public init(phoneOrEmail: String) {
        super.init()
        self.phoneOrEmail = phoneOrEmail
    }
}

open class CPDashboardButton: NSObject, @unchecked Sendable {
    public var image: UIImage = UIImage()
    public var subtitleVariants: [String] = []
    public var titleVariants: [String] = []
    var storedHandler: ((CPDashboardButton) -> Void)? = nil
    public override init() { super.init() }
    public init(titleVariants: [String], subtitleVariants: [String], image: UIImage, handler: ((CPDashboardButton) -> Void)? = nil) {
        super.init()
        self.titleVariants = titleVariants
        self.subtitleVariants = subtitleVariants
        self.image = image
        self.storedHandler = handler
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPDashboardController: NSObject, @unchecked Sendable {
    /// Stored locally only. Linux has no dashboard head unit, so assigning
    /// shortcuts never presents them to a vehicle.
    public var shortcutButtons: [CPDashboardButton] = []
    public override init() { super.init() }

    @_spi(OpenUIKitHost)
    public var openuikit_vehiclePresentationActive: Bool { false }
}

open class CPGridButton: NSObject, @unchecked Sendable {
    public var isEnabled: Bool = true
    public var image: UIImage = UIImage()
    public var messageConfiguration: CPMessageGridItemConfiguration? = nil
    public var titleVariants: [String] = []
    var storedHandler: ((CPGridButton) -> Void)? = nil
    public override init() { super.init() }
    public init(titleVariants: [String], image: UIImage, handler: ((CPGridButton) -> Void)? = nil) {
        super.init()
        self.titleVariants = titleVariants
        self.image = image
        self.storedHandler = handler
    }
    public init(titleVariants: [String], image: UIImage, messageConfiguration: CPMessageGridItemConfiguration?, handler: ((CPGridButton) -> Void)? = nil) {
        super.init()
        self.titleVariants = titleVariants
        self.image = image
        self.messageConfiguration = messageConfiguration
        self.storedHandler = handler
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
    public func updateImage(_ image: UIImage) {
        self.image = image
    }
    public func updateTitleVariants(_ titleVariants: [String]) {
        self.titleVariants = titleVariants
    }
}

open class CPImageSet: NSObject, @unchecked Sendable {
    public var darkContentImage: UIImage = UIImage()
    public var lightContentImage: UIImage = UIImage()
    public override init() { super.init() }
    public init(lightContentImage lightImage: UIImage, darkContentImage darkImage: UIImage) {
        super.init()
        self.lightContentImage = lightImage
        self.darkContentImage = darkImage
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPInformationItem: NSObject, @unchecked Sendable {
    public var detail: String? = nil
    public var title: String? = nil
    public override init() { super.init() }
    public init(title: String?, detail: String?) {
        super.init()
        self.title = title
        self.detail = detail
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPInformationRatingItem: CPInformationItem, @unchecked Sendable {
    public var maximumRating: NSNumber? = nil
    public var rating: NSNumber? = nil
    public override init() { super.init() }
    public init(rating: NSNumber?, maximumRating: NSNumber?, title: String?, detail: String?) {
        super.init(title: title, detail: detail)
        self.rating = rating
        self.maximumRating = maximumRating
    }
}

open class CPInstrumentClusterController: NSObject, @unchecked Sendable {
    public var attributedInactiveDescriptionVariants: [NSAttributedString] = []
    public var compassSetting: CPInstrumentClusterSetting = .unspecified
    public weak var delegate: (any CPInstrumentClusterControllerDelegate)?
    public var inactiveDescriptionVariants: [String] = []
    public var instrumentClusterWindow: UIWindow? = nil
    public var speedLimitSetting: CPInstrumentClusterSetting = .unspecified
    public override init() { super.init() }

    @_spi(OpenUIKitHost)
    public var openuikit_vehiclePresentationActive: Bool { false }
}

open class CPLane: NSObject, @unchecked Sendable {
    public var angles: [Measurement<UnitAngle>] = []
    public var highlightedAngle: Measurement<UnitAngle>? = nil
    public var primaryAngle: Measurement<UnitAngle> = Measurement(value: 0, unit: UnitAngle.degrees)
    public var secondaryAngles: [Measurement<UnitAngle>] = []
    public var status: CPLaneStatus = .notGood
    public override init() { super.init() }
    public init(angles: [Measurement<UnitAngle>]) {
        super.init()
        self.angles = angles
    }
    public init(angles: [Measurement<UnitAngle>], highlightedAngle: Measurement<UnitAngle>, isPreferred preferred: Bool) {
        super.init()
        self.angles = angles
        self.highlightedAngle = highlightedAngle
        self.primaryAngle = highlightedAngle
        self.status = preferred ? .preferred : .good
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPLaneGuidance: NSObject, @unchecked Sendable {
    public var instructionVariants: [String] = []
    public var lanes: [CPLane] = []
    public override init() { super.init() }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPListImageRowItem: NSObject, CPSelectableListItem, @unchecked Sendable {
    public class var maximumImageSize: CGSize { CPButtonMaximumImageSize }
    public var allowsMultipleLines: Bool = false
    public var elements: [CPListImageRowItemElement] = []
    public var isEnabled: Bool = true
    public var gridImages: [UIImage] = []
    public var handler: ((any CPSelectableListItem, @escaping () -> Void) -> Void)? = nil
    public var imageTitles: [String] = []
    public var listImageRowHandler: ((CPListImageRowItem, Int, @escaping () -> Void) -> Void)? = nil
    public var text: String? = nil
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init(text: String?, cardElements elements: [CPListImageRowItemCardElement], allowsMultipleLines: Bool) {
        super.init()
        self.text = text
        self.elements = elements
        self.allowsMultipleLines = allowsMultipleLines
    }
    public init(text: String?, condensedElements elements: [CPListImageRowItemCondensedElement], allowsMultipleLines: Bool) {
        super.init()
        self.text = text
        self.elements = elements
        self.allowsMultipleLines = allowsMultipleLines
    }
    public init(text: String?, elements: [CPListImageRowItemRowElement], allowsMultipleLines: Bool) {
        super.init()
        self.text = text
        self.elements = elements
        self.allowsMultipleLines = allowsMultipleLines
    }
    public init(text: String?, gridElements elements: [CPListImageRowItemGridElement], allowsMultipleLines: Bool) {
        super.init()
        self.text = text
        self.elements = elements
        self.allowsMultipleLines = allowsMultipleLines
    }
    public init(text: String?, imageGridElements elements: [CPListImageRowItemImageGridElement], allowsMultipleLines: Bool) {
        super.init()
        self.text = text
        self.elements = elements
        self.allowsMultipleLines = allowsMultipleLines
    }
    public init(text: String, images: [UIImage]) {
        super.init()
        self.text = text
        self.gridImages = images
    }
    public init(text: String, images: [UIImage], imageTitles: [String]) {
        super.init()
        self.text = text
        self.gridImages = images
        self.imageTitles = imageTitles
    }
    public func update(_ gridImages: [UIImage]) {
        self.gridImages = gridImages
    }
}

@MainActor open class CPListImageRowItemElement: NSObject, @unchecked Sendable {
    public class var maximumImageSize: CGSize { CPButtonMaximumImageSize }
    public var isEnabled: Bool = true
    public var image: UIImage = UIImage()
    public override init() { super.init() }
}

@MainActor open class CPListImageRowItemCardElement: CPListImageRowItemElement, @unchecked Sendable {
    public class var maximumFullHeightImageSize: CGSize { CPButtonMaximumImageSize }
    public override class var maximumImageSize: CGSize { CPButtonMaximumImageSize }
    public var showsImageFullHeight: Bool = false
    public var subtitle: String? = nil
    public var tintColor: UIColor? = nil
    public var title: String = ""
    public override init() { super.init() }
    public init(image: UIImage, showsImageFullHeight: Bool, title: String?, subtitle: String?, tintColor: UIColor?) {
        super.init()
        self.image = image
        self.showsImageFullHeight = showsImageFullHeight
        self.title = title ?? ""
        self.subtitle = subtitle
        self.tintColor = tintColor
    }
}

@MainActor open class CPListImageRowItemCondensedElement: CPListImageRowItemElement, @unchecked Sendable {
    public enum Shape: Int, Sendable, Hashable {
        case circular = 1
        case roundedRectangle = 0
    }
    public var accessorySymbolName: String? = nil
    public var imageShape: CPListImageRowItemCondensedElement.Shape = .roundedRectangle
    public var subtitle: String? = nil
    public var title: String = ""
    public override init() { super.init() }
    public init(image: UIImage, imageShape: CPListImageRowItemCondensedElement.Shape, title: String, subtitle: String?, accessorySymbolName: String?) {
        super.init()
        self.image = image
        self.imageShape = imageShape
        self.title = title
        self.subtitle = subtitle
        self.accessorySymbolName = accessorySymbolName
    }
}

@MainActor open class CPListImageRowItemGridElement: CPListImageRowItemElement, @unchecked Sendable {
    public override init() { super.init() }
    public init(image: UIImage) {
        super.init()
        self.image = image
    }
}

@MainActor open class CPListImageRowItemImageGridElement: CPListImageRowItemElement, @unchecked Sendable {
    public enum Shape: Int, Sendable, Hashable {
        case circular = 1
        case roundedRectangle = 0
    }
    public var accessorySymbolName: String? = nil
    public var imageShape: CPListImageRowItemImageGridElement.Shape = .roundedRectangle
    public var title: String = ""
    public override init() { super.init() }
    public init(image: UIImage, imageShape: CPListImageRowItemImageGridElement.Shape, title: String, accessorySymbolName: String?) {
        super.init()
        self.image = image
        self.imageShape = imageShape
        self.title = title
        self.accessorySymbolName = accessorySymbolName
    }
}

@MainActor open class CPListImageRowItemRowElement: CPListImageRowItemElement, @unchecked Sendable {
    public var subtitle: String? = nil
    public var title: String? = nil
    public override init() { super.init() }
    public init(image: UIImage, title: String?, subtitle: String?) {
        super.init()
        self.image = image
        self.title = title
        self.subtitle = subtitle
    }
}

@MainActor open class CPListItem: NSObject, CPSelectableListItem, @unchecked Sendable {
    public enum AssistantCellPosition: Int, Sendable, Hashable {
        case bottom = 1
        case top = 0
    }
    public enum AssistantCellVisibility: Int, Sendable, Hashable {
        case always = 2
        case off = 0
        case whileLimitedUIActive = 1
    }
    public class var maximumImageSize: CGSize { CGSize(width: 90, height: 90) }
    public private(set) var accessoryImage: UIImage? = nil
    public var accessoryType: CPListItemAccessoryType = .none
    public private(set) var detailText: String? = nil
    public var isEnabled: Bool = true
    public var isExplicitContent: Bool = false
    public var handler: ((any CPSelectableListItem, @escaping () -> Void) -> Void)? = nil
    public private(set) var image: UIImage? = nil
    public var playbackProgress: CGFloat = 0
    public var isPlaying: Bool = false
    public var playingIndicatorLocation: CPListItemPlayingIndicatorLocation = .leading
    public private(set) var showsDisclosureIndicator: Bool = false
    public var showsExplicitLabel: Bool = false
    public private(set) var text: String? = nil
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init(text: String?, detailText: String?) {
        super.init()
        self.text = text
        self.detailText = detailText
    }
    public init(text: String?, detailText: String?, image: UIImage?) {
        super.init()
        self.text = text
        self.detailText = detailText
        self.image = image
    }
    public init(text: String?, detailText: String?, image: UIImage?, accessoryImage: UIImage?, accessoryType: CPListItemAccessoryType) {
        super.init()
        self.text = text
        self.detailText = detailText
        self.image = image
        self.accessoryImage = accessoryImage
        self.accessoryType = accessoryType
        self.showsDisclosureIndicator = accessoryType == .disclosureIndicator
    }
    public init(text: String?, detailText: String?, image: UIImage?, showsDisclosureIndicator: Bool) {
        super.init()
        self.text = text
        self.detailText = detailText
        self.image = image
        self.showsDisclosureIndicator = showsDisclosureIndicator
    }
    public func setAccessoryImage(_ accessoryImage: UIImage?) {
        self.accessoryImage = accessoryImage
    }
    public func setDetailText(_ detailText: String?) {
        self.detailText = detailText
    }
    public func setImage(_ image: UIImage?) {
        self.image = image
    }
    public func setText(_ text: String) {
        self.text = text
    }
}

@MainActor open class CPListSection: NSObject, @unchecked Sendable {
    public var header: String? = nil
    public var headerButton: CPButton? = nil
    public var headerImage: UIImage? = nil
    public var headerSubtitle: String? = nil
    public var items: [any CPListTemplateItem] = []
    public var sectionIndexTitle: String? = nil
    public override init() { super.init() }
    public init(items: [any CPListTemplateItem], header: String, headerSubtitle: String?, headerImage: UIImage?, headerButton: CPButton?, sectionIndexTitle: String?) {
        super.init()
        self.items = items
        self.header = header
        self.headerSubtitle = headerSubtitle
        self.headerImage = headerImage
        self.headerButton = headerButton
        self.sectionIndexTitle = sectionIndexTitle
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
    public init(items: [any CPListTemplateItem], header: String?, sectionIndexTitle: String?) {
        super.init()
        self.items = items
        self.header = header
        self.sectionIndexTitle = sectionIndexTitle
    }
    public init(items: [CPListItem], header: String?, sectionIndexTitle: String?) {
        super.init()
        self.items = items
        self.header = header
        self.sectionIndexTitle = sectionIndexTitle
    }
    public init(items: [any CPListTemplateItem]) {
        super.init()
        self.items = items
    }
    public init(items: [CPListItem]) {
        super.init()
        self.items = items
    }
    public func index(of item: any CPListTemplateItem) -> Int {
        if let idx = items.firstIndex(where: { $0 === item }) {
            return idx
        }
        return NSNotFound
    }
    public func item(at index: Int) -> any CPListTemplateItem {
        if index >= 0, index < self.items.count { return self.items[index] }
        return CPListItem()
    }
}

open class CPManeuver: NSObject, @unchecked Sendable {
    public var attributedInstructionVariants: [NSAttributedString] = []
    public var cardBackgroundColor: UIColor? = nil
    public var dashboardAttributedInstructionVariants: [NSAttributedString] = []
    public var dashboardInstructionVariants: [String] = []
    public var dashboardJunctionImage: UIImage? = nil
    public var dashboardSymbolImage: UIImage? = nil
    public var highwayExitLabel: String = ""
    public var initialTravelEstimates: CPTravelEstimates? = nil
    public var instructionVariants: [String] = []
    public var junctionElementAngles: Set<Measurement<UnitAngle>>? = nil
    public var junctionExitAngle: Measurement<UnitAngle>? = nil
    public var junctionImage: UIImage? = nil
    public var junctionType: CPJunctionType = .intersection
    public var linkedLaneGuidance: CPLaneGuidance = CPLaneGuidance()
    public var maneuverType: CPManeuverType = .noTurn
    public var notificationAttributedInstructionVariants: [NSAttributedString] = []
    public var notificationInstructionVariants: [String] = []
    public var notificationSymbolImage: UIImage? = nil
    public var roadFollowingManeuverVariants: [String]? = nil
    public var symbolImage: UIImage? = nil
    public var symbolSet: CPImageSet? = nil
    public var trafficSide: CPTrafficSide = .right
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPMapButton: NSObject, @unchecked Sendable {
    public var isEnabled: Bool = true
    public var focusedImage: UIImage? = nil
    public var isHidden: Bool = false
    public var image: UIImage? = nil
    var storedHandler: ((CPMapButton) -> Void)? = nil
    public override init() { super.init() }
    public init(handler: ((CPMapButton) -> Void)? = nil) {
        super.init()
        self.storedHandler = handler
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPMessageComposeBarButton: CPBarButton, @unchecked Sendable {
    public override init() { super.init() }
    public init(image: UIImage) {
        super.init()
        self.image = image
        self.buttonType = .image
    }
}

open class CPMessageGridItemConfiguration: NSObject, @unchecked Sendable {
    public var conversationIdentifier: String = ""
    public var isUnread: Bool = false
    public override init() { super.init() }
    public init(conversationIdentifier: String, unread: Bool) {
        super.init()
        self.conversationIdentifier = conversationIdentifier
        self.isUnread = unread
    }
}

@MainActor open class CPMessageListItem: NSObject, CPListTemplateItem, @unchecked Sendable {
    public var conversationIdentifier: String? = nil
    public var detailText: String? = nil
    public var isEnabled: Bool = true
    public var leadingConfiguration: CPMessageListItemLeadingConfiguration = CPMessageListItemLeadingConfiguration()
    public var leadingDetailTextImage: UIImage? = nil
    public var phoneOrEmailAddress: String? = nil
    public var text: String? = nil
    public var trailingConfiguration: CPMessageListItemTrailingConfiguration? = nil
    public var trailingText: String? = nil
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init(conversationIdentifier: String, text: String, leadingConfiguration: CPMessageListItemLeadingConfiguration, trailingConfiguration: CPMessageListItemTrailingConfiguration?, detailText: String?, trailingText: String?) {
        super.init()
        self.conversationIdentifier = conversationIdentifier
        self.text = text
        self.leadingConfiguration = leadingConfiguration
        self.trailingConfiguration = trailingConfiguration
        self.detailText = detailText
        self.trailingText = trailingText
    }
    public init(fullName: String, phoneOrEmailAddress: String, leadingConfiguration: CPMessageListItemLeadingConfiguration, trailingConfiguration: CPMessageListItemTrailingConfiguration?, detailText: String?, trailingText: String?) {
        super.init()
        self.text = fullName
        self.phoneOrEmailAddress = phoneOrEmailAddress
        self.leadingConfiguration = leadingConfiguration
        self.trailingConfiguration = trailingConfiguration
        self.detailText = detailText
        self.trailingText = trailingText
    }
}

open class CPMessageListItemLeadingConfiguration: NSObject, @unchecked Sendable {
    public var leadingImage: UIImage? = nil
    public var leadingItem: CPMessageLeadingItem = .none
    public var isUnread: Bool = false
    public override init() { super.init() }
    public init(leadingItem: CPMessageLeadingItem, leadingImage: UIImage?, unread: Bool) {
        super.init()
        self.leadingItem = leadingItem
        self.leadingImage = leadingImage
        self.isUnread = unread
    }
}

open class CPMessageListItemTrailingConfiguration: NSObject, @unchecked Sendable {
    public var trailingImage: UIImage? = nil
    public var trailingItem: CPMessageTrailingItem = .none
    public override init() { super.init() }
    public init(trailingItem: CPMessageTrailingItem, trailingImage: UIImage?) {
        super.init()
        self.trailingItem = trailingItem
        self.trailingImage = trailingImage
    }
}

@MainActor open class CPNavigationAlert: NSObject, @unchecked Sendable {
    public enum DismissalContext: Int, Sendable, Hashable {
        case systemDismissed = 2
        case timeout = 0
        case userDismissed = 1
    }
    public var duration: TimeInterval = 0
    public var image: UIImage? = nil
    public var imageSet: CPImageSet? = nil
    public var primaryAction: CPAlertAction = CPAlertAction()
    public var secondaryAction: CPAlertAction? = nil
    public var subtitleVariants: [String] = []
    public var titleVariants: [String] = []
    public override init() { super.init() }
    public init(titleVariants: [String], subtitleVariants: [String]?, image: UIImage?, primaryAction: CPAlertAction, secondaryAction: CPAlertAction?, duration: TimeInterval) {
        super.init()
        self.titleVariants = titleVariants
        self.subtitleVariants = subtitleVariants ?? []
        self.image = image
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.duration = duration
    }
    public init(titleVariants: [String], subtitleVariants: [String]?, imageSet: CPImageSet?, primaryAction: CPAlertAction, secondaryAction: CPAlertAction?, duration: TimeInterval) {
        super.init()
        self.titleVariants = titleVariants
        self.subtitleVariants = subtitleVariants ?? []
        self.imageSet = imageSet
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.duration = duration
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
    public func updateTitleVariants(_ newTitleVariants: [String], subtitleVariants newSubtitleVariants: [String]) {
        self.titleVariants = newTitleVariants
        self.subtitleVariants = newSubtitleVariants
    }
}

@MainActor open class CPNavigationSession: NSObject, @unchecked Sendable {
    public enum PauseReason: Int, Sendable, Hashable {
        case arrived = 1
        case loading = 2
        case locating = 3
        case proceedToRoute = 5
        case rerouting = 4
    }
    public enum HostTripState: String, Sendable {
        case idle
        case navigating
        case paused
        case finished
        case cancelled
    }
    public var currentLaneGuidance: CPLaneGuidance? = nil
    public var currentRoadNameVariants: [String] = []
    public var maneuverState: CPManeuverState = .initial
    public private(set) var trip: CPTrip
    public var upcomingManeuvers: [CPManeuver] = []
    public private(set) var hostTripState: HostTripState = .navigating
    public private(set) var pauseReason: CPNavigationSession.PauseReason? = nil
    public private(set) var pauseDescription: String? = nil
    var maneuverEstimates: [ObjectIdentifier: CPTravelEstimates] = [:]

    public override init() {
        self.trip = CPTrip()
        super.init()
        self.hostTripState = .idle
    }

    init(trip: CPTrip) {
        self.trip = trip
        super.init()
        self.hostTripState = .navigating
        self.maneuverState = .initial
    }

    public func add(_ laneGuidances: [CPLaneGuidance]) {
        if hostTripState == .navigating || hostTripState == .paused {
            currentLaneGuidance = laneGuidances.last
        }
    }
    public func add(_ maneuvers: [CPManeuver]) {
        if hostTripState == .navigating || hostTripState == .paused {
            upcomingManeuvers = maneuvers
            if !maneuvers.isEmpty {
                maneuverState = .prepare
            }
        }
    }
    public func cancelTrip() {
        hostTripState = .cancelled
        upcomingManeuvers = []
        pauseReason = nil
    }
    public func finishTrip() {
        hostTripState = .finished
        upcomingManeuvers = []
        maneuverState = .execute
        pauseReason = .arrived
    }
    public func pauseTrip(for reason: CPNavigationSession.PauseReason, description: String?) {
        pauseTrip(for: reason, description: description, turnCardColor: nil)
    }
    public func pauseTrip(for reason: CPNavigationSession.PauseReason, description: String?, turnCardColor: UIColor?) {
        _ = turnCardColor
        if hostTripState == .navigating {
            hostTripState = .paused
            pauseReason = reason
            pauseDescription = description
        }
    }
    public func resumeTrip(updatedRouteInformation routeInformation: CPRouteInformation) {
        if hostTripState == .paused {
            hostTripState = .navigating
            pauseReason = nil
            pauseDescription = nil
            upcomingManeuvers = routeInformation.currentManeuvers
            currentLaneGuidance = routeInformation.currentLaneGuidance
            maneuverState = .continue
        }
    }
    public func updateEstimates(_ estimates: CPTravelEstimates, for maneuver: CPManeuver) {
        maneuverEstimates[ObjectIdentifier(maneuver)] = estimates
        if upcomingManeuvers.first === maneuver {
            maneuverState = .execute
        }
    }
}

@MainActor open class CPNowPlayingButton: NSObject, @unchecked Sendable {
    public var isEnabled: Bool = true
    public var isSelected: Bool = false
    var storedHandler: ((CPNowPlayingButton) -> Void)? = nil
    public override init() { super.init() }
    public init(handler: ((CPNowPlayingButton) -> Void)? = nil) {
        super.init()
        self.storedHandler = handler
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPNowPlayingAddToLibraryButton: CPNowPlayingButton, @unchecked Sendable {
    public override init() { super.init() }
}

@MainActor open class CPNowPlayingImageButton: CPNowPlayingButton, @unchecked Sendable {
    public var image: UIImage? = nil
    public override init() { super.init() }
    public init(image: UIImage, handler: ((CPNowPlayingButton) -> Void)? = nil) {
        super.init()
        self.image = image
        self.storedHandler = handler
    }
}

@MainActor open class CPNowPlayingMode: NSObject, @unchecked Sendable {
    static let _default = CPNowPlayingMode()
    public class var `default`: CPNowPlayingMode { CPNowPlayingMode._default }
    public override init() { super.init() }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPNowPlayingModeSports: CPNowPlayingMode, @unchecked Sendable {
    public var backgroundArtwork: UIImage? = nil
    public var eventStatus: CPNowPlayingSportsEventStatus? = nil
    public var leftTeam: CPNowPlayingSportsTeam = CPNowPlayingSportsTeam()
    public var rightTeam: CPNowPlayingSportsTeam = CPNowPlayingSportsTeam()
    public override init() { super.init() }
    public init(leftTeam: CPNowPlayingSportsTeam, rightTeam: CPNowPlayingSportsTeam, eventStatus: CPNowPlayingSportsEventStatus?, backgroundArtwork: UIImage?) {
        super.init()
        self.leftTeam = leftTeam
        self.rightTeam = rightTeam
        self.eventStatus = eventStatus
        self.backgroundArtwork = backgroundArtwork
    }
}

@MainActor open class CPNowPlayingMoreButton: CPNowPlayingButton, @unchecked Sendable {
    public override init() { super.init() }
}

@MainActor open class CPNowPlayingPlaybackRateButton: CPNowPlayingButton, @unchecked Sendable {
    public override init() { super.init() }
}

@MainActor open class CPNowPlayingRepeatButton: CPNowPlayingButton, @unchecked Sendable {
    public override init() { super.init() }
}

@MainActor open class CPNowPlayingShuffleButton: CPNowPlayingButton, @unchecked Sendable {
    public override init() { super.init() }
}

@MainActor open class CPNowPlayingSportsClock: NSObject, @unchecked Sendable {
    public var countsUp: Bool = false
    public var isPaused: Bool = false
    public var timeValue: TimeInterval = 0
    public override init() { super.init() }
    public init(elapsedTime: TimeInterval, paused: Bool) {
        super.init()
        self.timeValue = elapsedTime
        self.isPaused = paused
        self.countsUp = true
    }
    public init(timeRemaining: TimeInterval, paused: Bool) {
        super.init()
        self.timeValue = timeRemaining
        self.isPaused = paused
        self.countsUp = false
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPNowPlayingSportsEventStatus: NSObject, @unchecked Sendable {
    public var eventClock: CPNowPlayingSportsClock? = nil
    public var eventStatusImage: UIImage? = nil
    public var eventStatusText: [String]? = nil
    public override init() { super.init() }
    public init(eventStatusText: [String]?, eventStatusImage: UIImage?, eventClock: CPNowPlayingSportsClock?) {
        super.init()
        self.eventStatusText = eventStatusText
        self.eventStatusImage = eventStatusImage
        self.eventClock = eventClock
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPNowPlayingSportsTeam: NSObject, @unchecked Sendable {
    public var eventScore: String = ""
    public var isFavorite: Bool = false
    public var logo: CPNowPlayingSportsTeamLogo = CPNowPlayingSportsTeamLogo()
    public var name: String = ""
    public var possessionIndicator: UIImage? = nil
    public var teamStandings: String? = nil
    public override init() { super.init() }
    public init(name: String, logo: CPNowPlayingSportsTeamLogo, teamStandings: String?, eventScore: String, possessionIndicator: UIImage?, favorite: Bool) {
        super.init()
        self.name = name
        self.logo = logo
        self.teamStandings = teamStandings
        self.eventScore = eventScore
        self.possessionIndicator = possessionIndicator
        self.isFavorite = favorite
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPNowPlayingSportsTeamLogo: NSObject, @unchecked Sendable {
    public var initials: String? = nil
    public var logo: UIImage? = nil
    public override init() { super.init() }
    public init(teamInitials: String) {
        super.init()
        self.initials = teamInitials
    }
    public init(teamLogo: UIImage) {
        super.init()
        self.logo = teamLogo
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPPointOfInterest: NSObject, @unchecked Sendable {
    public class var pinImageSize: CGSize { CPButtonMaximumImageSize }
    public class var selectedPinImageSize: CGSize { CPButtonMaximumImageSize }
    public var detailSubtitle: String? = nil
    public var detailSummary: String? = nil
    public var detailTitle: String? = nil
    public var location: MKMapItem = MKMapItem()
    public var pinImage: UIImage? = nil
    public var primaryButton: CPTextButton? = nil
    public var secondaryButton: CPTextButton? = nil
    public var selectedPinImage: UIImage? = nil
    public var subtitle: String? = nil
    public var summary: String? = nil
    public var title: String = ""
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init(location: MKMapItem, title: String, subtitle: String?, summary: String?, detailTitle: String?, detailSubtitle: String?, detailSummary: String?, pinImage: UIImage?) {
        super.init()
        self.location = location
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.detailTitle = detailTitle
        self.detailSubtitle = detailSubtitle
        self.detailSummary = detailSummary
        self.pinImage = pinImage
    }
    public init(location: MKMapItem, title: String, subtitle: String?, summary: String?, detailTitle: String?, detailSubtitle: String?, detailSummary: String?, pinImage: UIImage?, selectedPinImage: UIImage?) {
        super.init()
        self.location = location
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.detailTitle = detailTitle
        self.detailSubtitle = detailSubtitle
        self.detailSummary = detailSummary
        self.pinImage = pinImage
        self.selectedPinImage = selectedPinImage
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPRouteChoice: NSObject, @unchecked Sendable {
    public var additionalInformationVariants: [String]? = nil
    public var selectionSummaryVariants: [String]? = nil
    public var summaryVariants: [String] = []
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init(summaryVariants: [String], additionalInformationVariants: [String], selectionSummaryVariants: [String]) {
        super.init()
        self.summaryVariants = summaryVariants
        self.additionalInformationVariants = additionalInformationVariants
        self.selectionSummaryVariants = selectionSummaryVariants
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPRouteInformation: NSObject, @unchecked Sendable {
    public var currentLaneGuidance: CPLaneGuidance = CPLaneGuidance()
    public var currentManeuvers: [CPManeuver] = []
    public var laneGuidances: [CPLaneGuidance] = []
    public var maneuverTravelEstimates: CPTravelEstimates = CPTravelEstimates()
    public var maneuvers: [CPManeuver] = []
    public var tripTravelEstimates: CPTravelEstimates = CPTravelEstimates()
    public override init() { super.init() }
    public init(maneuvers: [CPManeuver], laneGuidances: [CPLaneGuidance], currentManeuvers: [CPManeuver], currentLaneGuidance: CPLaneGuidance, trip tripTravelEstimates: CPTravelEstimates, maneuverTravelEstimates: CPTravelEstimates) {
        super.init()
        self.maneuvers = maneuvers
        self.laneGuidances = laneGuidances
        self.currentManeuvers = currentManeuvers
        self.currentLaneGuidance = currentLaneGuidance
        self.tripTravelEstimates = tripTravelEstimates
        self.maneuverTravelEstimates = maneuverTravelEstimates
    }
    public init(maneuvers: [CPManeuver], laneGuidances: [CPLaneGuidance], currentManeuvers: [CPManeuver], currentLaneGuidance: CPLaneGuidance, tripTravelEstimates: CPTravelEstimates, maneuverTravelEstimates: CPTravelEstimates) {
        super.init()
        self.maneuvers = maneuvers
        self.laneGuidances = laneGuidances
        self.currentManeuvers = currentManeuvers
        self.currentLaneGuidance = currentLaneGuidance
        self.tripTravelEstimates = tripTravelEstimates
        self.maneuverTravelEstimates = maneuverTravelEstimates
    }
}

open class CPSessionConfiguration: NSObject, @unchecked Sendable {
    public private(set) var contentStyle: CPContentStyle = []
    public private(set) var limitedUserInterfaces: CPLimitableUserInterface = []
    public weak var delegate: (any CPSessionConfigurationDelegate)?
    public override init() { super.init() }
    public init(delegate: any CPSessionConfigurationDelegate) {
        super.init()
        self.delegate = delegate
    }

    @_spi(OpenUIKitHost)
    @MainActor
    public func openuikit_applySimulatedStyle(_ style: CPContentStyle) {
        contentStyle = style
        delegate?.sessionConfiguration(self, contentStyleChanged: style)
    }

    @_spi(OpenUIKitHost)
    @MainActor
    public func openuikit_applyLimitedUserInterfaces(_ limited: CPLimitableUserInterface) {
        limitedUserInterfaces = limited
        delegate?.sessionConfiguration(self, limitedUserInterfacesChanged: limited)
    }
}

@MainActor open class CPTemplate: NSObject, @unchecked Sendable {
    public var backButton: CPBarButton? = nil
    public var leadingNavigationBarButtons: [CPBarButton] = []
    public var trailingNavigationBarButtons: [CPBarButton] = []
    public var showsTabBadge: Bool = false
    public var tabImage: UIImage? = nil
    public var tabSystemItem: UITabBarItem.SystemItem = .more
    public var tabTitle: String? = nil
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPActionSheetTemplate: CPTemplate, @unchecked Sendable {
    public var actions: [CPAlertAction] = []
    public var message: String? = nil
    public var title: String? = nil
    public override init() { super.init() }
    public init(title: String?, message: String?, actions: [CPAlertAction]) {
        super.init()
        self.title = title
        self.message = message
        self.actions = actions
    }
}

@MainActor open class CPAlertTemplate: CPTemplate, @unchecked Sendable {
    public class var maximumActionCount: Int { CarPlayAlertMaximumActionCount }
    public private(set) var actions: [CPAlertAction] = []
    public private(set) var titleVariants: [String] = []
    public override init() { super.init() }
    public init(titleVariants: [String], actions: [CPAlertAction]) {
        super.init()
        self.titleVariants = titleVariants
        self.actions = Array(actions.prefix(CarPlayAlertMaximumActionCount))
    }
}

@MainActor open class CPContactTemplate: CPTemplate, CPBarButtonProviding, @unchecked Sendable {
    public var contact: CPContact = CPContact()
    public override init() { super.init() }
    public init(contact: CPContact) {
        super.init()
        self.contact = contact
    }
}

@MainActor open class CPGridTemplate: CPTemplate, CPBarButtonProviding, @unchecked Sendable {
    public class var maximumGridButtonImageSize: CGSize { CPButtonMaximumImageSize }
    public private(set) var gridButtons: [CPGridButton] = []
    public private(set) var title: String = ""
    public override init() { super.init() }
    public init(title: String?, gridButtons: [CPGridButton]) {
        super.init()
        self.title = title ?? ""
        self.gridButtons = Array(gridButtons.prefix(CPGridTemplateMaximumItems))
    }
    public func updateGridButtons(_ gridButtons: [CPGridButton]) {
        self.gridButtons = Array(gridButtons.prefix(CPGridTemplateMaximumItems))
    }
    public func updateTitle(_ title: String) {
        self.title = title
    }
}

@MainActor open class CPInformationTemplate: CPTemplate, CPBarButtonProviding, @unchecked Sendable {
    public var actions: [CPTextButton] = []
    public var items: [CPInformationItem] = []
    public var layout: CPInformationTemplateLayout = .leading
    public var title: String = ""
    public override init() { super.init() }
    public init(title: String, layout: CPInformationTemplateLayout, items: [CPInformationItem], actions: [CPTextButton]) {
        super.init()
        self.title = title
        self.layout = layout
        self.items = Array(items.prefix(CarPlayInformationMaximumItemCount))
        self.actions = Array(actions.prefix(CarPlayInformationMaximumActionCount))
    }
}

@MainActor open class CPListTemplate: CPTemplate, CPBarButtonProviding, @unchecked Sendable {
    public class var maximumGridButtonImageSize: CGSize { CPButtonMaximumImageSize }
    public class var maximumHeaderGridButtonCount: Int { 3 }
    /// Documented CarPlay list cap (programming guide): 12 items.
    public class var maximumItemCount: Int { 12 }
    /// Documented CarPlay list cap (programming guide): 12 sections.
    public class var maximumSectionCount: Int { 12 }
    public var assistantCellConfiguration: CPAssistantCellConfiguration? = nil
    public weak var delegate: (any CPListTemplateDelegate)?
    public var emptyViewSubtitleVariants: [String] = []
    public var emptyViewTitleVariants: [String] = []
    public var headerGridButtons: [CPGridButton]? = nil
    public var itemCount: Int = 0
    public var sectionCount: Int = 0
    public private(set) var sections: [CPListSection] = []
    public var showsSpinnerWhileEmpty: Bool = false
    public var title: String? = nil
    public override init() { super.init() }
    public init(title: String?, sections: [CPListSection]) {
        super.init()
        self.title = title
        applySections(sections)
    }
    public init(title: String?, sections: [CPListSection], assistantCellConfiguration: CPAssistantCellConfiguration?) {
        super.init()
        self.title = title
        self.assistantCellConfiguration = assistantCellConfiguration
        applySections(sections)
    }
    public init(title: String?, sections: [CPListSection], assistantCellConfiguration: CPAssistantCellConfiguration?, headerGridButtons: [CPGridButton]?) {
        super.init()
        self.title = title
        self.assistantCellConfiguration = assistantCellConfiguration
        if let headerGridButtons {
            self.headerGridButtons = Array(headerGridButtons.prefix(CPListTemplate.maximumHeaderGridButtonCount))
        }
        applySections(sections)
    }
    public func indexPath(for item: any CPListTemplateItem) -> IndexPath? {
        for (sectionIndex, section) in sections.enumerated() {
            let itemIndex = section.index(of: item)
            if itemIndex != NSNotFound {
                return IndexPath(indexes: [sectionIndex, itemIndex])
            }
        }
        return nil
    }
    public func updateSections(_ sections: [CPListSection]) {
        applySections(sections)
    }
    private func applySections(_ sections: [CPListSection]) {
        let cappedSections = Array(sections.prefix(CPListTemplate.maximumSectionCount))
        var remaining = CPListTemplate.maximumItemCount
        var kept: [CPListSection] = []
        for section in cappedSections {
            if remaining <= 0 { break }
            if section.items.count > remaining {
                let trimmed = CPListSection(
                    items: Array(section.items.prefix(remaining)),
                    header: section.header,
                    sectionIndexTitle: section.sectionIndexTitle
                )
                trimmed.headerButton = section.headerButton
                trimmed.headerImage = section.headerImage
                trimmed.headerSubtitle = section.headerSubtitle
                kept.append(trimmed)
                remaining = 0
            } else {
                kept.append(section)
                remaining -= section.items.count
            }
        }
        self.sections = kept
        self.sectionCount = kept.count
        self.itemCount = kept.reduce(0) { $0 + $1.items.count }
    }
}

@MainActor open class CPMapTemplate: CPTemplate, CPBarButtonProviding, @unchecked Sendable {
    public struct PanDirection: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let left = PanDirection(rawValue: 1)
        public static let right = PanDirection(rawValue: 2)
        public static let up = PanDirection(rawValue: 4)
        public static let down = PanDirection(rawValue: 8)
    }
    public var automaticallyHidesNavigationBar: Bool = false
    public private(set) var currentNavigationAlert: CPNavigationAlert? = nil
    public var guidanceBackgroundColor: UIColor = UIColor()
    public var hidesButtonsWithNavigationBar: Bool = false
    public var mapButtons: [CPMapButton] = []
    public weak var mapDelegate: (any CPMapTemplateDelegate)?
    public private(set) var isPanningInterfaceVisible: Bool = false
    public var tripEstimateStyle: CPTripEstimateStyle = .light
    public private(set) var previewTrips: [CPTrip] = []
    public private(set) var selectedPreviewTrip: CPTrip? = nil
    public private(set) var tripEstimates: [ObjectIdentifier: (CPTravelEstimates, CPTimeRemainingColor)] = [:]
    public private(set) var activeNavigationSession: CPNavigationSession? = nil
    public override init() { super.init() }
    public func dismissNavigationAlert(animated: Bool) async -> Bool {
        _ = animated
        guard let alert = currentNavigationAlert else { return false }
        mapDelegate?.mapTemplate(self, willDismiss: alert, dismissalContext: .userDismissed)
        currentNavigationAlert = nil
        mapDelegate?.mapTemplate(self, didDismiss: alert, dismissalContext: .userDismissed)
        return true
    }
    public func dismissPanningInterface(animated: Bool) {
        _ = animated
        if isPanningInterfaceVisible {
            mapDelegate?.mapTemplateWillDismissPanningInterface(self)
            isPanningInterfaceVisible = false
            mapDelegate?.mapTemplateDidDismissPanningInterface(self)
        }
    }
    public func hideTripPreviews() {
        previewTrips = []
        selectedPreviewTrip = nil
    }
    public func present(navigationAlert: CPNavigationAlert, animated: Bool) {
        _ = animated
        mapDelegate?.mapTemplate(self, willShow: navigationAlert)
        currentNavigationAlert = navigationAlert
        mapDelegate?.mapTemplate(self, didShow: navigationAlert)
    }
    public func showPanningInterface(animated: Bool) {
        _ = animated
        isPanningInterfaceVisible = true
        mapDelegate?.mapTemplateDidShowPanningInterface(self)
    }
    public func showRouteChoicesPreview(for tripPreview: CPTrip, textConfiguration: CPTripPreviewTextConfiguration?) {
        _ = textConfiguration
        previewTrips = [tripPreview]
        selectedPreviewTrip = tripPreview
        if let choice = tripPreview.routeChoices.first {
            mapDelegate?.mapTemplate(self, selectedPreviewFor: tripPreview, using: choice)
        }
    }
    public func showTripPreviews(_ tripPreviews: [CPTrip], selectedTrip: CPTrip?, textConfiguration: CPTripPreviewTextConfiguration?) {
        _ = textConfiguration
        previewTrips = tripPreviews
        selectedPreviewTrip = selectedTrip ?? tripPreviews.first
    }
    public func showTripPreviews(_ tripPreviews: [CPTrip], textConfiguration: CPTripPreviewTextConfiguration?) {
        showTripPreviews(tripPreviews, selectedTrip: tripPreviews.first, textConfiguration: textConfiguration)
    }
    public func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
        hideTripPreviews()
        let session = CPNavigationSession(trip: trip)
        activeNavigationSession = session
        if let choice = trip.routeChoices.first {
            mapDelegate?.mapTemplate(self, startedTrip: trip, using: choice)
        }
        return session
    }
    public func updateEstimates(_ estimates: CPTravelEstimates, for trip: CPTrip) {
        update(estimates, for: trip, with: .default)
    }
    public func update(_ estimates: CPTravelEstimates, for trip: CPTrip, with timeRemainingColor: CPTimeRemainingColor) {
        tripEstimates[ObjectIdentifier(trip)] = (estimates, timeRemainingColor)
    }
}

@MainActor open class CPNowPlayingTemplate: CPTemplate, @unchecked Sendable {
    static let _shared = CPNowPlayingTemplate()
    public class var shared: CPNowPlayingTemplate { CPNowPlayingTemplate._shared }
    public var isAlbumArtistButtonEnabled: Bool = false
    public private(set) var nowPlayingButtons: [CPNowPlayingButton] = []
    public var nowPlayingMode: CPNowPlayingMode? = nil
    public var isUpNextButtonEnabled: Bool = false
    public var upNextTitle: String = ""
    private var observers: [ObjectIdentifier: any CPNowPlayingTemplateObserver] = [:]
    /// Declared MediaPlayer Now Playing bridge. Linux has no MPNowPlayingInfoCenter
    /// session; this remains fail-closed and does not invent Now Playing metadata.
    public private(set) var mpNowPlayingBridgeDeclared = true
    public override init() { super.init() }
    public func add(_ observer: any CPNowPlayingTemplateObserver) {
        observers[ObjectIdentifier(observer)] = observer
    }
    public func remove(_ observer: any CPNowPlayingTemplateObserver) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
    }
    public func updateNowPlayingButtons(_ nowPlayingButtons: [CPNowPlayingButton]) {
        self.nowPlayingButtons = nowPlayingButtons
    }

    @_spi(OpenUIKitHost)
    public func openuikit_notifyUpNext() {
        for observer in observers.values {
            observer.nowPlayingTemplateUpNextButtonTapped(self)
        }
    }

    @_spi(OpenUIKitHost)
    public func openuikit_notifyAlbumArtist() {
        for observer in observers.values {
            observer.nowPlayingTemplateAlbumArtistButtonTapped(self)
        }
    }
}

@MainActor open class CPPointOfInterestTemplate: CPTemplate, CPBarButtonProviding, @unchecked Sendable {
    public private(set) var pointsOfInterest: [CPPointOfInterest] = []
    public var selectedIndex: Int = 0
    public var title: String = ""
    public weak var pointOfInterestDelegate: (any CPPointOfInterestTemplateDelegate)?
    public override init() { super.init() }
    public init(title: String, pointsOfInterest: [CPPointOfInterest], selectedIndex: Int) {
        super.init()
        self.title = title
        applyPoints(pointsOfInterest, selectedIndex: selectedIndex)
    }
    public func setPointsOfInterest(_ pointsOfInterest: [CPPointOfInterest], selectedIndex: Int) {
        applyPoints(pointsOfInterest, selectedIndex: selectedIndex)
        if selectedIndex >= 0, selectedIndex < self.pointsOfInterest.count {
            pointOfInterestDelegate?.pointOfInterestTemplate(self, didSelectPointOfInterest: self.pointsOfInterest[selectedIndex])
        }
    }
    private func applyPoints(_ points: [CPPointOfInterest], selectedIndex: Int) {
        self.pointsOfInterest = Array(points.prefix(CarPlayPointOfInterestMaximumCount))
        if self.pointsOfInterest.isEmpty {
            self.selectedIndex = 0
        } else {
            self.selectedIndex = min(max(selectedIndex, 0), self.pointsOfInterest.count - 1)
        }
    }
}

@MainActor open class CPSearchTemplate: CPTemplate, @unchecked Sendable {
    public weak var delegate: (any CPSearchTemplateDelegate)?
    public override init() { super.init() }

    @_spi(OpenUIKitHost)
    public func openuikit_updateSearchText(_ text: String) async -> [CPListItem] {
        guard let delegate else { return [] }
        return await delegate.searchTemplate(self, updatedSearchText: text)
    }

    @_spi(OpenUIKitHost)
    public func openuikit_selectResult(_ item: CPListItem) async {
        await delegate?.searchTemplate(self, selectedResult: item)
    }

    @_spi(OpenUIKitHost)
    public func openuikit_pressSearchButton() {
        delegate?.searchTemplateSearchButtonPressed(self)
    }
}

@MainActor open class CPTabBarTemplate: CPTemplate, @unchecked Sendable {
    /// Documented maximum is 5. Some vehicles only support 4 tabs.
    public class var maximumTabCount: Int { CarPlayDocumentedTabBarMaximum }
    public class var someVehiclesMaximumTabCount: Int { CarPlayDocumentedTabBarSomeUnitsMaximum }
    public weak var delegate: (any CPTabBarTemplateDelegate)?
    public private(set) var selectedTemplate: CPTemplate? = nil
    public private(set) var templates: [CPTemplate] = []
    public override init() { super.init() }
    public init(templates: [CPTemplate]) {
        super.init()
        applyTemplates(templates)
    }
    public func select(_ newTemplate: CPTemplate) {
        if templates.contains(where: { $0 === newTemplate }) {
            selectedTemplate = newTemplate
            delegate?.tabBarTemplate(self, didSelect: newTemplate)
        }
    }
    public func selectTemplate(at index: Int) {
        guard index >= 0, index < templates.count else { return }
        select(templates[index])
    }
    public func updateTemplates(_ newTemplates: [CPTemplate]) {
        applyTemplates(newTemplates)
    }
    private func applyTemplates(_ newTemplates: [CPTemplate]) {
        templates = Array(newTemplates.prefix(CPTabBarTemplate.maximumTabCount))
        if let selected = selectedTemplate, templates.contains(where: { $0 === selected }) {
            return
        }
        selectedTemplate = templates.first
        if let selectedTemplate {
            delegate?.tabBarTemplate(self, didSelect: selectedTemplate)
        }
    }
}

open class CPTextButton: NSObject, @unchecked Sendable {
    public var textStyle: CPTextButtonStyle = .normal
    public var title: String = ""
    var storedHandler: ((CPTextButton) -> Void)? = nil
    public override init() { super.init() }
    public init(title: String, textStyle: CPTextButtonStyle, handler: ((CPTextButton) -> Void)? = nil) {
        super.init()
        self.title = title
        self.textStyle = textStyle
        self.storedHandler = handler
    }
}

open class CPTravelEstimates: NSObject, @unchecked Sendable {
    public var distanceRemaining: Measurement<UnitLength> = Measurement(value: 0, unit: UnitLength.meters)
    public var distanceRemainingToDisplay: Measurement<UnitLength> = Measurement(value: 0, unit: UnitLength.meters)
    public var timeRemaining: TimeInterval = 0
    public override init() { super.init() }
    public init(distanceRemaining: Measurement<UnitLength>, distanceRemainingToDisplay: Measurement<UnitLength>, timeRemaining time: TimeInterval) {
        super.init()
        self.distanceRemaining = distanceRemaining
        self.distanceRemainingToDisplay = distanceRemainingToDisplay
        self.timeRemaining = time
    }
    public init(distanceRemaining distance: Measurement<UnitLength>, timeRemaining time: TimeInterval) {
        super.init()
        self.distanceRemaining = distance
        self.distanceRemainingToDisplay = distance
        self.timeRemaining = time
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPTrip: NSObject, @unchecked Sendable {
    public var destination: MKMapItem = MKMapItem()
    public var destinationNameVariants: [String]? = nil
    public var origin: MKMapItem = MKMapItem()
    public var routeChoices: [CPRouteChoice] = []
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init(origin: MKMapItem, destination: MKMapItem, routeChoices: [CPRouteChoice]) {
        super.init()
        self.origin = origin
        self.destination = destination
        self.routeChoices = routeChoices
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPTripPreviewTextConfiguration: NSObject, @unchecked Sendable {
    public var additionalRoutesButtonTitle: String? = nil
    public var overviewButtonTitle: String? = nil
    public var startButtonTitle: String? = nil
    public override init() { super.init() }
    public init(startButtonTitle: String?, additionalRoutesButtonTitle: String?, overviewButtonTitle: String?) {
        super.init()
        self.startButtonTitle = startButtonTitle
        self.additionalRoutesButtonTitle = additionalRoutesButtonTitle
        self.overviewButtonTitle = overviewButtonTitle
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPVoiceControlState: NSObject, @unchecked Sendable {
    public var identifier: String = ""
    public var image: UIImage? = nil
    public var repeats: Bool = false
    public var titleVariants: [String]? = nil
    public override init() { super.init() }
    public init(identifier: String, titleVariants: [String]?, image: UIImage?, repeats: Bool) {
        super.init()
        self.identifier = identifier
        self.titleVariants = titleVariants
        self.image = image
        self.repeats = repeats
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

@MainActor open class CPVoiceControlTemplate: CPTemplate, @unchecked Sendable {
    public private(set) var activeStateIdentifier: String? = nil
    public private(set) var voiceControlStates: [CPVoiceControlState] = []
    public override init() { super.init() }
    public init(voiceControlStates: [CPVoiceControlState]) {
        super.init()
        self.voiceControlStates = voiceControlStates
    }
    public func activateVoiceControlState(withIdentifier identifier: String) {
        if voiceControlStates.contains(where: { $0.identifier == identifier }) {
            activeStateIdentifier = identifier
        }
    }
}

