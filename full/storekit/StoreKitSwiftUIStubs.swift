import Foundation

#if !canImport(SwiftUI)

// Empty SwiftUI lookalikes referenced by StoreKit's View overlay. Isolated
// host compilation has no SwiftUI module.

public protocol ButtonStyle {}
public protocol ToggleStyle {}
public protocol TextFieldStyle {}
public protocol TextEditorStyle {}
public protocol TableStyle {}
public protocol TabViewStyle {}
public protocol ProgressViewStyle {}
public protocol PrimitiveButtonStyle {}
public protocol PickerStyle {}
public protocol NavigationViewStyle {}
public protocol NavigationSplitViewStyle {}
public protocol MenuStyle {}
public protocol ListStyle {}
public protocol LabeledContentStyle {}
public protocol LabelStyle {}
public protocol IndexViewStyle {}
public protocol GroupBoxStyle {}
public protocol GaugeStyle {}
public protocol FormStyle {}
public protocol DisclosureGroupStyle {}
public protocol DatePickerStyle {}
public protocol ControlGroupStyle {}
public protocol ToolbarContent {}
public protocol CustomizableToolbarContent {}
public protocol VisualEffect {}
public protocol InsettableShape {}
public protocol DropDelegate {}
public protocol ScrollTargetBehavior {}
public protocol TextRenderer {}
public protocol Transition {}
public protocol ReferenceFileDocument {}
public protocol AXChartDescriptorRepresentable {}
public protocol UIGestureRecognizerRepresentable {}
public protocol Publisher {
    associatedtype Output
    associatedtype Failure: Error
}
public protocol Observable {}
public protocol LayoutValueKey { associatedtype Value }
public protocol SymbolEffect {}
public protocol IndefiniteSymbolEffect: SymbolEffect {}
public protocol DiscreteSymbolEffect: SymbolEffect {}
public protocol DropSession {}
public protocol RoundedRectangularShape {}
public protocol PresentationSizing {}
public protocol NavigationTransition {}
public protocol MatchedTransitionSourceConfiguration {}
public protocol CustomHoverEffect {}
public protocol TextSelectability {}
public protocol AttributedTextFormattingDefinition {}
public protocol PreviewContext {}

public struct Capsule: RoundedRectangularShape { public init() {} }
public struct AutomaticPresentationSizing: PresentationSizing { public init() {} }
public struct AutomaticNavigationTransition: NavigationTransition { public init() {} }
public struct AutomaticMatchedTransitionSourceConfiguration: MatchedTransitionSourceConfiguration { public init() {} }
public struct AutomaticCustomHoverEffect: CustomHoverEffect { public init() {} }
public struct EnabledTextSelectability: TextSelectability { public init() {} }
public struct DefaultAttributedTextFormattingDefinition: AttributedTextFormattingDefinition { public init() {} }
public struct DefaultPreviewContext: PreviewContext { public init() {} }

public struct SharePreview<I, D> { public init() {} }
public struct SensoryFeedback: Hashable, Sendable { public init() {} }
public struct ScrollPhase: Hashable, Sendable { public init() {} }
public struct Font: Hashable, Sendable {
    public struct Design: Hashable, Sendable { public init() {} }
    public struct Weight: Hashable, Sendable { public init() {} }
    public struct Width: Hashable, Sendable { public init() {} }
    public init() {}
}
public struct FocusedValues { public init() {} }
public struct EdgeInsets: Hashable, Sendable {
    public var top: CGFloat = 0
    public var leading: CGFloat = 0
    public var bottom: CGFloat = 0
    public var trailing: CGFloat = 0
    public init() {}
}
public struct VerticalAlignment: Hashable, Sendable {
    public static let center = VerticalAlignment()
    public init() {}
}
public struct Shader { public init() {} }
public struct ScrollTransitionConfiguration {
    public static let interactive = ScrollTransitionConfiguration()
    public init() {}
}
public struct PresentationDetent: Hashable, Sendable { public init() {} }
public struct PresentationAdaptation: Hashable, Sendable { public init() {} }
open class NSUserActivity: NSObject { public override init() { super.init() } }
public struct KeyboardShortcut: Hashable, Sendable {
    public struct Localization: Hashable, Sendable { public init() {} }
    public init() {}
}
public struct HoverEffect: Hashable, Sendable {
    public static let automatic = HoverEffect()
    public init() {}
}
public enum HorizontalEdge: Hashable, Sendable {
    case leading, trailing
    public struct Set: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
        public static let leading = Set(rawValue: 1)
        public static let trailing = Set(rawValue: 2)
        public static let all: Set = [.leading, .trailing]
    }
}
public struct GestureMask: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let all = GestureMask(rawValue: 1)
}
public struct GeometryProxy { public init() {} }
public struct EnvironmentValues { public init() {} }
public struct EmptyVisualEffect: VisualEffect { public init() {} }
public struct ContentMarginPlacement: Hashable, Sendable {
    public static let automatic = ContentMarginPlacement()
    public init() {}
}
public struct SymbolEffectOptions: Hashable, Sendable {
    public static let `default` = SymbolEffectOptions()
    public init() {}
}
public struct PopoverAttachmentAnchor: Hashable, Sendable {
    public static func rect(_ source: Anchor<CGRect>.Source) -> PopoverAttachmentAnchor { PopoverAttachmentAnchor() }
    public static var bounds: PopoverAttachmentAnchor { PopoverAttachmentAnchor() }
    public init() {}
}
public struct EventModifiers: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let command = EventModifiers(rawValue: 1)
}
public struct CoordinateSpace: Hashable, Sendable {
    public static let local = CoordinateSpace()
    public init() {}
}
public struct SubmitTriggers: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let text = SubmitTriggers(rawValue: 1)
}
public struct SafeAreaRegions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let all = SafeAreaRegions(rawValue: 1)
}
public struct MatchedGeometryProperties: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let frame = MatchedGeometryProperties(rawValue: 1)
}
public struct Glass {
    public static let regular = Glass()
    public init() {}
}
public struct DefaultFocusEvaluationPriority {
    public static let automatic = DefaultFocusEvaluationPriority()
    public init() {}
}
public struct ColorRenderingMode {
    public static let nonLinear = ColorRenderingMode()
    public init() {}
}
public struct AdaptableTabBarPlacement {
    public static let automatic = AdaptableTabBarPlacement()
    public init() {}
}
public struct AccessibilityChildBehavior {
    public static let ignore = AccessibilityChildBehavior()
    public init() {}
}
public struct AccessibilityActionKind {
    public static let `default` = AccessibilityActionKind()
    public init() {}
}

@resultBuilder
public enum ToolbarContentBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }
    public static func buildBlock<Content: View>(_ content: Content) -> Content { content }
}

public protocol Keyframes {}
public struct EmptyKeyframes: Keyframes { public init() {} }

@resultBuilder
public enum KeyframesBuilder<Value> {
    public static func buildBlock() -> EmptyKeyframes { EmptyKeyframes() }
    public static func buildBlock<Content: Keyframes>(_ content: Content) -> Content { content }
}

public enum DynamicTypeSize: Int, Hashable, Sendable, Comparable {
    case medium = 0
    public static func < (lhs: DynamicTypeSize, rhs: DynamicTypeSize) -> Bool { lhs.rawValue < rhs.rawValue }
}
public enum ControlSize: Int, Hashable, Sendable, Comparable {
    case regular = 0
    public static func < (lhs: ControlSize, rhs: ControlSize) -> Bool { lhs.rawValue < rhs.rawValue }
}
public struct ContainerBackgroundPlacement: Hashable, Sendable { public init() {} }
public enum ColorScheme: Hashable, Sendable { case light, dark }
public struct Angle: Hashable, Sendable {
    public var radians: Double = 0
    public init() {}
}
@propertyWrapper
public struct AccessibilityFocusState<Value> {
    public struct Binding {
        public var wrappedValue: Value
        public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    }
    public var wrappedValue: Value
    public var projectedValue: AccessibilityFocusState<Value>.Binding {
        AccessibilityFocusState.Binding(wrappedValue: wrappedValue)
    }
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
}
public struct _ConditionalContent<TrueContent, FalseContent>: View {
    public var body: EmptyView { EmptyView() }
}
public struct ViewDimensions { public init() {} }
public struct ScrollTransitionPhase: Hashable, Sendable { public init() {} }
public struct DefaultGlassEffectShape: Shape { public init() {} }
public struct ContentToolbarPlacement: Hashable, Sendable { public init() {} }
public enum ContentMode: Hashable, Sendable { case fit, fill }
public struct Alert { public init() {} }
public struct ActionSheet { public init() {} }
public struct WritingToolsBehavior: Hashable, Sendable { public init() {} }
public struct WindowToolbarFullScreenVisibility: Hashable, Sendable { public init() {} }
public struct UITextContentType: Hashable, Sendable { public init() {} }
public struct UITextAutocapitalizationType: Hashable, Sendable { public init() {} }
public struct UIKeyboardType: Hashable, Sendable { public init() {} }
public struct TypesettingLanguage: Hashable, Sendable { public init() {} }
public struct ToolbarTitleDisplayMode: Hashable, Sendable { public init() {} }
public struct ToolbarRole: Hashable, Sendable { public init() {} }
public struct ToolbarDefaultItemKind: Hashable, Sendable { public init() {} }
public struct TextSelectionAffinity: Hashable, Sendable { public init() {} }
public struct TextSelection: Hashable, Sendable { public init() {} }
public struct TextInputFormattingControlPlacement: Hashable, Sendable {
    public struct Set: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
    }
    public init() {}
}
public struct TextInputDictationBehavior: Hashable, Sendable { public init() {} }
public struct TextInputAutocapitalization: Hashable, Sendable { public init() {} }
public struct TextAlignment: Hashable, Sendable { public init() {} }
public struct TabViewCustomization { public init() {} }
public struct TabSearchActivation: Hashable, Sendable { public init() {} }
public struct TabBarMinimizeBehavior: Hashable, Sendable { public init() {} }
public struct SymbolVariants: Hashable, Sendable { public init() {} }
public struct SymbolVariableValueMode: Hashable, Sendable { public init() {} }
public struct SymbolRenderingMode: Hashable, Sendable { public init() {} }
public struct SymbolColorRenderingMode: Hashable, Sendable { public init() {} }
public struct SubmitLabel: Hashable, Sendable { public init() {} }
public struct SpringLoadingBehavior: Hashable, Sendable { public init() {} }
public struct SearchToolbarBehavior: Hashable, Sendable { public init() {} }
public struct SearchSuggestionsPlacement: Hashable, Sendable {
    public struct Set: OptionSet, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }
    }
    public init() {}
}
public struct SearchScopeActivation: Hashable, Sendable { public init() {} }
public struct SearchPresentationToolbarBehavior: Hashable, Sendable { public init() {} }
public struct ScrollPosition { public init() {} }
public struct ScrollPhaseChangeContext { public init() {} }
public struct ScrollInputKind: Hashable, Sendable { public init() {} }
public struct ScrollInputBehavior: Hashable, Sendable { public init() {} }
public struct ScrollIndicatorVisibility: Hashable, Sendable { public init() {} }
public struct ScrollGeometry { public init() {} }
public struct ScrollEdgeEffectStyle: Hashable, Sendable { public init() {} }
public struct ScrollDismissesKeyboardMode: Hashable, Sendable { public init() {} }
public struct ScrollBounceBehavior: Hashable, Sendable { public init() {} }
public struct ScrollAnchorRole: Hashable, Sendable { public init() {} }
public struct ScenePadding: Hashable, Sendable { public init() {} }
public struct RedactionReasons: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
}
public struct Prominence: Hashable, Sendable { public init() {} }
public struct ProjectionTransform { public init() {} }
public struct PreviewLayout { public init() {} }
public struct PreviewDevice { public init() {} }
public struct PresentationContentInteraction { public init() {} }
public struct PresentationBackgroundInteraction { public init() {} }
public struct PencilSqueezeGesturePhase { public init() {} }
public struct PencilDoubleTapGestureValue { public init() {} }
public struct PaletteSelectionEffect { public init() {} }
public struct NamedCoordinateSpace { public init() {} }
public struct MenuOrder { public init() {} }
public struct MenuActionDismissBehavior { public init() {} }
public struct MaterialActiveAppearance { public init() {} }
public struct ListSectionSpacing { public init() {} }
public struct ListItemTint { public init() {} }
public struct LayoutDirectionBehavior { public init() {} }
public struct InterfaceOrientation { public init() {} }
public struct HoverPhase { public init() {} }
public struct HandGestureShortcut { public init() {} }
public struct GlassEffectTransition { public init() {} }
public struct FocusInteractions { public init() {} }
public struct FileDialogBrowserOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
}
public struct EmptyMatchedTransitionSourceConfiguration: MatchedTransitionSourceConfiguration { public init() {} }
public struct ContextMenu<MenuItems> { public init() {} }
public struct ContentTransition { public init() {} }
public struct ContentShapeKinds: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
}
public struct ContainerValues { public init() {} }
public struct CGAffineTransform { public init() {} }
public struct ButtonSizing { public init() {} }
public struct ButtonRepeatBehavior { public init() {} }
public struct ButtonBorderShape { public init() {} }

extension AttributedString {
    public struct LineHeight: Hashable, Sendable { public init() {} }
}
public enum BlendMode { case normal }
public struct BadgeProminence { public init() {} }
public struct AnyTransition { public init() {} }
public struct AccessibilityZoomGestureAction { public init() {} }
public struct AccessibilityTextContentType { public init() {} }
public struct AccessibilityLabeledPairRole { public init() {} }
public struct AccessibilityHeadingLevel { public init() {} }
public struct AccessibilityDirectTouchOptions: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
}
public struct AccessibilityAdjustmentDirection { public init() {} }
public struct AccessibilityActionCategory { public init() {} }

public enum NavigationBarItem {
    public enum TitleDisplayMode: Hashable, Sendable {
        case automatic, inline, large
    }
}

#endif
