import Foundation

@MainActor open class CPInterfaceController: NSObject, @unchecked Sendable {
    public weak var delegate: (any CPInterfaceControllerDelegate)?
    public private(set) var carTraitCollection: UITraitCollection = UITraitCollection()
    public var prefersDarkUserInterfaceStyle: Bool = false
    public private(set) var presentedTemplate: CPTemplate? = nil
    private var storedRoot: CPTemplate = CPTemplate()
    private var stack: [CPTemplate] = []
    @_spi(OpenUIKitHost)
    public var hostSessionConnected: Bool = false

    public var rootTemplate: CPTemplate { storedRoot }
    public var templates: [CPTemplate] { stack }
    public var topTemplate: CPTemplate? { stack.last }

    public override init() {
        super.init()
    }

    func host_applyTraitCollection(_ traits: UITraitCollection) {
        carTraitCollection = traits
        prefersDarkUserInterfaceStyle = traits.userInterfaceStyle == .dark
    }

    private func requireConnected() throws {
        if !hostSessionConnected {
            throw CarPlayHostError.notConnected
        }
    }

    private func notifyAppearDisappear(outgoing: CPTemplate?, incoming: CPTemplate?, animated: Bool) {
        if let outgoing {
            delegate?.templateWillDisappear(outgoing, animated: animated)
        }
        if let incoming {
            delegate?.templateWillAppear(incoming, animated: animated)
        }
        if let outgoing {
            delegate?.templateDidDisappear(outgoing, animated: animated)
        }
        if let incoming {
            delegate?.templateDidAppear(incoming, animated: animated)
        }
    }

    private func applyRoot(_ root: CPTemplate, animated: Bool) throws {
        try requireConnected()
        if root is CPTabBarTemplate {
            try carPlayValidateTabTemplates((root as! CPTabBarTemplate).templates)
        }
        if let list = root as? CPListTemplate {
            try carPlayValidateListSections(list.sections)
        }
        if let grid = root as? CPGridTemplate {
            try carPlayValidateGridButtons(grid.gridButtons)
        }
        let outgoing = stack.last
        storedRoot = root
        stack = [root]
        notifyAppearDisappear(outgoing: outgoing, incoming: root, animated: animated)
    }

    public func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) {
        try? applyRoot(rootTemplate, animated: animated)
    }

    public func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) async throws -> Bool {
        try applyRoot(rootTemplate, animated: animated)
        return true
    }

    private func applyPush(_ templateToPush: CPTemplate, animated: Bool) throws {
        try requireConnected()
        if stack.isEmpty {
            throw CarPlayHostError.emptyTemplateStack
        }
        if templateToPush is CPTabBarTemplate {
            throw CarPlayHostError.invalidTemplate
        }
        if carPlayIsPresentable(templateToPush) {
            throw CarPlayHostError.invalidTemplate
        }
        if stack.count >= CarPlayMaximumTemplateDepth {
            throw CarPlayHostError.templateHierarchyExceeded
        }
        if let list = templateToPush as? CPListTemplate {
            try carPlayValidateListSections(list.sections)
        }
        if let grid = templateToPush as? CPGridTemplate {
            try carPlayValidateGridButtons(grid.gridButtons)
        }
        let outgoing = stack.last
        stack.append(templateToPush)
        notifyAppearDisappear(outgoing: outgoing, incoming: templateToPush, animated: animated)
    }

    public func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        try? applyPush(templateToPush, animated: animated)
    }

    public func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) async throws -> Bool {
        try applyPush(templateToPush, animated: animated)
        return true
    }

    private func applyPop(animated: Bool) throws {
        try requireConnected()
        if stack.count <= 1 {
            throw CarPlayHostError.emptyTemplateStack
        }
        let outgoing = stack.removeLast()
        notifyAppearDisappear(outgoing: outgoing, incoming: stack.last, animated: animated)
    }

    public func popTemplate(animated: Bool) {
        try? applyPop(animated: animated)
    }

    public func popTemplate(animated: Bool) async throws -> Bool {
        try applyPop(animated: animated)
        return true
    }

    private func applyPopToRoot(animated: Bool) throws {
        try requireConnected()
        if stack.isEmpty {
            throw CarPlayHostError.emptyTemplateStack
        }
        if stack.count == 1 {
            return
        }
        let outgoing = stack.last
        stack = [storedRoot]
        notifyAppearDisappear(outgoing: outgoing, incoming: storedRoot, animated: animated)
    }

    public func popToRootTemplate(animated: Bool) {
        try? applyPopToRoot(animated: animated)
    }

    public func popToRootTemplate(animated: Bool) async throws -> Bool {
        try applyPopToRoot(animated: animated)
        return true
    }

    private func applyPop(to targetTemplate: CPTemplate, animated: Bool) throws {
        try requireConnected()
        guard let idx = stack.firstIndex(where: { $0 === targetTemplate }) else {
            throw CarPlayHostError.templateNotInHierarchy
        }
        if idx == stack.count - 1 {
            return
        }
        let outgoing = stack.last
        stack = Array(stack.prefix(through: idx))
        notifyAppearDisappear(outgoing: outgoing, incoming: stack.last, animated: animated)
    }

    public func pop(to targetTemplate: CPTemplate, animated: Bool) {
        try? applyPop(to: targetTemplate, animated: animated)
    }

    public func pop(to targetTemplate: CPTemplate, animated: Bool) async throws -> Bool {
        try applyPop(to: targetTemplate, animated: animated)
        return true
    }

    private func applyPresent(_ templateToPresent: CPTemplate, animated: Bool) throws {
        try requireConnected()
        if presentedTemplate != nil {
            throw CarPlayHostError.invalidTemplate
        }
        if !carPlayIsPresentable(templateToPresent) {
            throw CarPlayHostError.invalidTemplate
        }
        if let alert = templateToPresent as? CPAlertTemplate {
            try carPlayValidateAlertActions(alert.actions)
        }
        presentedTemplate = templateToPresent
        notifyAppearDisappear(outgoing: nil, incoming: templateToPresent, animated: animated)
    }

    public func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool) {
        try? applyPresent(templateToPresent, animated: animated)
    }

    public func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool) async throws -> Bool {
        try applyPresent(templateToPresent, animated: animated)
        return true
    }

    private func applyDismiss(animated: Bool) throws {
        try requireConnected()
        guard let presented = presentedTemplate else {
            throw CarPlayHostError.emptyTemplateStack
        }
        presentedTemplate = nil
        notifyAppearDisappear(outgoing: presented, incoming: stack.last, animated: animated)
    }

    public func dismissTemplate(animated: Bool) {
        try? applyDismiss(animated: animated)
    }

    public func dismissTemplate(animated: Bool) async throws -> Bool {
        try applyDismiss(animated: animated)
        return true
    }
}

@MainActor open class CPWindow: UIWindow, @unchecked Sendable {
    public var mapButtonSafeAreaLayoutGuide: UILayoutGuide = UILayoutGuide()
    public weak var templateApplicationScene: CPTemplateApplicationScene?
    public override init() {
        super.init()
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
}

@MainActor open class CPTemplateApplicationScene: UIScene, @unchecked Sendable {
    public var carWindow: CPWindow = CPWindow()
    public private(set) var contentStyle: UIUserInterfaceStyle = .unspecified
    public var delegate: (any CPTemplateApplicationSceneDelegate)?
    public var interfaceController: CPInterfaceController = CPInterfaceController()
    private var hostConnected = false

    public override init() {
        super.init()
    }

    /// Documented Linux test hook: wires a simulated `CPInterfaceController`
    /// and `CPWindow`. This does not talk to a vehicle head unit.
    @_spi(OpenUIKitHost)
    public func openuikit_connectSimulatedSession(style: UIUserInterfaceStyle = .light) {
        hostConnected = true
        contentStyle = style
        let traits = UITraitCollection()
        traits.userInterfaceStyle = style
        interfaceController.host_applyTraitCollection(traits)
        interfaceController.hostSessionConnected = true
        carWindow.templateApplicationScene = self
        delegate?.templateApplicationScene(self, didConnect: interfaceController, to: carWindow)
        delegate?.templateApplicationScene(self, didConnect: interfaceController)
        delegate?.contentStyleDidChange(style)
    }

    @_spi(OpenUIKitHost)
    public func openuikit_disconnectSimulatedSession() {
        guard hostConnected else { return }
        hostConnected = false
        interfaceController.hostSessionConnected = false
        delegate?.templateApplicationScene(self, didDisconnect: interfaceController, from: carWindow)
        delegate?.templateApplicationScene(self, didDisconnectInterfaceController: interfaceController)
    }
}

@MainActor open class CPTemplateApplicationDashboardScene: UIScene, @unchecked Sendable {
    public var dashboardController: CPDashboardController = CPDashboardController()
    public var dashboardWindow: UIWindow = UIWindow()
    public var delegate: (any CPTemplateApplicationDashboardSceneDelegate)?
    public override init() {
        super.init()
    }

    /// Dashboard has no Linux head unit. Always fail-closed.
    @_spi(OpenUIKitHost)
    public func openuikit_simulateConnect() -> Bool {
        false
    }
}

@MainActor open class CPTemplateApplicationInstrumentClusterScene: UIScene, @unchecked Sendable {
    public var contentStyle: UIUserInterfaceStyle = .unspecified
    public var delegate: (any CPTemplateApplicationInstrumentClusterSceneDelegate)?
    public var instrumentClusterController: CPInstrumentClusterController = CPInstrumentClusterController()
    public override init() {
        super.init()
    }

    /// Instrument cluster has no Linux head unit. Always fail-closed.
    @_spi(OpenUIKitHost)
    public func openuikit_simulateConnect() -> Bool {
        false
    }
}
