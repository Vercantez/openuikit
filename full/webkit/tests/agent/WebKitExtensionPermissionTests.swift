import Foundation
import WebKit

private func wkPermMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated { try body() }
    } catch {
        fatalError("WebKit permission test failed: \(error)")
    }
}

@MainActor
private func sampleExtension() throws -> WKWebExtension {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("wk-perm-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let manifest = """
    {
      "manifest_version": 3,
      "name": "Perms",
      "version": "1",
      "permissions": ["storage", "tabs"],
      "optional_permissions": ["scripting"],
      "host_permissions": ["*://example.com/*"],
      "content_scripts": [{ "matches": ["*://example.com/*"], "js": ["c.js"] }]
    }
    """
    try Data(manifest.utf8).write(to: root.appendingPathComponent("manifest.json"))
    return try WKWebExtension(resourceBaseURL: root)
}

func testPermissionConstantsAndStatuses() {
    wkPermMain {
        precondition(WKWebExtension.Permission.activeTab.rawValue == "activeTab")
        precondition(WKWebExtension.Permission.alarms.rawValue == "alarms")
        precondition(WKWebExtension.Permission.clipboardWrite.rawValue == "clipboardWrite")
        precondition(WKWebExtension.Permission.contextMenus.rawValue == "contextMenus")
        precondition(WKWebExtension.Permission.cookies.rawValue == "cookies")
        precondition(WKWebExtension.Permission.declarativeNetRequest.rawValue == "declarativeNetRequest")
        precondition(WKWebExtension.Permission.declarativeNetRequestFeedback.rawValue == "declarativeNetRequestFeedback")
        precondition(WKWebExtension.Permission.declarativeNetRequestWithHostAccess.rawValue == "declarativeNetRequestWithHostAccess")
        precondition(WKWebExtension.Permission.menus.rawValue == "menus")
        precondition(WKWebExtension.Permission.nativeMessaging.rawValue == "nativeMessaging")
        precondition(WKWebExtension.Permission.scripting.rawValue == "scripting")
        precondition(WKWebExtension.Permission.storage.rawValue == "storage")
        precondition(WKWebExtension.Permission.tabs.rawValue == "tabs")
        precondition(WKWebExtension.Permission.unlimitedStorage.rawValue == "unlimitedStorage")
        precondition(WKWebExtension.Permission.webNavigation.rawValue == "webNavigation")
        precondition(WKWebExtension.Permission.webRequest.rawValue == "webRequest")
        let named = WKWebExtension.Permission("storage")
        precondition(named == .storage)
        precondition(named != .tabs)
        _ = named.hashValue
        precondition(WKWebExtension.DataType.local.rawValue == "WKWebExtensionDataTypeLocal")
        precondition(WKWebExtension.DataType.session.rawValue == "WKWebExtensionDataTypeSession")
        precondition(WKWebExtension.DataType.synchronized.rawValue == "WKWebExtensionDataTypeSynchronized")
        precondition(WKWebExtensionContext.PermissionStatus.deniedExplicitly.rawValue == -3)
        precondition(WKWebExtensionContext.PermissionStatus.deniedImplicitly.rawValue == -2)
        precondition(WKWebExtensionContext.PermissionStatus.requestedImplicitly.rawValue == -1)
        precondition(WKWebExtensionContext.PermissionStatus.unknown.rawValue == 0)
        precondition(WKWebExtensionContext.PermissionStatus.requestedExplicitly.rawValue == 1)
        precondition(WKWebExtensionContext.PermissionStatus.grantedImplicitly.rawValue == 2)
        precondition(WKWebExtensionContext.PermissionStatus.grantedExplicitly.rawValue == 3)
        _ = WKWebExtensionContext.PermissionStatus.grantedExplicitly.hashValue
        var hasher = Hasher()
        WKWebExtensionContext.PermissionStatus.unknown.hash(into: &hasher)
        precondition(WKWebExtensionContext.PermissionStatus(rawValue: 3) == .grantedExplicitly)
    }
}

func testContextPermissionGrantDenyAndURLAccess() {
    wkPermMain {
        let ext = try sampleExtension()
        let context = WKWebExtensionContext(for: ext)
        _ = WKWebExtensionContext(forExtension: ext)
        precondition(context.permissionStatus(for: .storage) == .requestedExplicitly)
        precondition(context.permissionStatus(for: .scripting) == .requestedImplicitly)
        precondition(context.permissionStatus(for: .cookies) == .unknown)
        precondition(!context.hasPermission(.storage))
        context.setPermissionStatus(.grantedExplicitly, for: .storage)
        precondition(context.hasPermission(.storage))
        precondition(context.hasPermission(.storage, in: nil))
        precondition(context.currentPermissions.contains(.storage))
        context.setPermissionStatus(.deniedExplicitly, for: .tabs, expirationDate: .distantFuture)
        precondition(context.permissionStatus(for: .tabs) == .deniedExplicitly)
        let pattern = try WKWebExtension.MatchPattern(string: "*://example.com/*")
        context.setPermissionStatus(.grantedExplicitly, for: pattern)
        precondition(context.permissionStatus(for: pattern) == .grantedExplicitly)
        let url = URL(string: "https://example.com/page")!
        precondition(context.hasAccess(to: url))
        precondition(context.hasAccess(to: url, in: nil))
        precondition(context.permissionStatus(for: url) == .grantedExplicitly)
        precondition(context.hasInjectedContent(for: url))
        context.setPermissionStatus(.deniedExplicitly, for: pattern, expirationDate: nil)
        precondition(!context.hasAccess(to: url))
        context.setPermissionStatus(.grantedExplicitly, for: url)
        precondition(context.hasAccess(to: URL(string: "https://example.com/page")!))
        let all = WKWebExtension.MatchPattern.allURLs()
        context.setPermissionStatus(.grantedExplicitly, for: all)
        precondition(context.hasAccessToAllURLs)
        precondition(context.hasAccess(to: URL(string: "https://anywhere.invalid/")!))
        _ = context.uniqueIdentifier
        _ = context.baseURL
        context.isInspectable = true
        context.inspectionName = "probe"
        context.unsupportedAPIs.insert("windows")
        _ = context.webViewConfiguration
        _ = context.errors
        _ = context.commands
        _ = context.currentPermissionMatchPatterns
        _ = WKWebExtensionContext.errorDomain
        _ = WKWebExtensionContext.errorsDidUpdateNotification
        _ = WKWebExtensionContext.permissionsWereGrantedNotification
        _ = WKWebExtensionContext.permissionsWereDeniedNotification
        _ = WKWebExtensionContext.grantedPermissionsWereRemovedNotification
        _ = WKWebExtensionContext.deniedPermissionsWereRemovedNotification
        _ = WKWebExtensionContext.permissionMatchPatternsWereGrantedNotification
        _ = WKWebExtensionContext.permissionMatchPatternsWereDeniedNotification
        _ = WKWebExtensionContext.grantedPermissionMatchPatternsWereRemovedNotification
        _ = WKWebExtensionContext.deniedPermissionMatchPatternsWereRemovedNotification
        precondition(WKWebExtensionContext.NotificationUserInfoKey.permissions.rawValue == "permissions")
        precondition(WKWebExtensionContext.NotificationUserInfoKey.matchPatterns.rawValue == "matchPatterns")
        _ = WKWebExtensionContext.NotificationUserInfoKey("custom")
        _ = WKWebExtensionContext.Error.Code.unknown.rawValue == 1
        precondition(WKWebExtensionContext.Error.Code.alreadyLoaded.rawValue == 2)
        precondition(WKWebExtensionContext.Error.Code.notLoaded.rawValue == 3)
        precondition(WKWebExtensionContext.Error.Code.baseURLAlreadyInUse.rawValue == 4)
        precondition(WKWebExtensionContext.Error.Code.noBackgroundContent.rawValue == 5)
        precondition(WKWebExtensionContext.Error.Code.backgroundContentFailedToLoad.rawValue == 6)
        let ctxErr = WKWebExtensionContext.Error(.notLoaded)
        _ = ctxErr.errorCode
        _ = ctxErr.errorUserInfo
        _ = ctxErr.localizedDescription
        _ = ctxErr.hashValue
        precondition(WKWebExtensionContext.Error.notLoaded ~= ctxErr)
        precondition(ctxErr != WKWebExtensionContext.Error(.unknown))
        var backgroundError: Error?
        context.loadBackgroundContent { backgroundError = $0 }
        precondition((backgroundError as? WKWebExtensionContext.Error)?.code == .noBackgroundContent)
        _ = context.menuItems(for: nil)
        context.performAction(for: nil)
        context.performCommand(WKWebExtension.Command(id: "x"))
        context.performCommand(for: "event")
        _ = context.action(for: nil)
        _ = context.hasContentModificationRules
        _ = context.hasInjectedContent
        _ = context.hasRequestedOptionalAccessToAllHosts
        _ = context.hasAccessToPrivateData
        _ = context.hasAccessToAllHosts
    }
}

func testTabChangedPropertiesOptionSet() {
    wkPermMain {
        precondition(WKWebExtension.TabChangedProperties.loading.rawValue != 0)
        precondition(WKWebExtension.TabChangedProperties.muted.rawValue != 0)
        precondition(WKWebExtension.TabChangedProperties.pinned.rawValue != 0)
        precondition(WKWebExtension.TabChangedProperties.playingAudio.rawValue != 0)
        precondition(WKWebExtension.TabChangedProperties.readerMode.rawValue != 0)
        precondition(WKWebExtension.TabChangedProperties.size.rawValue != 0)
        precondition(WKWebExtension.TabChangedProperties.title.rawValue != 0)
        precondition(WKWebExtension.TabChangedProperties.URL.rawValue != 0)
        precondition(WKWebExtension.TabChangedProperties.zoomFactor.rawValue != 0)
        var properties: WKWebExtension.TabChangedProperties = [.loading, .title]
        properties.formUnion(.URL)
        properties.formIntersection(.title)
        properties.formSymmetricDifference(.muted)
        var copy = WKWebExtension.TabChangedProperties(rawValue: properties.rawValue)
        _ = copy.insert(.pinned)
        _ = copy.remove(.pinned)
        _ = copy.contains(.loading)
        _ = copy.intersection(.title)
        _ = copy.union(.size)
        _ = copy.symmetricDifference(.muted)
        _ = copy.subtracting(.loading)
        copy.subtract(.title)
        _ = copy.isEmpty
        _ = copy.isDisjoint(with: .muted)
        _ = copy.isSubset(of: [.loading, .title, .URL, .size, .muted])
        _ = copy.isSuperset(of: [])
        _ = copy.isStrictSubset(of: [.loading, .title, .URL, .size, .muted, .pinned])
        _ = copy.isStrictSuperset(of: [])
        _ = WKWebExtension.TabChangedProperties()
        _ = WKWebExtension.TabChangedProperties([.loading])
        _ = WKWebExtension.TabChangedProperties(arrayLiteral: .loading, .title)
        _ = properties.update(with: .readerMode)
        _ = properties != []
    }
}
