import Foundation

open class CPAlertAction: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public enum Style: UInt, Equatable, Hashable, Sendable {
        case `default` = 0
        case cancel = 1
        case destructive = 2
    }

    public let title: String
    public let style: Style
    public let color: UIColor?
    public let handler: CPAlertActionHandler

    public init(title: String, style: Style, handler: @escaping CPAlertActionHandler) {
        self.title = title
        self.style = style
        self.color = nil
        self.handler = handler
        super.init()
    }

    public init(title: String, color: UIColor, handler: @escaping CPAlertActionHandler) {
        self.title = title
        self.style = .default
        self.color = color
        self.handler = handler
        super.init()
    }


    @_spi(OpenUIKitHost)
    public func portableInvoke() {
        handler(self)
    }
}

open class CPBarButton: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public enum `Type`: UInt, Equatable, Hashable, Sendable {
        case text = 0
        case image = 1
    }

    public let buttonType: `Type`
    public var buttonStyle: CPBarButtonStyle
    public var isEnabled: Bool
    public var image: UIImage?
    public var title: String?
    public let handler: CPBarButtonHandler?

    public init(image: UIImage, handler: CPBarButtonHandler? = nil) {
        self.buttonType = .image
        self.buttonStyle = .none
        self.isEnabled = true
        self.image = image
        self.title = nil
        self.handler = handler
        super.init()
    }

    public init(title: String, handler: CPBarButtonHandler? = nil) {
        self.buttonType = .text
        self.buttonStyle = .none
        self.isEnabled = true
        self.image = nil
        self.title = title
        self.handler = handler
        super.init()
    }

    public init(type: CPBarButton.`Type`, handler: CPBarButtonHandler? = nil) {
        self.buttonType = type
        self.buttonStyle = .none
        self.isEnabled = true
        self.image = nil
        self.title = nil
        self.handler = handler
        super.init()
    }


    @_spi(OpenUIKitHost)
    public func portableInvoke() {
        handler?(self)
    }
}

open class CPButton: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public private(set) var image: UIImage?
    public var title: String?
    public var isEnabled: Bool
    public let handler: ((CPButton) -> Void)?

    public init(image: UIImage, handler: ((CPButton) -> Void)? = nil) {
        self.image = image
        self.title = nil
        self.isEnabled = true
        self.handler = handler
        super.init()
    }


    @_spi(OpenUIKitHost)
    public func portableInvoke() {
        handler?(self)
    }
}

open class CPContactCallButton: CPButton {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public init(handler: ((CPButton) -> Void)? = nil) {
        super.init(image: UIImage(), handler: handler)
    }

}

open class CPContactDirectionsButton: CPButton {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public init(handler: ((CPButton) -> Void)? = nil) {
        super.init(image: UIImage(), handler: handler)
    }

}

open class CPContactMessageButton: CPButton {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let phoneOrEmail: String

    public init(phoneOrEmail: String) {
        self.phoneOrEmail = phoneOrEmail
        super.init(image: UIImage(), handler: nil)
    }

}

open class CPTextButton: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var title: String
    public var textStyle: CPTextButtonStyle
    public let handler: ((CPTextButton) -> Void)?

    public init(
        title: String,
        textStyle: CPTextButtonStyle,
        handler: ((CPTextButton) -> Void)? = nil
    ) {
        self.title = title
        self.textStyle = textStyle
        self.handler = handler
        super.init()
    }


    @_spi(OpenUIKitHost)
    public func portableInvoke() {
        handler?(self)
    }
}

open class CPGridButton: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public private(set) var titleVariants: [String]
    public private(set) var image: UIImage
    public var isEnabled: Bool
    public let messageConfiguration: CPMessageGridItemConfiguration?
    public let handler: ((CPGridButton) -> Void)?

    public init(
        titleVariants: [String],
        image: UIImage,
        messageConfiguration: CPMessageGridItemConfiguration?,
        handler: ((CPGridButton) -> Void)? = nil
    ) {
        self.titleVariants = titleVariants
        self.image = image
        self.isEnabled = true
        self.messageConfiguration = messageConfiguration
        self.handler = handler
        super.init()
    }

    public convenience init(
        titleVariants: [String],
        image: UIImage,
        handler: ((CPGridButton) -> Void)? = nil
    ) {
        self.init(
            titleVariants: titleVariants,
            image: image,
            messageConfiguration: nil,
            handler: handler
        )
    }

    public func updateImage(_ image: UIImage) {
        self.image = image
    }

    public func updateTitleVariants(_ titleVariants: [String]) {
        self.titleVariants = titleVariants
    }


    @_spi(OpenUIKitHost)
    public func portableInvoke() {
        handler?(self)
    }
}

open class CPDashboardButton: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let titleVariants: [String]
    public let subtitleVariants: [String]
    public let image: UIImage
    public let handler: ((CPDashboardButton) -> Void)?

    public init(
        titleVariants: [String],
        subtitleVariants: [String],
        image: UIImage,
        handler: ((CPDashboardButton) -> Void)? = nil
    ) {
        self.titleVariants = titleVariants
        self.subtitleVariants = subtitleVariants
        self.image = image
        self.handler = handler
        super.init()
    }

}

@MainActor
open class CPMapButton: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var isEnabled: Bool
    public var isHidden: Bool
    public var image: UIImage?
    public var focusedImage: UIImage?
    public let handler: ((CPMapButton) -> Void)?

    @MainActor
    public init(handler: ((CPMapButton) -> Void)? = nil) {
        self.isEnabled = true
        self.isHidden = false
        self.image = nil
        self.focusedImage = nil
        self.handler = handler
        super.init()
    }

}

open class CPMessageComposeBarButton: CPBarButton {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public init() {
        super.init(type: .text, handler: nil)
        title = nil
    }

    public init(image: UIImage) {
        super.init(image: image, handler: nil)
    }

}

open class CPMessageGridItemConfiguration: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let conversationIdentifier: String
    public var isUnread: Bool

    public init(conversationIdentifier: String, unread: Bool) {
        self.conversationIdentifier = conversationIdentifier
        self.isUnread = unread
        super.init()
    }

}

open class CPImageSet: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let lightContentImage: UIImage
    public let darkContentImage: UIImage

    public init(lightContentImage lightImage: UIImage, darkContentImage darkImage: UIImage) {
        self.lightContentImage = lightImage
        self.darkContentImage = darkImage
        super.init()
    }

}

open class CPContact: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var name: String
    public var image: UIImage
    public var subtitle: String?
    public var informativeText: String?
    public var actions: [CPButton]?

    public init(name: String, image: UIImage) {
        self.name = name
        self.image = image
        super.init()
    }

}

open class CPInformationItem: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let title: String?
    public let detail: String?

    public init(title: String?, detail: String?) {
        self.title = title
        self.detail = detail
        super.init()
    }

}

open class CPInformationRatingItem: CPInformationItem {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let rating: NSNumber?
    public let maximumRating: NSNumber?

    public init(rating: NSNumber?, maximumRating: NSNumber?, title: String?, detail: String?) {
        self.rating = rating
        self.maximumRating = maximumRating
        super.init(title: title, detail: detail)
    }

}

open class CPAssistantCellConfiguration: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let position: CPListItem.AssistantCellPosition
    public let visibility: CPListItem.AssistantCellVisibility
    public let assistantAction: CPAssistantCellActionType

    public init(
        position: CPListItem.AssistantCellPosition,
        visibility: CPListItem.AssistantCellVisibility,
        assistantAction: CPAssistantCellActionType
    ) {
        self.position = position
        self.visibility = visibility
        self.assistantAction = assistantAction
        super.init()
    }

}

open class CPVoiceControlState: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let identifier: String
    public let titleVariants: [String]?
    public let image: UIImage?
    public let repeats: Bool

    public init(identifier: String, titleVariants: [String]?, image: UIImage?, repeats: Bool) {
        self.identifier = identifier
        self.titleVariants = titleVariants
        self.image = image
        self.repeats = repeats
        super.init()
    }

}
