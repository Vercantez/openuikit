import Foundation
import DockKit

func testDockAccessoryManagerShared() {
    let a = DockAccessoryManager.shared
    let b = DockAccessoryManager.shared
    precondition(a === b)
}

func testSystemTrackingDisabled() {
    precondition(DockAccessoryManager.shared.isSystemTrackingEnabled == false)
}

func testAccessoryStateChangesThrow() {
    do {
        _ = try DockAccessoryManager.shared.accessoryStateChanges
        preconditionFailure("accessoryStateChanges must fail closed")
    } catch let error as DockKitError {
        precondition(error == .notSupported)
    } catch {
        preconditionFailure("expected DockKitError")
    }
}
