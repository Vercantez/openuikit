import Foundation
@_spi(OpenUIKitHost) import Contacts

func testErrorCodeAliases() {
    let aliases: [(CNError.Code, CNError.Code, Int)] = [
        (CNError.communicationError, .communicationError, 1),
        (CNError.dataAccessError, .dataAccessError, 2),
        (CNError.authorizationDenied, .authorizationDenied, 100),
        (CNError.noAccessableWritableContainers, .noAccessableWritableContainers, 101),
        (CNError.unauthorizedKeys, .unauthorizedKeys, 102),
        (CNError.featureDisabledByUser, .featureDisabledByUser, 103),
        (CNError.featureNotAvailable, .featureNotAvailable, 104),
        (CNError.recordDoesNotExist, .recordDoesNotExist, 200),
        (CNError.insertedRecordAlreadyExists, .insertedRecordAlreadyExists, 201),
        (CNError.containmentCycle, .containmentCycle, 202),
        (CNError.containmentScope, .containmentScope, 203),
        (CNError.recordIdentifierInvalid, .recordIdentifierInvalid, 204),
        (CNError.recordNotWritable, .recordNotWritable, 205),
        (CNError.parentRecordDoesNotExist, .parentRecordDoesNotExist, 206),
        (CNError.parentContainerNotWritable, .parentContainerNotWritable, 207),
        (CNError.validationMultipleErrors, .validationMultipleErrors, 300),
        (CNError.validationTypeMismatch, .validationTypeMismatch, 301),
        (CNError.validationConfigurationError, .validationConfigurationError, 302),
        (CNError.predicateInvalid, .predicateInvalid, 400),
        (CNError.policyViolation, .policyViolation, 500),
        (CNError.clientIdentifierInvalid, .clientIdentifierInvalid, 600),
        (CNError.clientIdentifierDoesNotExist, .clientIdentifierDoesNotExist, 601),
        (CNError.clientIdentifierCollision, .clientIdentifierCollision, 602),
        (CNError.changeHistoryExpired, .changeHistoryExpired, 700),
        (CNError.changeHistoryInvalidAnchor, .changeHistoryInvalidAnchor, 701),
        (CNError.changeHistoryInvalidFetchRequest, .changeHistoryInvalidFetchRequest, 702),
        (CNError.vCardMalformed, .vCardMalformed, 800),
        (CNError.vCardSummarizationError, .vCardSummarizationError, 801),
    ]
    expect(aliases.count == 28, "every CNError code alias")
    expect(Set(aliases.map(\.2)).count == aliases.count, "unique alias raw values")
    for (alias, code, raw) in aliases {
        expect(alias == code, "alias \(raw)")
        expect(alias.rawValue == raw, "alias raw \(raw)")
    }
    expect(CNError.vCardMalformed != CNError.vCardSummarizationError, "vcard error inequality")
    expect(CNError.changeHistoryExpired != CNError.changeHistoryInvalidAnchor, "history error inequality")
    expect(CNError.clientIdentifierInvalid != CNError.clientIdentifierCollision, "client id error inequality")
}

func testErrorUserInfoAndPatternMatching() {
    let denied = CNError(
        .authorizationDenied,
        userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: ["abc"]]
    )
    expect(CNError.errorDomain == CNErrorDomain, "custom nserror domain")
    expect(denied.errorCode == 100, "custom nserror code")
    expect(denied.code == .authorizationDenied, "bridged code")
    expect(denied.affectedRecordIdentifiers == ["abc"], "affected ids")
    expect(CNError.Code.authorizationDenied ~= denied, "error code pattern")
    expect(denied == CNError(.authorizationDenied, userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: ["abc"]]), "error equality")
    expect(denied != CNError(.dataAccessError), "error inequality")
    var hasher = Hasher()
    denied.hash(into: &hasher)
    expect(denied.hashValue == CNError(.authorizationDenied, userInfo: [CNErrorUserInfoAffectedRecordIdentifiersKey: ["abc"]]).hashValue, "error hash")
    expect(denied.keyPaths == nil, "error keyPaths")
    expect(denied.affectedRecords == nil, "error affectedRecords")
    _ = denied.userInfo
    _ = denied.errorUserInfo
    _ = denied.localizedDescription

    let records = NSObject()
    let detailed = CNError(
        .validationMultipleErrors,
        userInfo: [
            CNErrorUserInfoKeyPathsKey: [CNContactBirthdayKey],
            CNErrorUserInfoAffectedRecordsKey: [records],
            CNErrorUserInfoValidationErrorsKey: ["month"],
        ]
    )
    expect(detailed.keyPaths == [CNContactBirthdayKey], "keyPaths userInfo")
    expect(detailed.affectedRecords?.count == 1, "affectedRecords userInfo")
}
