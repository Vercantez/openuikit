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
    public var isEnabled: Bool = false
    public var image: UIImage? = nil
    public var title: String? = nil
    public override init() { super.init() }
    public init(image: UIImage, handler: CPBarButtonHandler? = nil) {
        super.init()
        self.image = image
    }
    public init(title: String, handler: CPBarButtonHandler? = nil) {
        super.init()
        self.title = title
    }
    public init(type: CPBarButton.`Type`, handler: CPBarButtonHandler? = nil) {
        super.init()
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPButton: NSObject, @unchecked Sendable {
    public var isEnabled: Bool = false
    public var image: UIImage? = nil
    public var title: String? = nil
    public override init() { super.init() }
    public init(image: UIImage, handler: ((CPButton) -> Void)? = nil) {
        super.init()
        self.image = image
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
    }
}

open class CPContactDirectionsButton: CPButton, @unchecked Sendable {
    public override init() { super.init() }
    public init(handler: ((CPButton) -> Void)? = nil) {
        super.init()
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
    public override init() { super.init() }
    public init(titleVariants: [String], subtitleVariants: [String], image: UIImage, handler: ((CPDashboardButton) -> Void)? = nil) {
        super.init()
        self.titleVariants = titleVariants
        self.subtitleVariants = subtitleVariants
        self.image = image
    }
    public init?(coder: NSCoder) {
        super.init()
        return nil
    }
}

open class CPDashboardController: NSObject, @unchecked Sendable {
    public var shortcutButtons: [CPDashboardButton] = []
    public override init() { super.init() }
}

open class CPGridButton: NSObject, @unchecked Sendable {
    public var isEnabled: Bool = false
    public var image: UIImage = UIImage()
    public var messageConfiguration: CPMessageGridItemConfiguration? = nil
    public var titleVariants: [String] = []
    public override init() { super.init() }
    public init(titleVariants: [String], image: UIImage, handler: ((CPGridButton) -> Void)? = nil) {
        super.init()
        self.titleVariants = titleVariants
        self.image = image
    }
    public init(titleVariants: [String], image: UIImage, messageConfiguration: CPMessageGridItemConfiguration?, handler: ((CPGridButton) -> Void)? = nil) {
        super.init()
        self.titleVariants = titleVariants
        self.image = image
        self.messageConfiguration = messageConfiguration
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
        super.init()
        self.rating = rating
        self.maximumRating = maximumRating
    }
}

open class CPInstrumentClusterController: NSObject, @unchecked Sendable {
    public var attributedInactiveDescriptionVariants: [NSAttributedString] = []
    public var compassSetting: CPInstrumentClusterSetting = .unspecified
    public var inactiveDescriptionVariants: [String] = []
    public var instrumentClusterWindow: UIWindow? = nil
    public var speedLimitSetting: CPInstrumentClusterSetting = .unspecified
    public override init() { super.init() }
}

@MainActor open class CPInterfaceController: NSObject, @unchecked Sendable {
    public weak var delegate: (any CPInterfaceControllerDelegate)?
    public var carTraitCollection: UITraitCollection = UITraitCollection()
    public var prefersDarkUserInterfaceStyle: Bool = false
    public var presentedTemplate: CPTemplate? = nil
    public var rootTemplate: CPTemplate = CPTemplate()
    public var templates: [CPTemplate] = []
    public var topTemplate: CPTemplate? = nil
    public override init() { super.init() }
    public func dismissTemplate(animated: Bool) {
        _ = animated
        self.presentedTemplate = nil
    }
    public func dismissTemplate(animated: Bool) async throws -> Bool {
        return false
    }
    public func popTemplate(animated: Bool) {
        _ = animated
        if self.templates.count > 1 { self.templates.removeLast() }
        self.topTemplate = self.templates.last
    }
    public func popTemplate(animated: Bool) async throws -> Bool {
        return false
    }
    public func popToRootTemplate(animated: Bool) {
        _ = animated
        if let first = self.templates.first { self.templates = [first] }
        self.topTemplate = self.templates.last
    }
    public func popToRootTemplate(animated: Bool) async throws -> Bool {
        return false
    }
    public func pop(to targetTemplate: CPTemplate, animated: Bool) {
        _ = animated
        if let idx = self.templates.firstIndex(where: { $0 === targetTemplate }) {
            self.templates = Array(self.templates.prefix(through: idx))
        }
        self.topTemplate = self.templates.last
    }
    public func pop(to targetTemplate: CPTemplate, animated: Bool) async throws -> Bool {
        return false
    }
    public func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool) {
        _ = animated
        self.presentedTemplate = templateToPresent
    }
    public func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool) async throws -> Bool {
        return false
    }
    public func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        _ = animated
        self.templates.append(templateToPush)
        self.topTemplate = templateToPush
    }
    public func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) async throws -> Bool {
        return false
    }
    public func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) {
        _ = animated
        self.rootTemplate = rootTemplate
        self.templates = [rootTemplate]
        self.topTemplate = rootTemplate
    }
    public func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) async throws -> Bool {
        return false
    }
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
    public var isEnabled: Bool = false
    public var gridImages: [UIImage] = []
    public var handler: ((any CPSelectableListItem, @escaping () -> Void) -> Void)? = nil
    public var imageTitles: [String] = []
    public var listImageRowHandler: ((CPListImageRowItem, Int, @escaping () -> Void) -> Void)? = nil
    public var text: String? = nil
    public var userInfo: Any? = nil
    public override init() { super.init() }
    public init(text: String?, cardElements elements: [CPListImageRowItemCardElement], allowsMultipleLines: Bool) {
        super.init()
        self.elements = elements
    }
    public init(text: String?, condensedElements elements: [CPListImageRowItemCondensedElement], allowsMultipleLines: Bool) {
        super.init()
        self.elements = elements
    }
    public init(text: String?, elements: [CPListImageRowItemRowElement], allowsMultipleLines: Bool) {
        super.init()
        self.text = text
        self.elements = elements
        self.allowsMultipleLines = allowsMultipleLines
    }
    public init(text: String?, gridElements elements: [CPListImageRowItemGridElement], allowsMultipleLines: Bool) {
        super.init()
        self.elements = elements
    }
    public init(text: String?, imageGridElements elements: [CPListImageRowItemImageGridElement], allowsMultipleLines: Bool) {
        super.init()
        self.elements = elements
    }
    public init(text: String, images: [UIImage]) {
        super.init()
        self.text = text
    }
    public init(text: String, images: [UIImage], imageTitles: [String]) {
        super.init()
        self.text = text
        self.imageTitles = imageTitles
    }
    public func update(_ gridImages: [UIImage]) {
        // fail-closed
    }
}

@MainActor open class CPListImageRowItemElement: NSObject, @unchecked Sendable {
    public class var maximumImageSize: CGSize { CPButtonMaximumImageSize }
    public var isEnabled: Bool = false
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
    public class var maximumImageSize: CGSize { CPButtonMaximumImageSize }
    public var accessoryImage: UIImage? = nil
    public var accessoryType: CPListItemAccessoryType = .none
    public var detailText: String? = nil
    public var isEnabled: Bool = false
    public var isExplicitContent: Bool = false
    public var handler: ((any CPSelectableListItem, @escaping () -> Void) -> Void)? = nil
    public var image: UIImage? = nil
    public var playbackProgress: CGFloat = 0
    public var isPlaying: Bool = false
    public var playingIndicatorLocation: CPListItemPlayingIndicatorLocation = .leading
    public var showsDisclosureIndicator: Bool = false
    public var showsExplicitLabel: Bool = false
    public var text: String? = nil
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
        return 0
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
    public var isEnabled: Bool = false
    public var focusedImage: UIImage? = nil
    public var isHidden: Bool = false
    public var image: UIImage? = nil
    public override init() { super.init() }
    public init(handler: ((CPMapButton) -> Void)? = nil) {
        super.init()
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
    }
}

open class CPMessageGridItemConfiguration: NSObject, @unchecked Sendable {
    public var conversationIdentifier: String = ""
    public var isUnread: Bool = false
    public override init() { super.init() }
    public init(conversationIdentifier: String, unread: Bool) {
        super.init()
        self.conversationIdentifier = conversationIdentifier
    }
}

open class CPMessageListItem: NSObject, @unchecked Sendable {
    public var conversationIdentifier: String? = nil
    public var detailText: String? = nil
    public var isEnabled: Bool = false
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
        // fail-closed
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
    public var currentLaneGuidance: CPLaneGuidance? = nil
    public var currentRoadNameVariants: [String] = []
    public var maneuverState: CPManeuverState = .initial
    public var trip: CPTrip = CPTrip()
    public var upcomingManeuvers: [CPManeuver] = []
    public override init() { super.init() }
    public func add(_ laneGuidances: [CPLaneGuidance]) {
        // fail-closed
    }
    public func add(_ maneuvers: [CPManeuver]) {
        // fail-closed
    }
    public func cancelTrip() {
        // fail-closed
    }
    public func finishTrip() {
        // fail-closed
    }
    public func pauseTrip(for reason: CPNavigationSession.PauseReason, description: String?) {
        // fail-closed
    }
    public func pauseTrip(for reason: CPNavigationSession.PauseReason, description: String?, turnCardColor: UIColor?) {
        // fail-closed
    }
    public func resumeTrip(updatedRouteInformation routeInformation: CPRouteInformation) {
        // fail-closed
    }
    public func updateEstimates(_ estimates: CPTravelEstimates, for maneuver: CPManeuver) {
        // fail-closed
    }
}

@MainActor open class CPNowPlayingButton: NSObject, @unchecked Sendable {
    public var isEnabled: Bool = false
    public var isSelected: Bool = false
    public override init() { super.init() }
    public init(handler: ((CPNowPlayingButton) -> Void)? = nil) {
        super.init()
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
    }
}

@MainActor open class CPNowPlayingMode: NSObject, @unchecked Sendable {
    static let _default = CPNowPlayingMode()
    public class var `default`: CPNowPlayingMode { CPNowPlayingMode() }
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
    }
    public init(timeRemaining: TimeInterval, paused: Bool) {
        super.init()
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
    }
    public init(teamLogo: UIImage) {
        super.init()
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
        self.tripTravelEstimates = tripTravelEstimates
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
    public var contentStyle: CPContentStyle = []
    public var limitedUserInterfaces: CPLimitableUserInterface = []
    public override init() { super.init() }
    public init(delegate: any CPSessionConfigurationDelegate) {
        super.init()
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
    public class var maximumActionCount: Int { 3 }
    public var actions: [CPAlertAction] = []
    public var titleVariants: [String] = []
    public override init() { super.init() }
    public init(titleVariants: [String], actions: [CPAlertAction]) {
        super.init()
        self.titleVariants = titleVariants
        self.actions = actions
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
    public var gridButtons: [CPGridButton] = []
    public var title: String = ""
    public override init() { super.init() }
    public init(title: String?, gridButtons: [CPGridButton]) {
        super.init()
        self.title = title ?? ""
        self.gridButtons = gridButtons
    }
    public func updateGridButtons(_ gridButtons: [CPGridButton]) {
        self.gridButtons = gridButtons
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
        self.items = items
        self.actions = actions
    }
}

@MainActor open class CPListTemplate: CPTemplate, CPBarButtonProviding, @unchecked Sendable {
    public class var maximumGridButtonImageSize: CGSize { CPButtonMaximumImageSize }
    public class var maximumHeaderGridButtonCount: Int { 3 }
    public class var maximumItemCount: Int { 12 }
    public class var maximumSectionCount: Int { 12 }
    public var assistantCellConfiguration: CPAssistantCellConfiguration? = nil
    public var emptyViewSubtitleVariants: [String] = []
    public var emptyViewTitleVariants: [String] = []
    public var headerGridButtons: [CPGridButton]? = nil
    public var itemCount: Int = 0
    public var sectionCount: Int = 0
    public var sections: [CPListSection] = []
    public var showsSpinnerWhileEmpty: Bool = false
    public var title: String? = nil
    public override init() { super.init() }
    public init(title: String?, sections: [CPListSection]) {
        super.init()
        self.title = title
        self.sections = sections
        self.sectionCount = sections.count
        self.itemCount = sections.reduce(0) { $0 + $1.items.count }
    }
    public init(title: String?, sections: [CPListSection], assistantCellConfiguration: CPAssistantCellConfiguration?) {
        super.init()
        self.title = title
        self.sections = sections
        self.assistantCellConfiguration = assistantCellConfiguration
    }
    public init(title: String?, sections: [CPListSection], assistantCellConfiguration: CPAssistantCellConfiguration?, headerGridButtons: [CPGridButton]?) {
        super.init()
        self.title = title
        self.sections = sections
        self.assistantCellConfiguration = assistantCellConfiguration
        self.headerGridButtons = headerGridButtons
    }
    public func indexPath(for item: any CPListTemplateItem) -> IndexPath? {
        return nil
    }
    public func updateSections(_ sections: [CPListSection]) {
        self.sections = sections
        self.sectionCount = sections.count
        self.itemCount = sections.reduce(0) { $0 + $1.items.count }
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
    public var currentNavigationAlert: CPNavigationAlert? = nil
    public var guidanceBackgroundColor: UIColor = UIColor()
    public var hidesButtonsWithNavigationBar: Bool = false
    public var mapButtons: [CPMapButton] = []
    public var isPanningInterfaceVisible: Bool = false
    public var tripEstimateStyle: CPTripEstimateStyle = .light
    public override init() { super.init() }
    public func dismissNavigationAlert(animated: Bool) async -> Bool {
        return false
    }
    public func dismissPanningInterface(animated: Bool) {
        // fail-closed
    }
    public func hideTripPreviews() {
        // fail-closed
    }
    public func present(navigationAlert: CPNavigationAlert, animated: Bool) {
        // fail-closed
    }
    public func showPanningInterface(animated: Bool) {
        // fail-closed
    }
    public func showRouteChoicesPreview(for tripPreview: CPTrip, textConfiguration: CPTripPreviewTextConfiguration?) {
        // fail-closed
    }
    public func showTripPreviews(_ tripPreviews: [CPTrip], selectedTrip: CPTrip?, textConfiguration: CPTripPreviewTextConfiguration?) {
        // fail-closed
    }
    public func showTripPreviews(_ tripPreviews: [CPTrip], textConfiguration: CPTripPreviewTextConfiguration?) {
        // fail-closed
    }
    public func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
        return CPNavigationSession()
    }
    public func updateEstimates(_ estimates: CPTravelEstimates, for trip: CPTrip) {
        // fail-closed
    }
    public func update(_ estimates: CPTravelEstimates, for trip: CPTrip, with timeRemainingColor: CPTimeRemainingColor) {
        // fail-closed
    }
}

@MainActor open class CPNowPlayingTemplate: CPTemplate, @unchecked Sendable {
    static let _shared = CPNowPlayingTemplate()
    public class var shared: CPNowPlayingTemplate { CPNowPlayingTemplate._shared }
    public var isAlbumArtistButtonEnabled: Bool = false
    public var nowPlayingButtons: [CPNowPlayingButton] = []
    public var nowPlayingMode: CPNowPlayingMode? = nil
    public var isUpNextButtonEnabled: Bool = false
    public var upNextTitle: String = ""
    public override init() { super.init() }
    public func add(_ observer: any CPNowPlayingTemplateObserver) {
        // fail-closed
    }
    public func remove(_ observer: any CPNowPlayingTemplateObserver) {
        // fail-closed
    }
    public func updateNowPlayingButtons(_ nowPlayingButtons: [CPNowPlayingButton]) {
        // fail-closed
    }
}

@MainActor open class CPPointOfInterestTemplate: CPTemplate, CPBarButtonProviding, @unchecked Sendable {
    public var pointsOfInterest: [CPPointOfInterest] = []
    public var selectedIndex: Int = 0
    public var title: String = ""
    public override init() { super.init() }
    public init(title: String, pointsOfInterest: [CPPointOfInterest], selectedIndex: Int) {
        super.init()
        self.title = title
        self.pointsOfInterest = pointsOfInterest
        self.selectedIndex = selectedIndex
    }
    public func setPointsOfInterest(_ pointsOfInterest: [CPPointOfInterest], selectedIndex: Int) {
        // fail-closed
    }
}

@MainActor open class CPSearchTemplate: CPTemplate, @unchecked Sendable {
    public override init() { super.init() }
}

@MainActor open class CPTabBarTemplate: CPTemplate, @unchecked Sendable {
    public class var maximumTabCount: Int { 5 }
    public var selectedTemplate: CPTemplate? = nil
    public var templates: [CPTemplate] = []
    public override init() { super.init() }
    public init(templates: [CPTemplate]) {
        super.init()
        self.templates = templates
    }
    public func select(_ newTemplate: CPTemplate) {
        // fail-closed
    }
    public func selectTemplate(at index: Int) {
        // fail-closed
    }
    public func updateTemplates(_ newTemplates: [CPTemplate]) {
        // fail-closed
    }
}

@MainActor open class CPTemplateApplicationDashboardScene: UIScene, @unchecked Sendable {
    public var dashboardController: CPDashboardController = CPDashboardController()
    public var dashboardWindow: UIWindow = UIWindow()
    public var delegate: (any CPTemplateApplicationDashboardSceneDelegate)? = nil
    public override init() { super.init() }
}

@MainActor open class CPTemplateApplicationInstrumentClusterScene: UIScene, @unchecked Sendable {
    public var contentStyle: UIUserInterfaceStyle = .unspecified
    public var delegate: (any CPTemplateApplicationInstrumentClusterSceneDelegate)? = nil
    public var instrumentClusterController: CPInstrumentClusterController = CPInstrumentClusterController()
    public override init() { super.init() }
}

@MainActor open class CPTemplateApplicationScene: UIScene, @unchecked Sendable {
    public var carWindow: CPWindow = CPWindow()
    public var contentStyle: UIUserInterfaceStyle = .unspecified
    public var delegate: (any CPTemplateApplicationSceneDelegate)? = nil
    public var interfaceController: CPInterfaceController = CPInterfaceController()
    public override init() { super.init() }
}

open class CPTextButton: NSObject, @unchecked Sendable {
    public var textStyle: CPTextButtonStyle = .normal
    public var title: String = ""
    public override init() { super.init() }
    public init(title: String, textStyle: CPTextButtonStyle, handler: ((CPTextButton) -> Void)? = nil) {
        super.init()
        self.title = title
        self.textStyle = textStyle
    }
}

open class CPTravelEstimates: NSObject, @unchecked Sendable {
    public var distanceRemaining: Measurement<UnitLength> = Measurement(value: 0, unit: UnitLength.meters)
    public var distanceRemainingToDisplay: Measurement<UnitLength> = Measurement(value: 0, unit: UnitLength.meters)
    public var timeRemaining: TimeInterval = 0
    public override init() { super.init() }
    public init(distanceRemaining: Measurement<UnitLength>, distanceRemainingToDisplay: Measurement<UnitLength>, timeRemaining time: TimeInterval) {
        super.init()
    }
    public init(distanceRemaining distance: Measurement<UnitLength>, timeRemaining time: TimeInterval) {
        super.init()
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
    public var activeStateIdentifier: String? = nil
    public var voiceControlStates: [CPVoiceControlState] = []
    public override init() { super.init() }
    public init(voiceControlStates: [CPVoiceControlState]) {
        super.init()
        self.voiceControlStates = voiceControlStates
    }
    public func activateVoiceControlState(withIdentifier identifier: String) {
        // fail-closed
    }
}

@MainActor open class CPWindow: UIWindow, @unchecked Sendable {
    public var mapButtonSafeAreaLayoutGuide: UILayoutGuide = UILayoutGuide()
    public override init() { super.init() }
}

