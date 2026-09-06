import Foundation
import LightweightCodeRequirements

func lcrRoundTrip<T: Codable>(_ value: T) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(T.self, from: data)
}

func testConstraintErrorCases() {
    let cases: [ConstraintError] = [
        .duplicateKey,
        .malformedConstraint,
        .unsupportedConstraintForRequirementType,
        .taskIsNoLongerValid,
    ]
    precondition(cases[0] == ConstraintError.duplicateKey)
    precondition(cases[1] == ConstraintError.malformedConstraint)
    precondition(cases[2] == ConstraintError.unsupportedConstraintForRequirementType)
    precondition(cases[3] == ConstraintError.taskIsNoLongerValid)
    precondition(cases[0] != cases[1])
}

func testConstraintErrorHashable() {
    var hasher = Hasher()
    ConstraintError.duplicateKey.hash(into: &hasher)
    let hashed = hasher.finalize()
    precondition(ConstraintError.duplicateKey.hashValue == ConstraintError.duplicateKey.hashValue)
    precondition(hashed == hashed)
    precondition(ConstraintError.malformedConstraint.hashValue != ConstraintError.duplicateKey.hashValue)
}

func testConstraintErrorLocalizedDescription() {
    let error: Error = ConstraintError.taskIsNoLongerValid
    precondition(!error.localizedDescription.isEmpty)
}

func testConstraintErrorThrownByEmptyRequirement() {
    do {
        _ = try LaunchCodeRequirement.allOf { }
        preconditionFailure("empty allOf must throw")
    } catch let error as ConstraintError {
        precondition(error == .malformedConstraint)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testConstraintErrorDuplicateKey() {
    do {
        _ = try LaunchCodeRequirement.allOf {
            TeamIdentifier("ABCDE12345")
            TeamIdentifier("FGHIJ67890")
        }
        preconditionFailure("duplicate team-identifier must throw")
    } catch let error as ConstraintError {
        precondition(error == .duplicateKey)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testConstraintErrorUnsupportedConversion() {
    let onDisk = try! OnDiskCodeRequirement.allOf {
        IsMainBinary(true)
    }
    do {
        _ = try LaunchCodeRequirement(onDisk)
        preconditionFailure("IsMainBinary cannot convert to launch")
    } catch let error as ConstraintError {
        precondition(error == .unsupportedConstraintForRequirementType)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}
