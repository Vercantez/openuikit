import Foundation
#if canImport(Observation)
import Observation
#endif

#if !canImport(SwiftUI)

public protocol Publisher {
    associatedtype Output
    associatedtype Failure: Error
}
public protocol Transferable {}
public struct LocalizedStringResource: ExpressibleByStringLiteral, Sendable {
    public var text: String
    public init(_ text: String) { self.text = text }
    public init(stringLiteral value: String) { self.text = value }
}
public struct LocalizedStringKey: ExpressibleByStringLiteral, Sendable {
    public var text: String
    public init(_ text: String) { self.text = text }
    public init(stringLiteral value: String) { self.text = value }
}

public protocol AXChartDescriptorRepresentable {}
public protocol AccessibilityRotorContent {}
public protocol AttributeScope {}
public protocol AttributedTextFormattingDefinition {}
public protocol ButtonStyle {}
public protocol ContentMode {}
public protocol ControlGroupStyle {}
public protocol CoordinateSpaceProtocol {}
public protocol CustomHoverEffect {}
public protocol CustomizableToolbarContent {}
public protocol DatePickerStyle {}
public protocol DisclosureGroupStyle {}
public protocol DiscreteSymbolEffect {}
public protocol DropDelegate {}
public protocol FileDocument {}
public protocol FocusInteractions {}
public protocol FormStyle {}
public protocol GaugeStyle {}
public protocol Gesture {}
public protocol GroupBoxStyle {}
public protocol IndefiniteSymbolEffect {}
public protocol IndexViewStyle {}
public protocol InsettableShape {}
public protocol Keyframes {}
public protocol LabelStyle {}
public protocol LabeledContentStyle {}
public protocol LayoutValueKey { associatedtype Value }
public protocol ListStyle {}
public protocol LocalizedError {}
public protocol MatchedTransitionSourceConfiguration {}
public protocol MenuStyle {}
public protocol MutableCollection {}
public protocol NavigationSplitViewStyle {}
public protocol NavigationTransition {}
public protocol NavigationViewStyle {}
public protocol ObservableObject {}
public protocol PickerStyle {}
public protocol PreferenceKey { associatedtype Value }
public protocol PresentationSizing {}
public protocol PreviewContext {}
public protocol PrimitiveButtonStyle {}
public protocol ProgressViewStyle {}
public protocol ReferenceFileDocument {}
public protocol RoundedRectangularShape {}
public protocol ScrollTargetBehavior {}
public protocol SearchScopeActivation {}
public protocol Shape {}
public struct DefaultGlassEffectShape: Shape {}
public protocol ShapeStyle {}
public protocol SymbolEffect {}
public protocol TabViewStyle {}
public protocol TableStyle {}
public protocol TaskExecutor {}
public protocol TextEditorStyle {}
public protocol TextFieldStyle {}
public protocol TextRenderer {}
public protocol TextSelectability {}
public protocol Tip {}
public protocol TipViewStyle {}
public protocol ToggleStyle {}
public protocol ToolbarContent {}
public protocol Transition {}
public protocol UIGestureRecognizerRepresentable {}
public protocol UTType {}
public protocol VisualEffect {}
public struct DefaultHoverEffect: CustomHoverEffect { public init() {} }
extension CustomHoverEffect where Self == DefaultHoverEffect {
    public static var automatic: DefaultHoverEffect { DefaultHoverEffect() }
}
public struct LocalCoordinateSpace: CoordinateSpaceProtocol { public init() {} }
extension CoordinateSpaceProtocol where Self == LocalCoordinateSpace {
    public static var local: LocalCoordinateSpace { LocalCoordinateSpace() }
}

public struct AXCustomContent: Sendable, Hashable {
    public init() {}
    public struct Importance: Sendable, Hashable {
        public init() {}
        public static let `default` = Importance()
    }
}

public struct AccessibilityActionCategory: Sendable, Hashable {
    public init() {}
}

public struct AccessibilityActionKind: Sendable, Hashable {
    public init() {}
    public static let `default` = AccessibilityActionKind()
}

public struct AccessibilityAdjustmentDirection: Sendable, Hashable {
    public init() {}
}

public struct AccessibilityAttachmentModifier: Sendable, Hashable {
    public init() {}
}

public struct AccessibilityChildBehavior: Sendable, Hashable {
    public init() {}
    public static let ignore = AccessibilityChildBehavior()
}

public struct AccessibilityCustomContentKey: Sendable, Hashable {
    public init() {}
}

public struct AccessibilityDirectTouchOptions: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let all = AccessibilityDirectTouchOptions(rawValue: 1)
}

public struct AccessibilityFocusState<Value>: Sendable {
    public init() {}
    public struct Binding: Sendable { public init() {} }
}

public struct AccessibilityHeadingLevel: Sendable, Hashable {
    public init() {}
}

public struct AccessibilityLabeledPairRole: Sendable, Hashable {
    public init() {}
}

@resultBuilder
public struct AccessibilityRotorContentBuilder {
    public static func buildBlock<C>(_ content: C) -> C { content }
}

public struct AccessibilitySystemRotor: Sendable, Hashable {
    public init() {}
}

public struct AccessibilityTextContentType: Sendable, Hashable {
    public init() {}
}

public struct AccessibilityTraits: Sendable, Hashable {
    public init() {}
}

public struct AccessibilityZoomGestureAction: Sendable, Hashable {
    public init() {}
}

public struct Action: Sendable, Hashable {
    public init() {}
}

public struct ActionSheet: Sendable, Hashable {
    public init() {}
}

public struct AdaptableTabBarPlacement: Sendable, Hashable {
    public init() {}
    public static let automatic = AdaptableTabBarPlacement()
}

public struct Alert: Sendable, Hashable {
    public init() {}
}

public struct AlignmentStrategy: Sendable, Hashable {
    public init() {}
}

public struct Anchor<Value>: Sendable {
    public init() {}
    public struct Source: Sendable { public init() {} }
}

public struct Angle: Sendable, Hashable {
    public init() {}
}

public struct Animation: Sendable, Hashable {
    public init() {}
    public static let `default` = Animation()
}

public struct AnyTransition: Sendable, Hashable {
    public init() {}
}

public struct AttributeScopes: Sendable, Hashable {
    public init() {}
}

public struct Axis: Sendable, Hashable {
    public init() {}
    public struct Set: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let horizontal = Set(rawValue: 1)
        public static let vertical = Set(rawValue: 2)
        public static let all = Set(rawValue: 4)
    }
}

public struct BadgeProminence: Sendable, Hashable {
    public init() {}
}

public struct BlendMode: Sendable, Hashable {
    public init() {}
}

public struct ButtonBorderShape: Sendable, Hashable {
    public init() {}
}

public struct ButtonRepeatBehavior: Sendable, Hashable {
    public init() {}
}

public struct ButtonSizing: Sendable, Hashable {
    public init() {}
}

public struct CGAffineTransform: Sendable, Hashable {
    public init() {}
}

public struct Case: Sendable, Hashable {
    public init() {}
}

public struct Color: ShapeStyle, Sendable, Hashable {
    public init() {}
    public enum RGBColorSpace: Sendable { case sRGBLinear, sRGB }
    public init(_ space: RGBColorSpace, white: Double, opacity: Double) { _ = (space, white, opacity) }
}

public struct ColorRenderingMode: Sendable, Hashable {
    public init() {}
    public static let nonLinear = ColorRenderingMode()
}

public struct ColorScheme: Sendable, Hashable {
    public init() {}
}

public struct ContainerBackgroundPlacement: Sendable, Hashable {
    public init() {}
}

public struct ContainerValues: Sendable, Hashable {
    public init() {}
}

public struct ContentMarginPlacement: Sendable, Hashable {
    public init() {}
    public static let automatic = ContentMarginPlacement()
}

public struct ContentShapeKinds: Sendable, Hashable {
    public init() {}
}

public struct ContentToolbarPlacement: Sendable, Hashable {
    public init() {}
}

public struct ContentTransition: Sendable, Hashable {
    public init() {}
}

public struct ContextMenu<Content>: Sendable {
    public init() {}
}

public struct ControlSize: Sendable, Hashable, Comparable {
    public var rank: Int = 0
    public init() {}
    public static func < (lhs: ControlSize, rhs: ControlSize) -> Bool { lhs.rank < rhs.rank }
}

public struct CoordinateSpace: Sendable, Hashable {
    public init() {}
    public static let local = CoordinateSpace()
}

public struct DefaultFocusEvaluationPriority: Sendable, Hashable {
    public init() {}
    public static let automatic = DefaultFocusEvaluationPriority()
}

public struct Design: Sendable, Hashable {
    public init() {}
}

public struct DropSession: Sendable, Hashable {
    public init() {}
}

public struct DynamicRange: Sendable, Hashable {
    public init() {}
}

public struct DynamicTypeSize: Sendable, Hashable, Comparable {
    public var rank: Int = 0
    public init() {}
    public static func < (lhs: DynamicTypeSize, rhs: DynamicTypeSize) -> Bool { lhs.rank < rhs.rank }
}

public struct Edge: Sendable, Hashable {
    public init() {}
    public struct Set: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let all = Set(rawValue: 1)
    }
}

public struct EdgeInsets: Sendable, Hashable {
    public init() {}
}

public struct EmptyMatchedTransitionSourceConfiguration: Sendable, Hashable {
    public init() {}
}

public struct EmptyVisualEffect: Sendable, Hashable {
    public init() {}
}

public struct EntryModel: Sendable, Hashable {
    public init() {}
}

public struct EnvironmentValues: Sendable, Hashable {
    public init() {}
}

public struct EventModifiers: Sendable, Hashable {
    public init() {}
    public static let command = EventModifiers()
}

public struct FileDialogBrowserOptions: Sendable, Hashable {
    public init() {}
}

public struct FillStyle: Sendable, Hashable {
    public init() {}
}

public struct FocusState<Value>: Sendable {
    public init() {}
    public struct Binding: Sendable { public init() {} }
}

public struct FocusedValues: Sendable, Hashable {
    public init() {}
}

public struct Font: Sendable, Hashable {
    public init() {}
    public struct Design: Sendable, Hashable {
        public init() {}
    }
    public struct Weight: Sendable, Hashable {
        public init() {}
    }
    public struct Width: Sendable, Hashable {
        public init() {}
    }
}

public struct GeometryProxy: Sendable, Hashable {
    public init() {}
}

public struct GestureMask: Sendable, Hashable {
    public init() {}
    public static let all = GestureMask()
}

public struct Glass: Sendable, Hashable {
    public init() {}
    public static let regular = Glass()
}

public struct GlassEffectTransition: Sendable, Hashable {
    public init() {}
}

public struct HandGestureShortcut: Sendable, Hashable {
    public init() {}
}

public struct HorizontalAlignment: Sendable, Hashable {
    public init() {}
    public static let center = HorizontalAlignment()
}

public struct HorizontalEdge: Sendable, Hashable {
    public init() {}
    public static let trailing = HorizontalEdge()
}

public struct HoverEffect: Sendable, Hashable {
    public init() {}
    public static let automatic = HoverEffect()
}

public struct HoverPhase: Sendable, Hashable {
    public init() {}
}

public struct I1: Sendable, Hashable {
    public init() {}
}

public struct I2: Sendable, Hashable {
    public init() {}
}

public struct Image: Sendable, Hashable {
    public init() {}
    public struct DynamicRange: Sendable, Hashable {
        public init() {}
    }
    public struct Scale: Sendable, Hashable {
        public init() {}
    }
}

public struct Importance: Sendable, Hashable {
    public init() {}
}

public struct Index: Sendable, Hashable {
    public init() {}
}

public struct InterfaceOrientation: Sendable, Hashable {
    public init() {}
}

public struct Key: Sendable, Hashable {
    public init() {}
    public struct Value: Sendable, Hashable {
        public init() {}
    }
}

public struct KeyEquivalent: Sendable, Hashable {
    public init() {}
}

public struct KeyPress: Sendable, Hashable {
    public init() {}
    public struct Phases: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let down = Phases(rawValue: 1)
        public static let `repeat` = Phases(rawValue: 2)
        public static let all = Phases(rawValue: 4)
    }
    public struct Result: Sendable, Hashable {
        public init() {}
    }
}

public struct KeyboardShortcut: Sendable, Hashable {
    public init() {}
    public struct Localization: Sendable, Hashable {
        public init() {}
    }
}

@resultBuilder
public struct KeyframesBuilder<Value> {
    public static func buildBlock<C>(_ content: C) -> C { content }
}

public struct Language: Sendable, Hashable {
    public init() {}
}

public struct LayoutDirectionBehavior: Sendable, Hashable {
    public init() {}
}

public struct LineHeight: Sendable, Hashable {
    public init() {}
}

public struct LineStyle: Sendable, Hashable {
    public init() {}
}

public struct ListItemTint: Sendable, Hashable {
    public init() {}
}

public struct ListSectionSpacing: Sendable, Hashable {
    public init() {}
}

public struct Locale: Sendable, Hashable {
    public init() {}
    public struct Language: Sendable, Hashable {
        public init() {}
    }
}

public struct Localization: Sendable, Hashable {
    public init() {}
}

public struct Mask: Sendable, Hashable {
    public init() {}
}

public struct MatchedGeometryProperties: Sendable, Hashable {
    public init() {}
    public static let frame = MatchedGeometryProperties()
}

public struct MaterialActiveAppearance: Sendable, Hashable {
    public init() {}
}

public struct MenuActionDismissBehavior: Sendable, Hashable {
    public init() {}
}

public struct MenuItems: Sendable, Hashable {
    public init() {}
}

public struct MenuOrder: Sendable, Hashable {
    public init() {}
}

public struct NSItemProvider: Sendable, Hashable {
    public init() {}
}

public struct NSUserActivity: Sendable, Hashable {
    public init() {}
}

public struct NamedCoordinateSpace: Sendable, Hashable {
    public init() {}
}

public struct Namespace: Sendable, Hashable {
    public init() {}
    public struct ID: Sendable, Hashable {
        public init() {}
    }
}

public struct NavigationBarItem: Sendable, Hashable {
    public init() {}
    public struct TitleDisplayMode: Sendable, Hashable {
        public init() {}
    }
}

public struct PaletteSelectionEffect: Sendable, Hashable {
    public init() {}
}

public struct Pattern: Sendable, Hashable {
    public init() {}
}

public struct PencilDoubleTapGestureValue: Sendable, Hashable {
    public init() {}
}

public struct PencilSqueezeGesturePhase: Sendable, Hashable {
    public init() {}
}

public struct Phase: Sendable, Hashable {
    public init() {}
}

public struct Phases: OptionSet, Sendable, Hashable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let all = Phases(rawValue: 1)
}

public struct PlaceholderContentView<Content>: Sendable {
    public init() {}
}

public struct PopoverAttachmentAnchor: Sendable, Hashable {
    public init() {}
    public static let rect = PopoverAttachmentAnchor()
    public static let bounds = PopoverAttachmentAnchor()
    public static func rect(_ rect: PopoverAttachmentAnchor = .bounds) -> PopoverAttachmentAnchor { PopoverAttachmentAnchor() }
}

public struct Predicate<Input>: Sendable {
    public init() {}
}

public struct PresentationAdaptation: Sendable, Hashable {
    public init() {}
}

public struct PresentationBackgroundInteraction: Sendable, Hashable {
    public init() {}
}

public struct PresentationContentInteraction: Sendable, Hashable {
    public init() {}
}

public struct PresentationDetent: Sendable, Hashable {
    public init() {}
}

public struct PreviewDevice: Sendable, Hashable {
    public init() {}
}

public struct PreviewLayout: Sendable, Hashable {
    public init() {}
}

public struct ProjectionTransform: Sendable, Hashable {
    public init() {}
}

public struct Prominence: Sendable, Hashable {
    public init() {}
}

public struct RedactionReasons: Sendable, Hashable {
    public init() {}
}

public struct SafeAreaRegions: Sendable, Hashable {
    public init() {}
    public static let all = SafeAreaRegions()
}

public struct Scale: Sendable, Hashable {
    public init() {}
}

public struct ScenePadding: Sendable, Hashable {
    public init() {}
}

public struct ScrollAnchorRole: Sendable, Hashable {
    public init() {}
}

public struct ScrollBounceBehavior: Sendable, Hashable {
    public init() {}
}

public struct ScrollDismissesKeyboardMode: Sendable, Hashable {
    public init() {}
}

public struct ScrollEdgeEffectStyle: Sendable, Hashable {
    public init() {}
}

public struct ScrollGeometry: Sendable, Hashable {
    public init() {}
}

public struct ScrollIndicatorVisibility: Sendable, Hashable {
    public init() {}
}

public struct ScrollInputBehavior: Sendable, Hashable {
    public init() {}
}

public struct ScrollInputKind: Sendable, Hashable {
    public init() {}
}

public struct ScrollPhase: Sendable, Hashable {
    public init() {}
}

public struct ScrollPhaseChangeContext: Sendable, Hashable {
    public init() {}
}

public struct ScrollPosition: Sendable, Hashable {
    public init() {}
}

public struct ScrollTransitionConfiguration: Sendable, Hashable {
    public init() {}
    public static let interactive = ScrollTransitionConfiguration()
}

public struct ScrollTransitionPhase: Sendable, Hashable {
    public init() {}
}

public struct SearchFieldPlacement: Sendable, Hashable {
    public init() {}
    public static let automatic = SearchFieldPlacement()
}

public struct SearchPresentationToolbarBehavior: Sendable, Hashable {
    public init() {}
}

public struct SearchSuggestionsPlacement: Sendable, Hashable {
    public init() {}
    public struct Set: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let all = Set(rawValue: 1)
    }
}

public struct SearchToolbarBehavior: Sendable, Hashable {
    public init() {}
}

public struct SensoryFeedback: Sendable, Hashable {
    public init() {}
}

public struct Shader: Sendable, Hashable {
    public init() {}
}

public struct SharePreview<I1, I2>: Sendable {
    public init() {}
}

public struct Source: Sendable, Hashable {
    public init() {}
}

public struct SpringLoadingBehavior: Sendable, Hashable {
    public init() {}
}

public struct SubmitLabel: Sendable, Hashable {
    public init() {}
}

public struct SubmitTriggers: Sendable, Hashable {
    public init() {}
    public static let text = SubmitTriggers()
}

public struct SymbolColorRenderingMode: Sendable, Hashable {
    public init() {}
}

public struct SymbolEffectOptions: Sendable, Hashable {
    public init() {}
    public static let `default` = SymbolEffectOptions()
}

public struct SymbolRenderingMode: Sendable, Hashable {
    public init() {}
}

public struct SymbolVariableValueMode: Sendable, Hashable {
    public init() {}
}

public struct SymbolVariants: Sendable, Hashable {
    public init() {}
}

public struct TabBarMinimizeBehavior: Sendable, Hashable {
    public init() {}
}

public struct TabSearchActivation: Sendable, Hashable {
    public init() {}
}

public struct TabViewCustomization: Sendable, Hashable {
    public init() {}
}

public struct TaskPriority: Sendable, Hashable {
    public init() {}
    public static let userInitiated = TaskPriority()
}

public struct Text: Sendable, Hashable {
    public init() {}
    public struct AlignmentStrategy: Sendable, Hashable {
        public init() {}
    }
    public struct Case: Sendable, Hashable {
        public init() {}
    }
    public struct LineStyle: Sendable, Hashable {
        public init() {}
        public struct Pattern: Sendable, Hashable {
            public init() {}
            public static let solid = Pattern()
        }
    }
    public struct Scale: Sendable, Hashable {
        public init() {}
    }
    public struct TruncationMode: Sendable, Hashable {
        public init() {}
    }
    public struct WritingDirectionStrategy: Sendable, Hashable {
        public init() {}
    }
}

public struct TextAlignment: Sendable, Hashable {
    public init() {}
}

public struct TextInputAutocapitalization: Sendable, Hashable {
    public init() {}
}

public struct TextInputDictationBehavior: Sendable, Hashable {
    public init() {}
}

public struct TextInputFormattingControlPlacement: Sendable, Hashable {
    public init() {}
    public struct Set: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let all = Set(rawValue: 1)
    }
}

public struct TextSelection: Sendable, Hashable {
    public init() {}
}

public struct TextSelectionAffinity: Sendable, Hashable {
    public init() {}
}

public struct Tips: Sendable, Hashable {
    public init() {}
    public struct Action: Sendable, Hashable {
        public init() {}
    }
}

public struct TitleDisplayMode: Sendable, Hashable {
    public init() {}
}

public struct ToolbarDefaultItemKind: Sendable, Hashable {
    public init() {}
}

public struct ToolbarPlacement: Sendable, Hashable {
    public init() {}
}

public struct ToolbarRole: Sendable, Hashable {
    public init() {}
}

public struct ToolbarTitleDisplayMode: Sendable, Hashable {
    public init() {}
}

public struct Transaction: Sendable, Hashable {
    public init() {}
}

public struct TruncationMode: Sendable, Hashable {
    public init() {}
}

public struct TypesettingLanguage: Sendable, Hashable {
    public init() {}
}

public struct UIKeyboardType: Sendable, Hashable {
    public init() {}
}

public struct UITextAutocapitalizationType: Sendable, Hashable {
    public init() {}
}

public struct UITextContentType: Sendable, Hashable {
    public init() {}
}

public struct UnitPoint: Sendable, Hashable {
    public init() {}
    public static let center = UnitPoint()
}

public struct VerticalAlignment: Sendable, Hashable {
    public init() {}
    public static let center = VerticalAlignment()
}

public struct VerticalEdge: Sendable, Hashable {
    public init() {}
    public struct Set: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let all = Set(rawValue: 1)
    }
}

public struct ViewDimensions: Sendable, Hashable {
    public init() {}
}

public struct Visibility: Sendable, Hashable {
    public init() {}
    public static let automatic = Visibility()
}

public struct Weight: Sendable, Hashable {
    public init() {}
}

public struct Width: Sendable, Hashable {
    public init() {}
}

public struct WindowToolbarFullScreenVisibility: Sendable, Hashable {
    public init() {}
}

public struct WritingDirectionStrategy: Sendable, Hashable {
    public init() {}
}

public struct WritingToolsBehavior: Sendable, Hashable {
    public init() {}
}

extension AttributedString {
    public struct LineHeight: Sendable, Hashable {
        public init() {}
    }
}

extension View {
    @MainActor @preconcurrency func onCameraCaptureEvent(isEnabled: Bool = true, primaryAction: @escaping (AVCaptureEvent) -> Void, secondaryAction: @escaping (AVCaptureEvent) -> Void) -> some View { self }

    @MainActor @preconcurrency func onCameraCaptureEvent(isEnabled: Bool = true, defaultSoundDisabled: Bool = false, primaryAction: @escaping (AVCaptureEvent) async -> Void, secondaryAction: @escaping (AVCaptureEvent) async -> Void) -> some View { self }

    @MainActor @preconcurrency func onCameraCaptureEvent(isEnabled: Bool = true, defaultSoundDisabled: Bool = false, primaryAction: @escaping (AVCaptureEvent) -> Void, secondaryAction: @escaping (AVCaptureEvent) -> Void) -> some View { self }

    @MainActor @preconcurrency func onCameraCaptureEvent(isEnabled: Bool = true, defaultSoundDisabled: Bool = false, action: @escaping (AVCaptureEvent) async -> Void) -> some View { self }

    @MainActor @preconcurrency func onCameraCaptureEvent(isEnabled: Bool = true, defaultSoundDisabled: Bool = false, action: @escaping (AVCaptureEvent) -> Void) -> some View { self }

    @MainActor @preconcurrency func onCameraCaptureEvent(isEnabled: Bool = true, action: @escaping (AVCaptureEvent) -> Void) -> some View { self }

    nonisolated func tipViewStyle(_ style: some TipViewStyle) -> some View { self }

    @preconcurrency nonisolated func popoverTip(_ tip: (any Tip)?, isPresented: Binding<Bool>? = nil, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdges: Edge.Set, action: @escaping @MainActor (Tips.Action) -> Void = { _ in }) -> some View { self }

    @preconcurrency nonisolated func popoverTip(_ tip: (any Tip)?, isPresented: Binding<Bool>? = nil, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge? = nil, action: @escaping @MainActor (Tips.Action) -> Void = { _ in }) -> some View { self }

    @preconcurrency nonisolated func popoverTip(_ tip: (any Tip)?, arrowEdge: Edge? = nil, action: @escaping @MainActor (Tips.Action) -> Void = { _ in }) -> some View { self }

    nonisolated func tipImageSize(_ size: CGSize) -> some View { self }

    nonisolated func tipBackground<S>(_ style: S) -> some View where S : ShapeStyle { self }

    nonisolated func tipImageStyle<S>(_ style: S) -> some View where S : ShapeStyle { self }

    nonisolated func tipImageStyle<S1, S2, S3>(_ primary: S1, _ secondary: S2, _ tertiary: S3) -> some View where S1 : ShapeStyle, S2 : ShapeStyle, S3 : ShapeStyle { self }

    nonisolated func tipImageStyle<S1, S2>(_ primary: S1, _ secondary: S2) -> some View where S1 : ShapeStyle, S2 : ShapeStyle { self }

    nonisolated func tipCornerRadius(_ cornerRadius: CGFloat, antialiased: Bool = true) -> some View { self }

    nonisolated func tipBackgroundInteraction(_ interaction: PresentationBackgroundInteraction) -> some View { self }

    nonisolated func tipAnchor<AnchorID>(_ id: AnchorID) -> some View where AnchorID : Hashable, AnchorID : Sendable { self }

    nonisolated func navigationViewStyle<S>(_ style: S) -> some View where S : NavigationViewStyle { self }

    nonisolated func navigationSplitViewColumnWidth(min: CGFloat? = nil, ideal: CGFloat, max: CGFloat? = nil) -> some View { self }

    nonisolated func navigationSplitViewColumnWidth(_ width: CGFloat) -> some View { self }

    nonisolated func navigationSplitViewStyle<S>(_ style: S) -> some View where S : NavigationSplitViewStyle { self }

    nonisolated func tabViewCustomization(_ customization: Binding<TabViewCustomization>?) -> some View { self }

    nonisolated func tabViewSidebarFooter<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { self }

    nonisolated func tabViewSidebarHeader<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { self }

    nonisolated func tabViewBottomAccessory<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { self }

    nonisolated func tabViewSearchActivation(_ activation: TabSearchActivation) -> some View { self }

    nonisolated func tabViewSidebarBottomBar<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { self }

    nonisolated func tabViewStyle<S>(_ style: S) -> some View where S : TabViewStyle { self }

    nonisolated func indexViewStyle<S>(_ style: S) -> some View where S : IndexViewStyle { self }

    nonisolated func progressViewStyle<S>(_ style: S) -> some View where S : ProgressViewStyle { self }

    nonisolated func background(ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View { self }

    nonisolated func background<S>(in shape: S, fillStyle: FillStyle = FillStyle()) -> some View where S : InsettableShape { self }

    nonisolated func background<S>(in shape: S, fillStyle: FillStyle = FillStyle()) -> some View where S : Shape { self }

    nonisolated func background<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View { self }

    nonisolated func background<S>(_ style: S, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View where S : ShapeStyle { self }

    nonisolated func background<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S : ShapeStyle, T : InsettableShape { self }

    nonisolated func background<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S : ShapeStyle, T : Shape { self }

    nonisolated func background<Background>(_ background: Background, alignment: Alignment = .center) -> some View where Background : View { self }

    nonisolated func brightness(_ amount: Double) -> some View { self }

    nonisolated func dialogIcon(_ icon: Image?) -> some View { self }

    nonisolated func fontDesign(_ design: Font.Design?) -> some View { self }

    nonisolated func fontWeight(_ weight: Font.Weight?) -> some View { self }

    nonisolated func gaugeStyle<S>(_ style: S) -> some View where S : GaugeStyle { self }

    nonisolated func imageScale(_ scale: Image.Scale) -> some View { self }

    nonisolated func labelStyle<S>(_ style: S) -> some View where S : LabelStyle { self }

    nonisolated func lineHeight(_ lineHeight: AttributedString.LineHeight?) -> some View { self }

    nonisolated func monospaced(_ isActive: Bool = true) -> some View { self }

    nonisolated func onKeyPress(characters: CharacterSet, phases: KeyPress.Phases = [.down, .repeat], action: @escaping (KeyPress) -> KeyPress.Result) -> some View { self }

    nonisolated func onKeyPress(keys: Set<KeyEquivalent>, phases: KeyPress.Phases = [.down, .repeat], action: @escaping (KeyPress) -> KeyPress.Result) -> some View { self }

    nonisolated func onKeyPress(phases: KeyPress.Phases = [.down, .repeat], action: @escaping (KeyPress) -> KeyPress.Result) -> some View { self }

    nonisolated func onKeyPress(_ key: KeyEquivalent, action: @escaping () -> KeyPress.Result) -> some View { self }

    nonisolated func onKeyPress(_ key: KeyEquivalent, phases: KeyPress.Phases, action: @escaping (KeyPress) -> KeyPress.Result) -> some View { self }

    nonisolated func preference<K>(key: K.Type = K.self, value: K.Value) -> some View where K : PreferenceKey { self }

    nonisolated func saturation(_ amount: Double) -> some View { self }

    nonisolated func searchable(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource) -> some View { self }

    nonisolated func searchable(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey) -> some View { self }

    nonisolated func searchable(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil) -> some View { self }

    nonisolated func searchable<S>(text: Binding<String>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: S) -> some View where S : StringProtocol { self }

    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { self }

    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { self }

    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { self }

    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: some StringProtocol, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { self }

    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { self }

    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { self }

    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { self }

    nonisolated func searchable<C>(text: Binding<String>, editableTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: some StringProtocol, @ViewBuilder token: @escaping (Binding<C.Element>) -> some View) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T, S>(text: Binding<String>, tokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, S : StringProtocol, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T, S>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, isPresented: Binding<Bool>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, S : StringProtocol, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T, S>(text: Binding<String>, tokens: Binding<C>, suggestedTokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : MutableCollection, C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, S : StringProtocol, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T>(text: Binding<String>, tokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, C.Element : Identifiable { self }

    nonisolated func searchable<C, T, S>(text: Binding<String>, tokens: Binding<C>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder token: @escaping (C.Element) -> T) -> some View where C : RandomAccessCollection, C : RangeReplaceableCollection, T : View, S : StringProtocol, C.Element : Identifiable { self }

    nonisolated func searchable<S>(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey, @ViewBuilder suggestions: () -> S) -> some View where S : View { self }

    nonisolated func searchable<S>(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil, @ViewBuilder suggestions: () -> S) -> some View where S : View { self }

    nonisolated func searchable<V, S>(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: S, @ViewBuilder suggestions: () -> V) -> some View where V : View, S : StringProtocol { self }

    nonisolated func searchable(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringResource) -> some View { self }

    nonisolated func searchable(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: LocalizedStringKey) -> some View { self }

    nonisolated func searchable(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: Text? = nil) -> some View { self }

    nonisolated func searchable<S>(text: Binding<String>, placement: SearchFieldPlacement = .automatic, prompt: S) -> some View where S : StringProtocol { self }

    nonisolated func tableStyle<S>(_ style: S) -> some View where S : TableStyle { self }

    nonisolated func transition(_ t: AnyTransition) -> some View { self }

    nonisolated func transition<T>(_ transition: T) -> some View where T : Transition { self }

    nonisolated func unredacted() -> some View { self }

    nonisolated func accentColor(_ accentColor: Color?) -> some View { self }

    nonisolated func actionSheet(isPresented: Binding<Bool>, content: () -> ActionSheet) -> some View { self }

    nonisolated func actionSheet<T>(item: Binding<T?>, content: (T) -> ActionSheet) -> some View where T : Identifiable { self }

    nonisolated func aspectRatio(_ aspectRatio: CGFloat? = nil, contentMode: ContentMode) -> some View { self }

    nonisolated func aspectRatio(_ aspectRatio: CGSize, contentMode: ContentMode) -> some View { self }

    nonisolated func buttonStyle<S>(_ style: S) -> some View where S : PrimitiveButtonStyle { self }

    nonisolated func buttonStyle<S>(_ style: S) -> some View where S : ButtonStyle { self }

    nonisolated func colorEffect(_ shader: Shader, isEnabled: Bool = true) -> some View { self }

    nonisolated func colorInvert() -> some View { self }

    nonisolated func colorScheme(_ colorScheme: ColorScheme) -> some View { self }

    nonisolated func contextMenu<I, M>(forSelectionType itemType: I.Type = I.self, @ViewBuilder menu: @escaping (Set<I>) -> M, primaryAction: ((Set<I>) -> Void)? = nil) -> some View where I : Hashable, M : View { self }

    nonisolated func contextMenu<M, P>(@ViewBuilder menuItems: () -> M, @ViewBuilder preview: () -> P) -> some View where M : View, P : View { self }

    nonisolated func contextMenu<MenuItems>(@ViewBuilder menuItems: () -> MenuItems) -> some View where MenuItems : View { self }

    nonisolated func contextMenu<MenuItems>(_ contextMenu: ContextMenu<MenuItems>?) -> some View where MenuItems : View { self }

    nonisolated func controlSize(_ controlSize: ControlSize) -> some View { self }

    nonisolated func controlSize<T>(_ range: T) -> some View where T : RangeExpression, T.Bound == ControlSize { self }

    nonisolated func environment<T>(_ object: T?) -> some View where T : AnyObject, T : Observable { self }

    nonisolated func environment<V>(_ keyPath: WritableKeyPath<EnvironmentValues, V>, _ value: V) -> some View { self }

    nonisolated func glassEffect(_ glass: Glass = .regular, in shape: some Shape = DefaultGlassEffectShape()) -> some View { self }

    nonisolated func hoverEffect(_ effect: HoverEffect = .automatic, isEnabled: Bool = true) -> some View { self }

    nonisolated func hoverEffect(_ effect: some CustomHoverEffect = .automatic, isEnabled: Bool = true) -> some View { self }

    nonisolated func hoverEffect(_ effect: HoverEffect = .automatic) -> some View { self }

    nonisolated func hueRotation(_ angle: Angle) -> some View { self }

    nonisolated func layerEffect(_ shader: Shader, maxSampleOffset: CGSize, isEnabled: Bool = true) -> some View { self }

    nonisolated func layoutValue<K>(key: K.Type, value: K.Value) -> some View where K : LayoutValueKey { self }

    nonisolated func lineSpacing(_ lineSpacing: CGFloat) -> some View { self }

    nonisolated func onDisappear(perform action: (() -> Void)? = nil) -> some View { self }

    nonisolated func pickerStyle<S>(_ style: S) -> some View where S : PickerStyle { self }

    nonisolated func refreshable(action: @escaping () async -> Void) -> some View { self }

    nonisolated func safeAreaBar(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> some View) -> some View { self }

    nonisolated func safeAreaBar(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> some View) -> some View { self }

    nonisolated func scaleEffect(x: CGFloat = 1.0, y: CGFloat = 1.0, anchor: UnitPoint = .center) -> some View { self }

    nonisolated func scaleEffect(_ s: CGFloat, anchor: UnitPoint = .center) -> some View { self }

    nonisolated func scaleEffect(_ scale: CGSize, anchor: UnitPoint = .center) -> some View { self }

    nonisolated func scaledToFit() -> some View { self }

    nonisolated func submitLabel(_ submitLabel: SubmitLabel) -> some View { self }

    nonisolated func submitScope(_ isBlocking: Bool = true) -> some View { self }

    nonisolated func toggleStyle<S>(_ style: S) -> some View where S : ToggleStyle { self }

    nonisolated func toolbarRole(_ role: ToolbarRole) -> some View { self }

    nonisolated func transaction(value: some Equatable, _ transform: @escaping (inout Transaction) -> Void) -> some View { self }

    nonisolated func transaction<V>(_ transform: @escaping (inout Transaction) -> Void, @ViewBuilder body: (PlaceholderContentView<Self>) -> V) -> some View where V : View { self }

    nonisolated func transaction(_ transform: @escaping (inout Transaction) -> Void) -> some View { self }

    nonisolated func buttonSizing(_ sizing: ButtonSizing) -> some View { self }

    nonisolated func contentShape<S>(_ shape: S, eoFill: Bool = false) -> some View where S : Shape { self }

    nonisolated func contentShape<S>(_ kind: ContentShapeKinds, _ shape: S, eoFill: Bool = false) -> some View where S : Shape { self }

    nonisolated func cornerRadius(_ radius: CGFloat, antialiased: Bool = true) -> some View { self }

    nonisolated func defaultFocus<V>(_ binding: FocusState<V>.Binding, _ value: V, priority: DefaultFocusEvaluationPriority = .automatic) -> some View where V : Hashable { self }

    nonisolated func drawingGroup(opaque: Bool = false, colorMode: ColorRenderingMode = .nonLinear) -> some View { self }

    nonisolated func fileExporter<T>(isPresented: Binding<Bool>, item: T?, contentTypes: [UTType] = [], defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void = { }) -> some View where T : Transferable { self }

    nonisolated func fileExporter<C, T>(isPresented: Binding<Bool>, items: C, contentTypes: [UTType] = [], onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void = { }) -> some View where C : Collection, T : Transferable, T == C.Element { self }

    nonisolated func fileExporter<D>(isPresented: Binding<Bool>, document: D?, contentType: UTType, defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void) -> some View where D : FileDocument { self }

    nonisolated func fileExporter<D>(isPresented: Binding<Bool>, document: D?, contentType: UTType, defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void) -> some View where D : ReferenceFileDocument { self }

    nonisolated func fileExporter<D>(isPresented: Binding<Bool>, document: D?, contentTypes: [UTType] = [], defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void = {}) -> some View where D : FileDocument { self }

    nonisolated func fileExporter<D>(isPresented: Binding<Bool>, document: D?, contentTypes: [UTType] = [], defaultFilename: String? = nil, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void = {}) -> some View where D : ReferenceFileDocument { self }

    nonisolated func fileExporter<C>(isPresented: Binding<Bool>, documents: C, contentType: UTType, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View where C : Collection, C.Element : FileDocument { self }

    nonisolated func fileExporter<C>(isPresented: Binding<Bool>, documents: C, contentType: UTType, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View where C : Collection, C.Element : ReferenceFileDocument { self }

    nonisolated func fileExporter<C>(isPresented: Binding<Bool>, documents: C, contentTypes: [UTType] = [], onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void = {}) -> some View where C : Collection, C.Element : FileDocument { self }

    nonisolated func fileExporter<C>(isPresented: Binding<Bool>, documents: C, contentTypes: [UTType] = [], onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void = {}) -> some View where C : Collection, C.Element : ReferenceFileDocument { self }

    nonisolated func fileImporter(isPresented: Binding<Bool>, allowedContentTypes: [UTType], onCompletion: @escaping (Result<URL, any Error>) -> Void) -> some View { self }

    nonisolated func fileImporter(isPresented: Binding<Bool>, allowedContentTypes: [UTType], allowsMultipleSelection: Bool, onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void) -> some View { self }

    nonisolated func fileImporter(isPresented: Binding<Bool>, allowedContentTypes: [UTType], allowsMultipleSelection: Bool, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View { self }

    nonisolated func findDisabled(_ isDisabled: Bool = true) -> some View { self }

    nonisolated func focusedValue<T>(_ object: T?) -> some View where T : AnyObject, T : Observable { self }

    nonisolated func focusedValue<Value>(_ keyPath: WritableKeyPath<FocusedValues, Value?>, _ value: Value?) -> some View { self }

    nonisolated func focusedValue<Value>(_ keyPath: WritableKeyPath<FocusedValues, Value?>, _ value: Value) -> some View { self }

    nonisolated func itemProvider(_ action: Optional<() -> NSItemProvider?>) -> some View { self }

    nonisolated func keyboardType(_ type: UIKeyboardType) -> some View { self }

    nonisolated func labelsHidden() -> some View { self }

    nonisolated func listItemTint(_ tint: ListItemTint?) -> some View { self }

    nonisolated func listItemTint(_ tint: Color?) -> some View { self }

    nonisolated func moveDisabled(_ isDisabled: Bool) -> some View { self }

    nonisolated func onTapGesture(count: Int = 1, coordinateSpace: CoordinateSpace = .local, perform action: @escaping (CGPoint) -> Void) -> some View { self }

    nonisolated func onTapGesture(count: Int = 1, coordinateSpace: some CoordinateSpaceProtocol = .local, perform action: @escaping (CGPoint) -> Void) -> some View { self }

    nonisolated func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View { self }

    nonisolated func renameAction(_ isFocused: FocusState<Bool>.Binding) -> some View { self }

    nonisolated func renameAction(_ action: @escaping () -> Void) -> some View { self }

    nonisolated func scaledToFill() -> some View { self }

    nonisolated func scenePadding(_ padding: ScenePadding, edges: Edge.Set = .all) -> some View { self }

    nonisolated func scenePadding(_ edges: Edge.Set = .all) -> some View { self }

    nonisolated func searchScopes<V, S>(_ scope: Binding<V>, activation: SearchScopeActivation, @ViewBuilder _ scopes: () -> S) -> some View where V : Hashable, S : View { self }

    nonisolated func searchScopes<V, S>(_ scope: Binding<V>, @ViewBuilder scopes: () -> S) -> some View where V : Hashable, S : View { self }

    nonisolated func swipeActions<T>(edge: HorizontalEdge = .trailing, allowsFullSwipe: Bool = true, @ViewBuilder content: () -> T) -> some View where T : View { self }

    nonisolated func symbolEffect<T, U>(_ effect: T, options: SymbolEffectOptions = .default, value: U) -> some View where T : DiscreteSymbolEffect, T : SymbolEffect, U : Equatable { self }

    nonisolated func symbolEffect<T>(_ effect: T, options: SymbolEffectOptions = .default, isActive: Bool = true) -> some View where T : IndefiniteSymbolEffect, T : SymbolEffect { self }

    nonisolated func textRenderer<T>(_ renderer: T) -> some View where T : TextRenderer { self }

    nonisolated func userActivity<P>(_ activityType: String, element: P?, _ update: @escaping (P, NSUserActivity) -> ()) -> some View { self }

    nonisolated func userActivity(_ activityType: String, isActive: Bool = true, _ update: @escaping (NSUserActivity) -> ()) -> some View { self }

    nonisolated func visualEffect(_ effect: @escaping (EmptyVisualEffect, GeometryProxy) -> some VisualEffect) -> some View { self }

    nonisolated func accessibility(identifier: String) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(inputLabels: [Text]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(removeTraits traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(sortPriority: Double) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(activationPoint: UnitPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(activationPoint: CGPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(selectionIdentifier: AnyHashable) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(hint: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(label: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(value: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(hidden: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibility(addTraits traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func colorMultiply(_ color: Color) -> some View { self }

    nonisolated func findNavigator(isPresented: Binding<Bool>) -> some View { self }

    nonisolated func focusedObject<T>(_ object: T) -> some View where T : ObservableObject { self }

    nonisolated func focusedObject<T>(_ object: T?) -> some View where T : ObservableObject { self }

    nonisolated func geometryGroup() -> some View { self }

    nonisolated func glassEffectID(_ id: (some Hashable & Sendable)?, in namespace: Namespace.ID) -> some View { self }

    nonisolated func groupBoxStyle<S>(_ style: S) -> some View where S : GroupBoxStyle { self }

    nonisolated func listRowInsets(_ insets: EdgeInsets?) -> some View { self }

    nonisolated func listRowInsets(_ edges: Edge.Set = .all, _ length: CGFloat?) -> some View { self }

    nonisolated func menuIndicator(_ visibility: Visibility) -> some View { self }

    nonisolated func phaseAnimator<Phase>(_ phases: some Sequence, @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Phase) -> some View, animation: @escaping (Phase) -> Animation? = { _ in .default }) -> some View where Phase : Equatable { self }

    nonisolated func phaseAnimator<Phase>(_ phases: some Sequence, trigger: some Equatable, @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Phase) -> some View, animation: @escaping (Phase) -> Animation? = { _ in .default }) -> some View where Phase : Equatable { self }

    nonisolated func previewDevice(_ value: PreviewDevice?) -> some View { self }

    nonisolated func previewLayout(_ value: PreviewLayout) -> some View { self }

    nonisolated func safeAreaInset<V>(edge: VerticalEdge, alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> V) -> some View where V : View { self }

    nonisolated func safeAreaInset<V>(edge: HorizontalEdge, alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> V) -> some View where V : View { self }

    nonisolated func searchFocused<V>(_ binding: FocusState<V>.Binding, equals value: V) -> some View where V : Hashable { self }

    nonisolated func searchFocused(_ binding: FocusState<Bool>.Binding) -> some View { self }

    nonisolated func strikethrough(_ isActive: Bool = true, pattern: Text.LineStyle.Pattern = .solid, color: Color? = nil) -> some View { self }

    nonisolated func symbolVariant(_ variant: SymbolVariants) -> some View { self }

    nonisolated func textSelection<S>(_ selectability: S) -> some View where S : TextSelectability { self }

    @preconcurrency nonisolated func alignmentGuide(_ g: VerticalAlignment, computeValue: @escaping (ViewDimensions) -> CGFloat) -> some View { self }

    @preconcurrency nonisolated func alignmentGuide(_ g: HorizontalAlignment, computeValue: @escaping (ViewDimensions) -> CGFloat) -> some View { self }

    nonisolated func baselineOffset(_ baselineOffset: CGFloat) -> some View { self }

    nonisolated func containerShape<T>(_ shape: T) -> some View where T : InsettableShape { self }

    nonisolated func containerShape(_ shape: some RoundedRectangularShape) -> some View { self }

    nonisolated func containerValue<V>(_ keyPath: WritableKeyPath<ContainerValues, V>, _ value: V) -> some View { self }

    nonisolated func contentMargins(_ length: CGFloat, for placement: ContentMarginPlacement = .automatic) -> some View { self }

    nonisolated func contentMargins(_ edges: Edge.Set = .all, _ length: CGFloat?, for placement: ContentMarginPlacement = .automatic) -> some View { self }

    nonisolated func contentMargins(_ edges: Edge.Set = .all, _ insets: EdgeInsets, for placement: ContentMarginPlacement = .automatic) -> some View { self }

    nonisolated func contentToolbar<Content>(for placement: ContentToolbarPlacement, @ToolbarContentBuilder content: () -> Content) -> some View where Content : ToolbarContent { self }

    nonisolated func contentToolbar<Content>(for placement: ContentToolbarPlacement, @ViewBuilder content: () -> Content) -> some View where Content : View { self }

    nonisolated func deleteDisabled(_ isDisabled: Bool) -> some View { self }

    nonisolated func gridCellAnchor(_ anchor: UnitPoint) -> some View { self }

    nonisolated func layoutPriority(_ value: Double) -> some View { self }

    nonisolated func listRowSpacing(_ spacing: CGFloat?) -> some View { self }

    nonisolated func previewContext<C>(_ value: C) -> some View where C : PreviewContext { self }

    nonisolated func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some View { self }

    nonisolated func scrollDisabled(_ disabled: Bool) -> some View { self }

    nonisolated func scrollPosition(id: Binding<(some Hashable)?>, anchor: UnitPoint? = nil) -> some View { self }

    nonisolated func scrollPosition(_ position: Binding<ScrollPosition>, anchor: UnitPoint? = nil) -> some View { self }

    nonisolated func sectionActions<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { self }

    nonisolated func textFieldStyle<S>(_ style: S) -> some View where S : TextFieldStyle { self }

    nonisolated func truncationMode(_ mode: Text.TruncationMode) -> some View { self }

    nonisolated func backgroundStyle<S>(_ style: S) -> some View where S : ShapeStyle { self }

    nonisolated func badgeProminence(_ prominence: BadgeProminence) -> some View { self }

    nonisolated func coordinateSpace<T>(name: T) -> some View where T : Hashable { self }

    nonisolated func coordinateSpace(_ name: NamedCoordinateSpace) -> some View { self }

    nonisolated func datePickerStyle<S>(_ style: S) -> some View where S : DatePickerStyle { self }

    nonisolated func dropDestination<T>(for payloadType: T.Type = T.self, action: @escaping ([T], CGPoint) -> Bool, isTargeted: @escaping (Bool) -> Void = { _ in }) -> some View where T : Transferable { self }

    nonisolated func dropDestination<T>(for type: T.Type = T.self, isEnabled: Bool = true, action: @escaping ([T], DropSession) -> Void) -> some View where T : Transferable { self }

    nonisolated func dynamicTypeSize(_ size: DynamicTypeSize) -> some View { self }

    nonisolated func dynamicTypeSize<T>(_ range: T) -> some View where T : RangeExpression, T.Bound == DynamicTypeSize { self }

    nonisolated func foregroundColor(_ color: Color?) -> some View { self }

    nonisolated func foregroundStyle<S>(_ style: S) -> some View where S : ShapeStyle { self }

    nonisolated func foregroundStyle<S1, S2, S3>(_ primary: S1, _ secondary: S2, _ tertiary: S3) -> some View where S1 : ShapeStyle, S2 : ShapeStyle, S3 : ShapeStyle { self }

    nonisolated func foregroundStyle<S1, S2>(_ primary: S1, _ secondary: S2) -> some View where S1 : ShapeStyle, S2 : ShapeStyle { self }

    nonisolated func fullScreenCover<Content>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View { self }

    nonisolated func fullScreenCover<Item, Content>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View { self }

    nonisolated func gridCellColumns(_ count: Int) -> some View { self }

    nonisolated func ignoresSafeArea(_ regions: SafeAreaRegions = .all, edges: Edge.Set = .all) -> some View { self }

    nonisolated func monospacedDigit() -> some View { self }

    nonisolated func navigationTitle(_ titleResource: LocalizedStringResource) -> some View { self }

    nonisolated func navigationTitle(_ titleKey: LocalizedStringKey) -> some View { self }

    nonisolated func navigationTitle(_ title: Text) -> some View { self }

    nonisolated func navigationTitle(_ title: Binding<String>) -> some View { self }

    nonisolated func navigationTitle<S>(_ title: S) -> some View where S : StringProtocol { self }

    nonisolated func navigationTitle<V>(@ViewBuilder _ title: () -> V) -> some View where V : View { self }

    nonisolated func onPencilSqueeze(perform action: @escaping (PencilSqueezeGesturePhase) -> Void) -> some View { self }

    nonisolated func replaceDisabled(_ isDisabled: Bool = true) -> some View { self }

    nonisolated func safeAreaPadding(_ length: CGFloat) -> some View { self }

    nonisolated func safeAreaPadding(_ insets: EdgeInsets) -> some View { self }

    nonisolated func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View { self }

    nonisolated func searchSelection(_ selection: Binding<TextSelection?>) -> some View { self }

    nonisolated func sensoryFeedback<T>(trigger: T, _ feedback: @escaping (T, T) -> SensoryFeedback?) -> some View where T : Equatable { self }

    nonisolated func sensoryFeedback<T>(trigger: T, _ feedback: @escaping () -> SensoryFeedback?) -> some View where T : Equatable { self }

    nonisolated func sensoryFeedback<T>(_ feedback: SensoryFeedback, trigger: T, condition: @escaping (T, T) -> Bool) -> some View where T : Equatable { self }

    nonisolated func sensoryFeedback<T>(_ feedback: SensoryFeedback, trigger: T) -> some View where T : Equatable { self }

    nonisolated func statusBarHidden(_ hidden: Bool = true) -> some View { self }

    nonisolated func textContentType(_ textContentType: UITextContentType?) -> some View { self }

    nonisolated func textEditorStyle(_ style: some TextEditorStyle) -> some View { self }

    nonisolated func transformEffect(_ transform: CGAffineTransform) -> some View { self }

    nonisolated func allowsHitTesting(_ enabled: Bool) -> some View { self }

    nonisolated func allowsTightening(_ flag: Bool) -> some View { self }

    nonisolated func anchorPreference<A, K>(key _: K.Type = K.self, value: Anchor<A>.Source, transform: @escaping (Anchor<A>) -> K.Value) -> some View where K : PreferenceKey { self }

    nonisolated func compositingGroup() -> some View { self }

    nonisolated func distortionEffect(_ shader: Shader, maxSampleOffset: CGSize, isEnabled: Bool = true) -> some View { self }

    @MainActor @preconcurrency func glassEffectUnion(id: (some Hashable & Sendable)?, namespace: Namespace.ID) -> some View { self }

    nonisolated func headerProminence(_ prominence: Prominence) -> some View { self }

    nonisolated func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = .command, localization: KeyboardShortcut.Localization) -> some View { self }

    nonisolated func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = .command) -> some View { self }

    nonisolated func keyboardShortcut(_ shortcut: KeyboardShortcut) -> some View { self }

    nonisolated func keyboardShortcut(_ shortcut: KeyboardShortcut?) -> some View { self }

    nonisolated func keyframeAnimator<Value>(initialValue: Value, trigger: some Equatable, @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Value) -> some View, @KeyframesBuilder<Value> keyframes: @escaping (Value) -> some Keyframes) -> some View { self }

    nonisolated func keyframeAnimator<Value>(initialValue: Value, repeating: Bool = true, @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Value) -> some View, @KeyframesBuilder<Value> keyframes: @escaping (Value) -> some Keyframes) -> some View { self }

    nonisolated func labelsVisibility(_ visibility: Visibility) -> some View { self }

    nonisolated func listRowSeparator(_ visibility: Visibility, edges: VerticalEdge.Set = .all) -> some View { self }

    nonisolated func luminanceToAlpha() -> some View { self }

    @preconcurrency nonisolated func onGeometryChange<T>(for type: T.Type, of transform: @escaping (GeometryProxy) -> T, action: @escaping (T, T) -> Void) -> some View where T : Equatable, T : Sendable { self }

    @preconcurrency nonisolated func onGeometryChange<T>(for type: T.Type, of transform: @escaping (GeometryProxy) -> T, action: @escaping (T) -> Void) -> some View where T : Equatable, T : Sendable { self }

    nonisolated func privacySensitive(_ sensitive: Bool = true) -> some View { self }

    nonisolated func projectionEffect(_ transform: ProjectionTransform) -> some View { self }

    nonisolated func rotation3DEffect(_ angle: Angle, axis: (x: CGFloat, y: CGFloat, z: CGFloat), anchor: UnitPoint = .center, anchorZ: CGFloat = 0, perspective: CGFloat = 1) -> some View { self }

    nonisolated func scrollIndicators(_ visibility: ScrollIndicatorVisibility, axes: Axis.Set = [.vertical, .horizontal]) -> some View { self }

    nonisolated func scrollTransition(topLeading: ScrollTransitionConfiguration, bottomTrailing: ScrollTransitionConfiguration, axis: Axis? = nil, transition: @escaping (EmptyVisualEffect, ScrollTransitionPhase) -> some VisualEffect) -> some View { self }

    nonisolated func scrollTransition(_ configuration: ScrollTransitionConfiguration = .interactive, axis: Axis? = nil, transition: @escaping (EmptyVisualEffect, ScrollTransitionPhase) -> some VisualEffect) -> some View { self }

    nonisolated func searchCompletion(_ completion: String) -> some View { self }

    nonisolated func searchCompletion<T>(_ token: T) -> some View where T : Identifiable { self }

    nonisolated func toolbarTitleMenu<C>(@ViewBuilder content: () -> C) -> some View where C : View { self }

    nonisolated func writingDirection(strategy: Text.WritingDirectionStrategy) -> some View { self }

    nonisolated func accessibilityHint(_ hint: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHint(_ hintKey: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHint(_ hint: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHint<S>(_ hint: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHint(_ hint: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHint(_ hintKey: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHint(_ hint: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHint<S>(_ hint: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func buttonBorderShape(_ shape: ButtonBorderShape) -> some View { self }

    nonisolated func contentTransition(_ transition: ContentTransition) -> some View { self }

    nonisolated func controlGroupStyle<S>(_ style: S) -> some View where S : ControlGroupStyle { self }

    nonisolated func defaultAppStorage(_ store: UserDefaults) -> some View { self }

    nonisolated func environmentObject<T>(_ object: T) -> some View where T : ObservableObject { self }

    nonisolated func fileDialogMessage(_ messageResource: LocalizedStringResource) -> some View { self }

    nonisolated func fileDialogMessage(_ messageKey: LocalizedStringKey) -> some View { self }

    nonisolated func fileDialogMessage(_ message: Text?) -> some View { self }

    nonisolated func fileDialogMessage<S>(_ message: S) -> some View where S : StringProtocol { self }

    nonisolated func focusedSceneValue<T>(_ object: T?) -> some View where T : AnyObject, T : Observable { self }

    nonisolated func focusedSceneValue<T>(_ keyPath: WritableKeyPath<FocusedValues, T?>, _ value: T?) -> some View { self }

    nonisolated func focusedSceneValue<T>(_ keyPath: WritableKeyPath<FocusedValues, T?>, _ value: T) -> some View { self }

    nonisolated func listRowBackground<V>(_ view: V?) -> some View where V : View { self }

    nonisolated func onContinuousHover(coordinateSpace: CoordinateSpace = .local, perform action: @escaping (HoverPhase) -> Void) -> some View { self }

    nonisolated func onContinuousHover(coordinateSpace: some CoordinateSpaceProtocol = .local, perform action: @escaping (HoverPhase) -> Void) -> some View { self }

    nonisolated func onPencilDoubleTap(perform action: @escaping (PencilDoubleTapGestureValue) -> Void) -> some View { self }

    nonisolated func searchSuggestions(_ visibility: Visibility, for placements: SearchSuggestionsPlacement.Set) -> some View { self }

    nonisolated func searchSuggestions<S>(@ViewBuilder _ suggestions: () -> S) -> some View where S : View { self }

    nonisolated func sectionIndexLabel(_ label: Text?) -> some View { self }

    nonisolated func sectionIndexLabel<S>(_ label: S?) -> some View where S : StringProtocol { self }

    nonisolated func selectionDisabled(_ isDisabled: Bool = true) -> some View { self }

    nonisolated func toolbarBackground(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { self }

    nonisolated func toolbarBackground<S>(_ style: S, for bars: ToolbarPlacement...) -> some View where S : ShapeStyle { self }

    nonisolated func toolbarVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { self }

    nonisolated func accessibilityLabel<V>(@ViewBuilder content: (PlaceholderContentView<Self>) -> V) -> some View where V : View { self }

    nonisolated func accessibilityLabel(_ label: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityLabel(_ labelKey: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityLabel(_ label: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityLabel<S>(_ label: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityLabel(_ label: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityLabel(_ labelKey: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityLabel(_ label: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityLabel<S>(_ label: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityRotor(_ label: LocalizedStringResource, textRanges: [Range<String.Index>]) -> some View { self }

    nonisolated func accessibilityRotor(_ systemRotor: AccessibilitySystemRotor, textRanges: [Range<String.Index>]) -> some View { self }

    nonisolated func accessibilityRotor(_ labelKey: LocalizedStringKey, textRanges: [Range<String.Index>]) -> some View { self }

    nonisolated func accessibilityRotor(_ label: Text, textRanges: [Range<String.Index>]) -> some View { self }

    nonisolated func accessibilityRotor<L>(_ label: L, textRanges: [Range<String.Index>]) -> some View where L : StringProtocol { self }

    nonisolated func accessibilityRotor<EntryModel>(_ rotorLabelResource: LocalizedStringResource, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where EntryModel : Identifiable { self }

    nonisolated func accessibilityRotor<EntryModel>(_ systemRotor: AccessibilitySystemRotor, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where EntryModel : Identifiable { self }

    nonisolated func accessibilityRotor<EntryModel>(_ rotorLabelKey: LocalizedStringKey, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where EntryModel : Identifiable { self }

    nonisolated func accessibilityRotor<EntryModel>(_ rotorLabel: Text, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where EntryModel : Identifiable { self }

    nonisolated func accessibilityRotor<L, EntryModel>(_ rotorLabel: L, entries: [EntryModel], entryLabel: KeyPath<EntryModel, String>) -> some View where L : StringProtocol, EntryModel : Identifiable { self }

    nonisolated func accessibilityRotor<EntryModel, ID>(_ rotorLabelResource: LocalizedStringResource, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where ID : Hashable { self }

    nonisolated func accessibilityRotor<EntryModel, ID>(_ systemRotor: AccessibilitySystemRotor, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where ID : Hashable { self }

    nonisolated func accessibilityRotor<EntryModel, ID>(_ rotorLabelKey: LocalizedStringKey, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where ID : Hashable { self }

    nonisolated func accessibilityRotor<EntryModel, ID>(_ rotorLabel: Text, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where ID : Hashable { self }

    nonisolated func accessibilityRotor<L, EntryModel, ID>(_ rotorLabel: L, entries: [EntryModel], entryID: KeyPath<EntryModel, ID>, entryLabel: KeyPath<EntryModel, String>) -> some View where L : StringProtocol, ID : Hashable { self }

    nonisolated func accessibilityRotor<Content>(_ label: LocalizedStringResource, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where Content : AccessibilityRotorContent { self }

    nonisolated func accessibilityRotor<Content>(_ systemRotor: AccessibilitySystemRotor, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where Content : AccessibilityRotorContent { self }

    nonisolated func accessibilityRotor<Content>(_ labelKey: LocalizedStringKey, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where Content : AccessibilityRotorContent { self }

    nonisolated func accessibilityRotor<Content>(_ label: Text, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where Content : AccessibilityRotorContent { self }

    nonisolated func accessibilityRotor<L, Content>(_ label: L, @AccessibilityRotorContentBuilder entries: @escaping () -> Content) -> some View where L : StringProtocol, Content : AccessibilityRotorContent { self }

    nonisolated func accessibilityValue(_ valueResource: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityValue(_ valueKey: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityValue(_ valueDescription: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityValue<S>(_ value: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityValue(_ valueResource: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityValue(_ valueKey: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityValue(_ valueDescription: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityValue<S>(_ value: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func autocapitalization(_ style: UITextAutocapitalizationType) -> some View { self }

    nonisolated func confirmationDialog<A, M, T>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { self }

    nonisolated func confirmationDialog<A, M, T>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { self }

    nonisolated func confirmationDialog<A, M, T>(_ title: Text, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { self }

    nonisolated func confirmationDialog<S, A, M, T>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where S : StringProtocol, A : View, M : View { self }

    nonisolated func confirmationDialog<A, T>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { self }

    nonisolated func confirmationDialog<A, T>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { self }

    nonisolated func confirmationDialog<A, T>(_ title: Text, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { self }

    nonisolated func confirmationDialog<S, A, T>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where S : StringProtocol, A : View { self }

    nonisolated func confirmationDialog<A, M>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { self }

    nonisolated func confirmationDialog<A, M>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { self }

    nonisolated func confirmationDialog<A, M>(_ title: Text, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { self }

    nonisolated func confirmationDialog<S, A, M>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where S : StringProtocol, A : View, M : View { self }

    nonisolated func confirmationDialog<A>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View where A : View { self }

    nonisolated func confirmationDialog<A>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View where A : View { self }

    nonisolated func confirmationDialog<A>(_ title: Text, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View where A : View { self }

    nonisolated func confirmationDialog<S, A>(_ title: S, isPresented: Binding<Bool>, titleVisibility: Visibility = .automatic, @ViewBuilder actions: () -> A) -> some View where S : StringProtocol, A : View { self }

    nonisolated func defaultHoverEffect(_ effect: HoverEffect?) -> some View { self }

    nonisolated func defaultHoverEffect(_ effect: some CustomHoverEffect) -> some View { self }

    nonisolated func focusedSceneObject<T>(_ object: T) -> some View where T : ObservableObject { self }

    nonisolated func focusedSceneObject<T>(_ object: T?) -> some View where T : ObservableObject { self }

    nonisolated func listSectionMargins(_ edges: Edge.Set = .all, _ length: CGFloat?) -> some View { self }

    nonisolated func listSectionSpacing(_ spacing: CGFloat) -> some View { self }

    nonisolated func listSectionSpacing(_ spacing: ListSectionSpacing) -> some View { self }

    nonisolated func minimumScaleFactor(_ factor: CGFloat) -> some View { self }

    nonisolated func navigationBarItems<L, T>(leading: L, trailing: T) -> some View where L : View, T : View { self }

    nonisolated func navigationBarItems<L>(leading: L) -> some View where L : View { self }

    nonisolated func navigationBarItems<T>(trailing: T) -> some View where T : View { self }

    nonisolated func navigationBarTitle(_ titleKey: LocalizedStringKey, displayMode: NavigationBarItem.TitleDisplayMode) -> some View { self }

    nonisolated func navigationBarTitle(_ title: Text, displayMode: NavigationBarItem.TitleDisplayMode) -> some View { self }

    nonisolated func navigationBarTitle<S>(_ title: S, displayMode: NavigationBarItem.TitleDisplayMode) -> some View where S : StringProtocol { self }

    nonisolated func navigationBarTitle(_ titleKey: LocalizedStringKey) -> some View { self }

    nonisolated func navigationBarTitle(_ title: Text) -> some View { self }

    nonisolated func navigationBarTitle<S>(_ title: S) -> some View where S : StringProtocol { self }

    nonisolated func navigationDocument<D, I1, I2>(_ document: D, preview: SharePreview<I1, I2>) -> some View where D : Transferable, I1 : Transferable, I2 : Transferable { self }

    nonisolated func navigationDocument<D, I>(_ document: D, preview: SharePreview<I, Never>) -> some View where D : Transferable, I : Transferable { self }

    nonisolated func navigationDocument<D>(_ document: D, preview: SharePreview<Never, Never>) -> some View where D : Transferable { self }

    nonisolated func navigationDocument<D, I>(_ document: D, preview: SharePreview<Never, I>) -> some View where D : Transferable, I : Transferable { self }

    nonisolated func navigationDocument(_ url: URL) -> some View { self }

    nonisolated func navigationDocument<D>(_ document: D) -> some View where D : Transferable { self }

    nonisolated func navigationSubtitle(_ subtitleKey: LocalizedStringResource) -> some View { self }

    nonisolated func navigationSubtitle(_ subtitleKey: LocalizedStringKey) -> some View { self }

    nonisolated func navigationSubtitle(_ subtitle: Text) -> some View { self }

    nonisolated func navigationSubtitle<S>(_ subtitle: S) -> some View where S : StringProtocol { self }

    nonisolated func onLongPressGesture(minimumDuration: Double = 0.5, maximumDistance: CGFloat = 10, perform action: @escaping () -> Void, onPressingChanged: ((Bool) -> Void)? = nil) -> some View { self }

    nonisolated func onLongPressGesture(minimumDuration: Double = 0.5, maximumDistance: CGFloat = 10, pressing: ((Bool) -> Void)? = nil, perform action: @escaping () -> Void) -> some View { self }

    nonisolated func onLongPressGesture(minimumDuration: Double = 0.5, perform action: @escaping () -> Void, onPressingChanged: ((Bool) -> Void)? = nil) -> some View { self }

    nonisolated func onLongPressGesture(minimumDuration: Double = 0.5, pressing: ((Bool) -> Void)? = nil, perform action: @escaping () -> Void) -> some View { self }

    nonisolated func onPreferenceChange<K>(_ key: K.Type = K.self, perform action: @escaping (K.Value) -> Void) -> some View where K : PreferenceKey, K.Value : Equatable { self }

    nonisolated func presentationSizing(_ sizing: some PresentationSizing) -> some View { self }

    nonisolated func previewDisplayName(_ value: String?) -> some View { self }

    nonisolated func scrollClipDisabled(_ disabled: Bool = true) -> some View { self }

    nonisolated func scrollTargetLayout(isEnabled: Bool = true) -> some View { self }

    nonisolated func tableColumnHeaders(_ visibility: Visibility) -> some View { self }

    nonisolated func toolbarColorScheme(_ colorScheme: ColorScheme?, for bars: ToolbarPlacement...) -> some View { self }

    nonisolated func accessibilityAction(named nameResource: LocalizedStringResource, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityAction(named nameKey: LocalizedStringKey, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityAction(named name: Text, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityAction<S>(named name: S, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityAction<Label>(action: @escaping () -> Void, @ViewBuilder label: () -> Label) -> some View where Label : View { self }

    nonisolated func accessibilityAction(_ actionKind: AccessibilityActionKind = .default, _ handler: @escaping () -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHidden(_ hidden: Bool, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityHidden(_ hidden: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func allowedDynamicRange(_ range: Image.DynamicRange?) -> some View { self }

    nonisolated func containerBackground<V>(for container: ContainerBackgroundPlacement, alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View { self }

    nonisolated func containerBackground<S>(_ style: S, for container: ContainerBackgroundPlacement) -> some View where S : ShapeStyle { self }

    nonisolated func defaultScrollAnchor(_ anchor: UnitPoint?, for role: ScrollAnchorRole) -> some View { self }

    nonisolated func defaultScrollAnchor(_ anchor: UnitPoint?) -> some View { self }

    nonisolated func focusEffectDisabled(_ disabled: Bool = true) -> some View { self }

    nonisolated func gridCellUnsizedAxes(_ axes: Axis.Set) -> some View { self }

    nonisolated func gridColumnAlignment(_ guide: HorizontalAlignment) -> some View { self }

    nonisolated func handGestureShortcut(_ shortcut: HandGestureShortcut, isEnabled: Bool = true) -> some View { self }

    nonisolated func highPriorityGesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture { self }

    nonisolated func highPriorityGesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture { self }

    nonisolated func highPriorityGesture<T>(_ gesture: T, isEnabled: Bool) -> some View where T : Gesture { self }

    nonisolated func hoverEffectDisabled(_ disabled: Bool = true) -> some View { self }

    nonisolated func labeledContentStyle<S>(_ style: S) -> some View where S : LabeledContentStyle { self }

    nonisolated func navigationBarHidden(_ hidden: Bool) -> some View { self }

    nonisolated func onScrollPhaseChange(_ action: @escaping (ScrollPhase, ScrollPhase) -> Void) -> some View { self }

    nonisolated func onScrollPhaseChange(_ action: @escaping (ScrollPhase, ScrollPhase, ScrollPhaseChangeContext) -> Void) -> some View { self }

    nonisolated func presentationDetents(_ detents: Set<PresentationDetent>, selection: Binding<PresentationDetent>) -> some View { self }

    nonisolated func presentationDetents(_ detents: Set<PresentationDetent>) -> some View { self }

    @MainActor @preconcurrency func scrollInputBehavior(_ behavior: ScrollInputBehavior, for input: ScrollInputKind) -> some View { self }

    nonisolated func simultaneousGesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture { self }

    nonisolated func simultaneousGesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture { self }

    nonisolated func simultaneousGesture<T>(_ gesture: T, isEnabled: Bool) -> some View where T : Gesture { self }

    nonisolated func speechAdjustedPitch(_ value: Double) -> some View { self }

    nonisolated func symbolRenderingMode(_ mode: SymbolRenderingMode?) -> some View { self }

    nonisolated func transformPreference<K>(_ key: K.Type = K.self, _ callback: @escaping (inout K.Value) -> Void) -> some View where K : PreferenceKey { self }

    nonisolated func typesettingLanguage(_ language: Locale.Language, isEnabled: Bool = true) -> some View { self }

    nonisolated func typesettingLanguage(_ language: TypesettingLanguage, isEnabled: Bool = true) -> some View { self }

    nonisolated func accessibilityActions<Content>(category: AccessibilityActionCategory, @ViewBuilder _ content: () -> Content) -> some View where Content : View { self }

    nonisolated func accessibilityActions<Content>(@ViewBuilder _ content: () -> Content) -> some View where Content : View { self }

    nonisolated func accessibilityElement(children: AccessibilityChildBehavior = .ignore) -> some View { self }

    nonisolated func accessibilityFocused<Value>(_ binding: AccessibilityFocusState<Value>.Binding, equals value: Value) -> some View where Value : Hashable { self }

    nonisolated func accessibilityFocused(_ condition: AccessibilityFocusState<Bool>.Binding) -> some View { self }

    nonisolated func accessibilityHeading(_ level: AccessibilityHeadingLevel) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func buttonRepeatBehavior(_ behavior: ButtonRepeatBehavior) -> some View { self }

    nonisolated func defersSystemGestures(on edges: Edge.Set) -> some View { self }

    nonisolated func disclosureGroupStyle<S>(_ style: S) -> some View where S : DisclosureGroupStyle { self }

    nonisolated func fileDialogURLEnabled(_ predicate: Predicate<URL>) -> some View { self }

    nonisolated func inspectorColumnWidth(min: CGFloat? = nil, ideal: CGFloat, max: CGFloat? = nil) -> some View { self }

    nonisolated func inspectorColumnWidth(_ width: CGFloat) -> some View { self }

    nonisolated func invalidatableContent(_ invalidatable: Bool = true) -> some View { self }

    nonisolated func listRowSeparatorTint(_ color: Color?, edges: VerticalEdge.Set = .all) -> some View { self }

    nonisolated func listSectionSeparator(_ visibility: Visibility, edges: VerticalEdge.Set = .all) -> some View { self }

    nonisolated func navigationTransition(_ style: some NavigationTransition) -> some View { self }

    nonisolated func preferredColorScheme(_ colorScheme: ColorScheme?) -> some View { self }

    nonisolated func scrollBounceBehavior(_ behavior: ScrollBounceBehavior, axes: Axis.Set = [.vertical]) -> some View { self }

    nonisolated func scrollTargetBehavior(_ behavior: some ScrollTargetBehavior) -> some View { self }

    nonisolated func symbolEffectsRemoved(_ isEnabled: Bool = true) -> some View { self }

    nonisolated func transformEnvironment<V>(_ keyPath: WritableKeyPath<EnvironmentValues, V>, transform: @escaping (inout V) -> Void) -> some View { self }

    nonisolated func typeSelectEquivalent(_ stringResource: LocalizedStringResource) -> some View { self }

    nonisolated func typeSelectEquivalent(_ stringKey: LocalizedStringKey) -> some View { self }

    nonisolated func typeSelectEquivalent(_ text: Text?) -> some View { self }

    nonisolated func typeSelectEquivalent<S>(_ string: S) -> some View where S : StringProtocol { self }

    @MainActor @preconcurrency func writingToolsBehavior(_ behavior: WritingToolsBehavior) -> some View { self }

    nonisolated func accessibilityChildren<V>(@ViewBuilder children: () -> V) -> some View where V : View { self }

    nonisolated func containerCornerOffset(_ edges: Edge.Set, sizeToFit: Bool = false) -> some View { self }

    nonisolated func disableAutocorrection(_ disable: Bool?) -> some View { self }

    nonisolated func edgesIgnoringSafeArea(_ edges: Edge.Set) -> some View { self }

    @MainActor @preconcurrency func glassEffectTransition(_ transition: GlassEffectTransition) -> some View { self }

    nonisolated func handlesExternalEvents(preferring: Set<String>, allowing: Set<String>) -> some View { self }

    nonisolated func matchedGeometryEffect<ID>(id: ID, in namespace: Namespace.ID, properties: MatchedGeometryProperties = .frame, anchor: UnitPoint = .center, isSource: Bool = true) -> some View where ID : Hashable { self }

    nonisolated func navigationDestination<V>(isPresented: Binding<Bool>, @ViewBuilder destination: () -> V) -> some View where V : View { self }

    nonisolated func navigationDestination<D, C>(for data: D.Type, @ViewBuilder destination: @escaping (D) -> C) -> some View where D : Hashable, C : View { self }

    nonisolated func navigationDestination<D, C>(item: Binding<Optional<D>>, @ViewBuilder destination: @escaping (D) -> C) -> some View where D : Hashable, C : View { self }

    nonisolated func scrollEdgeEffectStyle(_ style: ScrollEdgeEffectStyle?, for edges: Edge.Set) -> some View { self }

    nonisolated func scrollIndicatorsFlash(trigger value: some Equatable) -> some View { self }

    nonisolated func scrollIndicatorsFlash(onAppear: Bool) -> some View { self }

    nonisolated func searchToolbarBehavior(_ behavior: SearchToolbarBehavior) -> some View { self }

    nonisolated func sliderThumbVisibility(_ visibility: Visibility) -> some View { self }

    nonisolated func springLoadingBehavior(_ behavior: SpringLoadingBehavior) -> some View { self }

    nonisolated func textSelectionAffinity(_ affinity: TextSelectionAffinity) -> some View { self }

    nonisolated func accessibilityAddTraits(_ traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDragPoint<S>(_ point: UnitPoint, description: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDragPoint(_ point: UnitPoint, description: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDragPoint<S>(_ point: UnitPoint, description: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: LocalizedStringResource, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: LocalizedStringKey, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: Text, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDropPoint<S>(_ point: UnitPoint, description: S, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: LocalizedStringResource) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: LocalizedStringKey) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDropPoint(_ point: UnitPoint, description: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityDropPoint<S>(_ point: UnitPoint, description: S) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func autocorrectionDisabled(_ disable: Bool = true) -> some View { self }

    nonisolated func containerRelativeFrame(_ axes: Axis.Set, count: Int, span: Int = 1, spacing: CGFloat, alignment: Alignment = .center) -> some View { self }

    nonisolated func containerRelativeFrame(_ axes: Axis.Set, alignment: Alignment = .center) -> some View { self }

    nonisolated func containerRelativeFrame(_ axes: Axis.Set, alignment: Alignment = .center, _ length: @escaping (CGFloat, Axis) -> CGFloat) -> some View { self }

    nonisolated func labelReservedIconWidth(_ value: CGFloat) -> some View { self }

    nonisolated func multilineTextAlignment(strategy: Text.AlignmentStrategy) -> some View { self }

    nonisolated func multilineTextAlignment(_ alignment: TextAlignment) -> some View { self }

    nonisolated func onContinueUserActivity(_ activityType: String, perform action: @escaping (NSUserActivity) -> ()) -> some View { self }

    nonisolated func onScrollGeometryChange<T>(for type: T.Type, of transform: @escaping (ScrollGeometry) -> T, action: @escaping (T, T) -> Void) -> some View where T : Equatable { self }

    nonisolated func overlayPreferenceValue<K, V>(_ key: K.Type, alignment: Alignment = .center, @ViewBuilder _ transform: @escaping (K.Value) -> V) -> some View where K : PreferenceKey, V : View { self }

    nonisolated func overlayPreferenceValue<Key, T>(_ key: Key.Type = Key.self, @ViewBuilder _ transform: @escaping (Key.Value) -> T) -> some View where Key : PreferenceKey, T : View { self }

    nonisolated func paletteSelectionEffect(_ effect: PaletteSelectionEffect) -> some View { self }

    nonisolated func presentationBackground<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View { self }

    nonisolated func presentationBackground<S>(_ style: S) -> some View where S : ShapeStyle { self }

    nonisolated func scrollEdgeEffectHidden(_ hidden: Bool = true, for edges: Edge.Set = .all) -> some View { self }

    nonisolated func tabBarMinimizeBehavior(_ behavior: TabBarMinimizeBehavior) -> some View { self }

    nonisolated func toolbarForegroundStyle<S>(_ style: S, for bars: ToolbarPlacement...) -> some View where S : ShapeStyle { self }

    nonisolated func accessibilityIdentifier(_ identifier: String, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityIdentifier(_ identifier: String) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityRotorEntry<ID>(id: ID, in namespace: Namespace.ID) -> some View where ID : Hashable { self }

    nonisolated func accessibilityZoomAction(_ handler: @escaping (AccessibilityZoomGestureAction) -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func dialogSuppressionToggle(isSuppressed: Binding<Bool>) -> some View { self }

    nonisolated func dialogSuppressionToggle(_ titleResource: LocalizedStringResource, isSuppressed: Binding<Bool>) -> some View { self }

    nonisolated func dialogSuppressionToggle(_ titleKey: LocalizedStringKey, isSuppressed: Binding<Bool>) -> some View { self }

    nonisolated func dialogSuppressionToggle(_ label: Text, isSuppressed: Binding<Bool>) -> some View { self }

    nonisolated func dialogSuppressionToggle<S>(_ title: S, isSuppressed: Binding<Bool>) -> some View where S : StringProtocol { self }

    nonisolated func labelIconToTitleSpacing(_ value: CGFloat) -> some View { self }

    nonisolated func layoutDirectionBehavior(_ behavior: LayoutDirectionBehavior) -> some View { self }

    nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID, configuration: (EmptyMatchedTransitionSourceConfiguration) -> some MatchedTransitionSourceConfiguration) -> some View { self }

    nonisolated func matchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View { self }

    nonisolated func scrollContentBackground(_ visibility: Visibility) -> some View { self }

    nonisolated func scrollDismissesKeyboard(_ mode: ScrollDismissesKeyboardMode) -> some View { self }

    nonisolated func searchDictationBehavior(_ dictationBehavior: TextInputDictationBehavior) -> some View { self }

    nonisolated func symbolVariableValueMode(_ mode: SymbolVariableValueMode?) -> some View { self }

    nonisolated func toolbarTitleDisplayMode(_ mode: ToolbarTitleDisplayMode) -> some View { self }

    nonisolated func accessibilityDirectTouch(_ isDirectTouchArea: Bool = true, options: AccessibilityDirectTouchOptions = []) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityInputLabels(_ inputLabelKeys: [LocalizedStringKey], isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityInputLabels(_ inputLabels: [Text], isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityInputLabels<S>(_ inputLabels: [S], isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityInputLabels(_ inputLabelKeys: [LocalizedStringKey]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityInputLabels(_ inputLabels: [Text]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityInputLabels<S>(_ inputLabels: [S]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where S : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityLabeledPair<ID>(role: AccessibilityLabeledPairRole, id: ID, in namespace: Namespace.ID) -> some View where ID : Hashable { self }

    nonisolated func accessibilityLinkedGroup<ID>(id: ID, in namespace: Namespace.ID) -> some View where ID : Hashable { self }

    nonisolated func fileDialogBrowserOptions(_ options: FileDialogBrowserOptions) -> some View { self }

    nonisolated func listSectionSeparatorTint(_ color: Color?, edges: VerticalEdge.Set = .all) -> some View { self }

    nonisolated func materialActiveAppearance(_ appearance: MaterialActiveAppearance) -> some View { self }

    nonisolated func onScrollVisibilityChange(threshold: Double = 0.5, _ action: @escaping (Bool) -> Void) -> some View { self }

    nonisolated func persistentSystemOverlays(_ visibility: Visibility) -> some View { self }

    nonisolated func presentationCornerRadius(_ cornerRadius: CGFloat?) -> some View { self }

    nonisolated func symbolColorRenderingMode(_ mode: SymbolColorRenderingMode?) -> some View { self }

    nonisolated func accessibilityDefaultFocus<Value>(_ binding: AccessibilityFocusState<Value>.Binding, _ value: Value) -> some View where Value : Hashable { self }

    nonisolated func accessibilityRemoveTraits(_ traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityScrollAction(_ handler: @escaping (Edge) -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityScrollStatus(_ status: LocalizedStringResource, isEnabled: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityScrollStatus(_ statusKey: LocalizedStringKey, isEnabled: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityScrollStatus(_ status: Text, isEnabled: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityScrollStatus(_ status: some StringProtocol, isEnabled: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilitySortPriority(_ sortPriority: Double) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    @MainActor @preconcurrency func backgroundExtensionEffect(isEnabled: Bool) -> some View { self }

    @MainActor @preconcurrency func backgroundExtensionEffect() -> some View { self }

    nonisolated func backgroundPreferenceValue<K, V>(_ key: K.Type, alignment: Alignment = .center, @ViewBuilder _ transform: @escaping (K.Value) -> V) -> some View where K : PreferenceKey, V : View { self }

    nonisolated func backgroundPreferenceValue<Key, T>(_ key: Key.Type = Key.self, @ViewBuilder _ transform: @escaping (Key.Value) -> T) -> some View where Key : PreferenceKey, T : View { self }

    nonisolated func fileDialogCustomizationID(_ id: String) -> some View { self }

    nonisolated func fileExporterFilenameLabel(_ label: LocalizedStringResource) -> some View { self }

    nonisolated func fileExporterFilenameLabel(_ labelKey: LocalizedStringKey) -> some View { self }

    nonisolated func fileExporterFilenameLabel(_ label: Text?) -> some View { self }

    nonisolated func fileExporterFilenameLabel<S>(_ label: S) -> some View where S : StringProtocol { self }

    nonisolated func menuActionDismissBehavior(_ behavior: MenuActionDismissBehavior) -> some View { self }

    nonisolated func onInteractiveResizeChange(_ action: @escaping (Bool) -> Void) -> some View { self }

    nonisolated func presentationDragIndicator(_ visibility: Visibility) -> some View { self }

    nonisolated func speechAnnouncementsQueued(_ value: Bool = true) -> some View { self }

    nonisolated func speechSpellsOutCharacters(_ value: Bool = true) -> some View { self }

    nonisolated func transformAnchorPreference<A, K>(key _: K.Type = K.self, value: Anchor<A>.Source, transform: @escaping (inout K.Value, Anchor<A>) -> Void) -> some View where K : PreferenceKey { self }

    nonisolated func accessibilityCustomContent(_ label: LocalizedStringResource, _ value: Text, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent(_ label: LocalizedStringResource, _ valueResource: LocalizedStringResource, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent<V>(_ label: LocalizedStringResource, _ value: V, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where V : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent(_ key: AccessibilityCustomContentKey, _ valueResource: LocalizedStringResource, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent(_ key: AccessibilityCustomContentKey, _ valueKey: LocalizedStringKey, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent(_ key: AccessibilityCustomContentKey, _ value: Text?, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent<V>(_ key: AccessibilityCustomContentKey, _ value: V, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where V : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent(_ labelKey: LocalizedStringKey, _ value: Text, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent(_ labelKey: LocalizedStringKey, _ valueKey: LocalizedStringKey, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent<V>(_ labelKey: LocalizedStringKey, _ value: V, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where V : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent(_ label: Text, _ value: Text, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityCustomContent<L, V>(_ label: L, _ value: V, importance: AXCustomContent.Importance = .default) -> ModifiedContent<Self, AccessibilityAttachmentModifier> where L : StringProtocol, V : StringProtocol { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    @MainActor @preconcurrency func documentBrowserContextMenu(@ViewBuilder _ menu: @escaping ([URL]?) -> some View) -> some View { self }

    nonisolated func fileDialogDefaultDirectory(_ defaultDirectory: URL?) -> some View { self }

    nonisolated func interactiveDismissDisabled(_ isDisabled: Bool = true) -> some View { self }

    nonisolated func listSectionIndexVisibility(_ visibility: Visibility) -> some View { self }

    nonisolated func accessibilityRepresentation<V>(@ViewBuilder representation: () -> V) -> some View where V : View { self }

    nonisolated func fileDialogConfirmationLabel(_ label: LocalizedStringResource) -> some View { self }

    nonisolated func fileDialogConfirmationLabel(_ labelKey: LocalizedStringKey) -> some View { self }

    nonisolated func fileDialogConfirmationLabel(_ label: Text?) -> some View { self }

    nonisolated func fileDialogConfirmationLabel<S>(_ label: S) -> some View where S : StringProtocol { self }

    nonisolated func previewInterfaceOrientation(_ value: InterfaceOrientation) -> some View { self }

    nonisolated func textInputAutocapitalization(_ autocapitalization: TextInputAutocapitalization?) -> some View { self }

    nonisolated func toolbarBackgroundVisibility(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { self }

    nonisolated func accessibilityActivationPoint(_ activationPoint: UnitPoint, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityActivationPoint(_ activationPoint: CGPoint, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityActivationPoint(_ activationPoint: UnitPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityActivationPoint(_ activationPoint: CGPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityChartDescriptor<R>(_ representable: R) -> some View where R : AXChartDescriptorRepresentable { self }

    nonisolated func accessibilityTextContentType(_ value: AccessibilityTextContentType) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func allowsWindowActivationEvents() -> some View { self }

    nonisolated func allowsWindowActivationEvents(_ value: Bool?) -> some View { self }

    nonisolated func accessibilityAdjustableAction(_ handler: @escaping (AccessibilityAdjustmentDirection) -> Void) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func assistiveAccessNavigationIcon(systemImage: String) -> some View { self }

    nonisolated func assistiveAccessNavigationIcon(_ icon: Image) -> some View { self }

    nonisolated func navigationBarBackButtonHidden(_ hidesBackButton: Bool = true) -> some View { self }

    nonisolated func navigationBarTitleDisplayMode(_ displayMode: NavigationBarItem.TitleDisplayMode) -> some View { self }

    nonisolated func presentationCompactAdaptation(horizontal horizontalAdaptation: PresentationAdaptation, vertical verticalAdaptation: PresentationAdaptation) -> some View { self }

    nonisolated func presentationCompactAdaptation(_ adaptation: PresentationAdaptation) -> some View { self }

    nonisolated func id<ID>(_ id: ID) -> some View where ID : Hashable { self }

    nonisolated func interactionActivityTrackingTag(_ tag: String) -> some View { self }

    nonisolated func onScrollTargetVisibilityChange<ID>(idType: ID.Type, threshold: Double = 0.5, _ action: @escaping ([ID]) -> Void) -> some View where ID : Hashable { self }

    nonisolated func presentationContentInteraction(_ behavior: PresentationContentInteraction) -> some View { self }

    nonisolated func defaultAdaptableTabBarPlacement(_ defaultPlacement: AdaptableTabBarPlacement = .automatic) -> some View { self }

    nonisolated func speechAlwaysIncludesPunctuation(_ value: Bool = true) -> some View { self }

    nonisolated func accessibilityIgnoresInvertColors(_ active: Bool = true) -> some View { self }

    @MainActor @preconcurrency func writingToolsAffordanceVisibility(_ visibility: Visibility) -> some View { self }

    @MainActor @preconcurrency func navigationLinkIndicatorVisibility(_ visibility: Visibility) -> some View { self }

    nonisolated func presentationBackgroundInteraction(_ interaction: PresentationBackgroundInteraction) -> some View { self }

    nonisolated func searchPresentationToolbarBehavior(_ behavior: SearchPresentationToolbarBehavior) -> some View { self }

    nonisolated func windowToolbarFullScreenVisibility(_ visibility: WindowToolbarFullScreenVisibility) -> some View { self }

    nonisolated func attributedTextFormattingDefinition<D>(_ definition: D) -> some View where D : AttributedTextFormattingDefinition { self }

    nonisolated func attributedTextFormattingDefinition<S>(_ scope: S.Type) -> some View where S : AttributeScope { self }

    nonisolated func attributedTextFormattingDefinition<S>(_ path: KeyPath<AttributeScopes, S.Type>) -> some View where S : AttributeScope { self }

    nonisolated func fileDialogImportsUnresolvedAliases(_ imports: Bool) -> some View { self }

    nonisolated func flipsForRightToLeftLayoutDirection(_ enabled: Bool) -> some View { self }

    nonisolated func accessibilityShowsLargeContentViewer() -> some View { self }

    nonisolated func accessibilityShowsLargeContentViewer<V>(@ViewBuilder _ largeContentView: () -> V) -> some View where V : View { self }

    nonisolated func textInputFormattingControlVisibility(_ visibility: Visibility, for placement: TextInputFormattingControlPlacement.Set) -> some View { self }

    nonisolated func accessibilityRespondsToUserInteraction(_ respondsToUserInteraction: Bool, isEnabled: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func accessibilityRespondsToUserInteraction(_ respondsToUserInteraction: Bool = true) -> ModifiedContent<Self, AccessibilityAttachmentModifier> { ModifiedContent(content: self, modifier: AccessibilityAttachmentModifier()) }

    nonisolated func tag<V>(_ tag: V, includeOptional: Bool = true) -> some View where V : Hashable { self }

    nonisolated func blur(radius: CGFloat, opaque: Bool = false) -> some View { self }

    nonisolated func bold(_ isActive: Bool = true) -> some View { self }

    nonisolated func font(_ font: Font?) -> some View { self }

    nonisolated func help(_ textKey: LocalizedStringResource) -> some View { self }

    nonisolated func help(_ textKey: LocalizedStringKey) -> some View { self }

    nonisolated func help(_ text: Text) -> some View { self }

    nonisolated func help<S>(_ text: S) -> some View where S : StringProtocol { self }

    nonisolated func mask<Mask>(alignment: Alignment = .center, @ViewBuilder _ mask: () -> Mask) -> some View where Mask : View { self }

    nonisolated func mask<Mask>(_ mask: Mask) -> some View where Mask : View { self }

    nonisolated func task<T>(id: T, name: String? = nil, executorPreference taskExecutor: any TaskExecutor, priority: TaskPriority = .userInitiated, file: String = #fileID, line: Int = #line, _ action: sending @escaping @isolated(any) () async -> Void) -> some View where T : Equatable { self }

    nonisolated func task<T>(id value: T, priority: TaskPriority = .userInitiated, _ action: @escaping () async -> Void) -> some View where T : Equatable { self }

    nonisolated func task(priority: TaskPriority = .userInitiated, _ action: @escaping () async -> Void) -> some View { self }

    nonisolated func tint(_ tint: Color?) -> some View { self }

    nonisolated func tint<S>(_ tint: S?) -> some View where S : ShapeStyle { self }

    nonisolated func alert<E, A, M>(isPresented: Binding<Bool>, error: E?, @ViewBuilder actions: (E) -> A, @ViewBuilder message: (E) -> M) -> some View where E : LocalizedError, A : View, M : View { self }

    nonisolated func alert<E, A>(isPresented: Binding<Bool>, error: E?, @ViewBuilder actions: () -> A) -> some View where E : LocalizedError, A : View { self }

    nonisolated func alert(isPresented: Binding<Bool>, content: () -> Alert) -> some View { self }

    nonisolated func alert<Item>(item: Binding<Item?>, content: (Item) -> Alert) -> some View where Item : Identifiable { self }

    nonisolated func alert<A, M, T>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { self }

    nonisolated func alert<A, M, T>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { self }

    nonisolated func alert<A, M, T>(_ title: Text, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where A : View, M : View { self }

    nonisolated func alert<S, A, M, T>(_ title: S, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A, @ViewBuilder message: (T) -> M) -> some View where S : StringProtocol, A : View, M : View { self }

    nonisolated func alert<A, T>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { self }

    nonisolated func alert<A, T>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { self }

    nonisolated func alert<A, T>(_ title: Text, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where A : View { self }

    nonisolated func alert<S, A, T>(_ title: S, isPresented: Binding<Bool>, presenting data: T?, @ViewBuilder actions: (T) -> A) -> some View where S : StringProtocol, A : View { self }

    nonisolated func alert<A, M>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { self }

    nonisolated func alert<A, M>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { self }

    nonisolated func alert<A, M>(_ title: Text, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where A : View, M : View { self }

    nonisolated func alert<S, A, M>(_ title: S, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A, @ViewBuilder message: () -> M) -> some View where S : StringProtocol, A : View, M : View { self }

    nonisolated func alert<A>(_ titleResource: LocalizedStringResource, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View where A : View { self }

    nonisolated func alert<A>(_ titleKey: LocalizedStringKey, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View where A : View { self }

    nonisolated func alert<A>(_ title: Text, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View where A : View { self }

    nonisolated func alert<S, A>(_ title: S, isPresented: Binding<Bool>, @ViewBuilder actions: () -> A) -> some View where S : StringProtocol, A : View { self }

    nonisolated func badge(_ resource: LocalizedStringResource?) -> some View { self }

    nonisolated func badge(_ key: LocalizedStringKey?) -> some View { self }

    nonisolated func badge(_ label: Text?) -> some View { self }

    nonisolated func badge(_ count: Int) -> some View { self }

    nonisolated func badge<S>(_ label: S?) -> some View where S : StringProtocol { self }

    nonisolated func frame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View { self }

    nonisolated func frame(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil, alignment: Alignment = .center) -> some View { self }

    nonisolated func frame() -> some View { self }

    nonisolated func sheet<Content>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View { self }

    nonisolated func sheet<Item, Content>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View { self }

    nonisolated func border<S>(_ content: S, width: CGFloat = 1) -> some View where S : ShapeStyle { self }

    nonisolated func hidden() -> some View { self }

    nonisolated func italic(_ isActive: Bool = true) -> some View { self }

    nonisolated func offset(x: CGFloat = 0, y: CGFloat = 0) -> some View { self }

    nonisolated func offset(_ offset: CGSize) -> some View { self }

    nonisolated func onDrag<V>(_ data: @escaping () -> NSItemProvider, @ViewBuilder preview: () -> V) -> some View where V : View { self }

    nonisolated func onDrag(_ data: @escaping () -> NSItemProvider) -> some View { self }

    nonisolated func onDrop(of supportedContentTypes: [UTType], isTargeted: Binding<Bool>?, perform action: @escaping ([NSItemProvider], CGPoint) -> Bool) -> some View { self }

    nonisolated func onDrop(of supportedContentTypes: [UTType], isTargeted: Binding<Bool>?, perform action: @escaping ([NSItemProvider]) -> Bool) -> some View { self }

    nonisolated func onDrop(of supportedTypes: [String], isTargeted: Binding<Bool>?, perform action: @escaping ([NSItemProvider], CGPoint) -> Bool) -> some View { self }

    nonisolated func onDrop(of supportedTypes: [String], isTargeted: Binding<Bool>?, perform action: @escaping ([NSItemProvider]) -> Bool) -> some View { self }

    nonisolated func onDrop(of supportedContentTypes: [UTType], delegate: any DropDelegate) -> some View { self }

    nonisolated func onDrop(of supportedTypes: [String], delegate: any DropDelegate) -> some View { self }

    nonisolated func shadow(color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33), radius: CGFloat, x: CGFloat = 0, y: CGFloat = 0) -> some View { self }

    nonisolated func zIndex(_ value: Double) -> some View { self }

    nonisolated func clipped(antialiased: Bool = false) -> some View { self }

    nonisolated func focused<Value>(_ binding: FocusState<Value>.Binding, equals value: Value) -> some View where Value : Hashable { self }

    nonisolated func focused(_ condition: FocusState<Bool>.Binding) -> some View { self }

    nonisolated func gesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture { self }

    nonisolated func gesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture { self }

    nonisolated func gesture<T>(_ gesture: T, isEnabled: Bool) -> some View where T : Gesture { self }

    nonisolated func gesture(_ representable: some UIGestureRecognizerRepresentable) -> some View { self }

    nonisolated func kerning(_ kerning: CGFloat) -> some View { self }

    nonisolated func onHover(perform action: @escaping (Bool) -> Void) -> some View { self }

    nonisolated func opacity(_ opacity: Double) -> some View { self }

    nonisolated func overlay<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View { self }

    nonisolated func overlay<S>(_ style: S, ignoresSafeAreaEdges edges: Edge.Set = .all) -> some View where S : ShapeStyle { self }

    nonisolated func overlay<S, T>(_ style: S, in shape: T, fillStyle: FillStyle = FillStyle()) -> some View where S : ShapeStyle, T : Shape { self }

    nonisolated func overlay<Overlay>(_ overlay: Overlay, alignment: Alignment = .center) -> some View where Overlay : View { self }

    nonisolated func padding(_ length: CGFloat) -> some View { self }

    nonisolated func padding(_ insets: EdgeInsets) -> some View { self }

    nonisolated func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View { self }

    nonisolated func popover<Content>(isPresented: Binding<Bool>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View { self }

    nonisolated func popover<Item, Content>(item: Binding<Item?>, attachmentAnchor: PopoverAttachmentAnchor = .rect(.bounds), arrowEdge: Edge? = nil, @ViewBuilder content: @escaping (Item) -> Content) -> some View where Item : Identifiable, Content : View { self }

    nonisolated func tabItem<V>(@ViewBuilder _ label: () -> V) -> some View where V : View { self }

    nonisolated func toolbar<Content>(id: String, @ToolbarContentBuilder content: () -> Content) -> some View where Content : CustomizableToolbarContent { self }

    nonisolated func toolbar<Content>(@ToolbarContentBuilder content: () -> Content) -> some View where Content : ToolbarContent { self }

    nonisolated func toolbar<Content>(@ViewBuilder content: () -> Content) -> some View where Content : View { self }

    nonisolated func toolbar(removing defaultItemKind: ToolbarDefaultItemKind?) -> some View { self }

    nonisolated func toolbar(_ visibility: Visibility, for bars: ToolbarPlacement...) -> some View { self }

    nonisolated func contrast(_ amount: Double) -> some View { self }

    nonisolated func disabled(_ disabled: Bool) -> some View { self }

    nonisolated func modifier<T>(_ modifier: T) -> ModifiedContent<Self, T> { ModifiedContent(content: self, modifier: modifier) }

    nonisolated func onAppear(perform action: (() -> Void)? = nil) -> some View { self }

    nonisolated func onChange<V>(of value: V, initial: Bool = false, _ action: @escaping (V, V) -> Void) -> some View where V : Equatable { self }

    nonisolated func onChange<V>(of value: V, initial: Bool = false, _ action: @escaping () -> Void) -> some View where V : Equatable { self }

    nonisolated func onChange<V>(of value: V, perform action: @escaping (V) -> Void) -> some View where V : Equatable { self }

    nonisolated func onSubmit(of triggers: SubmitTriggers = .text, _ action: @escaping () -> Void) -> some View { self }

    nonisolated func position(x: CGFloat = 0, y: CGFloat = 0) -> some View { self }

    nonisolated func position(_ position: CGPoint) -> some View { self }

    nonisolated func redacted(reason: RedactionReasons) -> some View { self }

    nonisolated func textCase(_ textCase: Text.Case?) -> some View { self }

    nonisolated func tracking(_ tracking: CGFloat) -> some View { self }

    nonisolated func animation<V>(_ animation: Animation?, @ViewBuilder body: (PlaceholderContentView<Self>) -> V) -> some View where V : View { self }

    nonisolated func animation<V>(_ animation: Animation?, value: V) -> some View where V : Equatable { self }

    nonisolated func animation(_ animation: Animation?) -> some View { self }

    nonisolated func blendMode(_ blendMode: BlendMode) -> some View { self }

    nonisolated func clipShape<S>(_ shape: S, style: FillStyle = FillStyle()) -> some View where S : Shape { self }

    nonisolated func draggable<V, T>(_ payload: @autoclosure @escaping () -> T, @ViewBuilder preview: () -> V) -> some View where V : View, T : Transferable { self }

    nonisolated func draggable<T>(_ payload: @autoclosure @escaping () -> T) -> some View where T : Transferable { self }

    nonisolated func fileMover(isPresented: Binding<Bool>, file: URL?, onCompletion: @escaping (Result<URL, any Error>) -> Void, onCancellation: @escaping () -> Void) -> some View { self }

    nonisolated func fileMover(isPresented: Binding<Bool>, file: URL?, onCompletion: @escaping (Result<URL, any Error>) -> Void) -> some View { self }

    nonisolated func fileMover<C>(isPresented: Binding<Bool>, files: C, onCompletion: @escaping (Result<[URL], any Error>) -> Void, onCancellation: @escaping () -> Void) -> some View where C : Collection, C.Element == URL { self }

    nonisolated func fileMover<C>(isPresented: Binding<Bool>, files: C, onCompletion: @escaping (Result<[URL], any Error>) -> Void) -> some View where C : Collection, C.Element == URL { self }

    nonisolated func fixedSize(horizontal: Bool, vertical: Bool) -> some View { self }

    nonisolated func fixedSize() -> some View { self }

    nonisolated func focusable(_ isFocusable: Bool = true, interactions: FocusInteractions) -> some View { self }

    nonisolated func focusable(_ isFocusable: Bool = true) -> some View { self }

    nonisolated func fontWidth(_ width: Font.Width?) -> some View { self }

    nonisolated func formStyle<S>(_ style: S) -> some View where S : FormStyle { self }

    nonisolated func grayscale(_ amount: Double) -> some View { self }

    nonisolated func inspector<V>(isPresented: Binding<Bool>, @ViewBuilder content: () -> V) -> some View where V : View { self }

    nonisolated func lineLimit(_ limit: Int, reservesSpace: Bool) -> some View { self }

    nonisolated func lineLimit(_ limit: ClosedRange<Int>) -> some View { self }

    nonisolated func lineLimit(_ number: Int?) -> some View { self }

    nonisolated func lineLimit(_ limit: PartialRangeFrom<Int>) -> some View { self }

    nonisolated func lineLimit(_ limit: PartialRangeThrough<Int>) -> some View { self }

    nonisolated func listStyle<S>(_ style: S) -> some View where S : ListStyle { self }

    nonisolated func menuOrder(_ order: MenuOrder) -> some View { self }

    nonisolated func menuStyle<S>(_ style: S) -> some View where S : MenuStyle { self }

    @MainActor @preconcurrency func onOpenURL(prefersInApp: Bool) -> some View { self }

    nonisolated func onOpenURL(perform action: @escaping (URL) -> ()) -> some View { self }

    nonisolated func onReceive<P>(_ publisher: P, perform action: @escaping (P.Output) -> Void) -> some View where P : Publisher, P.Failure == Never { self }

    nonisolated func statusBar(hidden: Bool) -> some View { self }

    nonisolated func textScale(_ scale: Text.Scale, isEnabled: Bool = true) -> some View { self }

    nonisolated func underline(_ isActive: Bool = true, pattern: Text.LineStyle.Pattern = .solid, color: Color? = nil) -> some View { self }

}

#endif

