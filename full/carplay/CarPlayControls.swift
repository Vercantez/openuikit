import Foundation

#if canImport(UIKit)
import UIKit
#endif

open class CPAlertAction: NSObject {
    public enum Style: UInt, Equatable, Hashable, Sendable {
        case `default` = 0
        case cancel = 1
        case destructive = 2
    }

    public let title: String
    public let style: Style
    public let handler: CPAlertActionHandler
    #if canImport(UIKit)
    public let color: UIColor?
    #endif

    public init(title: String, style: Style, handler: @escaping CPAlertActionHandler) {
        self.title = title
        self.style = style
        self.handler = handler
        #if canImport(UIKit)
        self.color = nil
        #endif
        super.init()
    }

    #if canImport(UIKit)
    public init(title: String, color: UIColor, handler: @escaping CPAlertActionHandler) {
        self.title = title
        self.style = .default
        self.color = color
        self.handler = handler
        super.init()
    }
    #endif

    public required init?(coder: NSCoder) {
        return nil
    }

    @_spi(OpenUIKitHost)
    public func invokeHandler() {
        handler(self)
    }
}

open class CPBarButton: NSObject {
    public enum `Type`: UInt, Equatable, Hashable, Sendable {
        case text = 0
        case image = 1
    }

    public let buttonType: `Type`
    public var buttonStyle: CPBarButtonStyle = .none
    public var isEnabled = true
    public var title: String?
    public let handler: CPBarButtonHandler?
    #if canImport(UIKit)
    public var image: UIImage?
    #endif

    public init(title: String, handler: CPBarButtonHandler? = nil) {
        self.buttonType = .text
        self.title = title
        self.handler = handler
        super.init()
    }

    public init(type: CPBarButton.`Type`, handler: CPBarButtonHandler? = nil) {
        self.buttonType = type
        self.handler = handler
        super.init()
    }

    #if canImport(UIKit)
    public init(image: UIImage, handler: CPBarButtonHandler? = nil) {
        self.buttonType = .image
        self.image = image
        self.handler = handler
        super.init()
    }
    #endif

    public required init?(coder: NSCoder) {
        return nil
    }

    @_spi(OpenUIKitHost)
    public func invokeHandler() {
        handler?(self)
    }
}

open class CPTextButton: NSObject {
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

    public required init?(coder: NSCoder) {
        return nil
    }

    @_spi(OpenUIKitHost)
    public func invokeHandler() {
        handler?(self)
    }
}

open class CPMessageGridItemConfiguration: NSObject {
    public let conversationIdentifier: String
    public var isUnread: Bool

    public init(conversationIdentifier: String, unread: Bool) {
        self.conversationIdentifier = conversationIdentifier
        self.isUnread = unread
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPInformationItem: NSObject {
    public let title: String?
    public let detail: String?

    public init(title: String?, detail: String?) {
        self.title = title
        self.detail = detail
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPInformationRatingItem: CPInformationItem {
    public let rating: NSNumber?
    public let maximumRating: NSNumber?

    public init(rating: NSNumber?, maximumRating: NSNumber?, title: String?, detail: String?) {
        self.rating = rating
        self.maximumRating = maximumRating
        super.init(title: title, detail: detail)
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPAssistantCellConfiguration: NSObject {
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

    public required init?(coder: NSCoder) {
        return nil
    }
}

#if canImport(UIKit)
open class CPButton: NSObject {
    public private(set) var image: UIImage?
    public var title: String?
    public var isEnabled = true
    public let handler: ((CPButton) -> Void)?

    public init(image: UIImage, handler: ((CPButton) -> Void)? = nil) {
        self.image = image
        self.handler = handler
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    @_spi(OpenUIKitHost)
    public func invokeHandler() {
        handler?(self)
    }
}

open class CPContactCallButton: CPButton {
    public init(handler: ((CPButton) -> Void)? = nil) {
        super.init(image: UIImage(), handler: handler)
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPContactDirectionsButton: CPButton {
    public init(handler: ((CPButton) -> Void)? = nil) {
        super.init(image: UIImage(), handler: handler)
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPContactMessageButton: CPButton {
    public let phoneOrEmail: String

    public init(phoneOrEmail: String) {
        self.phoneOrEmail = phoneOrEmail
        super.init(image: UIImage(), handler: nil)
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPGridButton: NSObject {
    public private(set) var titleVariants: [String]
    public private(set) var image: UIImage
    public var isEnabled = true
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

    public required init?(coder: NSCoder) {
        return nil
    }

    @_spi(OpenUIKitHost)
    public func invokeHandler() {
        handler?(self)
    }
}

open class CPDashboardButton: NSObject {
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

    public required init?(coder: NSCoder) {
        return nil
    }
}

@MainActor
open class CPMapButton: NSObject {
    public var isEnabled = true
    public var isHidden = false
    public var image: UIImage?
    public var focusedImage: UIImage?
    public let handler: ((CPMapButton) -> Void)?

    public init(handler: ((CPMapButton) -> Void)? = nil) {
        self.handler = handler
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPMessageComposeBarButton: CPBarButton {
    public init() {
        super.init(type: .text, handler: nil)
    }

    public init(image: UIImage) {
        super.init(image: image, handler: nil)
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPImageSet: NSObject {
    public let lightContentImage: UIImage
    public let darkContentImage: UIImage

    public init(lightContentImage lightImage: UIImage, darkContentImage darkImage: UIImage) {
        self.lightContentImage = lightImage
        self.darkContentImage = darkImage
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPContact: NSObject {
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

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPVoiceControlState: NSObject {
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

    public required init?(coder: NSCoder) {
        return nil
    }
}
#else
open class CPMessageComposeBarButton: CPBarButton {
    public init() {
        super.init(type: .text, handler: nil)
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

open class CPVoiceControlState: NSObject {
    public let identifier: String
    public let titleVariants: [String]?
    public let repeats: Bool

    @_spi(OpenUIKitHost)
    public init(identifier: String, titleVariants: [String]?, repeats: Bool) {
        self.identifier = identifier
        self.titleVariants = titleVariants
        self.repeats = repeats
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}
#endif
