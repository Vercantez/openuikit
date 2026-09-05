import Foundation

#if canImport(UIKit)
import UIKit
#endif

public protocol ImageAnalysisInteractionDelegate: AnyObject {
#if canImport(UIKit)
    func contentView(for interaction: ImageAnalysisInteraction) -> UIView?
    func presentingViewController(for interaction: ImageAnalysisInteraction) -> UIViewController?
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
}

extension ImageAnalysisInteractionDelegate {
#if canImport(UIKit)
    public func contentView(for interaction: ImageAnalysisInteraction) -> UIView? {
        _ = interaction
        return nil
    }

    public func presentingViewController(
        for interaction: ImageAnalysisInteraction
    ) -> UIViewController? {
        _ = interaction
        return nil
    }
#endif

    public func interaction(
        _ interaction: ImageAnalysisInteraction,
        shouldBeginAt point: CGPoint,
        for interactionType: ImageAnalysisInteraction.InteractionTypes
    ) -> Bool {
        _ = interaction
        _ = point
        _ = interactionType
        return false
    }

    public func interaction(
        _ interaction: ImageAnalysisInteraction,
        highlightSelectedItemsDidChange highlightSelectedItems: Bool
    ) {
        _ = interaction
        _ = highlightSelectedItems
    }

    public func interaction(
        _ interaction: ImageAnalysisInteraction,
        liveTextButtonDidChangeToVisible visible: Bool
    ) {
        _ = interaction
        _ = visible
    }

    public func contentsRect(for interaction: ImageAnalysisInteraction) -> CGRect {
        _ = interaction
        return .zero
    }

    public func textSelectionDidChange(_ interaction: ImageAnalysisInteraction) {
        _ = interaction
    }
}

/// Live Text interaction overlay. Linux never surfaces Live Text UI, subjects,
/// or data detectors. Query methods are fail-closed (`false` / empty).
///
/// Apple annotates this type `@MainActor`. The isolated Linux host has no
/// UIKit run loop, so the Linux type is usable from synchronous tests.
public final class ImageAnalysisInteraction: NSObject {
    public struct InteractionTypes: OptionSet, Hashable, Sendable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let automatic = InteractionTypes(rawValue: 1 << 0)
        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let automaticTextOnly = InteractionTypes(rawValue: 1 << 1)
        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let textSelection = InteractionTypes(rawValue: 1 << 2)
        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let dataDetectors = InteractionTypes(rawValue: 1 << 3)
        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let visualLookUp = InteractionTypes(rawValue: 1 << 4)
        /// Linux-local bit. Darwin numeric ABI is unobserved.
        public static let imageSubject = InteractionTypes(rawValue: 1 << 5)
    }

    public enum SubjectUnavailable: Error, Hashable, Sendable {
        case imageUnavailable
    }

    public struct Subject: Hashable, Sendable {
        let identity: UUID
        let storedBounds: CGRect

        public static func == (a: Subject, b: Subject) -> Bool {
            a.identity == b.identity
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identity)
        }

        public var bounds: CGRect { storedBounds }

#if canImport(UIKit)
        public var image: UIImage {
            get async throws {
                throw SubjectUnavailable.imageUnavailable
            }
        }
#endif
    }

    public weak var delegate: (any ImageAnalysisInteractionDelegate)?
    public var analysis: ImageAnalysis?
    public var preferredInteractionTypes: InteractionTypes = []
    public var selectableItemsHighlighted = false
    public var isSupplementaryInterfaceHidden = true
    public var allowLongPressForDataDetectorsInTextMode = false
    public var highlightedSubjects: Set<Subject> = []
    public var selectedRanges: [Range<String.Index>] = []

#if canImport(UIKit)
    public private(set) weak var view: UIView?
    public var supplementaryInterfaceFont: UIFont?
    public var supplementaryInterfaceContentInsets = UIEdgeInsets()
#endif

    private var contentsRectNeedsUpdate = true
    private var cachedContentsRect = CGRect.zero

    public override init() {
        super.init()
    }

    public convenience init(_ delegate: any ImageAnalysisInteractionDelegate) {
        self.init()
        self.delegate = delegate
    }

#if canImport(UIKit)
    public func willMove(to view: UIView?) {
        if view == nil {
            self.view = nil
        }
    }

    public func didMove(to view: UIView?) {
        self.view = view
    }

    public func image(for subjects: Set<Subject>) async throws -> UIImage {
        _ = subjects
        throw SubjectUnavailable.imageUnavailable
    }
#endif

    public var activeInteractionTypes: InteractionTypes {
        guard analysis != nil else { return [] }
        return preferredInteractionTypes
    }

    public var contentsRect: CGRect {
        if !contentsRectNeedsUpdate {
            return cachedContentsRect
        }
        let rect = delegate?.contentsRect(for: self) ?? .zero
        cachedContentsRect = rect
        contentsRectNeedsUpdate = false
        return rect
    }

    public func setContentsRectNeedsUpdate() {
        contentsRectNeedsUpdate = true
    }

    public var selectedText: String { "" }

    public var selectedAttributedText: AttributedString { AttributedString() }

    public var hasActiveTextSelection: Bool { !selectedRanges.isEmpty }

    public var liveTextButtonVisible: Bool { false }

    public var text: String { analysis?.transcript ?? "" }

    public func resetTextSelection() {
        if !selectedRanges.isEmpty {
            selectedRanges = []
            delegate?.textSelectionDidChange(self)
        } else {
            selectedRanges = []
        }
    }

    public func setSupplementaryInterfaceHidden(_ hidden: Bool, animated: Bool) {
        _ = animated
        isSupplementaryInterfaceHidden = hidden
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

    public func subject(at point: CGPoint) async -> Subject? {
        _hostSubject(at: point)
    }

    public var subjects: Set<Subject> {
        get async { _hostSubjects() }
    }

    /// Synchronous peek of `subject(at:)`. The async API never suspends on
    /// Linux (no Vision subject pipeline); this SPI exists so sealed-host
    /// tests can observe the fail-closed result without a run loop.
    @_spi(OpenUIKitHost)
    public func _hostSubject(at point: CGPoint) -> Subject? {
        _ = point
        return nil
    }

    @_spi(OpenUIKitHost)
    public func _hostSubjects() -> Set<Subject> {
        []
    }
}

extension ImageAnalysisInteraction.Subject {
    @_spi(OpenUIKitHost)
    public static func hostFixture(bounds: CGRect, id: UUID = UUID()) -> ImageAnalysisInteraction.Subject {
        ImageAnalysisInteraction.Subject(identity: id, storedBounds: bounds)
    }
}
