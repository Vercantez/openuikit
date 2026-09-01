// CoreData Linux starting point.
//
// This module implements an in-memory object graph, model/metadata types,
// fetch/save, and NSPersistentContainer wiring. Durable Apple SQLite/binary
// store formats, CloudKit, ubiquity, Spotlight, momd decoding, and string
// NSPredicate/KVC sort descriptors are fail-closed: they compile where the
// Linux Foundation types exist, and otherwise remain deferred.

import Foundation

// MARK: - Store type names

public let NSSQLiteStoreType: String = "SQLite"
public let NSBinaryStoreType: String = "Binary"
public let NSInMemoryStoreType: String = "InMemory"

public let NSSQLiteErrorDomain: String = "NSSQLiteErrorDomain"

public let NSStoreTypeKey: String = "NSStoreTypeKey"
public let NSStoreUUIDKey: String = "NSStoreUUIDKey"
public let NSStoreModelVersionHashesKey: String = "NSStoreModelVersionHashesKey"
public let NSStoreModelVersionIdentifiersKey: String = "NSStoreModelVersionIdentifiersKey"
public let NSPersistentStoreURLKey: String = "NSPersistentStoreURLKey"
public let NSPersistentStoreTimeoutOption: String = "NSPersistentStoreTimeoutOption"
public let NSReadOnlyPersistentStoreOption: String = "NSReadOnlyPersistentStoreOption"
public let NSIgnorePersistentStoreVersioningOption: String = "NSIgnorePersistentStoreVersioningOption"
public let NSMigratePersistentStoresAutomaticallyOption: String = "NSMigratePersistentStoresAutomaticallyOption"
public let NSInferMappingModelAutomaticallyOption: String = "NSInferMappingModelAutomaticallyOption"
public let NSSQLitePragmasOption: String = "NSSQLitePragmasOption"
public let NSSQLiteAnalyzeOption: String = "NSSQLiteAnalyzeOption"
public let NSSQLiteManualVacuumOption: String = "NSSQLiteManualVacuumOption"
public let NSPersistentStoreFileProtectionKey: String = "NSPersistentStoreFileProtectionKey"
public let NSPersistentStoreForceDestroyOption: String = "NSPersistentStoreForceDestroyOption"
public let NSPersistentStoreConnectionPoolMaxSizeKey: String = "NSPersistentStoreConnectionPoolMaxSizeKey"
public let NSPersistentStoreModelVersionChecksumKey: String = "NSPersistentStoreModelVersionChecksumKey"
public let NSPersistentStoreOSCompatibility: String = "NSPersistentStoreOSCompatibility"
public let NSPersistentStoreDeferredLightweightMigrationOptionKey: String = "NSPersistentStoreDeferredLightweightMigrationOptionKey"
public let NSPersistentStoreStagedMigrationManagerOptionKey: String = "NSPersistentStoreStagedMigrationManagerOptionKey"
public let NSPersistentStoreRemoteChangeNotificationPostOptionKey: String = "NSPersistentStoreRemoteChangeNotificationPostOptionKey"
public let NSPersistentHistoryTrackingKey: String = "NSPersistentHistoryTrackingKey"
public let NSPersistentHistoryTokenKey: String = "NSPersistentHistoryTokenKey"
public let NSBinaryStoreSecureDecodingClasses: String = "NSBinaryStoreSecureDecodingClasses"
public let NSBinaryStoreInsecureDecodingCompatibilityOption: String = "NSBinaryStoreInsecureDecodingCompatibilityOption"
public let NSCoreDataCoreSpotlightExporter: String = "NSCoreDataCoreSpotlightExporter"

public let NSPersistentStoreRebuildFromUbiquitousContentOption: String = "NSPersistentStoreRebuildFromUbiquitousContentOption"
public let NSPersistentStoreRemoveUbiquitousMetadataOption: String = "NSPersistentStoreRemoveUbiquitousMetadataOption"
public let NSPersistentStoreUbiquitousContentNameKey: String = "NSPersistentStoreUbiquitousContentNameKey"
public let NSPersistentStoreUbiquitousContentURLKey: String = "NSPersistentStoreUbiquitousContentURLKey"
public let NSPersistentStoreUbiquitousContainerIdentifierKey: String = "NSPersistentStoreUbiquitousContainerIdentifierKey"
public let NSPersistentStoreUbiquitousPeerTokenOption: String = "NSPersistentStoreUbiquitousPeerTokenOption"
public let NSPersistentStoreUbiquitousTransitionTypeKey: String = "NSPersistentStoreUbiquitousTransitionTypeKey"

public let NSAddedPersistentStoresKey: String = "NSAddedPersistentStoresKey"
public let NSRemovedPersistentStoresKey: String = "NSRemovedPersistentStoresKey"
public let NSUUIDChangedPersistentStoresKey: String = "NSUUIDChangedPersistentStoresKey"
public let NSInsertedObjectsKey: String = "NSInsertedObjectsKey"
public let NSUpdatedObjectsKey: String = "NSUpdatedObjectsKey"
public let NSDeletedObjectsKey: String = "NSDeletedObjectsKey"
public let NSRefreshedObjectsKey: String = "NSRefreshedObjectsKey"
public let NSInvalidatedObjectsKey: String = "NSInvalidatedObjectsKey"
public let NSInvalidatedAllObjectsKey: String = "NSInvalidatedAllObjectsKey"
public let NSInsertedObjectIDsKey: String = "NSInsertedObjectIDsKey"
public let NSUpdatedObjectIDsKey: String = "NSUpdatedObjectIDsKey"
public let NSDeletedObjectIDsKey: String = "NSDeletedObjectIDsKey"
public let NSRefreshedObjectIDsKey: String = "NSRefreshedObjectIDsKey"
public let NSInvalidatedObjectIDsKey: String = "NSInvalidatedObjectIDsKey"
public let NSManagedObjectContextQueryGenerationKey: String = "NSManagedObjectContextQueryGenerationKey"

public let NSAffectedObjectsErrorKey: String = "NSAffectedObjectsErrorKey"
public let NSAffectedStoresErrorKey: String = "NSAffectedStoresErrorKey"
public let NSDetailedErrorsKey: String = "NSDetailedErrorsKey"
public let NSPersistentStoreSaveConflictsErrorKey: String = "NSPersistentStoreSaveConflictsErrorKey"
public let NSValidationObjectErrorKey: String = "NSValidationObjectErrorKey"
public let NSValidationKeyErrorKey: String = "NSValidationKeyErrorKey"
public let NSValidationPredicateErrorKey: String = "NSValidationPredicateErrorKey"
public let NSValidationValueErrorKey: String = "NSValidationValueErrorKey"

public let NSMigrationManagerKey: String = "NSMigrationManagerKey"
public let NSMigrationSourceObjectKey: String = "NSMigrationSourceObjectKey"
public let NSMigrationDestinationObjectKey: String = "NSMigrationDestinationObjectKey"
public let NSMigrationEntityMappingKey: String = "NSMigrationEntityMappingKey"
public let NSMigrationPropertyMappingKey: String = "NSMigrationPropertyMappingKey"
public let NSMigrationEntityPolicyKey: String = "NSMigrationEntityPolicyKey"

// MARK: - Public error codes (CoreDataErrors.h)

public var NSManagedObjectValidationError: Int { 1550 }
public var NSValidationMultipleErrorsError: Int { 1560 }
public var NSValidationMissingMandatoryPropertyError: Int { 1570 }
public var NSValidationRelationshipLacksMinimumCountError: Int { 1580 }
public var NSValidationRelationshipExceedsMaximumCountError: Int { 1590 }
public var NSValidationRelationshipDeniedDeleteError: Int { 1600 }
public var NSValidationNumberTooLargeError: Int { 1610 }
public var NSValidationNumberTooSmallError: Int { 1620 }
public var NSValidationDateTooLateError: Int { 1630 }
public var NSValidationDateTooSoonError: Int { 1640 }
public var NSValidationInvalidDateError: Int { 1650 }
public var NSValidationStringTooLongError: Int { 1660 }
public var NSValidationStringTooShortError: Int { 1670 }
public var NSValidationStringPatternMatchingError: Int { 1680 }
public var NSValidationInvalidURIError: Int { 1690 }
public var NSManagedObjectContextLockingError: Int { 132000 }
public var NSPersistentStoreCoordinatorLockingError: Int { 132010 }
public var NSManagedObjectReferentialIntegrityError: Int { 133000 }
public var NSManagedObjectExternalRelationshipError: Int { 133010 }
public var NSManagedObjectMergeError: Int { 133020 }
public var NSManagedObjectConstraintMergeError: Int { 133021 }
public var NSPersistentStoreInvalidTypeError: Int { 134000 }
public var NSPersistentStoreTypeMismatchError: Int { 134010 }
public var NSPersistentStoreIncompatibleSchemaError: Int { 134020 }
public var NSPersistentStoreSaveError: Int { 134030 }
public var NSPersistentStoreIncompleteSaveError: Int { 134040 }
public var NSPersistentStoreSaveConflictsError: Int { 134050 }
public var NSCoreDataError: Int { 134060 }
public var NSPersistentStoreOperationError: Int { 134070 }
public var NSPersistentStoreOpenError: Int { 134080 }
public var NSPersistentStoreTimeoutError: Int { 134090 }
public var NSPersistentStoreUnsupportedRequestTypeError: Int { 134091 }
public var NSPersistentStoreIncompatibleVersionHashError: Int { 134100 }
public var NSMigrationError: Int { 134110 }
public var NSMigrationConstraintViolationError: Int { 134111 }
public var NSMigrationCancelledError: Int { 134120 }
public var NSMigrationMissingSourceModelError: Int { 134130 }
public var NSMigrationMissingMappingModelError: Int { 134140 }
public var NSMigrationManagerSourceStoreError: Int { 134150 }
public var NSMigrationManagerDestinationStoreError: Int { 134160 }
public var NSEntityMigrationPolicyError: Int { 134170 }
public var NSSQLiteError: Int { 134180 }
public var NSInferredMappingModelError: Int { 134190 }
public var NSExternalRecordImportError: Int { 134200 }
public var NSPersistentHistoryTokenExpiredError: Int { 134301 }
public var NSManagedObjectConstraintValidationError: Int { 134400 }
public var NSManagedObjectModelReferenceNotFoundError: Int { 134510 }
public var NSStagedMigrationFrameworkVersionMismatchError: Int { 134520 }
public var NSStagedMigrationBackwardMigrationError: Int { 134530 }

extension CocoaError.Code {
    public static var managedObjectValidationError: CocoaError.Code { CocoaError.Code(rawValue: NSManagedObjectValidationError) }
    public static var managedObjectValidation: CocoaError.Code { .managedObjectValidationError }
    public static var validationMultipleErrorsError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationMultipleErrorsError) }
    public static var validationMultipleErrors: CocoaError.Code { .validationMultipleErrorsError }
    public static var validationMissingMandatoryPropertyError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationMissingMandatoryPropertyError) }
    public static var validationMissingMandatoryProperty: CocoaError.Code { .validationMissingMandatoryPropertyError }
    public static var validationRelationshipLacksMinimumCountError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationRelationshipLacksMinimumCountError) }
    public static var validationRelationshipLacksMinimumCount: CocoaError.Code { .validationRelationshipLacksMinimumCountError }
    public static var validationRelationshipExceedsMaximumCountError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationRelationshipExceedsMaximumCountError) }
    public static var validationRelationshipExceedsMaximumCount: CocoaError.Code { .validationRelationshipExceedsMaximumCountError }
    public static var validationRelationshipDeniedDeleteError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationRelationshipDeniedDeleteError) }
    public static var validationRelationshipDeniedDelete: CocoaError.Code { .validationRelationshipDeniedDeleteError }
    public static var validationNumberTooLargeError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationNumberTooLargeError) }
    public static var validationNumberTooLarge: CocoaError.Code { .validationNumberTooLargeError }
    public static var validationNumberTooSmallError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationNumberTooSmallError) }
    public static var validationNumberTooSmall: CocoaError.Code { .validationNumberTooSmallError }
    public static var validationDateTooLateError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationDateTooLateError) }
    public static var validationDateTooLate: CocoaError.Code { .validationDateTooLateError }
    public static var validationDateTooSoonError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationDateTooSoonError) }
    public static var validationDateTooSoon: CocoaError.Code { .validationDateTooSoonError }
    public static var validationInvalidDateError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationInvalidDateError) }
    public static var validationInvalidDate: CocoaError.Code { .validationInvalidDateError }
    public static var validationStringTooLongError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationStringTooLongError) }
    public static var validationStringTooLong: CocoaError.Code { .validationStringTooLongError }
    public static var validationStringTooShortError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationStringTooShortError) }
    public static var validationStringTooShort: CocoaError.Code { .validationStringTooShortError }
    public static var validationStringPatternMatchingError: CocoaError.Code { CocoaError.Code(rawValue: NSValidationStringPatternMatchingError) }
    public static var validationStringPatternMatching: CocoaError.Code { .validationStringPatternMatchingError }
    public static var managedObjectContextLockingError: CocoaError.Code { CocoaError.Code(rawValue: NSManagedObjectContextLockingError) }
    public static var managedObjectContextLocking: CocoaError.Code { .managedObjectContextLockingError }
    public static var persistentStoreCoordinatorLockingError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreCoordinatorLockingError) }
    public static var persistentStoreCoordinatorLocking: CocoaError.Code { .persistentStoreCoordinatorLockingError }
    public static var managedObjectReferentialIntegrityError: CocoaError.Code { CocoaError.Code(rawValue: NSManagedObjectReferentialIntegrityError) }
    public static var managedObjectReferentialIntegrity: CocoaError.Code { .managedObjectReferentialIntegrityError }
    public static var managedObjectExternalRelationshipError: CocoaError.Code { CocoaError.Code(rawValue: NSManagedObjectExternalRelationshipError) }
    public static var managedObjectExternalRelationship: CocoaError.Code { .managedObjectExternalRelationshipError }
    public static var managedObjectMergeError: CocoaError.Code { CocoaError.Code(rawValue: NSManagedObjectMergeError) }
    public static var managedObjectMerge: CocoaError.Code { .managedObjectMergeError }
    public static var managedObjectConstraintMergeError: CocoaError.Code { CocoaError.Code(rawValue: NSManagedObjectConstraintMergeError) }
    public static var managedObjectConstraintMerge: CocoaError.Code { .managedObjectConstraintMergeError }
    public static var persistentStoreInvalidTypeError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreInvalidTypeError) }
    public static var persistentStoreInvalidType: CocoaError.Code { .persistentStoreInvalidTypeError }
    public static var persistentStoreTypeMismatchError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreTypeMismatchError) }
    public static var persistentStoreTypeMismatch: CocoaError.Code { .persistentStoreTypeMismatchError }
    public static var persistentStoreIncompatibleSchemaError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreIncompatibleSchemaError) }
    public static var persistentStoreIncompatibleSchema: CocoaError.Code { .persistentStoreIncompatibleSchemaError }
    public static var persistentStoreSaveError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreSaveError) }
    public static var persistentStoreSave: CocoaError.Code { .persistentStoreSaveError }
    public static var persistentStoreIncompleteSaveError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreIncompleteSaveError) }
    public static var persistentStoreIncompleteSave: CocoaError.Code { .persistentStoreIncompleteSaveError }
    public static var persistentStoreSaveConflictsError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreSaveConflictsError) }
    public static var persistentStoreSaveConflicts: CocoaError.Code { .persistentStoreSaveConflictsError }
    public static var coreDataError: CocoaError.Code { CocoaError.Code(rawValue: NSCoreDataError) }
    public static var coreData: CocoaError.Code { .coreDataError }
    public static var persistentStoreOperationError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreOperationError) }
    public static var persistentStoreOperation: CocoaError.Code { .persistentStoreOperationError }
    public static var persistentStoreOpenError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreOpenError) }
    public static var persistentStoreOpen: CocoaError.Code { .persistentStoreOpenError }
    public static var persistentStoreTimeoutError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreTimeoutError) }
    public static var persistentStoreTimeout: CocoaError.Code { .persistentStoreTimeoutError }
    public static var persistentStoreUnsupportedRequestTypeError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreUnsupportedRequestTypeError) }
    public static var persistentStoreUnsupportedRequestType: CocoaError.Code { .persistentStoreUnsupportedRequestTypeError }
    public static var persistentStoreIncompatibleVersionHashError: CocoaError.Code { CocoaError.Code(rawValue: NSPersistentStoreIncompatibleVersionHashError) }
    public static var persistentStoreIncompatibleVersionHash: CocoaError.Code { .persistentStoreIncompatibleVersionHashError }
    public static var migrationError: CocoaError.Code { CocoaError.Code(rawValue: NSMigrationError) }
    public static var migration: CocoaError.Code { .migrationError }
    public static var migrationCancelledError: CocoaError.Code { CocoaError.Code(rawValue: NSMigrationCancelledError) }
    public static var migrationCancelled: CocoaError.Code { .migrationCancelledError }
    public static var migrationMissingSourceModelError: CocoaError.Code { CocoaError.Code(rawValue: NSMigrationMissingSourceModelError) }
    public static var migrationMissingSourceModel: CocoaError.Code { .migrationMissingSourceModelError }
    public static var migrationMissingMappingModelError: CocoaError.Code { CocoaError.Code(rawValue: NSMigrationMissingMappingModelError) }
    public static var migrationMissingMappingModel: CocoaError.Code { .migrationMissingMappingModelError }
    public static var migrationManagerSourceStoreError: CocoaError.Code { CocoaError.Code(rawValue: NSMigrationManagerSourceStoreError) }
    public static var migrationManagerSourceStore: CocoaError.Code { .migrationManagerSourceStoreError }
    public static var migrationManagerDestinationStoreError: CocoaError.Code { CocoaError.Code(rawValue: NSMigrationManagerDestinationStoreError) }
    public static var migrationManagerDestinationStore: CocoaError.Code { .migrationManagerDestinationStoreError }
    public static var entityMigrationPolicyError: CocoaError.Code { CocoaError.Code(rawValue: NSEntityMigrationPolicyError) }
    public static var entityMigrationPolicy: CocoaError.Code { .entityMigrationPolicyError }
    public static var sqliteError: CocoaError.Code { CocoaError.Code(rawValue: NSSQLiteError) }
    public static var sqlite: CocoaError.Code { .sqliteError }
    public static var inferredMappingModelError: CocoaError.Code { CocoaError.Code(rawValue: NSInferredMappingModelError) }
    public static var inferredMappingModel: CocoaError.Code { .inferredMappingModelError }
    public static var externalRecordImportError: CocoaError.Code { CocoaError.Code(rawValue: NSExternalRecordImportError) }
    public static var externalRecordImport: CocoaError.Code { .externalRecordImportError }
}

extension CocoaError {
    public static var managedObjectValidationError: CocoaError.Code { .managedObjectValidationError }
    public static var managedObjectValidation: CocoaError.Code { .managedObjectValidation }
    public static var validationMultipleErrorsError: CocoaError.Code { .validationMultipleErrorsError }
    public static var validationMultipleErrors: CocoaError.Code { .validationMultipleErrors }
    public static var validationMissingMandatoryPropertyError: CocoaError.Code { .validationMissingMandatoryPropertyError }
    public static var validationMissingMandatoryProperty: CocoaError.Code { .validationMissingMandatoryProperty }
    public static var validationRelationshipLacksMinimumCountError: CocoaError.Code { .validationRelationshipLacksMinimumCountError }
    public static var validationRelationshipLacksMinimumCount: CocoaError.Code { .validationRelationshipLacksMinimumCount }
    public static var validationRelationshipExceedsMaximumCountError: CocoaError.Code { .validationRelationshipExceedsMaximumCountError }
    public static var validationRelationshipExceedsMaximumCount: CocoaError.Code { .validationRelationshipExceedsMaximumCount }
    public static var validationRelationshipDeniedDeleteError: CocoaError.Code { .validationRelationshipDeniedDeleteError }
    public static var validationRelationshipDeniedDelete: CocoaError.Code { .validationRelationshipDeniedDelete }
    public static var validationNumberTooLargeError: CocoaError.Code { .validationNumberTooLargeError }
    public static var validationNumberTooLarge: CocoaError.Code { .validationNumberTooLarge }
    public static var validationNumberTooSmallError: CocoaError.Code { .validationNumberTooSmallError }
    public static var validationNumberTooSmall: CocoaError.Code { .validationNumberTooSmall }
    public static var validationDateTooLateError: CocoaError.Code { .validationDateTooLateError }
    public static var validationDateTooLate: CocoaError.Code { .validationDateTooLate }
    public static var validationDateTooSoonError: CocoaError.Code { .validationDateTooSoonError }
    public static var validationDateTooSoon: CocoaError.Code { .validationDateTooSoon }
    public static var validationInvalidDateError: CocoaError.Code { .validationInvalidDateError }
    public static var validationInvalidDate: CocoaError.Code { .validationInvalidDate }
    public static var validationStringTooLongError: CocoaError.Code { .validationStringTooLongError }
    public static var validationStringTooLong: CocoaError.Code { .validationStringTooLong }
    public static var validationStringTooShortError: CocoaError.Code { .validationStringTooShortError }
    public static var validationStringTooShort: CocoaError.Code { .validationStringTooShort }
    public static var validationStringPatternMatchingError: CocoaError.Code { .validationStringPatternMatchingError }
    public static var validationStringPatternMatching: CocoaError.Code { .validationStringPatternMatching }
    public static var managedObjectContextLockingError: CocoaError.Code { .managedObjectContextLockingError }
    public static var managedObjectContextLocking: CocoaError.Code { .managedObjectContextLocking }
    public static var persistentStoreCoordinatorLockingError: CocoaError.Code { .persistentStoreCoordinatorLockingError }
    public static var persistentStoreCoordinatorLocking: CocoaError.Code { .persistentStoreCoordinatorLocking }
    public static var managedObjectReferentialIntegrityError: CocoaError.Code { .managedObjectReferentialIntegrityError }
    public static var managedObjectReferentialIntegrity: CocoaError.Code { .managedObjectReferentialIntegrity }
    public static var managedObjectExternalRelationshipError: CocoaError.Code { .managedObjectExternalRelationshipError }
    public static var managedObjectExternalRelationship: CocoaError.Code { .managedObjectExternalRelationship }
    public static var managedObjectMergeError: CocoaError.Code { .managedObjectMergeError }
    public static var managedObjectMerge: CocoaError.Code { .managedObjectMerge }
    public static var managedObjectConstraintMergeError: CocoaError.Code { .managedObjectConstraintMergeError }
    public static var managedObjectConstraintMerge: CocoaError.Code { .managedObjectConstraintMerge }
    public static var persistentStoreInvalidTypeError: CocoaError.Code { .persistentStoreInvalidTypeError }
    public static var persistentStoreInvalidType: CocoaError.Code { .persistentStoreInvalidType }
    public static var persistentStoreTypeMismatchError: CocoaError.Code { .persistentStoreTypeMismatchError }
    public static var persistentStoreTypeMismatch: CocoaError.Code { .persistentStoreTypeMismatch }
    public static var persistentStoreIncompatibleSchemaError: CocoaError.Code { .persistentStoreIncompatibleSchemaError }
    public static var persistentStoreIncompatibleSchema: CocoaError.Code { .persistentStoreIncompatibleSchema }
    public static var persistentStoreSaveError: CocoaError.Code { .persistentStoreSaveError }
    public static var persistentStoreSave: CocoaError.Code { .persistentStoreSave }
    public static var persistentStoreIncompleteSaveError: CocoaError.Code { .persistentStoreIncompleteSaveError }
    public static var persistentStoreIncompleteSave: CocoaError.Code { .persistentStoreIncompleteSave }
    public static var persistentStoreSaveConflictsError: CocoaError.Code { .persistentStoreSaveConflictsError }
    public static var persistentStoreSaveConflicts: CocoaError.Code { .persistentStoreSaveConflicts }
    public static var coreDataError: CocoaError.Code { .coreDataError }
    public static var coreData: CocoaError.Code { .coreData }
    public static var persistentStoreOperationError: CocoaError.Code { .persistentStoreOperationError }
    public static var persistentStoreOperation: CocoaError.Code { .persistentStoreOperation }
    public static var persistentStoreOpenError: CocoaError.Code { .persistentStoreOpenError }
    public static var persistentStoreOpen: CocoaError.Code { .persistentStoreOpen }
    public static var persistentStoreTimeoutError: CocoaError.Code { .persistentStoreTimeoutError }
    public static var persistentStoreTimeout: CocoaError.Code { .persistentStoreTimeout }
    public static var persistentStoreUnsupportedRequestTypeError: CocoaError.Code { .persistentStoreUnsupportedRequestTypeError }
    public static var persistentStoreUnsupportedRequestType: CocoaError.Code { .persistentStoreUnsupportedRequestType }
    public static var persistentStoreIncompatibleVersionHashError: CocoaError.Code { .persistentStoreIncompatibleVersionHashError }
    public static var persistentStoreIncompatibleVersionHash: CocoaError.Code { .persistentStoreIncompatibleVersionHash }
    public static var migrationError: CocoaError.Code { .migrationError }
    public static var migration: CocoaError.Code { .migration }
    public static var migrationCancelledError: CocoaError.Code { .migrationCancelledError }
    public static var migrationCancelled: CocoaError.Code { .migrationCancelled }
    public static var migrationMissingSourceModelError: CocoaError.Code { .migrationMissingSourceModelError }
    public static var migrationMissingSourceModel: CocoaError.Code { .migrationMissingSourceModel }
    public static var migrationMissingMappingModelError: CocoaError.Code { .migrationMissingMappingModelError }
    public static var migrationMissingMappingModel: CocoaError.Code { .migrationMissingMappingModel }
    public static var migrationManagerSourceStoreError: CocoaError.Code { .migrationManagerSourceStoreError }
    public static var migrationManagerSourceStore: CocoaError.Code { .migrationManagerSourceStore }
    public static var migrationManagerDestinationStoreError: CocoaError.Code { .migrationManagerDestinationStoreError }
    public static var migrationManagerDestinationStore: CocoaError.Code { .migrationManagerDestinationStore }
    public static var entityMigrationPolicyError: CocoaError.Code { .entityMigrationPolicyError }
    public static var entityMigrationPolicy: CocoaError.Code { .entityMigrationPolicy }
    public static var sqliteError: CocoaError.Code { .sqliteError }
    public static var sqlite: CocoaError.Code { .sqlite }
    public static var inferredMappingModelError: CocoaError.Code { .inferredMappingModelError }
    public static var inferredMappingModel: CocoaError.Code { .inferredMappingModel }
    public static var externalRecordImportError: CocoaError.Code { .externalRecordImportError }
    public static var externalRecordImport: CocoaError.Code { .externalRecordImport }
    public var validationKey: String? { userInfo[NSValidationKeyErrorKey] as? String }
    public var validationObject: Any? { userInfo[NSValidationObjectErrorKey] }
    public var validationValue: Any? { userInfo[NSValidationValueErrorKey] }
    public var validationPredicate: NSPredicate? { userInfo[NSValidationPredicateErrorKey] as? NSPredicate }
    public var affectedStores: [AnyObject]? { userInfo[NSAffectedStoresErrorKey] as? [AnyObject] }
    public var affectedObjects: [AnyObject]? { userInfo[NSAffectedObjectsErrorKey] as? [AnyObject] }
    public var persistentStoreSaveConflicts: [NSMergeConflict]? {
        userInfo[NSPersistentStoreSaveConflictsErrorKey] as? [NSMergeConflict]
    }
}

// MARK: - Historical version numbers (public CoreDataDefines.h)

public var NSCoreDataVersionNumber: Double = 0
public var NSCoreDataVersionNumber10_4: Double { 185.0 }
public var NSCoreDataVersionNumber10_4_3: Double { 185.1 }
public var NSCoreDataVersionNumber10_5: Double { 186.0 }
public var NSCoreDataVersionNumber10_5_3: Double { 186.2 }
public var NSCoreDataVersionNumber10_6: Double { 246.0 }
public var NSCoreDataVersionNumber10_6_2: Double { 246.2 }
public var NSCoreDataVersionNumber10_6_3: Double { 246.3 }
public var NSCoreDataVersionNumber10_7: Double { 358.4 }
public var NSCoreDataVersionNumber10_7_2: Double { 358.12 }
public var NSCoreDataVersionNumber10_7_3: Double { 358.13 }
public var NSCoreDataVersionNumber10_7_4: Double { 358.14 }
public var NSCoreDataVersionNumber10_8: Double { 407.5 }
public var NSCoreDataVersionNumber10_8_2: Double { 407.7 }
public var NSCoreDataVersionNumber10_9: Double { 481.0 }
public var NSCoreDataVersionNumber10_9_2: Double { 481.1 }
public var NSCoreDataVersionNumber10_9_3: Double { 481.3 }
public var NSCoreDataVersionNumber10_10: Double { 526.0 }
public var NSCoreDataVersionNumber10_10_2: Double { 526.1 }
public var NSCoreDataVersionNumber10_10_3: Double { 526.2 }
public var NSCoreDataVersionNumber10_11: Double { 640.0 }
public var NSCoreDataVersionNumber10_11_3: Double { 641.3 }
public var NSCoreDataVersionNumber_iPhoneOS_3_0: Double { 241.0 }
public var NSCoreDataVersionNumber_iPhoneOS_3_1: Double { 248.0 }
public var NSCoreDataVersionNumber_iPhoneOS_3_2: Double { 310.2 }
public var NSCoreDataVersionNumber_iPhoneOS_4_0: Double { 320.5 }
public var NSCoreDataVersionNumber_iPhoneOS_4_1: Double { 320.11 }
public var NSCoreDataVersionNumber_iPhoneOS_4_2: Double { 320.15 }
public var NSCoreDataVersionNumber_iPhoneOS_4_3: Double { 320.17 }
public var NSCoreDataVersionNumber_iPhoneOS_5_0: Double { 386.1 }
public var NSCoreDataVersionNumber_iPhoneOS_5_1: Double { 386.5 }
public var NSCoreDataVersionNumber_iPhoneOS_6_0: Double { 419.0 }
public var NSCoreDataVersionNumber_iPhoneOS_6_1: Double { 420.1 }
public var NSCoreDataVersionNumber_iPhoneOS_7_0: Double { 479.0 }
public var NSCoreDataVersionNumber_iPhoneOS_7_1: Double { 479.3 }
public var NSCoreDataVersionNumber_iPhoneOS_8_0: Double { 519.0 }
public var NSCoreDataVersionNumber_iPhoneOS_8_3: Double { 519.15 }
public var NSCoreDataVersionNumber_iPhoneOS_9_0: Double { 640.0 }
public var NSCoreDataVersionNumber_iPhoneOS_9_2: Double { 641.2 }
public var NSCoreDataVersionNumber_iPhoneOS_9_3: Double { 641.6 }

// MARK: - Enumerations

public enum NSAttributeType: UInt, Hashable, Sendable {
    case undefinedAttributeType = 0
    case integer16AttributeType = 100
    case integer32AttributeType = 200
    case integer64AttributeType = 300
    case decimalAttributeType = 400
    case doubleAttributeType = 500
    case floatAttributeType = 600
    case stringAttributeType = 700
    case booleanAttributeType = 800
    case dateAttributeType = 900
    case binaryDataAttributeType = 1000
    case UUIDAttributeType = 1100
    case URIAttributeType = 1200
    case transformableAttributeType = 1800
    case objectIDAttributeType = 2000
    case compositeAttributeType = 2100
}

public enum NSDeleteRule: UInt, Hashable, Sendable {
    case noActionDeleteRule = 0
    case nullifyDeleteRule = 1
    case cascadeDeleteRule = 2
    case denyDeleteRule = 3
}

public enum NSManagedObjectContextConcurrencyType: UInt, Hashable, Sendable {
    case confinementConcurrencyType = 0
    case privateQueueConcurrencyType = 1
    case mainQueueConcurrencyType = 2
}

public enum NSMergePolicyType: UInt, Hashable, Sendable {
    case errorMergePolicyType = 0
    case rollbackMergePolicyType = 1
    case overwriteMergePolicyType = 2
    case mergeByPropertyStoreTrumpMergePolicyType = 3
    case mergeByPropertyObjectTrumpMergePolicyType = 4
}

public enum NSPersistentStoreRequestType: UInt, Hashable, Sendable {
    case fetchRequestType = 1
    case saveRequestType = 2
    case batchUpdateRequestType = 6
    case batchDeleteRequestType = 7
    case batchInsertRequestType = 8
}

public enum NSFetchedResultsChangeType: UInt, Hashable, Sendable {
    case insert = 1
    case delete = 2
    case move = 3
    case update = 4
}

public enum NSBatchDeleteRequestResultType: UInt, Hashable, Sendable {
    case resultTypeStatusOnly = 0
    case resultTypeObjectIDs = 1
    case resultTypeCount = 2
}

public enum NSBatchInsertRequestResultType: UInt, Hashable, Sendable {
    case statusOnly = 0
    case objectIDs = 1
    case count = 2
}

public enum NSBatchUpdateRequestResultType: UInt, Hashable, Sendable {
    case statusOnlyResultType = 0
    case updatedObjectIDsResultType = 1
    case updatedObjectsCountResultType = 2
}

public enum NSEntityMappingType: UInt, Hashable, Sendable {
    case undefinedEntityMappingType = 0
    case customEntityMappingType = 1
    case addEntityMappingType = 2
    case removeEntityMappingType = 3
    case copyEntityMappingType = 4
    case transformEntityMappingType = 5
}

public enum NSFetchIndexElementType: UInt, Hashable, Sendable {
    case binary = 0
    case rTree = 1
}

public enum NSPersistentHistoryChangeType: Int64, Hashable, Sendable {
    case insert = 0
    case update = 1
    case delete = 2
}

public enum NSPersistentHistoryResultType: Int, Hashable, Sendable {
    case statusOnly = 0
    case objectIDs = 1
    case count = 2
    case transactionsOnly = 3
    case changesOnly = 4
    case transactionsAndChanges = 5
}

public enum NSPersistentStoreUbiquitousTransitionType: UInt, Hashable, Sendable {
    case accountAdded = 1
    case accountRemoved = 2
    case contentRemoved = 3
    case initialImportCompleted = 4
}

public struct NSFetchRequestResultType: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static var managedObjectResultType: NSFetchRequestResultType { NSFetchRequestResultType(rawValue: 0) }
    public static var managedObjectIDResultType: NSFetchRequestResultType { NSFetchRequestResultType(rawValue: 1) }
    public static var dictionaryResultType: NSFetchRequestResultType { NSFetchRequestResultType(rawValue: 2) }
    public static var countResultType: NSFetchRequestResultType { NSFetchRequestResultType(rawValue: 4) }
}

public struct NSSnapshotEventType: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static var undoInsertion: NSSnapshotEventType { NSSnapshotEventType(rawValue: 1 << 1) }
    public static var undoDeletion: NSSnapshotEventType { NSSnapshotEventType(rawValue: 1 << 2) }
    public static var undoUpdate: NSSnapshotEventType { NSSnapshotEventType(rawValue: 1 << 3) }
    public static var rollback: NSSnapshotEventType { NSSnapshotEventType(rawValue: 1 << 4) }
    public static var refresh: NSSnapshotEventType { NSSnapshotEventType(rawValue: 1 << 5) }
    public static var mergePolicy: NSSnapshotEventType { NSSnapshotEventType(rawValue: 1 << 6) }
}

public struct NSPersistentCloudKitContainerSchemaInitializationOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static var dryRun: NSPersistentCloudKitContainerSchemaInitializationOptions { NSPersistentCloudKitContainerSchemaInitializationOptions(rawValue: 1 << 1) }
    public static var printSchema: NSPersistentCloudKitContainerSchemaInitializationOptions { NSPersistentCloudKitContainerSchemaInitializationOptions(rawValue: 1 << 2) }
}

// MARK: - Fetch result protocol

public protocol NSFetchRequestResult: NSObjectProtocol {}

extension NSNumber: NSFetchRequestResult {}
extension NSDictionary: NSFetchRequestResult {}
extension NSString: NSFetchRequestResult {}

// MARK: - Helpers

func _CDMakeError(_ code: Int, _ message: String, userInfo extra: [String: Any] = [:]) -> NSError {
    var info = extra
    info[NSLocalizedDescriptionKey] = message
    return NSError(domain: NSCocoaErrorDomain, code: code, userInfo: info)
}

func _CDUnsupportedStoreError(_ storeType: String) -> NSError {
    _CDMakeError(
        NSPersistentStoreOpenError,
        "Linux CoreData does not open Apple-format '\(storeType)' stores. Use NSInMemoryStoreType."
    )
}

enum _CDIDSource {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var value: UInt64 = 0

    static func next() -> UInt64 {
        lock.lock()
        defer { lock.unlock() }
        value &+= 1
        return value
    }
}
