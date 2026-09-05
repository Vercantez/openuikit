import Foundation
import GameKit

func testGKErrorRawValues() {
    let expected: [(GKError.Code, Int)] = [
        (.unknown, 1),
        (.cancelled, 2),
        (.communicationsFailure, 3),
        (.userDenied, 4),
        (.invalidCredentials, 5),
        (.notAuthenticated, 6),
        (.authenticationInProgress, 7),
        (.invalidPlayer, 8),
        (.scoreNotSet, 9),
        (.parentalControlsBlocked, 10),
        (.playerStatusExceedsMaximumLength, 11),
        (.playerStatusInvalid, 12),
        (.matchRequestInvalid, 13),
        (.underage, 14),
        (.gameUnrecognized, 15),
        (.notSupported, 16),
        (.invalidParameter, 17),
        (.unexpectedConnection, 18),
        (.challengeInvalid, 19),
        (.turnBasedMatchDataTooLarge, 20),
        (.turnBasedTooManySessions, 21),
        (.turnBasedInvalidParticipant, 22),
        (.turnBasedInvalidTurn, 23),
        (.turnBasedInvalidState, 24),
        (.invitationsDisabled, 25),
        (.playerPhotoFailure, 26),
        (.ubiquityContainerUnavailable, 27),
        (.matchNotConnected, 28),
        (.gameSessionRequestInvalid, 29),
        (.restrictedToAutomatch, 30),
        (.apiNotAvailable, 31),
        (.notAuthorized, 32),
        (.connectionTimeout, 33),
        (.apiObsolete, 34),
        (.iCloudUnavailable, 35),
        (.lockdownMode, 36),
        (.appUnlisted, 37),
        (.debugMode, 38),
        (.friendListDescriptionMissing, 100),
        (.friendListRestricted, 101),
        (.friendListDenied, 102),
        (.friendRequestNotAvailable, 103),
    ]
    for (code, raw) in expected {
        precondition(code.rawValue == raw)
        precondition(GKError.Code(rawValue: raw) == code)
        precondition(code != GKError.Code(rawValue: raw + 1000))
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
    }
    precondition(GKError.unknown == .unknown)
    precondition(GKError.cancelled == .cancelled)
    precondition(GKError.communicationsFailure == .communicationsFailure)
    precondition(GKError.userDenied == .userDenied)
    precondition(GKError.invalidCredentials == .invalidCredentials)
    precondition(GKError.notAuthenticated == .notAuthenticated)
    precondition(GKError.authenticationInProgress == .authenticationInProgress)
    precondition(GKError.invalidPlayer == .invalidPlayer)
    precondition(GKError.scoreNotSet == .scoreNotSet)
    precondition(GKError.parentalControlsBlocked == .parentalControlsBlocked)
    precondition(GKError.playerStatusExceedsMaximumLength == .playerStatusExceedsMaximumLength)
    precondition(GKError.playerStatusInvalid == .playerStatusInvalid)
    precondition(GKError.matchRequestInvalid == .matchRequestInvalid)
    precondition(GKError.underage == .underage)
    precondition(GKError.gameUnrecognized == .gameUnrecognized)
    precondition(GKError.notSupported == .notSupported)
    precondition(GKError.invalidParameter == .invalidParameter)
    precondition(GKError.unexpectedConnection == .unexpectedConnection)
    precondition(GKError.challengeInvalid == .challengeInvalid)
    precondition(GKError.turnBasedMatchDataTooLarge == .turnBasedMatchDataTooLarge)
    precondition(GKError.turnBasedTooManySessions == .turnBasedTooManySessions)
    precondition(GKError.turnBasedInvalidParticipant == .turnBasedInvalidParticipant)
    precondition(GKError.turnBasedInvalidTurn == .turnBasedInvalidTurn)
    precondition(GKError.turnBasedInvalidState == .turnBasedInvalidState)
    precondition(GKError.invitationsDisabled == .invitationsDisabled)
    precondition(GKError.playerPhotoFailure == .playerPhotoFailure)
    precondition(GKError.ubiquityContainerUnavailable == .ubiquityContainerUnavailable)
    precondition(GKError.matchNotConnected == .matchNotConnected)
    precondition(GKError.gameSessionRequestInvalid == .gameSessionRequestInvalid)
    precondition(GKError.restrictedToAutomatch == .restrictedToAutomatch)
    precondition(GKError.apiNotAvailable == .apiNotAvailable)
    precondition(GKError.notAuthorized == .notAuthorized)
    precondition(GKError.connectionTimeout == .connectionTimeout)
    precondition(GKError.apiObsolete == .apiObsolete)
    precondition(GKError.iCloudUnavailable == .iCloudUnavailable)
    precondition(GKError.lockdownMode == .lockdownMode)
    precondition(GKError.appUnlisted == .appUnlisted)
    precondition(GKError.debugMode == .debugMode)
    precondition(GKError.friendListDescriptionMissing == .friendListDescriptionMissing)
    precondition(GKError.friendListRestricted == .friendListRestricted)
    precondition(GKError.friendListDenied == .friendListDenied)
    precondition(GKError.friendRequestNotAvailable == .friendRequestNotAvailable)
    precondition(GKErrorDomain == "GKErrorDomain")
    precondition(GKError.errorDomain == GKErrorDomain)
}

func testGKErrorBehavior() {
    let error = GKError(.notAuthenticated, userInfo: [NSLocalizedDescriptionKey: "offline"])
    precondition(error.code == .notAuthenticated)
    precondition(error.errorCode == 6)
    precondition(error.errorUserInfo[NSLocalizedDescriptionKey] as? String == "offline")
    precondition(error.userInfo[NSLocalizedDescriptionKey] as? String == "offline")
    precondition(error.localizedDescription == "offline")
    let other = GKError(.notAuthenticated, userInfo: [NSLocalizedDescriptionKey: "offline"])
    precondition(error == other)
    precondition(!(error == GKError(.cancelled)))
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    let thrown: any Error = error
    precondition(GKError.Code.notAuthenticated ~= thrown)
    precondition(!(GKError.Code.cancelled ~= thrown))
}

func testGKGameSessionErrorRawValues() {
    let expected: [(GKGameSessionError.Code, Int)] = [
        (.unknown, 1),
        (.notAuthenticated, 2),
        (.sessionConflict, 3),
        (.sessionNotShared, 4),
        (.connectionCancelledByUser, 5),
        (.connectionFailed, 6),
        (.sessionHasMaxConnectedPlayers, 7),
        (.sendDataNotConnected, 8),
        (.sendDataNoRecipients, 9),
        (.sendDataNotReachable, 10),
        (.sendRateLimitReached, 11),
        (.badContainer, 12),
        (.cloudQuotaExceeded, 13),
        (.networkFailure, 14),
        (.cloudDriveDisabled, 15),
        (.invalidSession, 16),
    ]
    for (code, raw) in expected {
        precondition(code.rawValue == raw)
        precondition(GKGameSessionError.Code(rawValue: raw) == code)
        var hasher = Hasher()
        code.hash(into: &hasher)
        _ = hasher.finalize()
        precondition(code != GKGameSessionError.Code(rawValue: 99))
    }
    precondition(GKGameSessionError.unknown == .unknown)
    precondition(GKGameSessionError.notAuthenticated == .notAuthenticated)
    precondition(GKGameSessionError.sessionConflict == .sessionConflict)
    precondition(GKGameSessionError.sessionNotShared == .sessionNotShared)
    precondition(GKGameSessionError.connectionCancelledByUser == .connectionCancelledByUser)
    precondition(GKGameSessionError.connectionFailed == .connectionFailed)
    precondition(GKGameSessionError.sessionHasMaxConnectedPlayers == .sessionHasMaxConnectedPlayers)
    precondition(GKGameSessionError.sendDataNotConnected == .sendDataNotConnected)
    precondition(GKGameSessionError.sendDataNoRecipients == .sendDataNoRecipients)
    precondition(GKGameSessionError.sendDataNotReachable == .sendDataNotReachable)
    precondition(GKGameSessionError.sendRateLimitReached == .sendRateLimitReached)
    precondition(GKGameSessionError.badContainer == .badContainer)
    precondition(GKGameSessionError.cloudQuotaExceeded == .cloudQuotaExceeded)
    precondition(GKGameSessionError.networkFailure == .networkFailure)
    precondition(GKGameSessionError.cloudDriveDisabled == .cloudDriveDisabled)
    precondition(GKGameSessionError.invalidSession == .invalidSession)
    precondition(GKGameSessionErrorDomain == "GKGameSessionErrorDomain")
    precondition(GKGameSessionError.errorDomain == GKGameSessionErrorDomain)
    let error = GKGameSessionError(.invalidSession)
    precondition(error.code == .invalidSession)
    precondition(error.errorCode == 16)
    precondition(error == GKGameSessionError(.invalidSession))
    precondition(!(error == GKGameSessionError(.networkFailure)))
    var hasher = Hasher()
    error.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(GKGameSessionError.Code.invalidSession ~= error)
    _ = error.localizedDescription
    _ = error.errorUserInfo
    _ = error.userInfo
}
