import Foundation
import SystemExtensions

func testOSSystemExtensionErrorCodeRawValues() {
    typealias Code = OSSystemExtensionError.Code
    let expected: [(Code, Int)] = [
        (.unknown, 1),
        (.missingEntitlement, 2),
        (.unsupportedParentBundleLocation, 3),
        (.extensionNotFound, 4),
        (.extensionMissingIdentifier, 5),
        (.duplicateExtensionIdentifer, 6),
        (.unknownExtensionCategory, 7),
        (.codeSignatureInvalid, 8),
        (.validationFailed, 9),
        (.forbiddenBySystemPolicy, 10),
        (.requestCanceled, 11),
        (.requestSuperseded, 12),
        (.authorizationRequired, 13),
    ]
    precondition(expected.count == 13)
    for (code, raw) in expected {
        precondition(code.rawValue == raw)
        precondition(Code(rawValue: raw) == code)
    }
    precondition(Code(rawValue: 0) == nil)
    precondition(Code(rawValue: 14) == nil)
    precondition(Code(rawValue: -1) == nil)
}

func testOSSystemExtensionErrorStaticCodeAliases() {
    typealias Code = OSSystemExtensionError.Code
    let aliases: [(Code, Code)] = [
        (OSSystemExtensionError.unknown, .unknown),
        (OSSystemExtensionError.missingEntitlement, .missingEntitlement),
        (OSSystemExtensionError.unsupportedParentBundleLocation, .unsupportedParentBundleLocation),
        (OSSystemExtensionError.extensionNotFound, .extensionNotFound),
        (OSSystemExtensionError.extensionMissingIdentifier, .extensionMissingIdentifier),
        (OSSystemExtensionError.duplicateExtensionIdentifer, .duplicateExtensionIdentifer),
        (OSSystemExtensionError.unknownExtensionCategory, .unknownExtensionCategory),
        (OSSystemExtensionError.codeSignatureInvalid, .codeSignatureInvalid),
        (OSSystemExtensionError.validationFailed, .validationFailed),
        (OSSystemExtensionError.forbiddenBySystemPolicy, .forbiddenBySystemPolicy),
        (OSSystemExtensionError.requestCanceled, .requestCanceled),
        (OSSystemExtensionError.requestSuperseded, .requestSuperseded),
        (OSSystemExtensionError.authorizationRequired, .authorizationRequired),
    ]
    precondition(aliases.count == 13)
    for (alias, member) in aliases {
        precondition(alias == member)
        precondition(alias.rawValue == member.rawValue)
    }
}

func testOSSystemExtensionErrorCodePatternMatch() {
    let error = OSSystemExtensionError(.validationFailed)
    precondition(OSSystemExtensionError.Code.validationFailed ~= error)
    precondition(!(OSSystemExtensionError.Code.unknown ~= error))
    precondition(!(OSSystemExtensionError.Code.validationFailed ~= NSError(domain: "other", code: 9)))
    switch error {
    case OSSystemExtensionError.Code.validationFailed:
        break
    default:
        preconditionFailure("code pattern match failed")
    }
}

func testOSSystemExtensionErrorCodeHashValue() {
    let a = OSSystemExtensionError.Code.missingEntitlement.hashValue
    let b = OSSystemExtensionError.Code.missingEntitlement.hashValue
    precondition(a == b)
    precondition(
        OSSystemExtensionError.Code.unknown.hashValue
            != OSSystemExtensionError.Code.authorizationRequired.hashValue
    )
}

func testOSSystemExtensionErrorCodeHashInto() {
    var hasherA = Hasher()
    var hasherB = Hasher()
    OSSystemExtensionError.Code.codeSignatureInvalid.hash(into: &hasherA)
    OSSystemExtensionError.Code.codeSignatureInvalid.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())

    var hasherC = Hasher()
    OSSystemExtensionError.Code.unknown.hash(into: &hasherC)
    var hasherD = Hasher()
    OSSystemExtensionError.Code.missingEntitlement.hash(into: &hasherD)
    hasherC.combine(0)
    hasherD.combine(0)
    precondition(hasherC.finalize() != hasherD.finalize())
}
