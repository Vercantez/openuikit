import Foundation

/// A selectable collaboration option shown in a share sheet.
open class SWCollaborationOption: NSObject, NSCopying, NSSecureCoding {
    public var title: String
    public let identifier: String
    public var subtitle: String
    public var isSelected: Bool
    public var requiredOptionsIdentifiers: [String]

    public static var supportsSecureCoding: Bool { true }

    public init(title: String, identifier: String) {
        self.title = title
        self.identifier = identifier
        self.subtitle = ""
        self.isSelected = false
        self.requiredOptionsIdentifiers = []
        super.init()
    }

    public convenience init(
        title: String,
        identifier: String,
        subtitle: String = "",
        selected: Bool = false,
        requiredOptionsIdentifiers: [String] = []
    ) {
        self.init(title: title, identifier: identifier)
        self.subtitle = subtitle
        self.isSelected = selected
        self.requiredOptionsIdentifiers = requiredOptionsIdentifiers
    }

    public required init?(coder: NSCoder) {
        guard let identifier = swcDecodeObject(NSString.self, from: coder, key: "identifier") as String?
        else {
            return nil
        }
        self.identifier = identifier
        self.title = (swcDecodeObject(NSString.self, from: coder, key: "title") as String?) ?? ""
        self.subtitle = (swcDecodeObject(NSString.self, from: coder, key: "subtitle") as String?) ?? ""
        self.isSelected = coder.decodeBool(forKey: "selected")
        if let required = coder.decodeObject(
            of: [NSArray.self, NSString.self],
            forKey: "requiredOptionsIdentifiers"
        ) as? [NSString] {
            self.requiredOptionsIdentifiers = required.map { $0 as String }
        } else {
            self.requiredOptionsIdentifiers = []
        }
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(title as NSString, forKey: "title")
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(subtitle as NSString, forKey: "subtitle")
        coder.encode(isSelected, forKey: "selected")
        coder.encode(requiredOptionsIdentifiers.map { $0 as NSString } as NSArray, forKey: "requiredOptionsIdentifiers")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        SWCollaborationOption(
            title: title,
            identifier: identifier,
            subtitle: subtitle,
            selected: isSelected,
            requiredOptionsIdentifiers: requiredOptionsIdentifiers
        )
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SWCollaborationOption else { return false }
        return title == other.title
            && identifier == other.identifier
            && subtitle == other.subtitle
            && isSelected == other.isSelected
            && requiredOptionsIdentifiers == other.requiredOptionsIdentifiers
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(identifier)
        hasher.combine(title)
        hasher.combine(subtitle)
        hasher.combine(isSelected)
        hasher.combine(requiredOptionsIdentifiers)
        return hasher.finalize()
    }
}

/// A titled group of collaboration options.
open class SWCollaborationOptionsGroup: NSObject, NSCopying, NSSecureCoding {
    public var title: String
    public let identifier: String
    public var footer: String
    private var storedOptions: [SWCollaborationOption]

    public var options: [SWCollaborationOption] {
        get { storedOptions }
        set {
            storedOptions = swcCopyingArray(newValue)
            optionsDidChange()
        }
    }

    public static var supportsSecureCoding: Bool { true }

    public init(identifier: String, options: [SWCollaborationOption]) {
        self.identifier = identifier
        self.title = ""
        self.footer = ""
        self.storedOptions = swcCopyingArray(options)
        super.init()
        optionsDidChange()
    }

    public required init?(coder: NSCoder) {
        guard let identifier = swcDecodeObject(NSString.self, from: coder, key: "identifier") as String?
        else {
            return nil
        }
        self.identifier = identifier
        self.title = (swcDecodeObject(NSString.self, from: coder, key: "title") as String?) ?? ""
        self.footer = (swcDecodeObject(NSString.self, from: coder, key: "footer") as String?) ?? ""
        self.storedOptions = (coder.decodeObject(
            of: [NSArray.self, SWCollaborationOption.self],
            forKey: "options"
        ) as? [SWCollaborationOption]) ?? []
        super.init()
        optionsDidChange()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(title as NSString, forKey: "title")
        coder.encode(identifier as NSString, forKey: "identifier")
        coder.encode(footer as NSString, forKey: "footer")
        coder.encode(storedOptions as NSArray, forKey: "options")
    }

    open func optionsDidChange() {}

    open func copy(with zone: NSZone? = nil) -> Any {
        let copy = SWCollaborationOptionsGroup(identifier: identifier, options: storedOptions)
        copy.title = title
        copy.footer = footer
        return copy
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SWCollaborationOptionsGroup else { return false }
        return title == other.title
            && identifier == other.identifier
            && footer == other.footer
            && storedOptions == other.storedOptions
    }
}

/// Mutually exclusive collaboration options (radio group).
///
/// When constructed, `selectedOptionIdentifier` defaults to the first
/// option's identifier. Setting it updates `isSelected` so only the matching
/// option is selected. Darwin's cascade for `requiredOptionsIdentifiers`
/// inside a picker is unobserved.
open class SWCollaborationOptionsPickerGroup: SWCollaborationOptionsGroup {
    private var storedSelectedOptionIdentifier: String = ""

    public var selectedOptionIdentifier: String {
        get { storedSelectedOptionIdentifier }
        set {
            storedSelectedOptionIdentifier = newValue
            applyPickerSelection()
        }
    }

    public override init(identifier: String, options: [SWCollaborationOption]) {
        super.init(identifier: identifier, options: options)
        if storedSelectedOptionIdentifier.isEmpty, let first = self.options.first {
            storedSelectedOptionIdentifier = first.identifier
        }
        applyPickerSelection()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        if let selected = swcDecodeObject(
            NSString.self,
            from: coder,
            key: "selectedOptionIdentifier"
        ) as String? {
            storedSelectedOptionIdentifier = selected
        } else if let first = options.first {
            storedSelectedOptionIdentifier = first.identifier
        }
        applyPickerSelection()
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(storedSelectedOptionIdentifier as NSString, forKey: "selectedOptionIdentifier")
    }

    open override func optionsDidChange() {
        if storedSelectedOptionIdentifier.isEmpty, let first = options.first {
            storedSelectedOptionIdentifier = first.identifier
        }
        applyPickerSelection()
    }

    private func applyPickerSelection() {
        for option in options {
            option.isSelected = (option.identifier == storedSelectedOptionIdentifier)
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = SWCollaborationOptionsPickerGroup(identifier: identifier, options: options)
        copy.title = title
        copy.footer = footer
        copy.selectedOptionIdentifier = selectedOptionIdentifier
        return copy
    }
}

/// A bundle of collaboration option groups plus a summary string.
///
/// `init(optionsGroups:)` uses an empty summary rather than generating Apple
/// share-sheet copy. Darwin's generated-summary wording is unobserved.
open class SWCollaborationShareOptions: NSObject, NSCopying, NSSecureCoding {
    public var optionsGroups: [SWCollaborationOptionsGroup] {
        get { storedOptionsGroups }
        set { storedOptionsGroups = swcCopyingArray(newValue) }
    }

    public var summary: String

    private var storedOptionsGroups: [SWCollaborationOptionsGroup]

    public static var supportsSecureCoding: Bool { true }

    public init(optionsGroups: [SWCollaborationOptionsGroup], summary: String) {
        self.storedOptionsGroups = swcCopyingArray(optionsGroups)
        self.summary = summary
        super.init()
    }

    public convenience init(optionsGroups: [SWCollaborationOptionsGroup]) {
        self.init(optionsGroups: optionsGroups, summary: "")
    }

    /// Non-failable archive initializer matching the Swift overlay. Missing
    /// keys become empty groups and an empty summary rather than inventing
    /// Darwin defaults.
    public required init(coder: NSCoder) {
        self.storedOptionsGroups = (coder.decodeObject(
            of: [NSArray.self, SWCollaborationOptionsGroup.self, SWCollaborationOptionsPickerGroup.self],
            forKey: "optionsGroups"
        ) as? [SWCollaborationOptionsGroup]) ?? []
        self.summary = (swcDecodeObject(NSString.self, from: coder, key: "summary") as String?) ?? ""
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(storedOptionsGroups as NSArray, forKey: "optionsGroups")
        coder.encode(summary as NSString, forKey: "summary")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        SWCollaborationShareOptions(optionsGroups: storedOptionsGroups, summary: summary)
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SWCollaborationShareOptions else { return false }
        return summary == other.summary && storedOptionsGroups == other.storedOptionsGroups
    }
}
