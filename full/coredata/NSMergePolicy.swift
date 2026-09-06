import Foundation

open class NSMergePolicy: NSObject {
    public let mergeType: NSMergePolicyType

    public static var error: NSMergePolicy { _error }
    public static var rollback: NSMergePolicy { _rollback }
    public static var overwrite: NSMergePolicy { _overwrite }
    public static var mergeByPropertyStoreTrump: NSMergePolicy { _storeTrump }
    public static var mergeByPropertyObjectTrump: NSMergePolicy { _objectTrump }

    public init(merge ty: NSMergePolicyType) {
        self.mergeType = ty
        super.init()
    }

    public convenience init(mergeType ty: NSMergePolicyType) {
        self.init(merge: ty)
    }

    public func resolve(mergeConflicts list: [Any]) throws {
        if mergeType == .errorMergePolicyType, !list.isEmpty {
            let conflicts = list.compactMap { $0 as? NSMergeConflict }
            throw _CDMakeError(
                NSManagedObjectMergeError,
                "merge conflicts are not auto-resolved by the error merge policy",
                userInfo: [
                    NSPersistentStoreSaveConflictsErrorKey: conflicts,
                    NSAffectedObjectsErrorKey: conflicts.map(\.sourceObject)
                ]
            )
        }
        for item in list {
            if let conflict = item as? NSMergeConflict {
                let incoming = conflict.persistedSnapshot ?? conflict.cachedSnapshot ?? [:]
                try _CDApplyMergePolicy(self, object: conflict.sourceObject, incoming: incoming)
            }
        }
    }

    public func resolve(constraintConflicts list: [NSConstraintConflict]) throws {
        try resolve(mergeConflicts: list)
    }

    public func resolve(optimisticLockingConflicts list: [NSMergeConflict]) throws {
        try resolve(mergeConflicts: list)
    }
}

private let _error = NSMergePolicy(merge: .errorMergePolicyType)
private let _rollback = NSMergePolicy(merge: .rollbackMergePolicyType)
private let _overwrite = NSMergePolicy(merge: .overwriteMergePolicyType)
private let _storeTrump = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
private let _objectTrump = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)

public var NSErrorMergePolicy: AnyObject { NSMergePolicy.error }
public var NSRollbackMergePolicy: AnyObject { NSMergePolicy.rollback }
public var NSOverwriteMergePolicy: AnyObject { NSMergePolicy.overwrite }
public var NSMergeByPropertyStoreTrumpMergePolicy: AnyObject { NSMergePolicy.mergeByPropertyStoreTrump }
public var NSMergeByPropertyObjectTrumpMergePolicy: AnyObject { NSMergePolicy.mergeByPropertyObjectTrump }

open class NSMergeConflict: NSObject {
    public let sourceObject: NSManagedObject
    public let newVersionNumber: Int
    public let oldVersionNumber: Int
    public let objectSnapshot: [String: Any]?
    public let cachedSnapshot: [String: Any]?
    public let persistedSnapshot: [String: Any]?

    public init(
        source srcObject: NSManagedObject,
        newVersion newvers: Int,
        oldVersion oldvers: Int,
        cachedSnapshot cachesnap: [String: Any]?,
        persistedSnapshot persnap: [String: Any]?
    ) {
        self.sourceObject = srcObject
        self.newVersionNumber = newvers
        self.oldVersionNumber = oldvers
        self.objectSnapshot = srcObject._snapshotValues()
        self.cachedSnapshot = cachesnap
        self.persistedSnapshot = persnap
        super.init()
    }
}

open class NSConstraintConflict: NSObject {
    public let constraint: [String]
    public let constraintValues: [String: Any]
    public let databaseObject: NSManagedObject?
    public let databaseSnapshot: [String: Any]?
    public let conflictingObjects: [NSManagedObject]
    public let conflictingSnapshots: [[AnyHashable: Any]]

    public init(
        constraint contraint: [String],
        database databaseObject: NSManagedObject?,
        databaseSnapshot: [AnyHashable: Any]?,
        conflicting conflictingObjects: [NSManagedObject],
        conflictingSnapshots: [Any]
    ) {
        self.constraint = contraint
        self.databaseObject = databaseObject
        self.databaseSnapshot = databaseSnapshot as? [String: Any]
        self.conflictingObjects = conflictingObjects
        self.conflictingSnapshots = conflictingSnapshots as? [[AnyHashable: Any]] ?? []
        var values: [String: Any] = [:]
        if let object = conflictingObjects.first {
            for key in contraint {
                if let value = object.value(forKey: key) {
                    values[key] = value
                }
            }
        }
        self.constraintValues = values
        super.init()
    }

    public convenience init(
        constraint contraint: [String],
        databaseObject: NSManagedObject?,
        databaseSnapshot: [AnyHashable: Any]?,
        conflictingObjects: [NSManagedObject],
        conflictingSnapshots: [Any]
    ) {
        self.init(
            constraint: contraint,
            database: databaseObject,
            databaseSnapshot: databaseSnapshot,
            conflicting: conflictingObjects,
            conflictingSnapshots: conflictingSnapshots
        )
    }
}
