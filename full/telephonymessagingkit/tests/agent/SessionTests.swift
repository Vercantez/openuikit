
import Foundation
import TelephonyMessagingKit

func testSessionSharedFailClosed() {
    let session = TelephonyMessagingSession.shared
    precondition(session.isConfiguredForCarrierMessaging == false)
    precondition(session.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    let _: TelephonyMessagingSession.ID = session.id
    precondition(session.smsService.isViable(for: tmkServiceID()) == false)
    precondition(session.mmsService.isViable(for: tmkServiceID()) == false)
    precondition(session.rcsService.isViable(for: tmkServiceID()) == false)
    do {
        let services = try session.cellularServices
        precondition(services.isEmpty)
    } catch {
        preconditionFailure("cellularServices should return an empty inventory, not throw")
    }
    _ = session.cellularServiceStateUpdates
    _ = session.smsService
    _ = session.mmsService
    _ = session.rcsService
}

func testCellularServiceIdentity() {
    let id = tmkServiceID()
    let other = CellularServiceID(uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!)
    precondition(id != other)
    precondition(id == CellularServiceID(uuid: id.uuid))
    precondition(id.description == id.uuid.uuidString)
    tmkHash(id)
    tmkRoundTrip(id)
    let state = CellularServiceState(id: id, label: "SIM 1")
    precondition(state.id == id)
    precondition(state.label == "SIM 1")
    let _: CellularServiceState.ID = state.id
    tmkHash(state)
    tmkRoundTrip(state)
}

func testFoundationValuesThroughPublicAPI() {
    let uuid = UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee")!
    let data = Data("foundation-identity".utf8)
    let date = Date(timeIntervalSince1970: 1_234_567_890)
    let url = URL(string: "https://example.invalid/foundation")!
    precondition(type(of: uuid) == UUID.self)
    precondition(type(of: data) == Data.self)
    precondition(!String(reflecting: type(of: uuid)).hasPrefix("TelephonyMessagingKit."))
    let id = CellularServiceID(uuid: uuid)
    precondition(id.uuid == uuid)
    let part = MMSPartContent(
        data: data,
        contentType: .data,
        contentID: "cid",
        disposition: .attachment,
        fileName: "blob.bin"
    )
    precondition(part.data == data)
    let meta = RCSFileTransferMetadata(
        contentType: .png,
        disposition: .render,
        expirationDate: date,
        playbackLength: .seconds(1),
        url: url,
        fileName: url.lastPathComponent,
        fileSize: data.count
    )
    precondition(meta.expirationDate == date)
    precondition(meta.url == url)
}

func testSessionErrorLocalized() {
    let err = TelephonyMessagingSession.Error.serviceUnavailable
    precondition(err == .serviceUnavailable)
    precondition(err != .invalidSession)
    precondition(err.errorDescription != nil)
    precondition(err.failureReason != nil)
    precondition(err.recoverySuggestion != nil)
    precondition(err.helpAnchor == nil)
    precondition(!err.localizedDescription.isEmpty)
    tmkHash(err)
    tmkRoundTrip(err)
    tmkRoundTrip(TelephonyMessagingSession.Error.invalidArgument)
    tmkRoundTrip(TelephonyMessagingSession.Error.invalidSession)
    tmkRoundTrip(TelephonyMessagingSession.Error.internalError)
}
