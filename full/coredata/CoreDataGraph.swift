import Foundation

// Relationship tokens, inverse maintenance, delete-rule expansion, and
// merge-policy application for the in-memory store. SQLite is not present
// under full/ or uikit/ (grep sqlite3); NSSQLiteStoreType stays fail-closed.

let _CDRelationshipURIKey = "_cd.rel.uris"
let _CDRelationshipToManyKey = "_cd.rel.toMany"

final class _CDRelationshipToken: NSObject {
    let uris: [String]
    let isToMany: Bool

    init(uris: [String], isToMany: Bool) {
        self.uris = uris
        self.isToMany = isToMany
        super.init()
    }
}

func _CDURIList(from value: Any?) -> [String] {
    if let token = value as? _CDRelationshipToken {
        return token.uris
    }
    if let object = value as? NSManagedObject {
        return [object.objectID.uriRepresentation().absoluteString]
    }
    if let set = value as? Set<NSManagedObject> {
        return set.map { $0.objectID.uriRepresentation().absoluteString }
    }
    if let objects = value as? [NSManagedObject] {
        return objects.map { $0.objectID.uriRepresentation().absoluteString }
    }
    if let strings = value as? [String] {
        return strings
    }
    return []
}

func _CDStoreRelationshipValue(_ value: Any?, isToMany: Bool) -> Any {
    _CDRelationshipToken(uris: _CDURIList(from: value), isToMany: isToMany)
}

func _CDCompareAny(_ lhs: Any?, _ rhs: Any?) -> ComparisonResult {
    let left = _CDUnbox(lhs)
    let right = _CDUnbox(rhs)
    if left == nil && right == nil { return .orderedSame }
    if left == nil { return .orderedAscending }
    if right == nil { return .orderedDescending }
    if let leftString = left as? String, let rightString = right as? String {
        if leftString < rightString { return .orderedAscending }
        if leftString > rightString { return .orderedDescending }
        return .orderedSame
    }
    if let leftNumber = left as? NSNumber, let rightNumber = right as? NSNumber {
        return leftNumber.compare(rightNumber)
    }
    if let leftDate = left as? Date, let rightDate = right as? Date {
        return leftDate.compare(rightDate)
    }
    if let leftObject = left as? NSObject, let rightObject = right as? NSObject {
        if leftObject.isEqual(rightObject) { return .orderedSame }
    }
    let leftDesc = String(describing: left!)
    let rightDesc = String(describing: right!)
    if leftDesc < rightDesc { return .orderedAscending }
    if leftDesc > rightDesc { return .orderedDescending }
    return .orderedSame
}

func _CDSort(
    _ lhs: NSManagedObject,
    _ rhs: NSManagedObject,
    descriptors: [NSSortDescriptor]
) -> Bool {
    for descriptor in descriptors {
        let order: ComparisonResult
        if let key = descriptor.key, !key.isEmpty {
            order = _CDCompareAny(lhs.value(forKey: key), rhs.value(forKey: key))
        } else {
            order = descriptor.compare(lhs, to: rhs)
        }
        if order == .orderedSame {
            continue
        }
        if descriptor.ascending {
            return order == .orderedAscending
        }
        return order == .orderedDescending
    }
    return false
}

func _CDMatchesPredicate(_ predicate: NSPredicate?, object: NSManagedObject) -> Bool {
    guard let predicate else { return true }
    return predicate.evaluate(with: object)
}

func _CDApplyMergePolicy(
    _ policy: Any,
    object: NSManagedObject,
    incoming: [String: Any]
) throws {
    let type: NSMergePolicyType
    if let mergePolicy = policy as? NSMergePolicy {
        type = mergePolicy.mergeType
    } else {
        type = .errorMergePolicyType
    }
    switch type {
    case .errorMergePolicyType:
        if object.hasPersistentChangedValues {
            throw _CDMakeError(
                NSManagedObjectMergeError,
                "error merge policy refused overlapping changes",
                userInfo: [NSValidationObjectErrorKey: object]
            )
        }
        object._applyBoxedSnapshot(incoming, trackChanges: false)
    case .rollbackMergePolicyType:
        object._applyBoxedSnapshot(incoming, trackChanges: false)
    case .overwriteMergePolicyType:
        break
    case .mergeByPropertyStoreTrumpMergePolicyType:
        var merged = object._completeBoxedSnapshot()
        for (key, boxed) in incoming {
            merged[key] = boxed
        }
        for key in object.changedValues().keys {
            merged[key] = _CDBox(object.primitiveValue(forKey: key))
        }
        object._applyBoxedSnapshot(merged, trackChanges: false)
    case .mergeByPropertyObjectTrumpMergePolicyType:
        var merged = incoming
        for (key, boxed) in object.changedValues() {
            merged[key] = boxed
        }
        object._applyBoxedSnapshot(merged, trackChanges: false)
    }
}
