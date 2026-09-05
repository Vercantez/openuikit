import Foundation
import Accessibility

func testFeatureOverrideFailClosed() {
    let manager = AXFeatureOverrideSessionManager.sharedInstance
    precondition(manager === AXFeatureOverrideSessionManager.sharedInstance)
    do {
        _ = try manager.beginOverrideSession(enabling: .voiceOver, disabling: .zoom)
        preconditionFailure("beginOverrideSession must fail closed")
    } catch let error as AXFeatureOverrideSessionError {
        precondition(error.code == .appNotEntitled)
    } catch {
        preconditionFailure("expected AXFeatureOverrideSessionError")
    }
    _ = AXFeatureOverrideSession.self
    do {
        try manager.end(AXFeatureOverrideSession())
        preconditionFailure("end(_:) must fail closed without an active session")
    } catch let error as AXFeatureOverrideSessionError {
        precondition(error.code == .overrideNotFoundForUUID)
    } catch {
        preconditionFailure("expected AXFeatureOverrideSessionError")
    }
}
