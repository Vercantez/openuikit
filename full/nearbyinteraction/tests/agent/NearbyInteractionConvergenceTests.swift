import Foundation
import NearbyInteraction

func testNIAlgorithmConvergenceStatusReasonRawValues() {
    precondition(
        NIAlgorithmConvergenceStatus.Reason.insufficientHorizontalSweep.rawValue
            == "NIAlgorithmConvergenceStatusReasonInsufficientHorizontalSweep"
    )
    precondition(
        NIAlgorithmConvergenceStatus.Reason.insufficientVerticalSweep.rawValue
            == "NIAlgorithmConvergenceStatusReasonInsufficientVerticalSweep"
    )
    precondition(
        NIAlgorithmConvergenceStatus.Reason.insufficientMovement.rawValue
            == "NIAlgorithmConvergenceStatusReasonInsufficientMovement"
    )
    precondition(
        NIAlgorithmConvergenceStatus.Reason.insufficientLighting.rawValue
            == "NIAlgorithmConvergenceStatusReasonInsufficientLighting"
    )
    precondition(
        NIAlgorithmConvergenceStatus.Reason.insufficientSignalStrength.rawValue
            == "NIAlgorithmConvergenceStatusReasonInsufficientSignalStrength"
    )

    let custom = NIAlgorithmConvergenceStatus.Reason(rawValue: "custom-reason")
    precondition(custom.rawValue == "custom-reason")
    precondition(custom.localizedDescription == nil)
    precondition(NIAlgorithmConvergenceStatus.Reason.insufficientLighting.localizedDescription != nil)
    precondition(NIAlgorithmConvergenceStatus.Reason.insufficientLighting != .insufficientMovement)

    var hasherA = Hasher()
    var hasherB = Hasher()
    NIAlgorithmConvergenceStatus.Reason.insufficientLighting.hash(into: &hasherA)
    NIAlgorithmConvergenceStatus.Reason.insufficientLighting.hash(into: &hasherB)
    precondition(hasherA.finalize() == hasherB.finalize())
    precondition(
        NIAlgorithmConvergenceStatus.Reason.insufficientLighting.hashValue
            == NIAlgorithmConvergenceStatus.Reason.insufficientLighting.hashValue
    )

    let alias: NIAlgorithmConvergenceStatus.Reason.RawValue = "NIAlgorithmConvergenceStatusReasonInsufficientLighting"
    precondition(alias == NIAlgorithmConvergenceStatus.Reason.insufficientLighting.rawValue)
}

func testNIAlgorithmConvergenceStatusEquality() {
    let unknown = NIAlgorithmConvergenceStatus.unknown
    let converged = NIAlgorithmConvergenceStatus.converged
    let notConverged = NIAlgorithmConvergenceStatus.notConverged([.insufficientLighting])
    let same = NIAlgorithmConvergenceStatus.notConverged([.insufficientLighting])
    let other = NIAlgorithmConvergenceStatus.notConverged([.insufficientMovement])

    precondition(unknown == .unknown)
    precondition(converged == .converged)
    precondition(notConverged == same)
    precondition(unknown != converged)
    precondition(notConverged != other)
    precondition(unknown != notConverged)
}

func testNIAlgorithmConvergenceStatusProperty() {
    let unknown = NIAlgorithmConvergence(status: .unknown)
    precondition(unknown.status == .unknown)
    let converged = NIAlgorithmConvergence(status: .converged)
    precondition(converged.status == .converged)
    let reasons = [NIAlgorithmConvergenceStatus.Reason.insufficientHorizontalSweep]
    let pending = NIAlgorithmConvergence(status: .notConverged(reasons))
    precondition(pending.status == .notConverged([.insufficientHorizontalSweep]))

    let copy = pending.copy() as! NIAlgorithmConvergence
    precondition(copy.status == pending.status)
    precondition(copy !== pending)
}
