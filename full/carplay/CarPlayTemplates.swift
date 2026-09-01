import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(MapKit)
import MapKit
#endif

@MainActor
open class CPTemplate: NSObject, CPBarButtonProviding {
    public var showsTabBadge = false
    public var tabTitle: String?
    public var userInfo: Any?
    public var backButton: CPBarButton?
    public var leadingNavigationBarButtons: [CPBarButton] = []
    public var trailingNavigationBarButtons: [CPBarButton] = []

    #if canImport(UIKit)
    public var tabImage: UIImage?
    public var tabSystemItem: UITabBarItem.SystemItem = .more
    #endif

    public override init() {
        super.init()
    }

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }
}

@MainActor
open class CPListTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    @MainActor
    public class var maximumGridButtonImageSize: CGSize { .zero }
    @MainActor
    public class var maximumHeaderGridButtonCount: Int { 0 }
    @MainActor
    public class var maximumItemCount: Int { 0 }
    @MainActor
    public class var maximumSectionCount: Int { 0 }

    public private(set) var title: String?
    public private(set) var sections: [CPListSection]
    public var assistantCellConfiguration: CPAssistantCellConfiguration?
    public weak var delegate: (any CPListTemplateDelegate)?
    public var emptyViewSubtitleVariants: [String]
    public var emptyViewTitleVariants: [String]
    public var showsSpinnerWhileEmpty: Bool

    #if canImport(UIKit)
    public var headerGridButtons: [CPGridButton]?
    #endif

    public var sectionCount: Int { sections.count }
    public var itemCount: Int { sections.reduce(0) { $0 + $1.items.count } }

    public init(title: String?, sections: [CPListSection]) {
        self.title = title
        self.sections = sections
        self.emptyViewSubtitleVariants = []
        self.emptyViewTitleVariants = []
        self.showsSpinnerWhileEmpty = false
        super.init()
        self.tabTitle = title
    }

    public convenience init(
        title: String?,
        sections: [CPListSection],
        assistantCellConfiguration: CPAssistantCellConfiguration?
    ) {
        self.init(title: title, sections: sections)
        self.assistantCellConfiguration = assistantCellConfiguration
    }

    #if canImport(UIKit)
    public convenience init(
        title: String?,
        sections: [CPListSection],
        assistantCellConfiguration: CPAssistantCellConfiguration?,
        headerGridButtons: [CPGridButton]?
    ) {
        self.init(
            title: title,
            sections: sections,
            assistantCellConfiguration: assistantCellConfiguration
        )
        self.headerGridButtons = headerGridButtons
    }
    #endif

    public func updateSections(_ sections: [CPListSection]) {
        self.sections = sections
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
}

#if canImport(UIKit)
@MainActor
open class CPGridTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    @MainActor
    public class var maximumGridButtonImageSize: CGSize { .zero }

    public private(set) var title: String
    public private(set) var gridButtons: [CPGridButton]

    public init(title: String?, gridButtons: [CPGridButton]) {
        self.title = title ?? ""
        self.gridButtons = gridButtons
        super.init()
        self.tabTitle = title
    }

    public func updateGridButtons(_ gridButtons: [CPGridButton]) {
        self.gridButtons = gridButtons
    }

    public func updateTitle(_ title: String) {
        self.title = title
        self.tabTitle = title
    }
}
#endif

@MainActor
open class CPTabBarTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    @MainActor
    public class var maximumTabCount: Int { 0 }

    public private(set) var templates: [CPTemplate]
    public private(set) var selectedTemplate: CPTemplate?
    public weak var delegate: (any CPTabBarTemplateDelegate)?

    public init(templates: [CPTemplate]) {
        self.templates = templates
        self.selectedTemplate = templates.first
        super.init()
    }

    public func updateTemplates(_ newTemplates: [CPTemplate]) {
        templates = newTemplates
        if let selected = selectedTemplate, templates.contains(where: { $0 === selected }) {
            return
        }
        selectedTemplate = templates.first
    }

    public func select(_ newTemplate: CPTemplate) {
        guard templates.contains(where: { $0 === newTemplate }) else { return }
        selectedTemplate = newTemplate
        delegate?.tabBarTemplate(self, didSelect: newTemplate)
    }

    public func selectTemplate(at index: Int) {
        guard templates.indices.contains(index) else { return }
        select(templates[index])
    }
}

@MainActor
open class CPAlertTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    @MainActor
    public class var maximumActionCount: Int { 0 }

    public let titleVariants: [String]
    public let actions: [CPAlertAction]

    public init(titleVariants: [String], actions: [CPAlertAction]) {
        self.titleVariants = titleVariants
        self.actions = actions
        super.init()
    }
}

@MainActor
open class CPActionSheetTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let title: String?
    public let message: String?
    public let actions: [CPAlertAction]

    public init(title: String?, message: String?, actions: [CPAlertAction]) {
        self.title = title
        self.message = message
        self.actions = actions
        super.init()
    }
}

@MainActor
open class CPInformationTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var title: String
    public let layout: CPInformationTemplateLayout
    public var items: [CPInformationItem]
    public var actions: [CPTextButton]

    public init(
        title: String,
        layout: CPInformationTemplateLayout,
        items: [CPInformationItem],
        actions: [CPTextButton]
    ) {
        self.title = title
        self.layout = layout
        self.items = items
        self.actions = actions
        super.init()
        self.tabTitle = title
    }
}

#if canImport(UIKit)
@MainActor
open class CPContactTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var contact: CPContact

    public init(contact: CPContact) {
        self.contact = contact
        super.init()
        self.tabTitle = contact.name
    }
}
#endif

@MainActor
open class CPSearchTemplate: CPTemplate {
    public weak var delegate: (any CPSearchTemplateDelegate)?
}

@MainActor
open class CPVoiceControlTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public let voiceControlStates: [CPVoiceControlState]
    public private(set) var activeStateIdentifier: String?

    public init(voiceControlStates: [CPVoiceControlState]) {
        self.voiceControlStates = voiceControlStates
        self.activeStateIdentifier = voiceControlStates.first?.identifier
        super.init()
    }

    public func activateVoiceControlState(withIdentifier identifier: String) {
        guard voiceControlStates.contains(where: { $0.identifier == identifier }) else { return }
        activeStateIdentifier = identifier
    }
}

#if canImport(MapKit)
@MainActor
open class CPPointOfInterestTemplate: CPTemplate {
    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var title: String
    public private(set) var pointsOfInterest: [CPPointOfInterest]
    public var selectedIndex: Int
    public weak var pointOfInterestDelegate: (any CPPointOfInterestTemplateDelegate)?

    public init(title: String, pointsOfInterest: [CPPointOfInterest], selectedIndex: Int) {
        self.title = title
        self.pointsOfInterest = pointsOfInterest
        self.selectedIndex = selectedIndex
        super.init()
        self.tabTitle = title
    }

    public func setPointsOfInterest(_ pointsOfInterest: [CPPointOfInterest], selectedIndex: Int) {
        self.pointsOfInterest = pointsOfInterest
        self.selectedIndex = selectedIndex
    }
}
#endif
