import Foundation

#if canImport(UIKit)
import UIKit
#endif

@MainActor
open class CPInterfaceController: NSObject {
    public weak var delegate: (any CPInterfaceControllerDelegate)?
    public var prefersDarkUserInterfaceStyle = false
    public private(set) var templates: [CPTemplate] = []
    public private(set) var presentedTemplate: CPTemplate?
    private var hostVehicleSessionConnected = false

    #if canImport(UIKit)
    public let carTraitCollection = UITraitCollection()
    #endif

    public var rootTemplate: CPTemplate {
        templates.first ?? CPTemplate()
    }

    public var topTemplate: CPTemplate? {
        templates.last
    }

    @_spi(OpenUIKitHost)
    public var isHostVehicleSessionConnected: Bool {
        hostVehicleSessionConnected
    }

    @_spi(OpenUIKitHost)
    public func connectHostVehicleSession(rootTemplate: CPTemplate) {
        CarPlayHostSessionState.isConnected = true
        hostVehicleSessionConnected = true
        templates = [rootTemplate]
        presentedTemplate = nil
        delegate?.templateWillAppear(rootTemplate, animated: false)
        delegate?.templateDidAppear(rootTemplate, animated: false)
    }

    @_spi(OpenUIKitHost)
    public func disconnectHostVehicleSession() {
        if let current = presentedTemplate {
            delegate?.templateWillDisappear(current, animated: false)
            delegate?.templateDidDisappear(current, animated: false)
        }
        if let current = topTemplate {
            delegate?.templateWillDisappear(current, animated: false)
            delegate?.templateDidDisappear(current, animated: false)
        }
        presentedTemplate = nil
        templates = []
        hostVehicleSessionConnected = false
        CarPlayHostSessionState.isConnected = false
    }

    public func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) {
        guard hostVehicleSessionConnected else { return }
        performSetRootTemplate(rootTemplate, animated: animated)
    }

    public func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) async throws -> Bool {
        guard hostVehicleSessionConnected else {
            throw CarPlayHostError.vehicleSessionDisconnected
        }
        performSetRootTemplate(rootTemplate, animated: animated)
        return true
    }

    public func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        guard hostVehicleSessionConnected else { return }
        performPushTemplate(templateToPush, animated: animated)
    }

    public func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) async throws -> Bool {
        guard hostVehicleSessionConnected else {
            throw CarPlayHostError.vehicleSessionDisconnected
        }
        performPushTemplate(templateToPush, animated: animated)
        return true
    }

    public func popTemplate(animated: Bool) {
        guard hostVehicleSessionConnected else { return }
        performPopTemplate(animated: animated)
    }

    public func popTemplate(animated: Bool) async throws -> Bool {
        guard hostVehicleSessionConnected else {
            throw CarPlayHostError.vehicleSessionDisconnected
        }
        guard templates.count > 1 else {
            throw CarPlayHostError.emptyTemplateStack
        }
        performPopTemplate(animated: animated)
        return true
    }

    public func popToRootTemplate(animated: Bool) {
        guard hostVehicleSessionConnected else { return }
        performPopToRootTemplate(animated: animated)
    }

    public func popToRootTemplate(animated: Bool) async throws -> Bool {
        guard hostVehicleSessionConnected else {
            throw CarPlayHostError.vehicleSessionDisconnected
        }
        performPopToRootTemplate(animated: animated)
        return true
    }

    public func pop(to targetTemplate: CPTemplate, animated: Bool) {
        guard hostVehicleSessionConnected else { return }
        performPop(to: targetTemplate, animated: animated)
    }

    public func pop(to targetTemplate: CPTemplate, animated: Bool) async throws -> Bool {
        guard hostVehicleSessionConnected else {
            throw CarPlayHostError.vehicleSessionDisconnected
        }
        guard templates.contains(where: { $0 === targetTemplate }) else {
            throw CarPlayHostError.templateNotInStack
        }
        performPop(to: targetTemplate, animated: animated)
        return true
    }

    public func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool) {
        guard hostVehicleSessionConnected else { return }
        performPresentTemplate(templateToPresent, animated: animated)
    }

    public func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool) async throws -> Bool {
        guard hostVehicleSessionConnected else {
            throw CarPlayHostError.vehicleSessionDisconnected
        }
        performPresentTemplate(templateToPresent, animated: animated)
        return true
    }

    public func dismissTemplate(animated: Bool) {
        guard hostVehicleSessionConnected else { return }
        performDismissTemplate(animated: animated)
    }

    public func dismissTemplate(animated: Bool) async throws -> Bool {
        guard hostVehicleSessionConnected else {
            throw CarPlayHostError.vehicleSessionDisconnected
        }
        guard presentedTemplate != nil else {
            throw CarPlayHostError.noPresentedTemplate
        }
        performDismissTemplate(animated: animated)
        return true
    }

    private func performSetRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) {
        let previous = topTemplate
        if let previous {
            delegate?.templateWillDisappear(previous, animated: animated)
        }
        delegate?.templateWillAppear(rootTemplate, animated: animated)
        templates = [rootTemplate]
        presentedTemplate = nil
        if let previous {
            delegate?.templateDidDisappear(previous, animated: animated)
        }
        delegate?.templateDidAppear(rootTemplate, animated: animated)
    }

    private func performPushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        let previous = topTemplate
        if let previous {
            delegate?.templateWillDisappear(previous, animated: animated)
        }
        delegate?.templateWillAppear(templateToPush, animated: animated)
        templates.append(templateToPush)
        if let previous {
            delegate?.templateDidDisappear(previous, animated: animated)
        }
        delegate?.templateDidAppear(templateToPush, animated: animated)
    }

    private func performPopTemplate(animated: Bool) {
        guard templates.count > 1, let removed = templates.last else { return }
        let next = templates[templates.count - 2]
        delegate?.templateWillDisappear(removed, animated: animated)
        delegate?.templateWillAppear(next, animated: animated)
        templates.removeLast()
        delegate?.templateDidDisappear(removed, animated: animated)
        delegate?.templateDidAppear(next, animated: animated)
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
        let previous = presentedTemplate
        if let previous {
            delegate?.templateWillDisappear(previous, animated: animated)
        }
        delegate?.templateWillAppear(templateToPresent, animated: animated)
        presentedTemplate = templateToPresent
        if let previous {
            delegate?.templateDidDisappear(previous, animated: animated)
        }
        delegate?.templateDidAppear(templateToPresent, animated: animated)
    }

    private func performDismissTemplate(animated: Bool) {
        guard let current = presentedTemplate else { return }
        delegate?.templateWillDisappear(current, animated: animated)
        presentedTemplate = nil
        delegate?.templateDidDisappear(current, animated: animated)
    }
}

@MainActor
open class CPSessionConfiguration: NSObject {
    public weak var delegate: (any CPSessionConfigurationDelegate)?
    public private(set) var contentStyle: CPContentStyle = []
    public private(set) var limitedUserInterfaces: CPLimitableUserInterface = []

    public init(delegate: any CPSessionConfigurationDelegate) {
        self.delegate = delegate
        super.init()
    }
}

open class CPDashboardController: NSObject {
    #if canImport(UIKit)
    public var shortcutButtons: [CPDashboardButton] = []
    #endif
}

open class CPInstrumentClusterController: NSObject {
    public weak var delegate: (any CPInstrumentClusterControllerDelegate)?
    public var attributedInactiveDescriptionVariants: [NSAttributedString] = []
    public var inactiveDescriptionVariants: [String] = []
    public private(set) var compassSetting: CPInstrumentClusterSetting = .unspecified
    public private(set) var speedLimitSetting: CPInstrumentClusterSetting = .unspecified

    #if canImport(UIKit)
    public var instrumentClusterWindow: UIWindow? { nil }
    #endif
}

#if canImport(UIKit)
@MainActor
open class CPWindow: UIWindow {
    public weak var templateApplicationScene: CPTemplateApplicationScene?
    public let mapButtonSafeAreaLayoutGuide = UILayoutGuide()

    public override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder: NSCoder) {
        return nil
    }
}

@MainActor
open class CPTemplateApplicationScene: UIScene {
    public let interfaceController = CPInterfaceController()
    public var contentStyle: UIUserInterfaceStyle = .unspecified
    public var delegate: (any CPTemplateApplicationSceneDelegate)?
    public private(set) lazy var carWindow: CPWindow = {
        let window: CPWindow
        if let windowScene = self as? UIWindowScene {
            window = CPWindow(windowScene: windowScene)
        } else {
            window = CPWindow(frame: .zero)
        }
        window.templateApplicationScene = self
        return window
    }()

    public override init(session: UISceneSession, connectionOptions: UIScene.ConnectionOptions) {
        super.init(session: session, connectionOptions: connectionOptions)
    }
}

@MainActor
open class CPTemplateApplicationDashboardScene: UIScene {
    public let dashboardController = CPDashboardController()
    public var delegate: (any CPTemplateApplicationDashboardSceneDelegate)?
    public private(set) lazy var dashboardWindow: UIWindow = {
        if let windowScene = self as? UIWindowScene {
            return UIWindow(windowScene: windowScene)
        }
        return UIWindow(frame: .zero)
    }()

    public override init(session: UISceneSession, connectionOptions: UIScene.ConnectionOptions) {
        super.init(session: session, connectionOptions: connectionOptions)
    }
}

@MainActor
open class CPTemplateApplicationInstrumentClusterScene: UIScene {
    public let instrumentClusterController = CPInstrumentClusterController()
    public var contentStyle: UIUserInterfaceStyle = .unspecified
    public var delegate: (any CPTemplateApplicationInstrumentClusterSceneDelegate)?

    public override init(session: UISceneSession, connectionOptions: UIScene.ConnectionOptions) {
        super.init(session: session, connectionOptions: connectionOptions)
    }
}
#else
@MainActor
open class CPWindow: NSObject {
    public weak var templateApplicationScene: CPTemplateApplicationScene?
}

@MainActor
open class CPTemplateApplicationScene: NSObject {
    public let interfaceController = CPInterfaceController()
    public var delegate: (any CPTemplateApplicationSceneDelegate)?
    public let carWindow = CPWindow()
}

@MainActor
open class CPTemplateApplicationDashboardScene: NSObject {
    public let dashboardController = CPDashboardController()
    public var delegate: (any CPTemplateApplicationDashboardSceneDelegate)?
}

@MainActor
open class CPTemplateApplicationInstrumentClusterScene: NSObject {
    public let instrumentClusterController = CPInstrumentClusterController()
    public var delegate: (any CPTemplateApplicationInstrumentClusterSceneDelegate)?
}
#endif
