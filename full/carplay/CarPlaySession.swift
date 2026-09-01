import Foundation

@MainActor
open class CPWindow: UIWindow {
    public weak var templateApplicationScene: CPTemplateApplicationScene?
    public let mapButtonSafeAreaLayoutGuide = UILayoutGuide()
}

@MainActor
open class CPInterfaceController: CarPlayCodingObject {
    public weak var delegate: (any CPInterfaceControllerDelegate)?
    public var prefersDarkUserInterfaceStyle = false
    public private(set) var templates: [CPTemplate] = []
    public private(set) var presentedTemplate: CPTemplate?
    public let carTraitCollection = UITraitCollection()
    public private(set) var portableConnectedToVehicle = false

    public var rootTemplate: CPTemplate {
        templates.first ?? CPTemplate()
    }

    public var topTemplate: CPTemplate? {
        templates.last
    }

    @_spi(OpenUIKitHost)
    public convenience init(portableRoot rootTemplate: CPTemplate) {
        self.init()
        templates = [rootTemplate]
    }

    public func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) {
        performSetRootTemplate(rootTemplate, animated: animated)
    }

    public func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) async throws -> Bool {
        performSetRootTemplate(rootTemplate, animated: animated)
        return true
    }

    public func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        performPushTemplate(templateToPush, animated: animated)
    }

    public func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) async throws -> Bool {
        performPushTemplate(templateToPush, animated: animated)
        return true
    }

    public func popTemplate(animated: Bool) {
        performPopTemplate(animated: animated)
    }

    public func popTemplate(animated: Bool) async throws -> Bool {
        guard templates.count > 1 else {
            throw CarPlayPortableError(.emptyTemplateStack)
        }
        performPopTemplate(animated: animated)
        return true
    }

    public func popToRootTemplate(animated: Bool) {
        performPopToRootTemplate(animated: animated)
    }

    public func popToRootTemplate(animated: Bool) async throws -> Bool {
        performPopToRootTemplate(animated: animated)
        return true
    }

    public func pop(to targetTemplate: CPTemplate, animated: Bool) {
        performPop(to: targetTemplate, animated: animated)
    }

    public func pop(to targetTemplate: CPTemplate, animated: Bool) async throws -> Bool {
        guard templates.contains(where: { $0 === targetTemplate }) else {
            throw CarPlayPortableError(.templateNotInStack)
        }
        performPop(to: targetTemplate, animated: animated)
        return true
    }

    public func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool) {
        performPresentTemplate(templateToPresent, animated: animated)
    }

    public func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool) async throws -> Bool {
        performPresentTemplate(templateToPresent, animated: animated)
        return true
    }

    public func dismissTemplate(animated: Bool) {
        performDismissTemplate(animated: animated)
    }

    public func dismissTemplate(animated: Bool) async throws -> Bool {
        guard presentedTemplate != nil else {
            throw CarPlayPortableError(.noPresentedTemplate)
        }
        performDismissTemplate(animated: animated)
        return true
    }

    private func performSetRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) {
        notifyWillDisappear(animated: animated)
        templates = [rootTemplate]
        notifyDidAppear(rootTemplate, animated: animated)
    }

    private func performPushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        if let current = topTemplate {
            delegate?.templateWillDisappear(current, animated: animated)
        }
        delegate?.templateWillAppear(templateToPush, animated: animated)
        templates.append(templateToPush)
        if let previous = templates.dropLast().last {
            delegate?.templateDidDisappear(previous, animated: animated)
        }
        delegate?.templateDidAppear(templateToPush, animated: animated)
    }

    private func performPopTemplate(animated: Bool) {
        guard templates.count > 1, let removed = templates.popLast() else { return }
        delegate?.templateWillDisappear(removed, animated: animated)
        if let current = topTemplate {
            delegate?.templateWillAppear(current, animated: animated)
        }
        delegate?.templateDidDisappear(removed, animated: animated)
        if let current = topTemplate {
            delegate?.templateDidAppear(current, animated: animated)
        }
    }

    private func performPopToRootTemplate(animated: Bool) {
        guard templates.count > 1 else { return }
        while templates.count > 1 {
            performPopTemplate(animated: animated)
        }
    }

    private func performPop(to targetTemplate: CPTemplate, animated: Bool) {
        guard templates.contains(where: { $0 === targetTemplate }) else { return }
        while let top = topTemplate, top !== targetTemplate, templates.count > 1 {
            performPopTemplate(animated: animated)
        }
    }

    private func performPresentTemplate(_ templateToPresent: CPTemplate, animated: Bool) {
        if let current = presentedTemplate {
            delegate?.templateWillDisappear(current, animated: animated)
            delegate?.templateDidDisappear(current, animated: animated)
        }
        delegate?.templateWillAppear(templateToPresent, animated: animated)
        presentedTemplate = templateToPresent
        delegate?.templateDidAppear(templateToPresent, animated: animated)
    }

    private func performDismissTemplate(animated: Bool) {
        guard let current = presentedTemplate else { return }
        delegate?.templateWillDisappear(current, animated: animated)
        presentedTemplate = nil
        delegate?.templateDidDisappear(current, animated: animated)
    }

    private func notifyWillDisappear(animated: Bool) {
        if let current = topTemplate {
            delegate?.templateWillDisappear(current, animated: animated)
            delegate?.templateDidDisappear(current, animated: animated)
        }
    }

    private func notifyDidAppear(_ template: CPTemplate, animated: Bool) {
        delegate?.templateWillAppear(template, animated: animated)
        delegate?.templateDidAppear(template, animated: animated)
    }

}

@MainActor
open class CPSessionConfiguration: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public weak var delegate: (any CPSessionConfigurationDelegate)?
    public private(set) var contentStyle: CPContentStyle
    public private(set) var limitedUserInterfaces: CPLimitableUserInterface

    public init(delegate: any CPSessionConfigurationDelegate) {
        self.delegate = delegate
        self.contentStyle = []
        self.limitedUserInterfaces = []
        super.init()
    }

}

open class CPDashboardController: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public var shortcutButtons: [CPDashboardButton]

    public override init() {
        self.shortcutButtons = []
        super.init()
    }

}

open class CPInstrumentClusterController: CarPlayCodingObject {

    public nonisolated required init?(coder: NSCoder) {
        return nil
    }

    public weak var delegate: (any CPInstrumentClusterControllerDelegate)?
    public var attributedInactiveDescriptionVariants: [NSAttributedString]
    public var inactiveDescriptionVariants: [String]
    public private(set) var compassSetting: CPInstrumentClusterSetting
    public private(set) var speedLimitSetting: CPInstrumentClusterSetting
    /// Always nil: Linux has no instrument-cluster window.
    public var instrumentClusterWindow: UIWindow? { nil }

    public override init() {
        self.attributedInactiveDescriptionVariants = []
        self.inactiveDescriptionVariants = []
        self.compassSetting = .unspecified
        self.speedLimitSetting = .unspecified
        super.init()
    }

}

@MainActor
open class CPTemplateApplicationScene: UIScene {
    public private(set) lazy var carWindow: CPWindow = {
        let window = CPWindow()
        window.templateApplicationScene = self
        return window
    }()
    public let interfaceController = CPInterfaceController()
    public var contentStyle: UIUserInterfaceStyle = .unspecified
    public var delegate: (any CPTemplateApplicationSceneDelegate)?
}

@MainActor
open class CPTemplateApplicationDashboardScene: UIScene {
    public let dashboardController = CPDashboardController()
    public let dashboardWindow = UIWindow()
    public var delegate: (any CPTemplateApplicationDashboardSceneDelegate)?
}

@MainActor
open class CPTemplateApplicationInstrumentClusterScene: UIScene {
    public let instrumentClusterController = CPInstrumentClusterController()
    public var contentStyle: UIUserInterfaceStyle = .unspecified
    public var delegate: (any CPTemplateApplicationInstrumentClusterSceneDelegate)?
}
