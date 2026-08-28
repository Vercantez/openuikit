// A stub FocusAppServices (Mozilla Nimbus), so focus-ios can be compiled from
// source without the prebuilt FocusRustComponents.xcframework.
//
// THIS ONE IS NOT A NO-OP, AND THE DIFFERENCE MATTERS. Glean next door is
// write-only telemetry, so silence is behaviourally correct. Nimbus is a
// feature-flag service: the app READS values from it and BRANCHES ON THEM. A
// no-op returning `false`/zero would be inventing an answer, and the screen
// would differ from the shipping app for a reason nothing records.
//
// SO THE VALUES COME FROM THE APP'S OWN LOCAL DEFAULTS, NOT FROM ME.
// focus-ios/nimbus.fml.yaml is the feature manifest the real build compiles
// into `AppNimbus`, and it carries the default for every variable:
//
//     features:
//       nimbus-validation:
//         variables:
//           bold-tip-title:   type: Boolean   default: true      <-- mirrored
//       onboarding-variables:
//         variables:
//           show-new-onboarding: type: Boolean  default: false
//         defaults:
//           - channel: developer
//             value: { show-new-onboarding: true }
//
// That is exactly what real Nimbus returns when no experiment is enrolled and
// no server has been reached — which is the state of this build permanently.
// So these are not stand-ins for the real answers; offline, they ARE the real
// answers.
//
// MEASURED READ SURFACE: the app consults `AppNimbus` in exactly ONE place —
// TipViewController.swift:14, `features.nimbusValidation.value().boldTipTitle`,
// used to pick a bold vs medium font on the tips label. `show-new-onboarding`
// is NOT read from Nimbus at all: AppDelegate.swift:56 reads that decision from
// UserDefaults. It is mirrored below anyway because the manifest declares it and
// a partial mirror is the kind of gap that surfaces later as a wrong screen.
//
// WHAT DIES LOUDLY: everything that would have talked to the network or the
// Rust database. Fetching experiments, opting in or out, and enumerating
// available experiments cannot be answered offline, and answering them with an
// empty list would make the internal settings screens claim, falsely, that the
// user is enrolled in nothing. Those are `fatalError` here, and the two screens
// that call them are internal debug UI that the launch path never reaches.

import Foundation

// MARK: - The values the app reads. Mirrored from nimbus.fml.yaml.

public struct NimbusValidationFeature {
    /// nimbus.fml.yaml -> features.nimbus-validation.variables.bold-tip-title
    public let boldTipTitle: Bool
    public init(boldTipTitle: Bool = true) { self.boldTipTitle = boldTipTitle }
}

public struct OnboardingVariablesFeature {
    /// nimbus.fml.yaml -> features.onboarding-variables.variables.show-new-onboarding
    /// Release/beta default is false; the `developer` channel overrides to true.
    public let showNewOnboarding: Bool
    public init(showNewOnboarding: Bool = false) { self.showNewOnboarding = showNewOnboarding }
}

public final class FeatureHolder<T> {
    private let make: () -> T
    public init(_ make: @escaping () -> T) { self.make = make }
    public func value() -> T { make() }
}

public final class AppNimbusFeatures {
    public let nimbusValidation = FeatureHolder { NimbusValidationFeature() }
    public let onboardingVariables = FeatureHolder { OnboardingVariablesFeature() }
    public init() {}
}

public final class AppNimbus {
    public static let shared = AppNimbus()
    public let features = AppNimbusFeatures()
    private init() {}
}

// MARK: - Types the app names in signatures

public struct AvailableExperiment {
    public let slug: String
    public let userFacingName: String
    public let userFacingDescription: String
    public let branches: [ExperimentBranch]
    public init(slug: String, userFacingName: String = "",
                userFacingDescription: String = "", branches: [ExperimentBranch] = []) {
        self.slug = slug
        self.userFacingName = userFacingName
        self.userFacingDescription = userFacingDescription
        self.branches = branches
    }
}

public struct ExperimentBranch {
    public let slug: String
    public let ratio: Int32
    public init(slug: String, ratio: Int32 = 1) { self.slug = slug; self.ratio = ratio }
}

public struct NimbusAppSettings {
    public let appName: String
    public let channel: String
    public let customTargetingAttributes: [String: Any]
    public init(appName: String, channel: String,
                customTargetingAttributes: [String: Any] = [:]) {
        self.appName = appName
        self.channel = channel
        self.customTargetingAttributes = customTargetingAttributes
    }
}

public struct NimbusServerSettings {
    public let url: URL
    public let collection: String
    public init(url: URL, collection: String) { self.url = url; self.collection = collection }
}

public let remoteSettingsCollection = "nimbus-mobile-experiments"

// MARK: - The service surface
//
// Reads that CAN be answered offline are answered. Reads that CANNOT are
// `fatalError`, because the alternative — an empty list — is a confident false
// statement about what the user is enrolled in.

public protocol NimbusInterface: AnyObject {
    func fetchExperiments()
    func getAvailableExperiments() -> [AvailableExperiment]
    func getExperimentBranch(experimentId: String) -> String?
    func optIn(_ experimentId: String, branch: String)
    func optOut(_ experimentId: String)
}

public final class NimbusDisabled: NimbusInterface {
    public init() {}

    /// Correct offline: there is no server, so nothing is fetched and the
    /// manifest defaults above remain in force. That IS real Nimbus's behaviour
    /// when the network is unavailable, so it is not a stand-in.
    public func fetchExperiments() {}

    public func getAvailableExperiments() -> [AvailableExperiment] {
        fatalError("Nimbus stub: getAvailableExperiments() cannot be answered without "
                 + "the Rust component. Returning [] would assert that the user is "
                 + "enrolled in no experiments, which this build does not know.")
    }
    public func getExperimentBranch(experimentId: String) -> String? {
        fatalError("Nimbus stub: getExperimentBranch(\(experimentId)) needs the Rust "
                 + "component; nil here would read as 'not enrolled', which is a claim.")
    }
    public func optIn(_ experimentId: String, branch: String) {
        fatalError("Nimbus stub: optIn(\(experimentId)) needs the Rust component.")
    }
    public func optOut(_ experimentId: String) {
        fatalError("Nimbus stub: optOut(\(experimentId)) needs the Rust component.")
    }
}

public enum Nimbus {
    public static func defaultDatabasePath() -> String? {
        // A real path is required only so NimbusBuilder has something to hold;
        // nothing in this build opens it.
        let dir = FileManager.default.urls(for: .applicationSupportDirectory,
                                           in: .userDomainMask).first
        return dir?.appendingPathComponent("nimbus.db").path
    }
}

public final class NimbusBuilder {
    public init(dbPath: String) {}
    public func with(url: String?) -> NimbusBuilder { self }
    public func with(bundles: [Bundle]) -> NimbusBuilder { self }
    public func with(featureManifest: AppNimbus) -> NimbusBuilder { self }
    public func with(commandLineArgs: [String]) -> NimbusBuilder { self }
    public func using(previewCollection: Bool) -> NimbusBuilder { self }
    public func with(initialExperiments: URL?) -> NimbusBuilder { self }
    public func isFirstRun(_ value: Bool) -> NimbusBuilder { self }
    public func build(appInfo: NimbusAppSettings) -> NimbusInterface { NimbusDisabled() }
}

// MARK: - Rust plumbing the wrapper initialises

public enum LogLevel { case trace, debug, info, warn, error }
public typealias LogCallback = (LogLevel, String?, String) -> Bool

public final class RustLog {
    public static let shared = RustLog()
    private init() {}
    /// True, because there is no Rust log to enable and the caller throws on false.
    public func tryEnable(_ callback: @escaping LogCallback) -> Bool { true }
}

public final class Viaduct {
    public static let shared = Viaduct()
    private init() {}
    public func useReqwestBackend() {}
}
