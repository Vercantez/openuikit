import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// A delegate that customizes Live Text interaction.
@MainActor
public protocol ImageAnalysisInteractionDelegate: AnyObject {
#if canImport(UIKit)
    func contentView(for interaction: ImageAnalysisInteraction) -> UIView?
#endif
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
#if canImport(UIKit)
    func presentingViewController(for interaction: ImageAnalysisInteraction) -> UIViewController?
#endif
}

extension ImageAnalysisInteractionDelegate {
#if canImport(UIKit)
    @MainActor
    public func contentView(for interaction: ImageAnalysisInteraction) -> UIView? {
        interaction.view
    }
#endif

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
        // Apple's default (unit rect vs view size, nil-view) is unattested.
        return .zero
    }

    @MainActor
    public func textSelectionDidChange(_ interaction: ImageAnalysisInteraction) {
        _ = interaction
    }

#if canImport(UIKit)
    @MainActor
    public func presentingViewController(
        for interaction: ImageAnalysisInteraction
    ) -> UIViewController? {
        _ = interaction
        return nil
    }
#endif
}

/// Live Text overlay interaction. Without on-device analysis this object is
/// inert: it stores configuration and reports no subjects, text, or detectors.
@MainActor
public final class ImageAnalysisInteraction: NSObject {
    public struct InteractionTypes: OptionSet, Hashable, Sendable {
        public typealias ArrayLiteralElement = InteractionTypes
        public typealias Element = InteractionTypes
        public typealias RawValue = UInt

        /// Placeholder bits. Apple's raw layout is unattested.
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

#if canImport(UIKit)
        public var image: UIImage {
            get async throws {
                throw SubjectUnavailable.imageUnavailable
            }
        }
#endif

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

#if canImport(UIKit)
    public private(set) weak var view: UIView?
    public var supplementaryInterfaceFont: UIFont?
    public var supplementaryInterfaceContentInsets: UIEdgeInsets = .zero
#endif
    public weak var delegate: (any ImageAnalysisInteractionDelegate)?
    public var analysis: ImageAnalysis?
    /// Apple's zero-argument default is unattested; Linux starts empty.
    public var preferredInteractionTypes = InteractionTypes()
    public var selectedRanges: [Range<String.Index>] = []
    public var highlightedSubjects: Set<Subject> = []
    public var selectableItemsHighlighted = false
    public var isSupplementaryInterfaceHidden = false
    public var allowLongPressForDataDetectorsInTextMode = false

    private var storedContentsRect: CGRect = .zero

    public var activeInteractionTypes: InteractionTypes {
        guard let analysis else { return [] }
        var active = InteractionTypes()
        if preferredInteractionTypes.contains(.automatic)
            || preferredInteractionTypes.contains(.automaticTextOnly)
            || preferredInteractionTypes.contains(.textSelection),
           analysis.hasResults(for: .text)
        {
            active.insert(.textSelection)
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

#if canImport(UIKit)
    public func willMove(to view: UIView?) {
        _ = view
    }

    public func didMove(to view: UIView?) {
        self.view = view
    }
#endif

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
        storedContentsRect = delegate?.contentsRect(for: self) ?? .zero
    }

    public func setSupplementaryInterfaceHidden(_ hidden: Bool, animated: Bool) {
        _ = animated
        isSupplementaryInterfaceHidden = hidden
    }

#if canImport(UIKit)
    public func image(for subjects: Set<Subject>) async throws -> UIImage {
        _ = subjects
        throw SubjectUnavailable.imageUnavailable
    }
#endif

    public func subject(at point: CGPoint) async -> Subject? {
        _ = point
        return nil
    }
}

#if canImport(UIKit)
extension ImageAnalysisInteraction: UIInteraction {}
#endif
