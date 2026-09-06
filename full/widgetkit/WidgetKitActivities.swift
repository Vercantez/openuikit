#if canImport(SwiftUI)
import SwiftUI
#endif
import Foundation

// MARK: - Live Activities / Dynamic Island (no ActivityKit daemon on Linux)

public enum ActivityFamily: Int, Sendable, CustomStringConvertible {
    case small = 0
    case medium = 1

    public var description: String {
        switch self {
        case .small: "small"
        case .medium: "medium"
        }
    }
}

public struct ActivityViewContext<Attributes: ActivityAttributes>: @unchecked Sendable {
    public let activityID: String
    public let attributes: Attributes
    public let state: Attributes.ContentState
    public let isStale: Bool

    public init(
        activityID: String,
        attributes: Attributes,
        state: Attributes.ContentState,
        isStale: Bool = false
    ) {
        self.activityID = activityID
        self.attributes = attributes
        self.state = state
        self.isStale = isStale
    }
}

@_spi(OpenUIKitHost)
public enum ActivityViewHostError: Error, Equatable, Sendable {
    case emptyActivityID
}

/// Process-local Live Activity context factory. Linux has no ActivityKit
/// daemon; stale/live is host-installed state, never an Apple activity session.
@_spi(OpenUIKitHost)
public enum ActivityViewHost {
    private static let lock = NSLock()
    private static var staleIDs: Set<String> = []

    public static func makeContext<Attributes: ActivityAttributes>(
        activityID: String,
        attributes: Attributes,
        state: Attributes.ContentState,
        isStale: Bool = false
    ) throws -> ActivityViewContext<Attributes> {
        guard !activityID.isEmpty else {
            throw ActivityViewHostError.emptyActivityID
        }
        lock.lock()
        let markedStale = staleIDs.contains(activityID)
        lock.unlock()
        return ActivityViewContext(
            activityID: activityID,
            attributes: attributes,
            state: state,
            isStale: isStale || markedStale
        )
    }

    public static func markStale(activityID: String) {
        lock.lock()
        staleIDs.insert(activityID)
        lock.unlock()
    }

    public static func isMarkedStale(activityID: String) -> Bool {
        lock.lock()
        let value = staleIDs.contains(activityID)
        lock.unlock()
        return value
    }

    public static func resetProcessLocalState() {
        lock.lock()
        staleIDs = []
        lock.unlock()
    }
}

public enum ActivityPreviewViewKind: Sendable, Hashable {
    public enum DynamicIslandPreviewViewState: Sendable, Hashable {
        case compact
        case minimal
        case expanded
    }

    case content
    case dynamicIsland(DynamicIslandPreviewViewState)
}

public struct DynamicIslandMode: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let compactLeading = Self(0)
    public static let compactTrailing = Self(1)
    public static let minimal = Self(2)
    public static let expanded = Self(3)

    @_spi(OpenUIKitHost)
    public var portableName: String {
        switch rawValue {
        case 0: "compactLeading"
        case 1: "compactTrailing"
        case 2: "minimal"
        case 3: "expanded"
        default: "unknown"
        }
    }
}

public struct DynamicIslandExpandedRegionPosition: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let leading = Self(0)
    public static let trailing = Self(1)
    public static let center = Self(2)
    public static let bottom = Self(3)

    @_spi(OpenUIKitHost)
    public var portableName: String {
        switch rawValue {
        case 0: "leading"
        case 1: "trailing"
        case 2: "center"
        case 3: "bottom"
        default: "unknown"
        }
    }
}

public struct DynamicIslandExpandedRegionVerticalPlacement: Equatable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let `default` = Self(0)
    public static let belowIfTooWide = Self(1)

    @_spi(OpenUIKitHost)
    public var portableName: String {
        switch rawValue {
        case 0: "default"
        case 1: "belowIfTooWide"
        default: "unknown"
        }
    }
}

@_spi(OpenUIKitHost)
public struct DynamicIslandExpandedRegionDescriptor: Equatable, Sendable {
    public var position: DynamicIslandExpandedRegionPosition
    public var priority: Double
    public var marginEdges: Int
    public var marginLength: Double?

    public init(
        position: DynamicIslandExpandedRegionPosition,
        priority: Double = 0,
        marginEdges: Int = Edge.Set.all.rawValue,
        marginLength: Double? = nil
    ) {
        self.position = position
        self.priority = priority
        self.marginEdges = marginEdges
        self.marginLength = marginLength
    }
}

@_spi(OpenUIKitHost)
public struct DynamicIslandDescriptor: Equatable, Sendable {
    public var compactLeading: String?
    public var compactTrailing: String?
    public var minimal: String?
    public var widgetURL: URL?
    public var hasKeylineTint: Bool
    public var regions: [DynamicIslandExpandedRegionDescriptor]
    public var margins: [String: Double]

    public init(
        compactLeading: String? = nil,
        compactTrailing: String? = nil,
        minimal: String? = nil,
        widgetURL: URL? = nil,
        hasKeylineTint: Bool = false,
        regions: [DynamicIslandExpandedRegionDescriptor] = [],
        margins: [String: Double] = [:]
    ) {
        self.compactLeading = compactLeading
        self.compactTrailing = compactTrailing
        self.minimal = minimal
        self.widgetURL = widgetURL
        self.hasKeylineTint = hasKeylineTint
        self.regions = regions
        self.margins = margins
    }
}

private func _textContent<V: View>(_ view: V) -> String? {
    (view as? Text)?.content
}

public struct DynamicIslandExpandedRegion<Content: View>: @unchecked Sendable {
    @_spi(OpenUIKitHost) public var portableDescriptor: DynamicIslandExpandedRegionDescriptor
    public let content: Content

    public init(
        _ position: DynamicIslandExpandedRegionPosition,
        priority: Double = 0,
        @ViewBuilder content: () -> Content
    ) {
        portableDescriptor = DynamicIslandExpandedRegionDescriptor(
            position: position,
            priority: priority
        )
        self.content = content()
    }

    public func contentMargins(
        _ edges: Edge.Set = .all,
        _ length: Double
    ) -> DynamicIslandExpandedRegion<Content> {
        var copy = self
        copy.portableDescriptor.marginEdges = edges.rawValue
        copy.portableDescriptor.marginLength = length
        return copy
    }
}

public struct DynamicIslandExpandedContent<Content: View>: @unchecked Sendable {
    @_spi(OpenUIKitHost) public var portableRegions: [DynamicIslandExpandedRegionDescriptor]

    public init() {
        portableRegions = []
    }

    @_spi(OpenUIKitHost)
    public init(regions: [DynamicIslandExpandedRegionDescriptor]) {
        portableRegions = regions
    }
}

@resultBuilder
public struct DynamicIslandExpandedContentBuilder {
    public static func buildPartialBlock<C: View>(
        first: DynamicIslandExpandedRegion<C>
    ) -> DynamicIslandExpandedContent<C> {
        DynamicIslandExpandedContent(regions: [first.portableDescriptor])
    }

    public static func buildPartialBlock<C: View>(
        first: DynamicIslandExpandedContent<C>
    ) -> DynamicIslandExpandedContent<C> {
        first
    }

    public static func buildPartialBlock<C0: View, C1: View>(
        accumulated: DynamicIslandExpandedContent<C0>,
        next: DynamicIslandExpandedRegion<C1>
    ) -> DynamicIslandExpandedContent<C0> {
        var regions = accumulated.portableRegions
        regions.append(next.portableDescriptor)
        return DynamicIslandExpandedContent(regions: regions)
    }

    public static func buildPartialBlock<C0: View, C1: View>(
        accumulated: DynamicIslandExpandedContent<C0>,
        next: DynamicIslandExpandedContent<C1>
    ) -> DynamicIslandExpandedContent<C0> {
        DynamicIslandExpandedContent(
            regions: accumulated.portableRegions + next.portableRegions
        )
    }
}

public struct DynamicIsland: @unchecked Sendable {
    @_spi(OpenUIKitHost) public var portableDescriptor: DynamicIslandDescriptor

    public init<Expanded: View, CompactLeading: View, CompactTrailing: View, Minimal: View>(
        @DynamicIslandExpandedContentBuilder expanded: () -> DynamicIslandExpandedContent<Expanded> = {
            DynamicIslandExpandedContent()
        },
        compactLeading: () -> CompactLeading,
        compactTrailing: () -> CompactTrailing,
        minimal: () -> Minimal
    ) {
        portableDescriptor = DynamicIslandDescriptor(
            compactLeading: _textContent(compactLeading()),
            compactTrailing: _textContent(compactTrailing()),
            minimal: _textContent(minimal()),
            regions: expanded().portableRegions
        )
    }

    public func keylineTint(_ color: Color?) -> DynamicIsland {
        var copy = self
        copy.portableDescriptor.hasKeylineTint = color != nil
        return copy
    }

    public func contentMargins(
        _ edges: Edge.Set = .all,
        _ length: Double,
        for mode: DynamicIslandMode
    ) -> DynamicIsland {
        _ = edges
        var copy = self
        var margins = portableDescriptor.margins
        margins[mode.portableName] = length
        copy.portableDescriptor.margins = margins
        return copy
    }

    public func widgetURL(_ url: URL?) -> DynamicIsland {
        var copy = self
        copy.portableDescriptor.widgetURL = url
        return copy
    }
}

@resultBuilder
public struct PreviewActivityBuilder<A: ActivityAttributes> {
    public static func buildExpression(_ contentState: A.ContentState) -> [A.ContentState] {
        [contentState]
    }

    public static func buildPartialBlock(first: [A.ContentState]) -> [A.ContentState] {
        first
    }

    public static func buildPartialBlock(
        accumulated: [A.ContentState],
        next: [A.ContentState]
    ) -> [A.ContentState] {
        accumulated + next
    }

    public static func buildArray(_ components: [[A.ContentState]]) -> [A.ContentState] {
        Array(components.joined())
    }
}

@resultBuilder
public struct PreviewTimelineBuilder {
    public static func buildExpression(_ entry: some TimelineEntry) -> [any TimelineEntry] {
        [entry]
    }

    public static func buildPartialBlock(first: [any TimelineEntry]) -> [any TimelineEntry] {
        first
    }

    public static func buildPartialBlock(
        accumulated: [any TimelineEntry],
        next: [any TimelineEntry]
    ) -> [any TimelineEntry] {
        accumulated + next
    }

    public static func buildArray(_ components: [[any TimelineEntry]]) -> [any TimelineEntry] {
        Array(components.joined())
    }
}

public struct ActivityConfiguration<Attributes: ActivityAttributes>: @unchecked Sendable {
    @_spi(OpenUIKitHost) public let portableDescriptor: WidgetConfigurationDescriptor
    private let islandBuilder: (ActivityViewContext<Attributes>) -> DynamicIsland

    public init<Content: View>(
        for attributesType: Attributes.Type,
        @ViewBuilder content: @escaping (ActivityViewContext<Attributes>) -> Content,
        dynamicIsland: @escaping (ActivityViewContext<Attributes>) -> DynamicIsland
    ) {
        portableDescriptor = WidgetConfigurationDescriptor(
            kind: String(describing: attributesType)
        )
        _ = content
        islandBuilder = dynamicIsland
    }

    @_spi(OpenUIKitHost)
    public func portableDynamicIsland(
        _ context: ActivityViewContext<Attributes>
    ) -> DynamicIsland {
        islandBuilder(context)
    }
}

#if !canImport(SwiftUI) || OPENUIKIT_PORTABLE_SWIFTUI
extension ActivityConfiguration: WidgetConfiguration {
    public typealias Body = Never
    public var body: Never {
        fatalError("Widget configurations are host-driven")
    }
}
#else
extension ActivityConfiguration: SwiftUI.WidgetConfiguration {
    public typealias Body = Never
    public var body: Never {
        fatalError("Widget configurations are host-driven")
    }
}
#endif
