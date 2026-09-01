import Foundation

/// A delegate that customizes Live Text interaction.
@MainActor
public protocol ImageAnalysisInteractionDelegate: AnyObject {
    func contentView(for interaction: ImageAnalysisInteraction) -> UIView?
    func interaction(
        _ interaction: ImageAnalysisInteraction,
        shouldBeginAt point: CGPoint,
        for interactionType: ImageAnalysisInteraction.InteractionTypes
    ) -> Bool
    func interaction(
        _ interaction: ImageAnalysisInteraction,
        highlightSelectedItemsDidChange highlightSelectedItems: Bool
    )
    func interaction(
        _ interaction: ImageAnalysisInteraction,
        liveTextButtonDidChangeToVisible visible: Bool
    )
    func contentsRect(for interaction: ImageAnalysisInteraction) -> CGRect
    func textSelectionDidChange(_ interaction: ImageAnalysisInteraction)
    func presentingViewController(for interaction: ImageAnalysisInteraction) -> UIViewController?
}

extension ImageAnalysisInteractionDelegate {
    @MainActor
    public func contentView(for interaction: ImageAnalysisInteraction) -> UIView? {
        interaction.view
    }

    @MainActor
    public func interaction(
        _ interaction: ImageAnalysisInteraction,
        shouldBeginAt point: CGPoint,
        for interactionType: ImageAnalysisInteraction.InteractionTypes
    ) -> Bool {
        _ = interaction
        _ = point
        _ = interactionType
        return true
    }

    @MainActor
    public func interaction(
        _ interaction: ImageAnalysisInteraction,
        highlightSelectedItemsDidChange highlightSelectedItems: Bool
    ) {
        _ = interaction
        _ = highlightSelectedItems
    }

    @MainActor
    public func interaction(
        _ interaction: ImageAnalysisInteraction,
        liveTextButtonDidChangeToVisible visible: Bool
    ) {
        _ = interaction
        _ = visible
    }

    @MainActor
    public func contentsRect(for interaction: ImageAnalysisInteraction) -> CGRect {
        _ = interaction
        return CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    @MainActor
    public func textSelectionDidChange(_ interaction: ImageAnalysisInteraction) {
        _ = interaction
    }

    @MainActor
    public func presentingViewController(
        for interaction: ImageAnalysisInteraction
    ) -> UIViewController? {
        _ = interaction
        return nil
    }
}

/// Live Text overlay interaction. Without on-device analysis this object is
/// inert: it stores configuration and reports no subjects, text, or detectors.
@MainActor
public final class ImageAnalysisInteraction: NSObject, UIInteraction {
    public struct InteractionTypes: OptionSet, Hashable, Sendable {
        public typealias ArrayLiteralElement = InteractionTypes
        public typealias Element = InteractionTypes
        public typealias RawValue = UInt

        public var rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let automatic = InteractionTypes(rawValue: 1 << 0)
        public static let automaticTextOnly = InteractionTypes(rawValue: 1 << 1)
        public static let textSelection = InteractionTypes(rawValue: 1 << 2)
        public static let dataDetectors = InteractionTypes(rawValue: 1 << 3)
        public static let visualLookUp = InteractionTypes(rawValue: 1 << 4)
        public static let imageSubject = InteractionTypes(rawValue: 1 << 5)
    }

    public enum SubjectUnavailable: Error, Hashable, Sendable {
        case imageUnavailable
    }

    public struct Subject: Hashable, Sendable {
        private let identifier: UUID
        private let storedBounds: CGRect

        public var bounds: CGRect { storedBounds }

        public var image: UIImage {
            get async throws {
                throw SubjectUnavailable.imageUnavailable
            }
        }

        @_spi(OpenUIKitHost)
        public init(bounds: CGRect, identifier: UUID = UUID()) {
            self.identifier = identifier
            self.storedBounds = bounds
        }

        public static func == (a: Subject, b: Subject) -> Bool {
            a.identifier == b.identifier
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }
    }

    public private(set) weak var view: UIView?
    public weak var delegate: (any ImageAnalysisInteractionDelegate)?
    public var analysis: ImageAnalysis?
    public var preferredInteractionTypes: InteractionTypes = []
    public var selectedRanges: [Range<String.Index>] = []
    public var highlightedSubjects: Set<Subject> = []
    public var selectableItemsHighlighted = false
    public var isSupplementaryInterfaceHidden = false
    public var supplementaryInterfaceFont: UIFont?
    public var supplementaryInterfaceContentInsets: UIEdgeInsets = .zero
    public var allowLongPressForDataDetectorsInTextMode = false

    private var storedContentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)

    public var activeInteractionTypes: InteractionTypes {
        guard let analysis else { return [] }
        var active = InteractionTypes()
        if preferredInteractionTypes.contains(.automatic)
            || preferredInteractionTypes.contains(.automaticTextOnly)
            || preferredInteractionTypes.contains(.textSelection)
        {
            if analysis.hasResults(for: .text) {
                active.insert(.textSelection)
            }
        }
        if preferredInteractionTypes.contains(.dataDetectors),
           analysis.hasResults(for: .text) || analysis.hasResults(for: .machineReadableCode)
        {
            active.insert(.dataDetectors)
        }
        if preferredInteractionTypes.contains(.visualLookUp),
           analysis.hasResults(for: .visualLookUp)
        {
            active.insert(.visualLookUp)
        }
        if preferredInteractionTypes.contains(.imageSubject) {
            // Subject lifting still requires Apple analysis; stay inert.
        }
        if preferredInteractionTypes.contains(.automatic), analysis.hasResults(for: .text) {
            active.insert(.automatic)
        }
        return active.intersection(preferredInteractionTypes.union(active))
    }

    public var contentsRect: CGRect {
        if let delegate {
            return delegate.contentsRect(for: self)
        }
        return storedContentsRect
    }

    public var selectedText: String { "" }

    public var selectedAttributedText: AttributedString { AttributedString() }

    public var text: String { analysis?.transcript ?? "" }

    public var liveTextButtonVisible: Bool { false }

    public var hasActiveTextSelection: Bool { !selectedRanges.isEmpty }

    public var subjects: Set<Subject> {
        get async { [] }
    }

    public override init() {
        super.init()
    }

    public convenience init(_ delegate: any ImageAnalysisInteractionDelegate) {
        self.init()
        self.delegate = delegate
    }

    public func willMove(to view: UIView?) {
        _ = view
    }

    public func didMove(to view: UIView?) {
        self.view = view
    }

    public func analysisHasText(at point: CGPoint) -> Bool {
        _ = point
        return false
    }

    public func hasDataDetector(at point: CGPoint) -> Bool {
        _ = point
        return false
    }

    public func hasInteractiveItem(at point: CGPoint) -> Bool {
        _ = point
        return false
    }

    public func hasSupplementaryInterface(at point: CGPoint) -> Bool {
        _ = point
        return false
    }

    public func hasText(at point: CGPoint) -> Bool {
        _ = point
        return false
    }

    public func resetTextSelection() {
        selectedRanges = []
        delegate?.textSelectionDidChange(self)
    }

    public func setContentsRectNeedsUpdate() {
        storedContentsRect = delegate?.contentsRect(for: self)
            ?? CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    public func setSupplementaryInterfaceHidden(_ hidden: Bool, animated: Bool) {
        _ = animated
        isSupplementaryInterfaceHidden = hidden
    }

    public func image(for subjects: Set<Subject>) async throws -> UIImage {
        _ = subjects
        throw SubjectUnavailable.imageUnavailable
    }

    public func subject(at point: CGPoint) async -> Subject? {
        _ = point
        return nil
    }
}
