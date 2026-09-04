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
    public var activityID: String
    public var attributes: Attributes
    public var state: Attributes.ContentState
    public var isStale: Bool

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
}

public struct DynamicIslandExpandedRegionPosition: Hashable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let leading = Self(0)
    public static let trailing = Self(1)
    public static let center = Self(2)
    public static let bottom = Self(3)
}

public struct DynamicIslandExpandedRegionVerticalPlacement: Equatable, Sendable {
    private let rawValue: UInt8
    private init(_ rawValue: UInt8) { self.rawValue = rawValue }

    public static let `default` = Self(0)
    public static let belowIfTooWide = Self(1)
}

public struct DynamicIslandExpandedRegion<Content: View>: @unchecked Sendable {
    public init(
        _ position: DynamicIslandExpandedRegionPosition,
        priority: Double = 0,
        @ViewBuilder content: () -> Content
    ) {
        _ = position
        _ = priority
        _ = content
    }

    public func contentMargins(_ edges: UInt = 0, _ length: Double) -> DynamicIslandExpandedRegion<Content> {
        _ = edges
        _ = length
        return self
    }
}

public struct DynamicIslandExpandedContent<Content: View>: @unchecked Sendable {
    public init() {}
}

@resultBuilder
public enum DynamicIslandExpandedContentBuilder {
    public static func buildPartialBlock<C: View>(
        first: DynamicIslandExpandedRegion<C>
    ) -> DynamicIslandExpandedContent<C> {
        _ = first
        return DynamicIslandExpandedContent()
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
        _ = next
        return accumulated
    }

    public static func buildPartialBlock<C0: View, C1: View>(
        accumulated: DynamicIslandExpandedContent<C0>,
        next: DynamicIslandExpandedContent<C1>
    ) -> DynamicIslandExpandedContent<C0> {
        _ = next
        return accumulated
    }
}

public struct DynamicIsland: @unchecked Sendable {
    public init<Expanded: View, CompactLeading: View, CompactTrailing: View, Minimal: View>(
        expanded: () -> DynamicIslandExpandedContent<Expanded> = { DynamicIslandExpandedContent() },
        compactLeading: () -> CompactLeading,
        compactTrailing: () -> CompactTrailing,
        minimal: () -> Minimal
    ) {
        _ = expanded
        _ = compactLeading
        _ = compactTrailing
        _ = minimal
    }

    public func keylineTint(_ color: Color?) -> DynamicIsland {
        _ = color
        return self
    }

    public func contentMargins(
        _ edges: UInt = 0,
        _ length: Double,
        for mode: DynamicIslandMode
    ) -> DynamicIsland {
        _ = edges
        _ = length
        _ = mode
        return self
    }

    public func widgetURL(_ url: URL?) -> DynamicIsland {
        _ = url
        return self
    }
}

@MainActor
public struct ActivityConfiguration<Attributes: ActivityAttributes>: @unchecked Sendable {
    @_spi(OpenUIKitHost) public let portableDescriptor: WidgetConfigurationDescriptor

    public init<Content: View>(
        for attributesType: Attributes.Type,
        @ViewBuilder content: @escaping (ActivityViewContext<Attributes>) -> Content,
        dynamicIsland: @escaping (ActivityViewContext<Attributes>) -> DynamicIsland
    ) {
        portableDescriptor = WidgetConfigurationDescriptor(
            kind: String(describing: attributesType)
        )
        _ = content
        _ = dynamicIsland
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
