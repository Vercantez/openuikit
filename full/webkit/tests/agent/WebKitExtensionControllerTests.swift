import Foundation
import WebKit

private func wkCtlMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated { try body() }
    } catch {
        fatalError("WebKit extension controller test failed: \(error)")
    }
}

@MainActor
private final class ProbeTab: WKWebExtensionTab {
    var titleValue = "Tab"
    var urlValue = URL(string: "https://example.com/")
    var pinned = false
    var muted = false
    var zoom = 1.0
    weak var windowRef: ProbeWindow?

    func window(for context: WKWebExtensionContext) -> (any WKWebExtensionWindow)? {
        _ = context
        return windowRef
    }
    func title(for context: WKWebExtensionContext) -> String? {
        _ = context
        return titleValue
    }
    func url(for context: WKWebExtensionContext) -> URL? {
        _ = context
        return urlValue
    }
    func isPinned(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return pinned
    }
    func isMuted(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return muted
    }
    func zoomFactor(for context: WKWebExtensionContext) -> Double {
        _ = context
        return zoom
    }
    func shouldGrantPermissionsOnUserGesture(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return true
    }
}

@MainActor
private final class ProbeWindow: WKWebExtensionWindow {
    var tabList: [any WKWebExtensionTab] = []
    var active: (any WKWebExtensionTab)?
    var type: WKWebExtension.WindowType = .normal
    var state: WKWebExtension.WindowState = .normal
    var frameValue = CGRect(x: 0, y: 0, width: 800, height: 600)
    var privateWindow = false

    func tabs(for context: WKWebExtensionContext) -> [any WKWebExtensionTab] {
        _ = context
        return tabList
    }
    func activeTab(for context: WKWebExtensionContext) -> (any WKWebExtensionTab)? {
        _ = context
        return active
    }
    func windowType(for context: WKWebExtensionContext) -> WKWebExtension.WindowType {
        _ = context
        return type
    }
    func windowState(for context: WKWebExtensionContext) -> WKWebExtension.WindowState {
        _ = context
        return state
    }
    func isPrivate(for context: WKWebExtensionContext) -> Bool {
        _ = context
        return privateWindow
    }
    func frame(for context: WKWebExtensionContext) -> CGRect {
        _ = context
        return frameValue
    }
}

func testControllerLoadUnloadAndExtensionContextLookup() {
    wkCtlMain {
        let ext = WKWebExtension()
        let context = WKWebExtensionContext(for: ext)
        let configuration = WKWebExtensionController.Configuration.default()
        _ = WKWebExtensionController.Configuration.nonPersistent()
        _ = WKWebExtensionController.Configuration(identifier: UUID())
        precondition(configuration.isPersistent)
        _ = configuration.identifier
        _ = configuration.webViewConfiguration
        _ = configuration.defaultWebsiteDataStore
        let controller = WKWebExtensionController(configuration: configuration)
        _ = WKWebExtensionController()
        precondition(!context.isLoaded)
        try controller.load(context)
        precondition(context.isLoaded)
        precondition(context.webExtensionController === controller)
        precondition(controller.extensionContexts.contains(context))
        precondition(controller.extensions.contains(ext))
        precondition(controller.extensionContext(for: ext) === context)
        precondition(controller.extensionContext(for: context.baseURL) === context)
        do {
            try controller.load(context)
            fatalError("expected alreadyLoaded")
        } catch let error as WKWebExtensionContext.Error {
            precondition(error.code == .alreadyLoaded)
        }
        try controller.unload(context)
        precondition(!context.isLoaded)
        do {
            try controller.unload(context)
            fatalError("expected notLoaded")
        } catch let error as WKWebExtensionContext.Error {
            precondition(error.code == .notLoaded)
        }
        _ = controller.configuration
        _ = WKWebExtensionController.allExtensionDataTypes
        precondition(WKWebExtensionController.allExtensionDataTypes.contains(.local))
    }
}

func testControllerTabAndWindowRegistry() {
    wkCtlMain {
        let ext = WKWebExtension()
        let context = WKWebExtensionContext(for: ext)
        let controller = WKWebExtensionController()
        try controller.load(context)
        let window = ProbeWindow()
        let tab = ProbeTab()
        tab.windowRef = window
        window.tabList = [tab]
        window.active = tab
        controller.didOpenWindow(window)
        controller.didFocusWindow(window)
        controller.didOpenTab(tab)
        controller.didSelectTabs([tab])
        controller.didActivateTab(tab, previousActiveTab: nil)
        controller.didChangeTabProperties([.title, .URL], for: tab)
        controller.didMoveTab(tab, from: 0, in: window)
        precondition(context.openWindows.count == 1)
        precondition(context.openTabs.count == 1)
        precondition(context.focusedWindow === window)
        precondition(tab.title(for: context) == "Tab")
        precondition(tab.url(for: context)?.host == "example.com")
        precondition(tab.window(for: context) === window)
        precondition(tab.indexInWindow(for: context) == 0)
        precondition(tab.parentTab(for: context) == nil)
        precondition(!tab.isPinned(for: context))
        precondition(!tab.isReaderModeActive(for: context))
        precondition(!tab.isPlayingAudio(for: context))
        precondition(!tab.isMuted(for: context))
        precondition(tab.size(for: context) == .zero)
        precondition(tab.zoomFactor(for: context) == 1)
        precondition(tab.pendingURL(for: context) == nil)
        precondition(tab.isLoadingComplete(for: context))
        precondition(tab.shouldGrantPermissionsOnUserGesture(for: context))
        precondition(window.tabs(for: context).count == 1)
        precondition(window.activeTab(for: context) === tab)
        precondition(window.windowType(for: context) == .normal)
        precondition(window.windowState(for: context) == .normal)
        precondition(!window.isPrivate(for: context))
        precondition(window.frame(for: context).width == 800)
        context.userGesturePerformed(in: tab)
        precondition(context.hasActiveUserGesture(in: tab))
        context.clearUserGesture(in: tab)
        precondition(!context.hasActiveUserGesture(in: tab))
        let action = context.action(for: tab)
        _ = action.badgeText
        action.badgeText = "1"
        action.isEnabled = false
        _ = action.hasUnreadBadgeText
        _ = action.inspectionName
        _ = action.label
        _ = action.presentsPopup
        _ = action.popupWebView
        _ = action.popupViewController
        _ = action.associatedTab
        _ = action.webExtensionContext
        _ = action.icon(for: CGSize(width: 16, height: 16))
        action.closePopup()
        let other = ProbeTab()
        controller.didReplaceTab(tab, with: other)
        controller.didDeselectTabs([other])
        controller.didCloseTab(other, windowIsClosing: false)
        controller.didCloseWindow(window)
        let tabConfig = WKWebExtension.TabConfiguration()
        tabConfig.url = URL(string: "https://example.com/")
        tabConfig.window = window
        tabConfig.index = 1
        tabConfig.parentTab = nil
        tabConfig.shouldAddToSelection = true
        tabConfig.shouldBeActive = true
        tabConfig.shouldBeMuted = false
        tabConfig.shouldBePinned = false
        tabConfig.shouldReaderModeBeActive = false
        let windowConfig = WKWebExtension.WindowConfiguration()
        windowConfig.frame = .zero
        windowConfig.shouldBeFocused = true
        windowConfig.shouldBePrivate = false
        windowConfig.tabURLs = [URL(string: "https://example.com/")!]
        windowConfig.tabs = []
        windowConfig.windowState = .maximized
        windowConfig.windowType = .popup
        precondition(WKWebExtension.WindowType.normal.rawValue == 0)
        precondition(WKWebExtension.WindowType.popup.rawValue == 1)
        precondition(WKWebExtension.WindowState.normal.rawValue == 0)
        precondition(WKWebExtension.WindowState.minimized.rawValue == 1)
        precondition(WKWebExtension.WindowState.maximized.rawValue == 2)
        precondition(WKWebExtension.WindowState.fullscreen.rawValue == 3)
        _ = WKWebExtension.WindowType.normal.hashValue
        _ = WKWebExtension.WindowState.normal.hashValue
        precondition(WKWebExtension.WindowType(rawValue: 1) == .popup)
        precondition(WKWebExtension.WindowState(rawValue: 3) == .fullscreen)
    }
}

func testActionCommandDataRecordAndMessagePort() {
    wkCtlMain {
        let command = WKWebExtension.Command(id: "run")
        command.title = "Run"
        command.activationKey = "R"
        command.modifierFlags = 0
        precondition(command.id == "run")
        _ = command.webExtensionContext
        let record = WKWebExtension.DataRecord(
            displayName: "Perms",
            uniqueIdentifier: "id",
            containedDataTypes: [.local],
            errors: [WKWebExtension.DataRecord.Error(.unknown)],
            totalSizeInBytes: 4
        )
        precondition(record.displayName == "Perms")
        precondition(record.uniqueIdentifier == "id")
        precondition(record.containedDataTypes.contains(.local))
        precondition(record.totalSizeInBytes == 4)
        precondition(record.sizeInBytes(ofTypes: [.local]) == 0)
        precondition(WKWebExtension.DataRecord.errorDomain == "WKWebExtensionDataRecordErrorDomain")
        precondition(WKWebExtension.DataRecord.Error.Code.unknown.rawValue == 1)
        precondition(WKWebExtension.DataRecord.Error.Code.localStorageFailed.rawValue == 2)
        precondition(WKWebExtension.DataRecord.Error.Code.sessionStorageFailed.rawValue == 3)
        precondition(WKWebExtension.DataRecord.Error.Code.synchronizedStorageFailed.rawValue == 4)
        let recErr = WKWebExtension.DataRecord.Error(.localStorageFailed)
        _ = recErr.errorCode
        _ = recErr.errorUserInfo
        _ = recErr.localizedDescription
        _ = recErr.hashValue
        precondition(WKWebExtension.DataRecord.Error.localStorageFailed ~= recErr)
        let port = WKWebExtension.MessagePort(applicationIdentifier: "app")
        precondition(port.applicationIdentifier == "app")
        precondition(!port.isDisconnected)
        var disconnected = 0
        port.disconnectHandler = { _ in disconnected += 1 }
        port.messageHandler = { _, _ in }
        do {
            try port.sendMessage("hi")
            fatalError("expected notConnected")
        } catch let error as WKWebExtension.MessagePort.Error {
            precondition(error.code == .notConnected)
        }
        port.disconnect()
        precondition(port.isDisconnected)
        precondition(disconnected == 1)
        port.disconnect(throwing: WKWebExtension.MessagePort.Error(.messageInvalid))
        precondition(WKWebExtension.MessagePort.errorDomain == "WKWebExtensionMessagePortErrorDomain")
        precondition(WKWebExtension.MessagePort.Error.Code.unknown.rawValue == 1)
        precondition(WKWebExtension.MessagePort.Error.Code.notConnected.rawValue == 2)
        precondition(WKWebExtension.MessagePort.Error.Code.messageInvalid.rawValue == 3)
        let portErr = WKWebExtension.MessagePort.Error(.unknown)
        _ = portErr.errorCode
        _ = portErr.hashValue
        precondition(WKWebExtension.MessagePort.Error.unknown ~= portErr)
        _ = WKWebExtension.Permission(rawValue: "storage")
        _ = WKWebExtension.DataType(rawValue: "WKWebExtensionDataTypeLocal")
        _ = WKWebExtension.DataType("WKWebExtensionDataTypeSession")
    }
}

func testUserGestureAndContextHelpers() {
    wkCtlMain {
        let context = WKWebExtensionContext(for: WKWebExtension())
        let tab = ProbeTab()
        context.didOpenTab(tab)
        context.didSelectTabs([tab])
        context.didDeselectTabs([tab])
        context.didActivateTab(tab, previousActiveTab: nil)
        context.didChangeTabProperties(.title, for: tab)
        context.didMoveTab(tab, from: 0, in: nil)
        context.didReplaceTab(tab, with: ProbeTab())
        context.didCloseTab(tab, windowIsClosing: true)
        let window = ProbeWindow()
        context.didOpenWindow(window)
        context.didFocusWindow(window)
        context.didCloseWindow(window)
        _ = context.optionsPageURL
        _ = context.overrideNewTabPageURL
    }
}
