import Foundation
import TelephonyMessagingKit

func testRCSServiceBoundaries() {
    let service = TelephonyMessagingSession.shared.rcsService
    precondition(service.isViable(for: tmkServiceID()) == false)
    do {
        _ = try service.configuration(for: tmkServiceID())
        preconditionFailure("RCS configuration must fail closed")
    } catch let error as RCSService.Error {
        precondition(error == .serviceUnavailable)
    } catch {
        preconditionFailure("wrong error \(error)")
    }
    do {
        _ = try service.incomingMessageNotifications
        preconditionFailure("RCS incoming must fail closed")
    } catch let error as RCSService.Error {
        precondition(error == .serviceUnavailable)
    } catch {
        preconditionFailure("wrong error \(error)")
    }
    do {
        _ = try service.viabilityNotifications
        preconditionFailure("RCS viability must fail closed")
    } catch let error as RCSService.Error {
        precondition(error == .serviceUnavailable)
    } catch {
        preconditionFailure("wrong error \(error)")
    }
    do {
        _ = try service.groupChatEvents
        preconditionFailure("RCS group events must fail closed")
    } catch let error as RCSService.Error {
        precondition(error == .serviceUnavailable)
    } catch {
        preconditionFailure("wrong error \(error)")
    }
    do {
        _ = try service.remoteHandleUpdates
        preconditionFailure("RCS remote handle updates must fail closed")
    } catch let error as RCSService.Error {
        precondition(error == .serviceUnavailable)
    } catch {
        preconditionFailure("wrong error \(error)")
    }
    let err = RCSService.Error.serviceUnavailable
    precondition(err.errorDescription != nil)
    precondition(err.helpAnchor == nil)
    tmkHash(err)
    tmkRoundTrip(err)
    tmkRoundTrip(RCSService.Error.notFound)
    tmkRoundTrip(RCSService.Error.decodingFailed)
}

func testEmptyAsyncSequenceType() {
    let stream = TelephonyMessagingEmptyAsyncSequence<Int>()
    _ = stream
    let sessionStream = TelephonyMessagingSession.shared.cellularServiceStateUpdates
    _ = sessionStream
}
