#if canImport(SwiftUI)
import SwiftUI
#endif

/// Provides an action to request a person's declared age range.
///
/// On Apple platforms this type encapsulates UI context retrieval for the
/// window or view controller. Linux has no window scene: ``callAsFunction(ageGates:_:_:)``
/// uses the same fail-closed gate validation as ``AgeRangeService``.
public struct DeclaredAgeRangeAction {
    public init() {}

    /// Returns a response indicating whether the person has declared their
    /// age range.
    ///
    /// Linux never suspends. Well-formed gates throw
    /// ``AgeRangeService/Error/notAvailable``. Ill-formed gates throw
    /// ``AgeRangeService/Error/invalidRequest``.
    public func callAsFunction(
        ageGates threshold1: Int,
        _ threshold2: Int? = nil,
        _ threshold3: Int? = nil
    ) async throws -> AgeRangeService.Response {
        try linuxCallAsFunction(
            ageGates: threshold1,
            threshold2,
            threshold3
        )
    }

    func linuxCallAsFunction(
        ageGates threshold1: Int,
        _ threshold2: Int?,
        _ threshold3: Int?
    ) throws -> AgeRangeService.Response {
        try AgeRangeService.validateAgeGates(threshold1, threshold2, threshold3)
        throw AgeRangeService.Error.notAvailable
    }
}

extension EnvironmentValues {
    /// The property in the environment for adoption of the age range API.
    ///
    /// Linux returns a process-local ``DeclaredAgeRangeAction`` that always
    /// fails closed. There is no SwiftUI environment storage.
    public var requestAgeRange: DeclaredAgeRangeAction {
        DeclaredAgeRangeAction()
    }
}
