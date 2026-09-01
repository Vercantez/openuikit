import Foundation

@MainActor
open class CPListItem: CarPlayCodingObject, CPSelectableListItem {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public enum AssistantCellPosition: Int, Equatable, Hashable, Sendable {
        case top = 0
        case bottom = 1
    }

    public enum AssistantCellVisibility: Int, Equatable, Hashable, Sendable {
        case off = 0
        case whileLimitedUIActive = 1
        case always = 2
    }

    @MainActor
    public class var maximumImageSize: CGSize {
        CGSize(width: 90, height: 90)
    }

    public private(set) var text: String?
    public private(set) var detailText: String?
    public private(set) var image: UIImage?
    public private(set) var accessoryImage: UIImage?
    public var accessoryType: CPListItemAccessoryType
    public var isEnabled: Bool
    public var isExplicitContent: Bool
    public var showsExplicitLabel: Bool
    public var isPlaying: Bool
    public var playbackProgress: CGFloat
    public var playingIndicatorLocation: CPListItemPlayingIndicatorLocation
    public var handler: ((any CPSelectableListItem, @escaping () -> Void) -> Void)?
    public var userInfo: Any?

    public var showsDisclosureIndicator: Bool {
        accessoryType == .disclosureIndicator
    }

    public init(text: String?, detailText: String?) {
        self.text = text
        self.detailText = detailText
        self.image = nil
        self.accessoryImage = nil
        self.accessoryType = .none
        self.isEnabled = true
        self.isExplicitContent = false
        self.showsExplicitLabel = false
        self.isPlaying = false
        self.playbackProgress = 0
        self.playingIndicatorLocation = .leading
        super.init()
    }

    public convenience init(text: String?, detailText: String?, image: UIImage?) {
        self.init(text: text, detailText: detailText)
        self.image = image
    }

    public convenience init(
        text: String?,
        detailText: String?,
        image: UIImage?,
        accessoryImage: UIImage?,
        accessoryType: CPListItemAccessoryType
    ) {
        self.init(text: text, detailText: detailText)
        self.image = image
        self.accessoryImage = accessoryImage
        self.accessoryType = accessoryType
    }

    public convenience init(
        text: String?,
        detailText: String?,
        image: UIImage?,
        showsDisclosureIndicator: Bool
    ) {
        self.init(text: text, detailText: detailText)
        self.image = image
        self.accessoryType = showsDisclosureIndicator ? .disclosureIndicator : .none
    }

    public func setText(_ text: String) {
        self.text = text
    }

    public func setDetailText(_ detailText: String?) {
        self.detailText = detailText
    }

    public func setImage(_ image: UIImage?) {
        self.image = image
    }

    public func setAccessoryImage(_ accessoryImage: UIImage?) {
        self.accessoryImage = accessoryImage
    }


    @_spi(OpenUIKitHost)
    public func portableSelect() {
        handler?(self, {})
    }
}

@MainActor
open class CPListSection: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public private(set) var items: [any CPListTemplateItem]
    public private(set) var header: String?
    public var headerImage: UIImage?
    public private(set) var headerSubtitle: String?
    public private(set) var headerButton: CPButton?
    public private(set) var sectionIndexTitle: String?

    public init(
        items: [any CPListTemplateItem],
        header: String,
        headerSubtitle: String?,
        headerImage: UIImage?,
        headerButton: CPButton?,
        sectionIndexTitle: String?
    ) {
        self.items = items
        self.header = header
        self.headerSubtitle = headerSubtitle
        self.headerImage = headerImage
        self.headerButton = headerButton
        self.sectionIndexTitle = sectionIndexTitle
        super.init()
    }

    public convenience init(items: [any CPListTemplateItem], header: String?, sectionIndexTitle: String?) {
        self.init(
            items: items,
            header: header ?? "",
            headerSubtitle: nil,
            headerImage: nil,
            headerButton: nil,
            sectionIndexTitle: sectionIndexTitle
        )
        self.header = header
    }

    public convenience init(items: [CPListItem], header: String?, sectionIndexTitle: String?) {
        self.init(
            items: items.map { $0 as any CPListTemplateItem },
            header: header,
            sectionIndexTitle: sectionIndexTitle
        )
    }

    public convenience init(items: [any CPListTemplateItem]) {
        self.init(items: items, header: nil, sectionIndexTitle: nil)
    }

    public convenience init(items: [CPListItem]) {
        self.init(items: items.map { $0 as any CPListTemplateItem })
    }

    public func index(of item: any CPListTemplateItem) -> Int {
        items.firstIndex { $0 === item } ?? NSNotFound
    }

    public func item(at index: Int) -> any CPListTemplateItem {
        items[index]
    }

}

@MainActor
open class CPListImageRowItemElement: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    @MainActor
    public class var maximumImageSize: CGSize {
        CGSize(width: 90, height: 90)
    }

    public var image: UIImage
    public var isEnabled: Bool

    public init(image: UIImage) {
        self.image = image
        self.isEnabled = true
        super.init()
    }

}

@MainActor
open class CPListImageRowItemCardElement: CPListImageRowItemElement {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    @MainActor
    public class var maximumFullHeightImageSize: CGSize {
        CGSize(width: 150, height: 220)
    }

    public let showsImageFullHeight: Bool
    public var title: String
    public var subtitle: String?
    public var tintColor: UIColor?

    public init(
        image: UIImage,
        showsImageFullHeight: Bool,
        title: String?,
        subtitle: String?,
        tintColor: UIColor?
    ) {
        self.showsImageFullHeight = showsImageFullHeight
        self.title = title ?? ""
        self.subtitle = subtitle
        self.tintColor = tintColor
        super.init(image: image)
    }

}

@MainActor
open class CPListImageRowItemCondensedElement: CPListImageRowItemElement {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public enum Shape: Int, Equatable, Hashable, Sendable {
        case circular = 0
        case roundedRectangle = 1
    }

    public let imageShape: Shape
    public var title: String
    public var subtitle: String?
    public var accessorySymbolName: String?

    public init(
        image: UIImage,
        imageShape: Shape,
        title: String,
        subtitle: String?,
        accessorySymbolName: String?
    ) {
        self.imageShape = imageShape
        self.title = title
        self.subtitle = subtitle
        self.accessorySymbolName = accessorySymbolName
        super.init(image: image)
    }

}

@MainActor
open class CPListImageRowItemGridElement: CPListImageRowItemElement {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public override init(image: UIImage) {
        super.init(image: image)
    }

}

@MainActor
open class CPListImageRowItemImageGridElement: CPListImageRowItemElement {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public enum Shape: Int, Equatable, Hashable, Sendable {
        case circular = 0
        case roundedRectangle = 1
    }

    public let imageShape: Shape
    public var title: String
    public var accessorySymbolName: String?

    public init(image: UIImage, imageShape: Shape, title: String, accessorySymbolName: String?) {
        self.imageShape = imageShape
        self.title = title
        self.accessorySymbolName = accessorySymbolName
        super.init(image: image)
    }

}

@MainActor
open class CPListImageRowItemRowElement: CPListImageRowItemElement {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var title: String?
    public var subtitle: String?

    public init(image: UIImage, title: String?, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
        super.init(image: image)
    }

}

@MainActor
open class CPListImageRowItem: CarPlayCodingObject, CPSelectableListItem {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    @MainActor
    public class var maximumImageSize: CGSize {
        CGSize(width: 90, height: 90)
    }

    public var text: String?
    public var isEnabled: Bool
    public var userInfo: Any?
    public var handler: ((any CPSelectableListItem, @escaping () -> Void) -> Void)?
    public var listImageRowHandler: ((CPListImageRowItem, Int, @escaping () -> Void) -> Void)?
    public var elements: [CPListImageRowItemElement]
    public private(set) var gridImages: [UIImage]
    public private(set) var imageTitles: [String]
    public let allowsMultipleLines: Bool

    public init(text: String, images: [UIImage]) {
        self.text = text
        self.isEnabled = true
        self.elements = []
        self.gridImages = images
        self.imageTitles = []
        self.allowsMultipleLines = false
        super.init()
    }

    public init(text: String, images: [UIImage], imageTitles: [String]) {
        self.text = text
        self.isEnabled = true
        self.elements = []
        self.gridImages = images
        self.imageTitles = imageTitles
        self.allowsMultipleLines = false
        super.init()
    }

    public init(text: String?, cardElements elements: [CPListImageRowItemCardElement], allowsMultipleLines: Bool) {
        self.text = text
        self.isEnabled = true
        self.elements = elements
        self.gridImages = elements.map(\.image)
        self.imageTitles = elements.map(\.title)
        self.allowsMultipleLines = allowsMultipleLines
        super.init()
    }

    public init(
        text: String?,
        condensedElements elements: [CPListImageRowItemCondensedElement],
        allowsMultipleLines: Bool
    ) {
        self.text = text
        self.isEnabled = true
        self.elements = elements
        self.gridImages = elements.map(\.image)
        self.imageTitles = elements.map(\.title)
        self.allowsMultipleLines = allowsMultipleLines
        super.init()
    }

    public init(text: String?, elements: [CPListImageRowItemRowElement], allowsMultipleLines: Bool) {
        self.text = text
        self.isEnabled = true
        self.elements = elements
        self.gridImages = elements.map(\.image)
        self.imageTitles = elements.compactMap(\.title)
        self.allowsMultipleLines = allowsMultipleLines
        super.init()
    }

    public init(text: String?, gridElements elements: [CPListImageRowItemGridElement], allowsMultipleLines: Bool) {
        self.text = text
        self.isEnabled = true
        self.elements = elements
        self.gridImages = elements.map(\.image)
        self.imageTitles = []
        self.allowsMultipleLines = allowsMultipleLines
        super.init()
    }

    public init(
        text: String?,
        imageGridElements elements: [CPListImageRowItemImageGridElement],
        allowsMultipleLines: Bool
    ) {
        self.text = text
        self.isEnabled = true
        self.elements = elements
        self.gridImages = elements.map(\.image)
        self.imageTitles = elements.map(\.title)
        self.allowsMultipleLines = allowsMultipleLines
        super.init()
    }

    public func update(_ gridImages: [UIImage]) {
        self.gridImages = gridImages
    }

}

open class CPMessageListItemLeadingConfiguration: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let leadingItem: CPMessageLeadingItem
    public let leadingImage: UIImage?
    public let isUnread: Bool

    public init(leadingItem: CPMessageLeadingItem, leadingImage: UIImage?, unread: Bool) {
        self.leadingItem = leadingItem
        self.leadingImage = leadingImage
        self.isUnread = unread
        super.init()
    }

}

open class CPMessageListItemTrailingConfiguration: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let trailingItem: CPMessageTrailingItem
    public let trailingImage: UIImage?

    public init(trailingItem: CPMessageTrailingItem, trailingImage: UIImage?) {
        self.trailingItem = trailingItem
        self.trailingImage = trailingImage
        super.init()
    }

}

@MainActor
open class CPMessageListItem: CarPlayCodingObject, CPListTemplateItem {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var conversationIdentifier: String?
    public var text: String?
    public var detailText: String?
    public var trailingText: String?
    public var phoneOrEmailAddress: String?
    public var leadingConfiguration: CPMessageListItemLeadingConfiguration
    public var trailingConfiguration: CPMessageListItemTrailingConfiguration?
    public var leadingDetailTextImage: UIImage?
    public var isEnabled: Bool
    public var userInfo: Any?

    public init(
        conversationIdentifier: String,
        text: String,
        leadingConfiguration: CPMessageListItemLeadingConfiguration,
        trailingConfiguration: CPMessageListItemTrailingConfiguration?,
        detailText: String?,
        trailingText: String?
    ) {
        self.conversationIdentifier = conversationIdentifier
        self.text = text
        self.leadingConfiguration = leadingConfiguration
        self.trailingConfiguration = trailingConfiguration
        self.detailText = detailText
        self.trailingText = trailingText
        self.isEnabled = true
        super.init()
    }

    public init(
        fullName: String,
        phoneOrEmailAddress: String,
        leadingConfiguration: CPMessageListItemLeadingConfiguration,
        trailingConfiguration: CPMessageListItemTrailingConfiguration?,
        detailText: String?,
        trailingText: String?
    ) {
        self.text = fullName
        self.phoneOrEmailAddress = phoneOrEmailAddress
        self.leadingConfiguration = leadingConfiguration
        self.trailingConfiguration = trailingConfiguration
        self.detailText = detailText
        self.trailingText = trailingText
        self.isEnabled = true
        super.init()
    }

}
