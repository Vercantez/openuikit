import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
import OpenUIKit
#endif

/// Linux starting point for Apple's public `DeclaredAgeRange` module.
///
/// Isolated host compilation has Foundation only. `UIViewController` and
/// `EnvironmentValues` names use the lookalikes in
/// `DeclaredAgeRangeLookalikes.swift` until those modules are on the link
/// line. Linux has no Age Range daemon, Screen Time / Family Sharing session,
/// or Declared Age Range entitlement: requests never present Apple UI and
/// never return a shared range.
///
/// Darwin types: https://developer.apple.com/documentation/declaredagerange

/// Linux host-test control. Hidden from ordinary `import DeclaredAgeRange`
/// clients and not part of Apple's public DeclaredAgeRange surface.
@_spi(OpenUIKitHost)
public enum DeclaredAgeRangeHostControl {
    /// Same fail-closed error a well-formed Linux request surfaces.
    public static var linuxUnavailableError: AgeRangeService.Error {
        .notAvailable
    }

    /// Synchronous twin of `AgeRangeService.requestAgeRange(ageGates:_:_:in:)`.
    /// The async method never suspends; it throws this path's error.
    public static func requestAgeRangeSync(
        _ service: AgeRangeService = .shared,
        ageGates threshold1: Int,
        _ threshold2: Int? = nil,
        _ threshold3: Int? = nil,
        in viewController: UIViewController
    ) throws -> AgeRangeService.Response {
        try service.linuxRequestAgeRange(
            ageGates: threshold1,
            threshold2,
            threshold3,
            in: viewController
        )
    }

    /// Synchronous twin of `DeclaredAgeRangeAction.callAsFunction(ageGates:_:_:)`.
    public static func callAsFunctionSync(
        _ action: DeclaredAgeRangeAction,
        ageGates threshold1: Int,
        _ threshold2: Int? = nil,
        _ threshold3: Int? = nil
    ) throws -> AgeRangeService.Response {
        try action.linuxCallAsFunction(
            ageGates: threshold1,
            threshold2,
            threshold3
        )
    }
}

/// A request for the age range of a person logged onto the current device.
///
/// Linux never talks to Apple's age-range service. ``shared`` is a local
/// value; ``requestAgeRange(ageGates:_:_:in:)`` validates gates then throws
/// ``Error/notAvailable``.
public struct AgeRangeService {
    /// The singleton app instance.
    public static let shared = AgeRangeService()

    public init() {}

    /// An error that occurs when an age range request fails.
    public enum Error: Swift.Error, LocalizedError, Hashable, Sendable {
        /// The system was unable to share the person's age.
        case notAvailable
        /// The request is invalid.
        case invalidRequest
    }

    /// An enumeration that describes the declared age range.
    public enum AgeRangeDeclaration: Equatable, Hashable {
        /// The age range was declared by the person.
        case selfDeclared
        /// The age range was declared by a parent or guardian.
        case guardianDeclared
    }

    /// An option set to define parental controls enabled and shared as a part
    /// of age range declaration.
    public struct ParentalControls: OptionSet {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// The system limits communication with the person.
        ///
        /// Linux uses bit 0 (`1`) as the only published flag. Apple's exact
        /// raw value is unobserved; see `oracle-questions.tsv`.
        public static let communicationLimits = ParentalControls(rawValue: 1)

        /// The raw value of the option set, as a decimal string.
        public var description: String {
            String(rawValue)
        }
    }

    /// A person's age range based on information provided in response to an
    /// age range request.
    ///
    /// Linux never produces this from ``requestAgeRange(ageGates:_:_:in:)``.
    /// The initializer exists so tests can construct ``Response/sharing(range:)``
    /// values and exercise documented bound/control storage.
    public struct AgeRange {
        /// The lower limit of the person's age range.
        ///
        /// If `nil`, then the lower bound of the person's age range is 0.
        public var lowerBound: Int?

        /// The upper limit of the person's age range.
        ///
        /// If `nil`, then there's no upper bound of the person's age range.
        public var upperBound: Int?

        /// The sharer of the age range.
        public var ageRangeDeclaration: AgeRangeDeclaration?

        /// The parental controls turned on as a part of the response.
        ///
        /// If empty, the upper bound of the age range is not below 18 or the
        /// person is under 18 with no parental controls enabled.
        public var activeParentalControls: ParentalControls

        public init(
            lowerBound: Int? = nil,
            upperBound: Int? = nil,
            ageRangeDeclaration: AgeRangeDeclaration? = nil,
            activeParentalControls: ParentalControls = []
        ) {
            self.lowerBound = lowerBound
            self.upperBound = upperBound
            self.ageRangeDeclaration = ageRangeDeclaration
            self.activeParentalControls = activeParentalControls
        }
    }

    /// A response indicating either a person shared their age range or
    /// declined to share it.
    public enum Response {
        /// The person declined to share their age range.
        case declinedSharing
        /// The person shared the age range successfully.
        case sharing(range: AgeRange)
    }

    /// Determines an age range for the person logged onto the device.
    ///
    /// Linux never presents system UI and never returns ``Response/sharing(range:)``.
    /// Well-formed gates throw ``Error/notAvailable``. Ill-formed gates throw
    /// ``Error/invalidRequest``. The async method never suspends.
    public func requestAgeRange(
        ageGates threshold1: Int,
        _ threshold2: Int? = nil,
        _ threshold3: Int? = nil,
        in viewController: UIViewController
    ) async throws -> Response {
        try linuxRequestAgeRange(
            ageGates: threshold1,
            threshold2,
            threshold3,
            in: viewController
        )
    }

    func linuxRequestAgeRange(
        ageGates threshold1: Int,
        _ threshold2: Int?,
        _ threshold3: Int?,
        in viewController: UIViewController
    ) throws -> Response {
        _ = viewController
        try AgeRangeService.validateAgeGates(threshold1, threshold2, threshold3)
        throw Error.notAvailable
    }

    /// Local gate checks documented by the request signature and sample
    /// (`ageGates: 13, 15, 18`): each provided threshold is a positive minimum
    /// age, and later gates are strictly greater. Apple's full invalid-request
    /// matrix is unobserved.
    static func validateAgeGates(
        _ threshold1: Int,
        _ threshold2: Int?,
        _ threshold3: Int?
    ) throws {
        guard threshold1 >= 1 else {
            throw Error.invalidRequest
        }
        if let threshold2 {
            guard threshold2 >= 1, threshold2 > threshold1 else {
                throw Error.invalidRequest
            }
        }
        if let threshold3 {
            guard let threshold2 else {
                throw Error.invalidRequest
            }
            guard threshold3 >= 1, threshold3 > threshold2 else {
                throw Error.invalidRequest
            }
        }
    }
}
