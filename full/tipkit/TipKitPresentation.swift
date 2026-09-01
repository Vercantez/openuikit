import Foundation

/// A group of tips that presents one eligible tip at a time.
public final class TipGroup: @unchecked Sendable {
    public enum Priority: Hashable, Sendable {
        case firstAvailable
        case ordered
    }

    private let priority: Priority
    private let tips: [any Tip]

    public init(
        _ priority: Priority = .firstAvailable,
        @Tips.GroupBuilder _ builder: () -> [any Tip]
    ) {
        self.priority = priority
        self.tips = builder()
    }

    @MainActor
    public var currentTip: (any Tip)? {
        switch priority {
        case .firstAvailable:
            return tips.first { $0.shouldDisplay }
        case .ordered:
            for tip in tips {
                if tip.shouldDisplay {
                    return tip
                }
                if case .invalidated = tip.status {
                    continue
                }
                return nil
            }
            return nil
        }
    }

    public var currentTipUpdates: AsyncStream<any Tip> {
        let snapshot = tips
        let prioritySnapshot = priority
        return AsyncStream { continuation in
            if let current = Self.resolve(tips: snapshot, priority: prioritySnapshot) {
                continuation.yield(current)
            }
            continuation.finish()
        }
    }

    private static func resolve(tips: [any Tip], priority: Priority) -> (any Tip)? {
        switch priority {
        case .firstAvailable:
            return tips.first { $0.shouldDisplay }
        case .ordered:
            for tip in tips {
                if tip.shouldDisplay {
                    return tip
                }
                if case .invalidated = tip.status {
                    continue
                }
                return nil
            }
            return nil
        }
    }
}

/// The container type that holds a tip's configuration.
public struct TipViewStyleConfiguration: @unchecked Sendable {
    public let tip: any Tip

    public init(tip: any Tip) {
        self.tip = tip
    }

    @MainActor @preconcurrency
    public var image: Image? { tip.image }

    @MainActor @preconcurrency
    public var title: Text? { tip.title }

    @MainActor @preconcurrency
    public var message: Text? { tip.message }

    @MainActor @preconcurrency
    public var actions: [Tips.Action] { tip.actions }
}

#if canImport(SwiftUI)

@MainActor @preconcurrency
public protocol TipViewStyle {
    associatedtype Body: View
    typealias Configuration = TipViewStyleConfiguration
    @ViewBuilder @MainActor @preconcurrency
    func makeBody(configuration: Self.Configuration) -> Self.Body
}

@MainActor @preconcurrency
public struct MiniTipViewStyle: TipViewStyle {
    public init() {}

    @MainActor @preconcurrency
    public func makeBody(configuration: MiniTipViewStyle.Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = configuration.title {
                title.font(.headline)
            }
            if let message = configuration.message {
                message.font(.subheadline)
            }
        }
    }
}

extension TipViewStyle where Self == MiniTipViewStyle {
    nonisolated public static var miniTip: MiniTipViewStyle { MiniTipViewStyle() }
}

@MainActor @preconcurrency
public struct TipView<Content: Tip>: View {
    private let tip: AnyTip?
    private let isPresented: Binding<Bool>?
    private let arrowEdge: Edge?
    private let action: @MainActor (Tips.Action) -> Void

    public var body: some View {
        if let tip, tip.shouldDisplay {
            VStack(alignment: .leading, spacing: 8) {
                tip.title
                if let message = tip.message {
                    message
                }
                ForEach(Array(tip.actions.enumerated()), id: \.offset) { _, item in
                    Button(action: {
                        item.handler()
                        action(item)
                    }) {
                        item.label()
                    }
                }
            }
        }
    }
}

extension TipView where Content == AnyTip {
    @MainActor @preconcurrency
    public init(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        arrowEdge: Edge? = nil,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) {
        self.tip = tip.map(AnyTip.init)
        self.isPresented = isPresented
        self.arrowEdge = arrowEdge
        self.action = action
        _ = isPresented
        _ = arrowEdge
    }

    @MainActor @preconcurrency
    public init<AnchorID: Hashable>(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        arrowEdge: Edge? = nil,
        anchorID: AnchorID,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) {
        self.init(tip, isPresented: isPresented, arrowEdge: arrowEdge, action: action)
        _ = anchorID
    }

    @MainActor @preconcurrency
    public init(
        _ tip: (any Tip)?,
        arrowEdge: Edge? = nil,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) {
        self.init(tip, isPresented: nil, arrowEdge: arrowEdge, action: action)
    }
}

extension View {
    @preconcurrency nonisolated
    public func popoverTip(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdge: Edge? = nil,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) -> some View {
        _ = (tip, isPresented, attachmentAnchor, arrowEdge, action)
        return self
    }

    @preconcurrency nonisolated
    public func popoverTip(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds),
        arrowEdges: Edge.Set,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) -> some View {
        _ = (tip, isPresented, attachmentAnchor, arrowEdges, action)
        return self
    }

    @preconcurrency nonisolated
    public func popoverTip(
        _ tip: (any Tip)?,
        arrowEdge: Edge? = nil,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) -> some View {
        popoverTip(tip, isPresented: nil, arrowEdge: arrowEdge, action: action)
    }

    nonisolated public func tipViewStyle(_ style: some TipViewStyle) -> some View {
        _ = style
        return self
    }

    nonisolated public func tipImageSize(_ size: CGSize) -> some View {
        _ = size
        return self
    }

    nonisolated public func tipBackground<S: ShapeStyle>(_ style: S) -> some View {
        _ = style
        return self
    }

    nonisolated public func tipImageStyle<S: ShapeStyle>(_ style: S) -> some View {
        _ = style
        return self
    }

    nonisolated public func tipImageStyle<S1: ShapeStyle, S2: ShapeStyle>(
        _ primary: S1,
        _ secondary: S2
    ) -> some View {
        _ = (primary, secondary)
        return self
    }

    nonisolated public func tipImageStyle<S1: ShapeStyle, S2: ShapeStyle, S3: ShapeStyle>(
        _ primary: S1,
        _ secondary: S2,
        _ tertiary: S3
    ) -> some View {
        _ = (primary, secondary, tertiary)
        return self
    }

    nonisolated public func tipCornerRadius(
        _ cornerRadius: CGFloat,
        antialiased: Bool = true
    ) -> some View {
        _ = (cornerRadius, antialiased)
        return self
    }

    nonisolated public func tipBackgroundInteraction(
        _ interaction: PresentationBackgroundInteraction
    ) -> some View {
        _ = interaction
        return self
    }

    nonisolated public func tipAnchor<AnchorID: Hashable & Sendable>(_ id: AnchorID) -> some View {
        _ = id
        return self
    }
}

#else

@MainActor @preconcurrency
public struct MiniTipViewStyle: Sendable {
    nonisolated public init() {}

    nonisolated public static var miniTip: MiniTipViewStyle { MiniTipViewStyle() }
}

@MainActor @preconcurrency
public struct TipView<Content: Tip>: @unchecked Sendable {
    public let portableTip: AnyTip?
    public let portableIsPresented: Binding<Bool>?
    public let portableArrowEdge: Edge?
    let action: @MainActor (Tips.Action) -> Void

    @MainActor @preconcurrency
    public init(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        arrowEdge: Edge? = nil,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) where Content == AnyTip {
        portableTip = tip.map { AnyTip($0) }
        portableIsPresented = isPresented
        portableArrowEdge = arrowEdge
        self.action = action
    }

    @MainActor @preconcurrency
    public init<AnchorID: Hashable>(
        _ tip: (any Tip)?,
        isPresented: Binding<Bool>? = nil,
        arrowEdge: Edge? = nil,
        anchorID: AnchorID,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) where Content == AnyTip {
        self.init(tip, isPresented: isPresented, arrowEdge: arrowEdge, action: action)
        _ = anchorID
    }

    @MainActor @preconcurrency
    public init(
        _ tip: (any Tip)?,
        arrowEdge: Edge? = nil,
        action: @escaping @MainActor (Tips.Action) -> Void = { _ in }
    ) where Content == AnyTip {
        self.init(tip, isPresented: nil, arrowEdge: arrowEdge, action: action)
    }

    @_spi(OpenUIKitHost)
    public var portableShouldDisplay: Bool {
        portableTip?.shouldDisplay ?? false
    }
}

#endif
