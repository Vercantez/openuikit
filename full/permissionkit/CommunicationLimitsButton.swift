import Foundation

/// SwiftUI overlay control. On Linux the button stores the question and
/// renders `label` without presenting an Apple permission sheet. Apple's
/// overlay is `@MainActor`; the sealed host runner is nonisolated, so this
/// Linux type is not actor-isolated.
public struct CommunicationLimitsButton<Label: View>: View {
    public let question: PermissionQuestion<CommunicationTopic>
    private let label: () -> Label

    public init(
        question: PermissionQuestion<CommunicationTopic>,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.question = question
        self.label = label
    }

    public var body: Label {
        label()
    }
}
