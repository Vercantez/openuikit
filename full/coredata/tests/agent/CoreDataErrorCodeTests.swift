import Foundation
import CoreData
func testErrorCodes() {
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

            let container = try makeLoadedContainer(makeNoteModel(), name: "ErrorCodes")
            let context = container.viewContext
            _ = NSEntityDescription.insertNewObject(forEntityName: "Note", into: context)
            do {
                try context.save()
                throw ProbeFailure.message("missing required title must fail with NSValidationMissingMandatoryPropertyError")
            } catch is ProbeFailure {
                throw ProbeFailure.message("missing required title must fail with NSValidationMissingMandatoryPropertyError")
            } catch {
                let ns = error as NSError
                guard ns.code == NSValidationMissingMandatoryPropertyError else {
                    throw ProbeFailure.message("expected NSValidationMissingMandatoryPropertyError, got \(ns.code)")
                }
                guard ns.userInfo[NSValidationKeyErrorKey] as? String == "title" else {
                    throw ProbeFailure.message("validation userInfo must name the title key")
                }

                let cocoa = CocoaError(_nsError: ns)
                _ = cocoa.validationKey
                _ = cocoa.validationObject
                _ = cocoa.validationValue
                _ = cocoa.validationPredicate
                _ = cocoa.affectedStores
                _ = cocoa.affectedObjects
                _ = cocoa.persistentStoreSaveConflicts
            }

            let model = makeNoteModel()
            do {
                try NSPersistentCloudKitContainer(name: "ErrCloud", managedObjectModel: model)
                    .initializeCloudKitSchema(options: [])
                throw ProbeFailure.message("CloudKit schema init must fail closed")
            } catch is ProbeFailure {
                throw ProbeFailure.message("CloudKit schema init must fail closed")
            } catch {
                let ns = error as NSError
                guard ns.code == NSPersistentStoreOperationError else {
                    throw ProbeFailure.message("CloudKit fail-closed should use NSPersistentStoreOperationError")
                }
            }

            do {
                _ = try NSMigrationManager(sourceModel: model, destinationModel: model).migrateStore(
                    from: URL(fileURLWithPath: "/tmp/src.sqlite"),
                    sourceType: NSSQLiteStoreType,
                    with: nil,
                    toDestinationURL: URL(fileURLWithPath: "/tmp/dst.sqlite"),
                    destinationType: NSSQLiteStoreType
                )
                throw ProbeFailure.message("migrateStore must fail closed")
            } catch is ProbeFailure {
                throw ProbeFailure.message("migrateStore must fail closed")
            } catch {
                let ns = error as NSError
                guard ns.code == NSMigrationError else {
                    throw ProbeFailure.message("migrateStore should use NSMigrationError")
                }
            }

            _ = [
                CocoaError.Code.managedObjectValidation,
                CocoaError.Code.validationMultipleErrors,
                CocoaError.Code.validationMissingMandatoryProperty,
                CocoaError.Code.validationRelationshipLacksMinimumCount,
                CocoaError.Code.validationRelationshipExceedsMaximumCount,
                CocoaError.Code.validationRelationshipDeniedDelete,
                CocoaError.Code.validationNumberTooLarge,
                CocoaError.Code.validationNumberTooSmall,
                CocoaError.Code.validationDateTooLate,
                CocoaError.Code.validationDateTooSoon,
                CocoaError.Code.validationInvalidDate,
                CocoaError.Code.validationStringTooLong,
                CocoaError.Code.validationStringTooShort,
                CocoaError.Code.validationStringPatternMatching,
                CocoaError.Code.managedObjectContextLocking,
                CocoaError.Code.persistentStoreCoordinatorLocking,
                CocoaError.Code.managedObjectReferentialIntegrity,
                CocoaError.Code.managedObjectExternalRelationship,
                CocoaError.Code.managedObjectMerge,
                CocoaError.Code.managedObjectConstraintMerge,
                CocoaError.Code.persistentStoreInvalidType,
                CocoaError.Code.persistentStoreTypeMismatch,
                CocoaError.Code.persistentStoreIncompatibleSchema,
                CocoaError.Code.persistentStoreSave,
                CocoaError.Code.persistentStoreIncompleteSave,
                CocoaError.Code.persistentStoreSaveConflicts,
                CocoaError.Code.coreData,
                CocoaError.Code.persistentStoreOperation,
                CocoaError.Code.persistentStoreOpen,
                CocoaError.Code.persistentStoreTimeout,
                CocoaError.Code.persistentStoreUnsupportedRequestType,
                CocoaError.Code.persistentStoreIncompatibleVersionHash,
                CocoaError.Code.migration,
                CocoaError.Code.migrationCancelled,
                CocoaError.Code.migrationMissingSourceModel,
                CocoaError.Code.migrationMissingMappingModel,
                CocoaError.Code.migrationManagerSourceStore,
                CocoaError.Code.migrationManagerDestinationStore,
                CocoaError.Code.entityMigrationPolicy,
                CocoaError.Code.sqlite,
                CocoaError.Code.inferredMappingModel,
                CocoaError.Code.externalRecordImport,
                CocoaError.managedObjectValidationError,
                CocoaError.managedObjectValidation,
                CocoaError.validationMultipleErrorsError,
                CocoaError.validationMultipleErrors,
                CocoaError.validationMissingMandatoryPropertyError,
                CocoaError.validationMissingMandatoryProperty,
                CocoaError.validationRelationshipLacksMinimumCountError,
                CocoaError.validationRelationshipLacksMinimumCount,
                CocoaError.validationRelationshipExceedsMaximumCountError,
                CocoaError.validationRelationshipExceedsMaximumCount,
                CocoaError.validationRelationshipDeniedDeleteError,
                CocoaError.validationRelationshipDeniedDelete,
                CocoaError.validationNumberTooLargeError,
                CocoaError.validationNumberTooLarge,
                CocoaError.validationNumberTooSmallError,
                CocoaError.validationNumberTooSmall,
                CocoaError.validationDateTooLateError,
                CocoaError.validationDateTooLate,
                CocoaError.validationDateTooSoonError,
                CocoaError.validationDateTooSoon,
                CocoaError.validationInvalidDateError,
                CocoaError.validationInvalidDate,
                CocoaError.validationStringTooLongError,
                CocoaError.validationStringTooLong,
                CocoaError.validationStringTooShortError,
                CocoaError.validationStringTooShort,
                CocoaError.validationStringPatternMatchingError,
                CocoaError.validationStringPatternMatching,
                CocoaError.managedObjectContextLockingError,
                CocoaError.managedObjectContextLocking,
                CocoaError.persistentStoreCoordinatorLockingError,
                CocoaError.persistentStoreCoordinatorLocking,
                CocoaError.managedObjectReferentialIntegrityError,
                CocoaError.managedObjectReferentialIntegrity,
                CocoaError.managedObjectExternalRelationshipError,
                CocoaError.managedObjectExternalRelationship,
                CocoaError.managedObjectMergeError,
                CocoaError.managedObjectMerge,
                CocoaError.managedObjectConstraintMergeError,
                CocoaError.managedObjectConstraintMerge,
                CocoaError.persistentStoreInvalidTypeError,
                CocoaError.persistentStoreInvalidType,
                CocoaError.persistentStoreTypeMismatchError,
                CocoaError.persistentStoreTypeMismatch,
                CocoaError.persistentStoreIncompatibleSchemaError,
                CocoaError.persistentStoreIncompatibleSchema,
                CocoaError.persistentStoreSaveError,
                CocoaError.persistentStoreSave,
                CocoaError.persistentStoreIncompleteSaveError,
                CocoaError.persistentStoreIncompleteSave,
                CocoaError.persistentStoreSaveConflictsError,
                CocoaError.persistentStoreSaveConflicts,
                CocoaError.coreDataError,
                CocoaError.coreData,
                CocoaError.persistentStoreOperationError,
                CocoaError.persistentStoreOperation,
                CocoaError.persistentStoreOpenError,
                CocoaError.persistentStoreOpen,
                CocoaError.persistentStoreTimeoutError,
                CocoaError.persistentStoreTimeout,
                CocoaError.persistentStoreUnsupportedRequestTypeError,
                CocoaError.persistentStoreUnsupportedRequestType,
                CocoaError.persistentStoreIncompatibleVersionHashError,
                CocoaError.persistentStoreIncompatibleVersionHash,
                CocoaError.migrationError,
                CocoaError.migration,
                CocoaError.migrationCancelledError,
                CocoaError.migrationCancelled,
                CocoaError.migrationMissingSourceModelError,
                CocoaError.migrationMissingSourceModel,
                CocoaError.migrationMissingMappingModelError,
                CocoaError.migrationMissingMappingModel,
                CocoaError.migrationManagerSourceStoreError,
                CocoaError.migrationManagerSourceStore,
                CocoaError.migrationManagerDestinationStoreError,
                CocoaError.migrationManagerDestinationStore,
                CocoaError.entityMigrationPolicyError,
                CocoaError.entityMigrationPolicy,
                CocoaError.sqliteError,
                CocoaError.sqlite,
                CocoaError.inferredMappingModelError,
                CocoaError.inferredMappingModel,
                CocoaError.externalRecordImportError,
                CocoaError.externalRecordImport,
                CocoaError.Code.validationMissingMandatoryPropertyError,
                CocoaError.Code.sqliteError,
                CocoaError.Code.coreDataError,
                CocoaError.Code.migrationError,
            ]
    } catch {
        fatalError("testErrorCodes failed: \(error)")
    }
}

