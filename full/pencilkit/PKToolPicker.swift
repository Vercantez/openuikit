import Foundation

#if canImport(UIKit)
@MainActor
#endif
open class PKToolPicker: NSObject {
    public weak var delegate: (any PKToolPicker.Delegate)?
    public var accessoryItem: PencilKitBarButtonItem?
    public var colorMaximumLinearExposure: CGFloat = 1
    public var colorUserInterfaceStyle: PencilKitUserInterfaceStyle = .unspecified
    public var overrideUserInterfaceStyle: PencilKitUserInterfaceStyle = .unspecified
    public var isRulerActive: Bool = false {
        didSet { notifyRuler() }
    }
    public var maximumSupportedContentVersion: PKContentVersion = .latest
    public var showsDrawingPolicyControls: Bool = true
    public var stateAutosaveName: String?

    public private(set) var toolItems: [PKToolPickerItem]
    public private(set) var isVisible: Bool = false

    private var observers: [ObjectIdentifier: ObserverBox] = [:]
    private var visibleResponders: Set<ObjectIdentifier> = []

    public override init() {
        self.toolItems = PKToolPicker.makeDefaultItems()
        super.init()
        if let first = toolItems.first {
            _selectedToolItem = first
        }
    }

    public init(toolItems items: [PKToolPickerItem]) {
        self.toolItems = items.isEmpty ? PKToolPicker.makeDefaultItems() : items
        super.init()
        if let first = toolItems.first {
            _selectedToolItem = first
        }
    }

    private var _selectedToolItem: PKToolPickerItem?

    public var selectedToolItem: PKToolPickerItem {
        get { _selectedToolItem ?? toolItems[0] }
        set {
            _selectedToolItem = newValue
            if !toolItems.contains(where: { $0 === newValue }) {
                toolItems.append(newValue)
            }
            notifySelected()
        }
    }

    public var selectedToolItemIdentifier: String {
        get { selectedToolItem.identifier }
        set {
            if let match = toolItems.first(where: { $0.identifier == newValue }) {
                selectedToolItem = match
            }
        }
    }

    public var selectedTool: any PKTool {
        get { selectedToolItem.tool ?? PKInkingTool(.pen) }
        set {
            if let match = toolItems.first(where: { item in
                PKToolPicker.toolsMatch(item.tool, newValue)
            }) {
                selectedToolItem = match
            }
        }
    }

    public class var defaultToolItems: [PKToolPickerItem] {
        makeDefaultItems()
    }

    /// In-process registry keyed by window identity. This is not Apple's
    /// window-associated picker; a missing window still returns a picker so
    /// callers can configure tools, but UI chrome stays inert.
    public class func shared(for window: PencilKitWindow) -> PKToolPicker? {
        let key = ObjectIdentifier(window)
        if let existing = PKToolPickerStore.pickers[key] {
            return existing
        }
        let picker = PKToolPicker()
        PKToolPickerStore.pickers[key] = picker
        return picker
    }

    public func addObserver(_ observer: any PKToolPickerObserver) {
        observers[ObjectIdentifier(observer)] = ObserverBox(observer)
    }

    public func removeObserver(_ observer: any PKToolPickerObserver) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
    }

    public func frameObscured(in view: PencilKitView) -> CGRect {
        _ = view
        // Fail-closed: no overlay chrome on isolated Linux.
        return .zero
    }

    public func setVisible(_ visible: Bool, forFirstResponder responder: PencilKitResponder) {
        let key = ObjectIdentifier(responder)
        if visible {
            visibleResponders.insert(key)
        } else {
            visibleResponders.remove(key)
        }
        let wasVisible = isVisible
        isVisible = !visibleResponders.isEmpty
        if wasVisible != isVisible {
            notifyVisibility()
        }
    }

    private func notifySelected() {
        for observer in liveObservers() {
            observer.toolPickerSelectedToolDidChange(self)
            observer.toolPickerSelectedToolItemDidChange(self)
        }
    }

    private func notifyRuler() {
        for observer in liveObservers() {
            observer.toolPickerIsRulerActiveDidChange(self)
        }
    }

    private func notifyVisibility() {
        for observer in liveObservers() {
            observer.toolPickerVisibilityDidChange(self)
            observer.toolPickerFramesObscuredDidChange(self)
        }
    }

    private func liveObservers() -> [any PKToolPickerObserver] {
        observers.values.compactMap { $0.value as? any PKToolPickerObserver }
    }

    private static func toolsMatch(_ lhs: (any PKTool)?, _ rhs: any PKTool) -> Bool {
        switch (lhs, rhs) {
        case let (l as PKInkingTool, r as PKInkingTool):
            return l == r
        case let (l as PKEraserTool, r as PKEraserTool):
            return l == r
        case (is PKLassoTool, is PKLassoTool):
            return true
        default:
            return false
        }
    }

    private static func makeDefaultItems() -> [PKToolPickerItem] {
        [
            PKToolPickerInkingItem(type: .pen),
            PKToolPickerInkingItem(type: .pencil),
            PKToolPickerInkingItem(type: .marker),
            PKToolPickerEraserItem(type: .vector),
            PKToolPickerLassoItem(),
            PKToolPickerRulerItem(),
        ]
    }

    #if canImport(UIKit)
    @MainActor
    #endif
    public protocol Delegate: AnyObject {}

    private struct ObserverBox {
        weak var value: AnyObject?

        init(_ observer: any PKToolPickerObserver) {
            self.value = observer as AnyObject
        }
    }
}

private enum PKToolPickerStore {
    static var pickers: [ObjectIdentifier: PKToolPicker] = [:]
}

#if canImport(UIKit)
@MainActor
#endif
public protocol PKToolPickerObserver: AnyObject {
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker)
    func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker)
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker)
    func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker)
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker)
}

public extension PKToolPickerObserver {
    func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {}
    func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker) {}
    func toolPickerSelectedToolDidChange(_ toolPicker: PKToolPicker) {}
    func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {}
    func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {}
}

open class PKToolPickerItem: NSObject {
    public let identifier: String
    public var tool: (any PKTool)?

    public init(identifier: String, tool: (any PKTool)? = nil) {
        self.identifier = identifier
        self.tool = tool
    }
}

open class PKToolPickerCustomItem: PKToolPickerItem {
    public var configuration: Configuration
    public var allowsColorSelection: Bool
    public var color: PencilKitColor
    public var width: CGFloat
    public private(set) var imageReloadCount: Int = 0

    public init(configuration: Configuration) {
        self.configuration = configuration
        self.allowsColorSelection = configuration.allowsColorSelection
        self.color = configuration.defaultColor
        self.width = configuration.defaultWidth
        super.init(identifier: configuration.identifier, tool: nil)
    }

    public func reloadImage() {
        imageReloadCount += 1
        _ = configuration.imageProvider?(self)
    }

    public struct Configuration {
        public var identifier: String
        public var name: String
        public var defaultColor: PencilKitColor = .black
        public var defaultWidth: CGFloat = 5
        public var imageProvider: ((PKToolPickerCustomItem) -> PencilKitImage)?
        public var widthVariants: [CGFloat: PencilKitImage] = [:]
        public var allowsColorSelection: Bool = true
        public var toolAttributeControls: PKToolPickerCustomItem.ControlOptions = [.width, .opacity]
        public var viewControllerProvider: ((PKToolPickerCustomItem) -> PencilKitViewController)?

        public init(identifier: String, name: String) {
            self.identifier = identifier
            self.name = name
        }
    }
}

open class PKToolPickerEraserItem: PKToolPickerItem {
    public var eraserTool: PKEraserTool

    public convenience init(type: PKEraserTool.EraserType) {
        self.init(type: type, width: type.defaultWidth)
    }

    public init(type: PKEraserTool.EraserType, width: CGFloat) {
        let tool = PKEraserTool(type, width: width)
        self.eraserTool = tool
        super.init(identifier: "eraser.\(type.rawValue)", tool: tool)
    }
}

open class PKToolPickerInkingItem: PKToolPickerItem {
    public var inkingTool: PKInkingTool
    public var allowsColorSelection: Bool = true

    public convenience init(
        type: PKInkingTool.InkType,
        color: PencilKitColor? = nil,
        width: CGFloat? = nil,
        identifier: String? = nil
    ) {
        self.init(type: type, color: color, width: width, azimuth: nil, identifier: identifier)
    }

    public init(
        type: PKInkingTool.InkType,
        color: PencilKitColor? = nil,
        width: CGFloat? = nil,
        azimuth: CGFloat? = nil,
        identifier: String? = nil
    ) {
        let tool = PKInkingTool(
            type,
            color: color ?? .black,
            width: width,
            azimuth: azimuth ?? 0
        )
        self.inkingTool = tool
        super.init(identifier: identifier ?? "ink.\(type.rawValue)", tool: tool)
    }
}

open class PKToolPickerLassoItem: PKToolPickerItem {
    public var lassoTool: PKLassoTool { PKLassoTool() }

    public init() {
        super.init(identifier: "lasso", tool: PKLassoTool())
    }
}

open class PKToolPickerRulerItem: PKToolPickerItem {
    public init() {
        super.init(identifier: "ruler", tool: nil)
    }
}

open class PKToolPickerScribbleItem: PKToolPickerItem {
    public init() {
        super.init(identifier: "scribble", tool: nil)
    }
}
