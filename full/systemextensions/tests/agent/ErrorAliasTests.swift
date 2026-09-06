import Foundation
import SystemExtensions

func testOSSystemExtensionErrorUnknownAlias() {
    precondition(OSSystemExtensionError.unknown == OSSystemExtensionError.Code.unknown)
    precondition(OSSystemExtensionError.unknown.rawValue == 1)
}

func testOSSystemExtensionErrorMissingEntitlementAlias() {
    precondition(OSSystemExtensionError.missingEntitlement == OSSystemExtensionError.Code.missingEntitlement)
    precondition(OSSystemExtensionError.missingEntitlement.rawValue == 2)
}

func testOSSystemExtensionErrorUnsupportedParentBundleLocationAlias() {
    precondition(
        OSSystemExtensionError.unsupportedParentBundleLocation
            == OSSystemExtensionError.Code.unsupportedParentBundleLocation
    )
    precondition(OSSystemExtensionError.unsupportedParentBundleLocation.rawValue == 3)
}

func testOSSystemExtensionErrorExtensionNotFoundAlias() {
    precondition(OSSystemExtensionError.extensionNotFound == OSSystemExtensionError.Code.extensionNotFound)
    precondition(OSSystemExtensionError.extensionNotFound.rawValue == 4)
}

func testOSSystemExtensionErrorExtensionMissingIdentifierAlias() {
    precondition(
        OSSystemExtensionError.extensionMissingIdentifier
            == OSSystemExtensionError.Code.extensionMissingIdentifier
    )
    precondition(OSSystemExtensionError.extensionMissingIdentifier.rawValue == 5)
}

func testOSSystemExtensionErrorDuplicateExtensionIdentiferAlias() {
    precondition(
        OSSystemExtensionError.duplicateExtensionIdentifer
            == OSSystemExtensionError.Code.duplicateExtensionIdentifer
    )
    precondition(OSSystemExtensionError.duplicateExtensionIdentifer.rawValue == 6)
}

func testOSSystemExtensionErrorUnknownExtensionCategoryAlias() {
    precondition(
        OSSystemExtensionError.unknownExtensionCategory
            == OSSystemExtensionError.Code.unknownExtensionCategory
    )
    precondition(OSSystemExtensionError.unknownExtensionCategory.rawValue == 7)
}

func testOSSystemExtensionErrorCodeSignatureInvalidAlias() {
    precondition(
        OSSystemExtensionError.codeSignatureInvalid
            == OSSystemExtensionError.Code.codeSignatureInvalid
    )
    precondition(OSSystemExtensionError.codeSignatureInvalid.rawValue == 8)
}

func testOSSystemExtensionErrorValidationFailedAlias() {
    precondition(OSSystemExtensionError.validationFailed == OSSystemExtensionError.Code.validationFailed)
    precondition(OSSystemExtensionError.validationFailed.rawValue == 9)
}

func testOSSystemExtensionErrorForbiddenBySystemPolicyAlias() {
    precondition(
        OSSystemExtensionError.forbiddenBySystemPolicy
            == OSSystemExtensionError.Code.forbiddenBySystemPolicy
    )
    precondition(OSSystemExtensionError.forbiddenBySystemPolicy.rawValue == 10)
}

func testOSSystemExtensionErrorRequestCanceledAlias() {
    precondition(OSSystemExtensionError.requestCanceled == OSSystemExtensionError.Code.requestCanceled)
    precondition(OSSystemExtensionError.requestCanceled.rawValue == 11)
}

func testOSSystemExtensionErrorRequestSupersededAlias() {
    precondition(OSSystemExtensionError.requestSuperseded == OSSystemExtensionError.Code.requestSuperseded)
    precondition(OSSystemExtensionError.requestSuperseded.rawValue == 12)
}

func testOSSystemExtensionErrorAuthorizationRequiredAlias() {
    precondition(
        OSSystemExtensionError.authorizationRequired
            == OSSystemExtensionError.Code.authorizationRequired
    )
    precondition(OSSystemExtensionError.authorizationRequired.rawValue == 13)
}
