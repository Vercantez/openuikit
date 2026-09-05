import Foundation
import CoreData
func testEnumOptionSetAndConstantValues() {
    do {
            func eq(_ got: Int, _ expected: Int, _ name: String) throws {
                guard got == expected else {
                    throw ProbeFailure.message("\(name) raw value \(got) != \(expected)")
                }
            }
            try eq(NSManagedObjectValidationError, 1550, "NSManagedObjectValidationError")
            try eq(NSValidationMultipleErrorsError, 1560, "NSValidationMultipleErrorsError")
            try eq(NSValidationMissingMandatoryPropertyError, 1570, "NSValidationMissingMandatoryPropertyError")
            try eq(NSValidationRelationshipLacksMinimumCountError, 1580, "NSValidationRelationshipLacksMinimumCountError")
            try eq(NSValidationRelationshipExceedsMaximumCountError, 1590, "NSValidationRelationshipExceedsMaximumCountError")
            try eq(NSValidationRelationshipDeniedDeleteError, 1600, "NSValidationRelationshipDeniedDeleteError")
            try eq(NSValidationNumberTooLargeError, 1610, "NSValidationNumberTooLargeError")
            try eq(NSValidationNumberTooSmallError, 1620, "NSValidationNumberTooSmallError")
            try eq(NSValidationDateTooLateError, 1630, "NSValidationDateTooLateError")
            try eq(NSValidationDateTooSoonError, 1640, "NSValidationDateTooSoonError")
            try eq(NSValidationInvalidDateError, 1650, "NSValidationInvalidDateError")
            try eq(NSValidationStringTooLongError, 1660, "NSValidationStringTooLongError")
            try eq(NSValidationStringTooShortError, 1670, "NSValidationStringTooShortError")
            try eq(NSValidationStringPatternMatchingError, 1680, "NSValidationStringPatternMatchingError")
            try eq(NSValidationInvalidURIError, 1690, "NSValidationInvalidURIError")
            try eq(NSManagedObjectContextLockingError, 132000, "NSManagedObjectContextLockingError")
            try eq(NSPersistentStoreCoordinatorLockingError, 132010, "NSPersistentStoreCoordinatorLockingError")
            try eq(NSManagedObjectReferentialIntegrityError, 133000, "NSManagedObjectReferentialIntegrityError")
            try eq(NSManagedObjectExternalRelationshipError, 133010, "NSManagedObjectExternalRelationshipError")
            try eq(NSManagedObjectMergeError, 133020, "NSManagedObjectMergeError")
            try eq(NSManagedObjectConstraintMergeError, 133021, "NSManagedObjectConstraintMergeError")
            try eq(NSPersistentStoreInvalidTypeError, 134000, "NSPersistentStoreInvalidTypeError")
            try eq(NSPersistentStoreTypeMismatchError, 134010, "NSPersistentStoreTypeMismatchError")
            try eq(NSPersistentStoreIncompatibleSchemaError, 134020, "NSPersistentStoreIncompatibleSchemaError")
            try eq(NSPersistentStoreSaveError, 134030, "NSPersistentStoreSaveError")
            try eq(NSPersistentStoreIncompleteSaveError, 134040, "NSPersistentStoreIncompleteSaveError")
            try eq(NSPersistentStoreSaveConflictsError, 134050, "NSPersistentStoreSaveConflictsError")
            try eq(NSCoreDataError, 134060, "NSCoreDataError")
            try eq(NSPersistentStoreOperationError, 134070, "NSPersistentStoreOperationError")
            try eq(NSPersistentStoreOpenError, 134080, "NSPersistentStoreOpenError")
            try eq(NSPersistentStoreTimeoutError, 134090, "NSPersistentStoreTimeoutError")
            try eq(NSPersistentStoreUnsupportedRequestTypeError, 134091, "NSPersistentStoreUnsupportedRequestTypeError")
            try eq(NSPersistentStoreIncompatibleVersionHashError, 134100, "NSPersistentStoreIncompatibleVersionHashError")
            try eq(NSMigrationError, 134110, "NSMigrationError")
            try eq(NSMigrationConstraintViolationError, 134111, "NSMigrationConstraintViolationError")
            try eq(NSMigrationCancelledError, 134120, "NSMigrationCancelledError")
            try eq(NSMigrationMissingSourceModelError, 134130, "NSMigrationMissingSourceModelError")
            try eq(NSMigrationMissingMappingModelError, 134140, "NSMigrationMissingMappingModelError")
            try eq(NSMigrationManagerSourceStoreError, 134150, "NSMigrationManagerSourceStoreError")
            try eq(NSMigrationManagerDestinationStoreError, 134160, "NSMigrationManagerDestinationStoreError")
            try eq(NSEntityMigrationPolicyError, 134170, "NSEntityMigrationPolicyError")
            try eq(NSSQLiteError, 134180, "NSSQLiteError")
            try eq(NSInferredMappingModelError, 134190, "NSInferredMappingModelError")
            try eq(NSExternalRecordImportError, 134200, "NSExternalRecordImportError")
            try eq(NSPersistentHistoryTokenExpiredError, 134301, "NSPersistentHistoryTokenExpiredError")
            try eq(NSManagedObjectConstraintValidationError, 134400, "NSManagedObjectConstraintValidationError")
            try eq(NSManagedObjectModelReferenceNotFoundError, 134510, "NSManagedObjectModelReferenceNotFoundError")
            try eq(NSStagedMigrationFrameworkVersionMismatchError, 134520, "NSStagedMigrationFrameworkVersionMismatchError")
            try eq(NSStagedMigrationBackwardMigrationError, 134530, "NSStagedMigrationBackwardMigrationError")

            try eq(CocoaError.Code.managedObjectValidationError.rawValue, 1550, "CocoaError.Code.managedObjectValidationError")
            try eq(CocoaError.managedObjectValidation.rawValue, 1550, "CocoaError.managedObjectValidation")
            try eq(CocoaError.Code.validationMultipleErrorsError.rawValue, 1560, "validationMultipleErrorsError")
            try eq(CocoaError.validationMissingMandatoryProperty.rawValue, 1570, "validationMissingMandatoryProperty")
            try eq(CocoaError.Code.validationRelationshipDeniedDeleteError.rawValue, 1600, "validationRelationshipDeniedDeleteError")
            try eq(CocoaError.Code.managedObjectMergeError.rawValue, 133020, "managedObjectMergeError")
            try eq(CocoaError.Code.persistentStoreOpenError.rawValue, 134080, "persistentStoreOpenError")
            try eq(CocoaError.Code.persistentStoreSaveError.rawValue, 134030, "persistentStoreSaveError")
            try eq(CocoaError.Code.migrationError.rawValue, 134110, "migrationError")
            try eq(CocoaError.Code.sqliteError.rawValue, 134180, "sqliteError")
            try eq(CocoaError.Code.inferredMappingModelError.rawValue, 134190, "inferredMappingModelError")
            try eq(CocoaError.Code.persistentStoreOperationError.rawValue, 134070, "persistentStoreOperationError")
            try eq(CocoaError.Code.validationRelationshipLacksMinimumCountError.rawValue, 1580, "lacksMinimum")
            try eq(CocoaError.Code.validationRelationshipExceedsMaximumCountError.rawValue, 1590, "exceedsMaximum")
            try eq(CocoaError.Code.validationNumberTooLargeError.rawValue, 1610, "numberTooLarge")
            try eq(CocoaError.Code.validationNumberTooSmallError.rawValue, 1620, "numberTooSmall")
            try eq(CocoaError.Code.validationDateTooLateError.rawValue, 1630, "dateTooLate")
            try eq(CocoaError.Code.validationDateTooSoonError.rawValue, 1640, "dateTooSoon")
            try eq(CocoaError.Code.validationInvalidDateError.rawValue, 1650, "invalidDate")
            try eq(CocoaError.Code.validationStringTooLongError.rawValue, 1660, "stringTooLong")
            try eq(CocoaError.Code.validationStringTooShortError.rawValue, 1670, "stringTooShort")
            try eq(CocoaError.Code.validationStringPatternMatchingError.rawValue, 1680, "stringPattern")
            try eq(CocoaError.Code.managedObjectContextLockingError.rawValue, 132000, "contextLocking")
            try eq(CocoaError.Code.persistentStoreCoordinatorLockingError.rawValue, 132010, "coordinatorLocking")
            try eq(CocoaError.Code.managedObjectReferentialIntegrityError.rawValue, 133000, "referentialIntegrity")
            try eq(CocoaError.Code.managedObjectExternalRelationshipError.rawValue, 133010, "externalRelationship")
            try eq(CocoaError.Code.managedObjectConstraintMergeError.rawValue, 133021, "constraintMerge")
            try eq(CocoaError.Code.persistentStoreInvalidTypeError.rawValue, 134000, "invalidType")
            try eq(CocoaError.Code.persistentStoreTypeMismatchError.rawValue, 134010, "typeMismatch")
            try eq(CocoaError.Code.persistentStoreIncompatibleSchemaError.rawValue, 134020, "incompatibleSchema")
            try eq(CocoaError.Code.persistentStoreIncompleteSaveError.rawValue, 134040, "incompleteSave")
            try eq(CocoaError.Code.persistentStoreSaveConflictsError.rawValue, 134050, "saveConflicts")
            try eq(CocoaError.Code.coreDataError.rawValue, 134060, "coreDataError")
            try eq(CocoaError.Code.persistentStoreTimeoutError.rawValue, 134090, "timeout")
            try eq(CocoaError.Code.persistentStoreUnsupportedRequestTypeError.rawValue, 134091, "unsupportedRequest")
            try eq(CocoaError.Code.persistentStoreIncompatibleVersionHashError.rawValue, 134100, "incompatibleHash")
            try eq(CocoaError.Code.migrationCancelledError.rawValue, 134120, "migrationCancelled")
            try eq(CocoaError.Code.migrationMissingSourceModelError.rawValue, 134130, "missingSource")
            try eq(CocoaError.Code.migrationMissingMappingModelError.rawValue, 134140, "missingMapping")
            try eq(CocoaError.Code.migrationManagerSourceStoreError.rawValue, 134150, "migrationSourceStore")
            try eq(CocoaError.Code.migrationManagerDestinationStoreError.rawValue, 134160, "migrationDestStore")
            try eq(CocoaError.Code.entityMigrationPolicyError.rawValue, 134170, "entityMigrationPolicy")
            try eq(CocoaError.Code.externalRecordImportError.rawValue, 134200, "externalRecordImport")

            guard NSSQLiteStoreType == "SQLite",
                  NSBinaryStoreType == "Binary",
                  NSInMemoryStoreType == "InMemory",
                  NSStoreTypeKey == "NSStoreTypeKey",
                  NSInsertedObjectsKey == "NSInsertedObjectsKey",
                  NSUpdatedObjectsKey == "NSUpdatedObjectsKey",
                  NSDeletedObjectsKey == "NSDeletedObjectsKey",
                  NSValidationKeyErrorKey == "NSValidationKeyErrorKey",
                  NSPersistentStoreSaveConflictsErrorKey == "NSPersistentStoreSaveConflictsErrorKey",
                  NSErrorMergePolicy === NSMergePolicy.error,
                  NSRollbackMergePolicy === NSMergePolicy.rollback,
                  NSOverwriteMergePolicy === NSMergePolicy.overwrite,
                  NSMergeByPropertyStoreTrumpMergePolicy === NSMergePolicy.mergeByPropertyStoreTrump,
                  NSMergeByPropertyObjectTrumpMergePolicy === NSMergePolicy.mergeByPropertyObjectTrump else {
                throw ProbeFailure.message("store-type/notification/merge-policy constants mismatch")
            }

            guard NSAttributeType.stringAttributeType.rawValue == 700,
                  NSAttributeType.integer64AttributeType.rawValue == 300,
                  NSAttributeType.booleanAttributeType.rawValue == 800,
                  NSAttributeType.dateAttributeType.rawValue == 900,
                  NSAttributeType.binaryDataAttributeType.rawValue == 1000,
                  NSAttributeType.UUIDAttributeType.rawValue == 1100,
                  NSAttributeType.URIAttributeType.rawValue == 1200,
                  NSAttributeType.transformableAttributeType.rawValue == 1800,
                  NSAttributeType.objectIDAttributeType.rawValue == 2000,
                  NSAttributeType.compositeAttributeType.rawValue == 2100,
                  NSDeleteRule.cascadeDeleteRule.rawValue == 2,
                  NSDeleteRule.denyDeleteRule.rawValue == 3,
                  NSDeleteRule.nullifyDeleteRule.rawValue == 1,
                  NSSnapshotEventType.refresh.rawValue == 1 << 5,
                  NSFetchRequestResultType.managedObjectResultType.rawValue == 0,
                  NSFetchRequestResultType.countResultType.rawValue == 4,
                  NSPersistentStoreRequestType.fetchRequestType.rawValue == 1,
                  NSPersistentStoreRequestType.batchDeleteRequestType.rawValue == 7,
                  NSFetchedResultsChangeType.insert.rawValue == 1,
                  NSCoreDataVersionNumber10_4 == 185.0,
                  NSCoreDataVersionNumber_iPhoneOS_9_0 == 640.0,
                  NSFetchRequestExpressionType.rawValue == 50 else {
                throw ProbeFailure.message("enum/option-set/version catalog mismatch")
            }
            var snapshot: NSSnapshotEventType = [.refresh, .rollback]
            snapshot.formUnion(.mergePolicy)
            guard snapshot.contains(.refresh),
                  snapshot.union(.undoInsertion).contains(.undoInsertion),
                  !snapshot.intersection(.refresh).isEmpty,
                  snapshot.isSuperset(of: .refresh),
                  !snapshot.isDisjoint(with: .rollback) else {
                throw ProbeFailure.message("NSSnapshotEventType OptionSet operations failed")
            }

            _ = [
                NSAddedPersistentStoresKey, NSRemovedPersistentStoresKey, NSUUIDChangedPersistentStoresKey,
                NSInsertedObjectIDsKey, NSUpdatedObjectIDsKey, NSDeletedObjectIDsKey,
                NSRefreshedObjectsKey, NSRefreshedObjectIDsKey, NSInvalidatedObjectsKey,
                NSInvalidatedObjectIDsKey, NSInvalidatedAllObjectsKey,
                NSAffectedObjectsErrorKey, NSAffectedStoresErrorKey, NSDetailedErrorsKey,
                NSValidationObjectErrorKey, NSValidationPredicateErrorKey, NSValidationValueErrorKey,
                NSPersistentStoreURLKey, NSPersistentStoreTimeoutOption, NSReadOnlyPersistentStoreOption,
                NSIgnorePersistentStoreVersioningOption, NSMigratePersistentStoresAutomaticallyOption,
                NSInferMappingModelAutomaticallyOption, NSSQLitePragmasOption, NSSQLiteAnalyzeOption,
                NSSQLiteManualVacuumOption, NSPersistentStoreFileProtectionKey, NSPersistentStoreForceDestroyOption,
                NSPersistentStoreConnectionPoolMaxSizeKey, NSPersistentStoreModelVersionChecksumKey,
                NSPersistentStoreOSCompatibility, NSPersistentStoreDeferredLightweightMigrationOptionKey,
                NSPersistentStoreStagedMigrationManagerOptionKey, NSPersistentStoreRemoteChangeNotificationPostOptionKey,
                NSPersistentHistoryTrackingKey, NSPersistentHistoryTokenKey,
                NSBinaryStoreSecureDecodingClasses, NSBinaryStoreInsecureDecodingCompatibilityOption,
                NSCoreDataCoreSpotlightExporter, NSStoreUUIDKey, NSStoreModelVersionHashesKey,
                NSStoreModelVersionIdentifiersKey, NSSQLiteErrorDomain,
                NSMigrationManagerKey, NSMigrationSourceObjectKey, NSMigrationDestinationObjectKey,
                NSMigrationEntityMappingKey, NSMigrationPropertyMappingKey, NSMigrationEntityPolicyKey,
                NSManagedObjectContextQueryGenerationKey
            ]
            _ = NSPersistentStore.StoreType.sqlite
            _ = NSPersistentStore.StoreType.binary
            _ = NSPersistentStore.StoreType.inMemory
            _ = NSManagedObjectContext.ConcurrencyType.mainQueue
            _ = NSManagedObjectContext.ConcurrencyType.privateQueue
            _ = NSManagedObjectContext.NotificationKey.insertedObjects
            _ = NSManagedObjectContext.NotificationKey.updatedObjects
            _ = NSManagedObjectContext.NotificationKey.deletedObjects
            _ = NSManagedObjectContext.didSaveObjectsNotification
            _ = NSManagedObjectContext.willSaveObjectsNotification
            _ = NSManagedObjectContext.didChangeObjectsNotification
            _ = NSManagedObjectContext.didSaveObjectIDsNotification
            _ = NSManagedObjectContext.didMergeChangesObjectIDsNotification
            _ = NSAttributeDescription.AttributeType.integer16
            _ = NSAttributeDescription.AttributeType.integer32
            _ = NSAttributeDescription.AttributeType.decimal
            _ = NSAttributeDescription.AttributeType.double
            _ = NSAttributeDescription.AttributeType.float
            _ = NSAttributeDescription.AttributeType.undefined
            _ = NSSnapshotEventType.undoInsertion
            _ = NSSnapshotEventType.undoDeletion
            _ = NSSnapshotEventType.undoUpdate
            _ = NSSnapshotEventType.rollback
            _ = NSSnapshotEventType.mergePolicy
            _ = NSPersistentCloudKitContainerSchemaInitializationOptions.dryRun.union(.printSchema)
            _ = NSFetchRequestResultType.managedObjectIDResultType.union(.dictionaryResultType)
            _ = NSPersistentHistoryChangeType.insert
            _ = NSPersistentHistoryResultType.transactionsAndChanges
            _ = NSPersistentCloudKitContainer.EventType.setup
            _ = NSPersistentCloudKitContainerEventResult.ResultType.events
            _ = NSEntityMappingType.transformEntityMappingType
            _ = NSFetchIndexElementType.rTree
            _ = NSBatchDeleteRequestResultType.resultTypeObjectIDs
            _ = NSBatchInsertRequestResultType.objectIDs
            _ = NSBatchUpdateRequestResultType.updatedObjectIDsResultType
            _ = NSManagedObject.contextShouldIgnoreUnmodeledPropertyChanges
            _ = NSManagedObject.fetchRequest()
            _ = NSEntityDescription()
            _ = NSConstraintConflict(
                constraint: ["title"],
                databaseObject: nil,
                databaseSnapshot: nil,
                conflictingObjects: [],
                conflictingSnapshots: []
            )

            try eq(Int(NSAttributeType.undefinedAttributeType.rawValue), 0, "undefinedAttributeType")
            try eq(Int(NSAttributeType.integer16AttributeType.rawValue), 100, "integer16AttributeType")
            try eq(Int(NSAttributeType.integer32AttributeType.rawValue), 200, "integer32AttributeType")
            try eq(Int(NSAttributeType.decimalAttributeType.rawValue), 400, "decimalAttributeType")
            try eq(Int(NSAttributeType.doubleAttributeType.rawValue), 500, "doubleAttributeType")
            try eq(Int(NSAttributeType.floatAttributeType.rawValue), 600, "floatAttributeType")
            try eq(Int(NSDeleteRule.noActionDeleteRule.rawValue), 0, "noActionDeleteRule")
            try eq(Int(NSManagedObjectContextConcurrencyType.confinementConcurrencyType.rawValue), 0, "confinementConcurrencyType")
            try eq(Int(NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType.rawValue), 1, "privateQueueConcurrencyType")
            try eq(Int(NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType.rawValue), 2, "mainQueueConcurrencyType")
            try eq(Int(NSMergePolicyType.errorMergePolicyType.rawValue), 0, "errorMergePolicyType")
            try eq(Int(NSMergePolicyType.rollbackMergePolicyType.rawValue), 1, "rollbackMergePolicyType")
            try eq(Int(NSMergePolicyType.overwriteMergePolicyType.rawValue), 2, "overwriteMergePolicyType")
            try eq(Int(NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType.rawValue), 3, "mergeByPropertyStoreTrumpMergePolicyType")
            try eq(Int(NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType.rawValue), 4, "mergeByPropertyObjectTrumpMergePolicyType")
            try eq(Int(NSPersistentStoreRequestType.saveRequestType.rawValue), 2, "saveRequestType")
            try eq(Int(NSPersistentStoreRequestType.batchUpdateRequestType.rawValue), 6, "batchUpdateRequestType")
            try eq(Int(NSPersistentStoreRequestType.batchInsertRequestType.rawValue), 8, "batchInsertRequestType")
            try eq(Int(NSFetchedResultsChangeType.delete.rawValue), 2, "FRC.delete")
            try eq(Int(NSFetchedResultsChangeType.move.rawValue), 3, "FRC.move")
            try eq(Int(NSFetchedResultsChangeType.update.rawValue), 4, "FRC.update")
            try eq(Int(NSBatchDeleteRequestResultType.resultTypeStatusOnly.rawValue), 0, "resultTypeStatusOnly")
            try eq(Int(NSBatchDeleteRequestResultType.resultTypeCount.rawValue), 2, "resultTypeCount")
            try eq(Int(NSBatchInsertRequestResultType.statusOnly.rawValue), 0, "batchInsert.statusOnly")
            try eq(Int(NSBatchInsertRequestResultType.count.rawValue), 2, "batchInsert.count")
            try eq(Int(NSBatchUpdateRequestResultType.statusOnlyResultType.rawValue), 0, "statusOnlyResultType")
            try eq(Int(NSBatchUpdateRequestResultType.updatedObjectsCountResultType.rawValue), 2, "updatedObjectsCountResultType")
            try eq(Int(NSEntityMappingType.undefinedEntityMappingType.rawValue), 0, "undefinedEntityMappingType")
            try eq(Int(NSEntityMappingType.customEntityMappingType.rawValue), 1, "customEntityMappingType")
            try eq(Int(NSEntityMappingType.addEntityMappingType.rawValue), 2, "addEntityMappingType")
            try eq(Int(NSEntityMappingType.removeEntityMappingType.rawValue), 3, "removeEntityMappingType")
            try eq(Int(NSEntityMappingType.copyEntityMappingType.rawValue), 4, "copyEntityMappingType")
            try eq(Int(NSFetchIndexElementType.binary.rawValue), 0, "fetchIndex.binary")
            try eq(Int(NSPersistentHistoryChangeType.update.rawValue), 1, "history.update")
            try eq(Int(NSPersistentHistoryChangeType.delete.rawValue), 2, "history.delete")
            try eq(NSPersistentHistoryResultType.statusOnly.rawValue, 0, "history.statusOnly")
            try eq(NSPersistentHistoryResultType.objectIDs.rawValue, 1, "history.objectIDs")
            try eq(NSPersistentHistoryResultType.count.rawValue, 2, "history.count")
            try eq(NSPersistentHistoryResultType.transactionsOnly.rawValue, 3, "history.transactionsOnly")
            try eq(NSPersistentHistoryResultType.changesOnly.rawValue, 4, "history.changesOnly")
            try eq(Int(NSPersistentStoreUbiquitousTransitionType.accountAdded.rawValue), 1, "accountAdded")
            try eq(Int(NSPersistentStoreUbiquitousTransitionType.accountRemoved.rawValue), 2, "accountRemoved")
            try eq(Int(NSPersistentStoreUbiquitousTransitionType.contentRemoved.rawValue), 3, "contentRemoved")
            try eq(Int(NSPersistentStoreUbiquitousTransitionType.initialImportCompleted.rawValue), 4, "initialImportCompleted")
            try eq(Int(NSPersistentCloudKitContainer.EventType.`import`.rawValue), 1, "cloud.import")
            try eq(Int(NSPersistentCloudKitContainer.EventType.export.rawValue), 2, "cloud.export")
            try eq(NSPersistentCloudKitContainerEventResult.ResultType.countEvents.rawValue, 1, "countEvents")
            guard NSCoreDataVersionNumber10_4_3 == 185.1,
                  NSCoreDataVersionNumber10_5 == 186.0,
                  NSCoreDataVersionNumber10_5_3 == 186.2,
                  NSCoreDataVersionNumber10_6 == 246.0,
                  NSCoreDataVersionNumber10_6_2 == 246.2,
                  NSCoreDataVersionNumber10_6_3 == 246.3,
                  NSCoreDataVersionNumber10_7 == 358.4,
                  NSCoreDataVersionNumber10_7_2 == 358.12,
                  NSCoreDataVersionNumber10_7_3 == 358.13,
                  NSCoreDataVersionNumber10_7_4 == 358.14,
                  NSCoreDataVersionNumber10_8 == 407.5,
                  NSCoreDataVersionNumber10_8_2 == 407.7,
                  NSCoreDataVersionNumber10_9 == 481.0,
                  NSCoreDataVersionNumber10_9_2 == 481.1,
                  NSCoreDataVersionNumber10_9_3 == 481.3,
                  NSCoreDataVersionNumber10_10 == 526.0,
                  NSCoreDataVersionNumber10_10_2 == 526.1,
                  NSCoreDataVersionNumber10_10_3 == 526.2,
                  NSCoreDataVersionNumber10_11 == 640.0,
                  NSCoreDataVersionNumber10_11_3 == 641.3,
                  NSCoreDataVersionNumber_iPhoneOS_3_0 == 241.0,
                  NSCoreDataVersionNumber_iPhoneOS_3_1 == 248.0,
                  NSCoreDataVersionNumber_iPhoneOS_3_2 == 310.2,
                  NSCoreDataVersionNumber_iPhoneOS_4_0 == 320.5,
                  NSCoreDataVersionNumber_iPhoneOS_4_1 == 320.11,
                  NSCoreDataVersionNumber_iPhoneOS_4_2 == 320.15,
                  NSCoreDataVersionNumber_iPhoneOS_4_3 == 320.17,
                  NSCoreDataVersionNumber_iPhoneOS_5_0 == 386.1,
                  NSCoreDataVersionNumber_iPhoneOS_5_1 == 386.5,
                  NSCoreDataVersionNumber_iPhoneOS_6_0 == 419.0,
                  NSCoreDataVersionNumber_iPhoneOS_6_1 == 420.1,
                  NSCoreDataVersionNumber_iPhoneOS_7_0 == 479.0,
                  NSCoreDataVersionNumber_iPhoneOS_7_1 == 479.3,
                  NSCoreDataVersionNumber_iPhoneOS_8_0 == 519.0,
                  NSCoreDataVersionNumber_iPhoneOS_8_3 == 519.15,
                  NSCoreDataVersionNumber_iPhoneOS_9_2 == 641.2,
                  NSCoreDataVersionNumber_iPhoneOS_9_3 == 641.6 else {
                throw ProbeFailure.message("historical NSCoreDataVersionNumber* catalog mismatch")
            }
            _ = NSAttributeDescription.AttributeType.boolean
            _ = NSAttributeDescription.AttributeType.date
            _ = NSAttributeDescription.AttributeType.binaryData
            _ = NSAttributeDescription.AttributeType.uuid
            _ = NSAttributeDescription.AttributeType.uri
            _ = NSAttributeDescription.AttributeType.transformable
            _ = NSAttributeDescription.AttributeType.objectID
            _ = NSAttributeDescription.AttributeType.composite
            _ = NSAttributeDescription.AttributeType.integer64
            _ = NSManagedObjectContext.ScheduledTaskType.immediate
            _ = NSManagedObjectContext.ScheduledTaskType.enqueued
            _ = NSManagedObjectContext.NotificationKey.refreshedObjects
            _ = NSManagedObjectContext.NotificationKey.invalidatedObjects
            _ = NSManagedObjectContext.NotificationKey.invalidatedAllObjects
            _ = NSManagedObjectContext.NotificationKey.queryGeneration
            _ = NSNotification.Name.NSManagedObjectContextDidSave
            _ = NSNotification.Name.NSManagedObjectContextWillSave
            _ = NSNotification.Name.NSManagedObjectContextObjectsDidChange
            _ = NSNotification.Name.NSManagedObjectContextDidSaveObjectIDs
            _ = NSNotification.Name.NSManagedObjectContextDidMergeChangesObjectIDs
            _ = NSPersistentCloudKitContainer.eventChangedNotification
            _ = NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            _ = NSQueryGenerationToken.current
            _ = NSPersistentHistoryChange.entityDescription
            _ = NSPersistentHistoryTransaction.fetchRequest
            _ = NSNotification.Name.NSCoreDataCoreSpotlightDelegateIndexDidUpdate
            _ = NSNotification.Name.NSPersistentStoreDidImportUbiquitousContentChanges
            _ = NSNotification.Name.NSPersistentStoreRemoteChange
            _ = NSNotification.Name.NSPersistentStoreCoordinatorStoresDidChange
            _ = NSNotification.Name.NSPersistentStoreCoordinatorStoresWillChange
            _ = NSNotification.Name.NSPersistentStoreCoordinatorWillRemoveStore
    } catch {
        fatalError("testEnumOptionSetAndConstantValues failed: \(error)")
    }
}

