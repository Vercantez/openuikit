import Foundation

extension AEAssessmentConfiguration {
    /// Keyboard autocorrect features permitted during an assessment.
    ///
    /// Raw values match pinned macios `AEAutocorrectMode`: `spelling = 1 << 0`,
    /// `punctuation = 1 << 1`. Empty (`rawValue == 0`) is "none".
    public struct AutocorrectMode: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let spelling = AutocorrectMode(rawValue: 1 << 0)
        public static let punctuation = AutocorrectMode(rawValue: 1 << 1)
    }
}

/// Process-local assessment restrictions.
///
/// Boolean `allows*` flags and `autocorrectMode` are stored on this object.
/// Linux defaults every `allows*` flag to `false` and `autocorrectMode` to
/// `[]`. Those defaults are a restrictive local policy, not a claim about
/// Darwin `init` values. Applying the configuration to the OS requires
/// `AEAssessmentSession`, which fails closed.
open class AEAssessmentConfiguration: NSObject {
    open var allowsAccessibilityLiveCaptions: Bool = false
    open var allowsAccessibilityReader: Bool = false
    open var allowsAccessibilitySpeech: Bool = false
    open var allowsAccessibilityTypingFeedback: Bool = false
    open var allowsActivityContinuation: Bool = false
    open var allowsContinuousPathKeyboard: Bool = false
    open var allowsDictation: Bool = false
    open var allowsKeyboardShortcuts: Bool = false
    open var allowsPasswordAutoFill: Bool = false
    open var allowsPredictiveKeyboard: Bool = false
    open var allowsSpellCheck: Bool = false
    open var autocorrectMode: AutocorrectMode = []

    private let storedMainParticipant = AEAssessmentParticipantConfiguration()
    private var storedByBundle: [String: AEAssessmentParticipantConfiguration] = [:]

    public override init() {
        super.init()
    }

    /// Configuration for the assessment app itself.
    ///
    /// The returned object is the stored instance (`Strong` in the pinned
    /// bindings): mutating it persists on this configuration.
    open var mainParticipantConfiguration: AEAssessmentParticipantConfiguration {
        storedMainParticipant
    }

    /// Snapshot of extra-participant configurations, keyed by application.
    ///
    /// Linux keys applications by bundle identifier. The dictionary and the
    /// participant objects are snapshots; mutating them does not change this
    /// configuration until `setConfiguration(_:for:)` is called again.
    open var configurationsByApplication: [AEAssessmentApplication: AEAssessmentParticipantConfiguration] {
        var result: [AEAssessmentApplication: AEAssessmentParticipantConfiguration] = [:]
        for (bundle, participant) in storedByBundle {
            result[AEAssessmentApplication(bundleIdentifier: bundle)] = participant.makeSnapshot()
        }
        return result
    }

    open func setConfiguration(
        _ configuration: AEAssessmentParticipantConfiguration,
        for application: AEAssessmentApplication
    ) {
        storedByBundle[application.bundleIdentifier] = configuration.makeSnapshot()
    }

    open func remove(_ application: AEAssessmentApplication) {
        storedByBundle.removeValue(forKey: application.bundleIdentifier)
    }

    func makeSnapshot() -> AEAssessmentConfiguration {
        let copy = AEAssessmentConfiguration()
        copy.allowsAccessibilityLiveCaptions = allowsAccessibilityLiveCaptions
        copy.allowsAccessibilityReader = allowsAccessibilityReader
        copy.allowsAccessibilitySpeech = allowsAccessibilitySpeech
        copy.allowsAccessibilityTypingFeedback = allowsAccessibilityTypingFeedback
        copy.allowsActivityContinuation = allowsActivityContinuation
        copy.allowsContinuousPathKeyboard = allowsContinuousPathKeyboard
        copy.allowsDictation = allowsDictation
        copy.allowsKeyboardShortcuts = allowsKeyboardShortcuts
        copy.allowsPasswordAutoFill = allowsPasswordAutoFill
        copy.allowsPredictiveKeyboard = allowsPredictiveKeyboard
        copy.allowsSpellCheck = allowsSpellCheck
        copy.autocorrectMode = autocorrectMode
        copy.mainParticipantConfiguration.allowsNetworkAccess =
            mainParticipantConfiguration.allowsNetworkAccess
        copy.mainParticipantConfiguration.configurationInfo =
            mainParticipantConfiguration.configurationInfo
        copy.mainParticipantConfiguration.isRequired =
            mainParticipantConfiguration.isRequired
        for (bundle, participant) in storedByBundle {
            copy.setConfiguration(
                participant,
                for: AEAssessmentApplication(bundleIdentifier: bundle)
            )
        }
        return copy
    }
}
