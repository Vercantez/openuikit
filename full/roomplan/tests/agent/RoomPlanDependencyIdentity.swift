import Foundation
import RoomPlan

/// Isolated-host identity probe. The sealed host gate does not compile this
/// file. The later EC2 integration build imports real Foundation and passes
/// genuine Foundation values through public RoomPlan APIs.
func roomPlanDependencyIdentityProbe() {
    let identifier = UUID()
    let room = CapturedRoom(identifier: identifier, version: 2, story: 1)
    precondition(room.identifier == identifier)
    precondition(room.version == 2)
    precondition(room.story == 1)

    let url = URL(fileURLWithPath: "/tmp/roomplan-identity.usdz")
    do {
        try room.export(to: url)
        preconditionFailure("export must fail closed")
    } catch let error as CapturedRoom.Error {
        precondition(error == .deviceNotSupported)
    } catch {
        preconditionFailure("export must throw CapturedRoom.Error")
    }

    let encoded = try! JSONEncoder().encode(room)
    let decoded = try! JSONDecoder().decode(CapturedRoom.self, from: encoded)
    precondition(decoded.identifier == identifier)

    var provider = CapturedRoom.ModelProvider()
    let missing = URL(fileURLWithPath: "/tmp/roomplan-missing-\(UUID().uuidString).usdz")
    do {
        try provider.setModelFileURL(missing, for: .chair)
        preconditionFailure("missing model file must throw")
    } catch CapturedRoom.ModelProvider.Error.nonExistingFile(let url) {
        precondition(url.path == missing.path)
    } catch {
        preconditionFailure("expected nonExistingFile")
    }
}
