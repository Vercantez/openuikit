import Foundation
import DockKit

func testLimitInitStoresRangeAndSpeed() {
    do {
        let limit = try DockAccessory.Limits.Limit(
            positionRange: -1.5..<1.5,
            maximumSpeed: 0.75
        )
        precondition(limit.positionRange.lowerBound == -1.5)
        precondition(limit.positionRange.upperBound == 1.5)
        precondition(limit.maximumSpeed == 0.75)
    } catch {
        preconditionFailure("valid Limit must succeed: \(error)")
    }
}

func testLimitInitRejectsInvalidSpeed() {
    do {
        _ = try DockAccessory.Limits.Limit(positionRange: 0..<1, maximumSpeed: -0.1)
        preconditionFailure("negative speed must throw")
    } catch let error as DockKitError {
        precondition(error == .invalidParameter)
    } catch {
        preconditionFailure("expected DockKitError.invalidParameter")
    }

    do {
        _ = try DockAccessory.Limits.Limit(positionRange: 0..<1, maximumSpeed: .nan)
        preconditionFailure("NaN speed must throw")
    } catch let error as DockKitError {
        precondition(error == .invalidParameter)
    } catch {
        preconditionFailure("expected DockKitError.invalidParameter")
    }
}

func testLimitInitRejectsEmptyRange() {
    do {
        _ = try DockAccessory.Limits.Limit(positionRange: 1.0..<0.0, maximumSpeed: 1)
        preconditionFailure("empty range must throw")
    } catch let error as DockKitError {
        precondition(error == .invalidParameter)
    } catch {
        preconditionFailure("expected DockKitError.invalidParameter")
    }
}

func testLimitsInitStoresAxes() {
    do {
        let yaw = try DockAccessory.Limits.Limit(positionRange: -2..<2, maximumSpeed: 1)
        let pitch = try DockAccessory.Limits.Limit(positionRange: -0.5..<0.5, maximumSpeed: 0.2)
        let limits = DockAccessory.Limits(yaw: yaw, pitch: pitch, roll: nil)
        precondition(limits.yaw?.maximumSpeed == 1)
        precondition(limits.pitch?.positionRange.lowerBound == -0.5)
        precondition(limits.roll == nil)
    } catch {
        preconditionFailure("valid Limits must succeed: \(error)")
    }
}

func testLimitAllowsZeroSpeed() {
    do {
        let limit = try DockAccessory.Limits.Limit(positionRange: 0..<1, maximumSpeed: 0)
        precondition(limit.maximumSpeed == 0)
    } catch {
        preconditionFailure("zero speed should be accepted: \(error)")
    }
}
