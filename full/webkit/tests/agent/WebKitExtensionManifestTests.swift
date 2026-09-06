import Foundation
import WebKit

private func wkManifestMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated { try body() }
    } catch {
        fatalError("WebKit manifest test failed: \(error)")
    }
}

@MainActor
private func writeExtension(manifest: String, messages: String? = nil) throws -> URL {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("wk-ext-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try Data(manifest.utf8).write(to: root.appendingPathComponent("manifest.json"))
    if let messages {
        let locale = root.appendingPathComponent("_locales/en", isDirectory: true)
        try FileManager.default.createDirectory(at: locale, withIntermediateDirectories: true)
        try Data(messages.utf8).write(to: locale.appendingPathComponent("messages.json"))
    }
    return root
}

func testManifestV3ParsesPermissionsContentScriptsAndAction() {
    wkManifestMain {
        let root = try writeExtension(manifest: """
        {
          "manifest_version": 3,
          "name": "Portable",
          "version": "1.2.3",
          "description": "A portable extension",
          "short_name": "Port",
          "permissions": ["storage", "tabs"],
          "optional_permissions": ["scripting"],
          "host_permissions": ["*://*.example.com/*"],
          "action": { "default_title": "Open" },
          "background": { "service_worker": "bg.js" },
          "content_scripts": [{ "matches": ["https://example.com/*"], "js": ["content.js"] }],
          "icons": { "16": "icon.png" },
          "commands": { "_execute_action": { "suggested_key": { "default": "Ctrl+Shift+Y" } } },
          "options_page": "options.html",
          "chrome_url_overrides": { "newtab": "newtab.html" }
        }
        """)
        let ext = try WKWebExtension(resourceBaseURL: root)
        precondition(ext.errors.isEmpty)
        precondition(ext.manifestVersion == 3)
        precondition(ext.displayName == "Portable")
        precondition(ext.displayShortName == "Port")
        precondition(ext.displayVersion == "1.2.3")
        precondition(ext.version == "1.2.3")
        precondition(ext.displayDescription == "A portable extension")
        precondition(ext.displayActionLabel == "Open")
        precondition(ext.hasBackgroundContent)
        precondition(!ext.hasPersistentBackgroundContent)
        precondition(ext.hasInjectedContent)
        precondition(ext.hasCommands)
        precondition(ext.hasOptionsPage)
        precondition(ext.hasOverrideNewTabPage)
        precondition(ext.requestedPermissions.contains(.storage))
        precondition(ext.requestedPermissions.contains(.tabs))
        precondition(ext.optionalPermissions.contains(.scripting))
        precondition(ext.supportsManifestVersion(2))
        precondition(ext.supportsManifestVersion(3))
        precondition(!ext.supportsManifestVersion(1))
        precondition(!ext.requestedPermissionMatchPatterns.isEmpty)
        precondition(!ext.allRequestedMatchPatterns.isEmpty)
        precondition(ext.icon(for: CGSize(width: 16, height: 16)) == nil)
        precondition(ext.actionIcon(for: CGSize(width: 16, height: 16)) == nil)
        precondition(ext.manifest["name"] as? String == "Portable")
        try? FileManager.default.removeItem(at: root)
    }
}

func testManifestV2BackgroundPersistenceAndDefaultLocaleSubstitution() {
    wkManifestMain {
        let root = try writeExtension(
            manifest: """
            {
              "manifest_version": 2,
              "name": "__MSG_extName__",
              "version": "0.1",
              "default_locale": "en",
              "background": { "scripts": ["bg.js"], "persistent": true },
              "browser_action": { "default_title": "__MSG_action__" }
            }
            """,
            messages: """
            {
              "extName": { "message": "Localized" },
              "action": { "message": "Go" }
            }
            """
        )
        let ext = try WKWebExtension(resourceBaseURL: root)
        precondition(ext.displayName == "Localized")
        precondition(ext.displayActionLabel == "Go")
        precondition(ext.defaultLocale?.identifier.hasPrefix("en") == true)
        precondition(ext.hasPersistentBackgroundContent)
        precondition(ext.hasBackgroundContent)
        try? FileManager.default.removeItem(at: root)
    }
}

func testManifestRejectsMalformedAndUnsupportedVersions() {
    wkManifestMain {
        let missing = FileManager.default.temporaryDirectory
            .appendingPathComponent("wk-missing-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: missing, withIntermediateDirectories: true)
        do {
            _ = try WKWebExtension(resourceBaseURL: missing)
            fatalError("expected resourceNotFound")
        } catch let error as WKWebExtension.Error {
            precondition(error.code == .resourceNotFound)
            precondition(WKWebExtension.Error.resourceNotFound ~= error)
        }
        let badJSON = try writeExtension(manifest: "{")
        do {
            _ = try WKWebExtension(resourceBaseURL: badJSON)
            fatalError("expected invalidManifest")
        } catch let error as WKWebExtension.Error {
            precondition(error.code == .invalidManifest)
        }
        let badVersion = try writeExtension(manifest: """
        {"manifest_version": 1, "name": "x", "version": "1"}
        """)
        do {
            _ = try WKWebExtension(resourceBaseURL: badVersion)
            fatalError("expected unsupportedManifestVersion")
        } catch let error as WKWebExtension.Error {
            precondition(error.code == .unsupportedManifestVersion)
        }
        let badName = try writeExtension(manifest: """
        {"manifest_version": 3, "version": "1"}
        """)
        do {
            _ = try WKWebExtension(resourceBaseURL: badName)
            fatalError("expected invalidManifestEntry")
        } catch let error as WKWebExtension.Error {
            precondition(error.code == .invalidManifestEntry)
        }
        let badPattern = try writeExtension(manifest: """
        {"manifest_version": 3, "name": "x", "version": "1", "host_permissions": ["not-a-pattern"]}
        """)
        do {
            _ = try WKWebExtension(resourceBaseURL: badPattern)
            fatalError("expected match pattern failure")
        } catch {
            _ = error
        }
        let empty = WKWebExtension()
        precondition(!empty.errors.isEmpty)
        precondition(empty.errors[0].code == .unknown)
        precondition(WKWebExtension.Error.Code.unknown.rawValue == 1)
        precondition(WKWebExtension.Error.Code.resourceNotFound.rawValue == 2)
        precondition(WKWebExtension.Error.Code.invalidResourceCodeSignature.rawValue == 3)
        precondition(WKWebExtension.Error.Code.invalidManifest.rawValue == 4)
        precondition(WKWebExtension.Error.Code.unsupportedManifestVersion.rawValue == 5)
        precondition(WKWebExtension.Error.Code.invalidManifestEntry.rawValue == 6)
        precondition(WKWebExtension.Error.Code.invalidDeclarativeNetRequestEntry.rawValue == 7)
        precondition(WKWebExtension.Error.Code.invalidBackgroundPersistence.rawValue == 8)
        precondition(WKWebExtension.Error.Code.invalidArchive.rawValue == 9)
        precondition(WKWebExtension.errorDomain == "WKWebExtensionErrorDomain")
        let err = WKWebExtension.Error(.invalidArchive)
        _ = err.errorCode
        _ = err.errorUserInfo
        _ = err.localizedDescription
        _ = err.hashValue
        precondition(err != WKWebExtension.Error(.unknown))
        try? FileManager.default.removeItem(at: missing)
        try? FileManager.default.removeItem(at: badJSON)
        try? FileManager.default.removeItem(at: badVersion)
        try? FileManager.default.removeItem(at: badName)
        try? FileManager.default.removeItem(at: badPattern)
    }
}
