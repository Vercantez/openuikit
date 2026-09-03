import Foundation

public protocol CNChangeHistoryEventVisitor: NSObjectProtocol {
    func visit(_ event: CNChangeHistoryAddContactEvent)
    func visit(_ event: CNChangeHistoryDeleteContactEvent)
    func visit(_ event: CNChangeHistoryDropEverythingEvent)
    func visit(_ event: CNChangeHistoryUpdateContactEvent)
    func visit(_ event: CNChangeHistoryAddGroupEvent)
    func visit(_ event: CNChangeHistoryDeleteGroupEvent)
    func visit(_ event: CNChangeHistoryUpdateGroupEvent)
    func visitAddMember(_ event: CNChangeHistoryAddMemberToGroupEvent)
    func visitAddSubgroup(_ event: CNChangeHistoryAddSubgroupToGroupEvent)
    func visitRemoveMember(_ event: CNChangeHistoryRemoveMemberFromGroupEvent)
    func visitRemoveSubgroup(_ event: CNChangeHistoryRemoveSubgroupFromGroupEvent)
}

extension CNChangeHistoryEventVisitor {
    public func visit(_ event: CNChangeHistoryAddGroupEvent) {}
    public func visit(_ event: CNChangeHistoryDeleteGroupEvent) {}
    public func visit(_ event: CNChangeHistoryUpdateGroupEvent) {}
    public func visitAddMember(_ event: CNChangeHistoryAddMemberToGroupEvent) {}
    public func visitAddSubgroup(_ event: CNChangeHistoryAddSubgroupToGroupEvent) {}
    public func visitRemoveMember(_ event: CNChangeHistoryRemoveMemberFromGroupEvent) {}
    public func visitRemoveSubgroup(_ event: CNChangeHistoryRemoveSubgroupFromGroupEvent) {}
}

open class CNChangeHistoryEvent: NSObject, NSCopying, NSSecureCoding {
    public override init() {
        super.init()
    }

    open func accept(_ visitor: any CNChangeHistoryEventVisitor) {}

    public func copy(with zone: NSZone? = nil) -> Any { self }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        super.init()
    }

    public func encode(with coder: NSCoder) {}
}

open class CNChangeHistoryFetchRequest: CNFetchRequest, NSSecureCoding {
    public var startingToken: Data?
    public var additionalContactKeyDescriptors: [any CNKeyDescriptor]?
    public var shouldUnifyResults = true
    public var mutableObjects = false
    public var includeGroupChanges = false
    public var excludedTransactionAuthors: [String]?

    public override init() {
        super.init()
    }

    public static var supportsSecureCoding: Bool { true }

    public required init?(coder: NSCoder) {
        self.startingToken = coder.decodeObject(of: NSData.self, forKey: "startingToken") as Data?
        self.shouldUnifyResults = coder.decodeBool(forKey: "shouldUnifyResults")
        self.mutableObjects = coder.decodeBool(forKey: "mutableObjects")
        self.includeGroupChanges = coder.decodeBool(forKey: "includeGroupChanges")
        self.excludedTransactionAuthors = coder.decodeObject(
            of: [NSArray.self, NSString.self],
            forKey: "excludedTransactionAuthors"
        ) as? [String]
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(startingToken as NSData?, forKey: "startingToken")
        coder.encode(shouldUnifyResults, forKey: "shouldUnifyResults")
        coder.encode(mutableObjects, forKey: "mutableObjects")
        coder.encode(includeGroupChanges, forKey: "includeGroupChanges")
        coder.encode(excludedTransactionAuthors as NSArray?, forKey: "excludedTransactionAuthors")
    }
}

open class CNChangeHistoryAddContactEvent: CNChangeHistoryEvent {
    public let contact: CNContact
    public let containerIdentifier: String?

    public init(contact: CNContact, containerIdentifier: String?) {
        self.contact = contact
        self.containerIdentifier = containerIdentifier
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let contact = coder.decodeObject(of: CNContact.self, forKey: "contact") else { return nil }
        self.contact = contact
        self.containerIdentifier = coder.decodeObject(of: NSString.self, forKey: "containerIdentifier") as String?
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(contact, forKey: "contact")
        coder.encode(containerIdentifier as NSString?, forKey: "containerIdentifier")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visit(self)
    }
}

open class CNChangeHistoryUpdateContactEvent: CNChangeHistoryEvent {
    public let contact: CNContact

    public init(contact: CNContact) {
        self.contact = contact
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let contact = coder.decodeObject(of: CNContact.self, forKey: "contact") else { return nil }
        self.contact = contact
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(contact, forKey: "contact")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visit(self)
    }
}

open class CNChangeHistoryDeleteContactEvent: CNChangeHistoryEvent {
    public let contactIdentifier: String

    public init(contactIdentifier: String) {
        self.contactIdentifier = contactIdentifier
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.contactIdentifier = coder.decodeObject(of: NSString.self, forKey: "contactIdentifier") as String? ?? ""
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(contactIdentifier as NSString, forKey: "contactIdentifier")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visit(self)
    }
}

open class CNChangeHistoryDropEverythingEvent: CNChangeHistoryEvent {
    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visit(self)
    }
}

open class CNChangeHistoryAddGroupEvent: CNChangeHistoryEvent {
    public let group: CNGroup
    public let containerIdentifier: String

    public init(group: CNGroup, containerIdentifier: String) {
        self.group = group
        self.containerIdentifier = containerIdentifier
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let group = coder.decodeObject(of: CNGroup.self, forKey: "group") else { return nil }
        self.group = group
        self.containerIdentifier = coder.decodeObject(of: NSString.self, forKey: "containerIdentifier") as String? ?? ""
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(group, forKey: "group")
        coder.encode(containerIdentifier as NSString, forKey: "containerIdentifier")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visit(self)
    }
}

open class CNChangeHistoryUpdateGroupEvent: CNChangeHistoryEvent {
    public let group: CNGroup

    public init(group: CNGroup) {
        self.group = group
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let group = coder.decodeObject(of: CNGroup.self, forKey: "group") else { return nil }
        self.group = group
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(group, forKey: "group")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visit(self)
    }
}

open class CNChangeHistoryDeleteGroupEvent: CNChangeHistoryEvent {
    public let groupIdentifier: String

    public init(groupIdentifier: String) {
        self.groupIdentifier = groupIdentifier
        super.init()
    }

    public required init?(coder: NSCoder) {
        self.groupIdentifier = coder.decodeObject(of: NSString.self, forKey: "groupIdentifier") as String? ?? ""
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(groupIdentifier as NSString, forKey: "groupIdentifier")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visit(self)
    }
}

open class CNChangeHistoryAddMemberToGroupEvent: CNChangeHistoryEvent {
    public let member: CNContact
    public let group: CNGroup

    public init(member: CNContact, group: CNGroup) {
        self.member = member
        self.group = group
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let member = coder.decodeObject(of: CNContact.self, forKey: "member"),
            let group = coder.decodeObject(of: CNGroup.self, forKey: "group")
        else { return nil }
        self.member = member
        self.group = group
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(member, forKey: "member")
        coder.encode(group, forKey: "group")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visitAddMember(self)
    }
}

open class CNChangeHistoryRemoveMemberFromGroupEvent: CNChangeHistoryEvent {
    public let member: CNContact
    public let group: CNGroup

    public init(member: CNContact, group: CNGroup) {
        self.member = member
        self.group = group
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let member = coder.decodeObject(of: CNContact.self, forKey: "member"),
            let group = coder.decodeObject(of: CNGroup.self, forKey: "group")
        else { return nil }
        self.member = member
        self.group = group
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(member, forKey: "member")
        coder.encode(group, forKey: "group")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visitRemoveMember(self)
    }
}

open class CNChangeHistoryAddSubgroupToGroupEvent: CNChangeHistoryEvent {
    public let subgroup: CNGroup
    public let group: CNGroup

    public init(subgroup: CNGroup, group: CNGroup) {
        self.subgroup = subgroup
        self.group = group
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let subgroup = coder.decodeObject(of: CNGroup.self, forKey: "subgroup"),
            let group = coder.decodeObject(of: CNGroup.self, forKey: "group")
        else { return nil }
        self.subgroup = subgroup
        self.group = group
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(subgroup, forKey: "subgroup")
        coder.encode(group, forKey: "group")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visitAddSubgroup(self)
    }
}

open class CNChangeHistoryRemoveSubgroupFromGroupEvent: CNChangeHistoryEvent {
    public let subgroup: CNGroup
    public let group: CNGroup

    public init(subgroup: CNGroup, group: CNGroup) {
        self.subgroup = subgroup
        self.group = group
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let subgroup = coder.decodeObject(of: CNGroup.self, forKey: "subgroup"),
            let group = coder.decodeObject(of: CNGroup.self, forKey: "group")
        else { return nil }
        self.subgroup = subgroup
        self.group = group
        super.init(coder: coder)
    }

    public override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        coder.encode(subgroup, forKey: "subgroup")
        coder.encode(group, forKey: "group")
    }

    open override func accept(_ visitor: any CNChangeHistoryEventVisitor) {
        visitor.visitRemoveSubgroup(self)
    }
}
