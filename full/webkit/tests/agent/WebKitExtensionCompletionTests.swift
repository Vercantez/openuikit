import Foundation
import WebKit

private func wkExtCompleteMain<T>(_ body: @escaping @MainActor () throws -> T) -> T {
    do {
        return try MainActor.assumeIsolated { try body() }
    } catch {
        fatalError("WebKit extension completion test failed: \(error)")
    }
}

@MainActor
private final class StubExtensionDelegate: WKWebExtensionControllerDelegate {}

@MainActor
private final class StubExtensionTab: WKWebExtensionTab {}

@MainActor
private final class StubExtensionWindow: WKWebExtensionWindow {}

@MainActor
private func extCompletionContext() -> (WKWebExtensionController, WKWebExtensionContext) {
    let context = WKWebExtensionContext(for: WKWebExtension())
    return (WKWebExtensionController(), context)
}

private func isPortableUnknown(_ error: (any Error)?) -> Bool {
    (error as? WKError)?.errorCode == WKError.Code.unknown.rawValue
}

func testExtensionDataCompletionHandlers() {
    wkExtCompleteMain {
        let (controller, context) = extCompletionContext()
        try controller.load(context)
        var singleFired = false
        var single: WKWebExtension.DataRecord?
        controller.dataRecord(ofTypes: [.local], for: context) { record in
            singleFired = true
            single = record
        }
        precondition(singleFired)
        precondition(single?.containedDataTypes == [.local])
        precondition(single?.uniqueIdentifier == context.uniqueIdentifier)
        var many: [WKWebExtension.DataRecord] = []
        controller.dataRecords(ofTypes: [.local, .session]) { many = $0 }
        precondition(many.count == 1)
        precondition(many[0].containedDataTypes == [.local, .session])
        precondition(many[0].uniqueIdentifier == context.uniqueIdentifier)
        var removed = false
        controller.removeData(ofTypes: [.local], from: many) { removed = true }
        precondition(removed)
    }
}

func testExtensionMessagePortCompletionHandler() {
    wkExtCompleteMain {
        let port = WKWebExtension.MessagePort(applicationIdentifier: "com.example.app")
        var fired = false
        var reply: Any?
        var sendError: (any Error)?
        port.sendMessage(["ping": true]) { value, error in
            fired = true
            reply = value
            sendError = error
        }
        precondition(fired)
        precondition(reply == nil)
        precondition(
            (sendError as? WKWebExtension.MessagePort.Error)
                == WKWebExtension.MessagePort.Error(.notConnected)
        )
    }
}

func testExtensionDelegateTabWindowCompletionHandlers() {
    wkExtCompleteMain {
        let delegate = StubExtensionDelegate()
        let (controller, context) = extCompletionContext()
        var tabFired = false
        var tabError: (any Error)?
        delegate.webExtensionController(
            controller,
            openNewTabUsing: WKWebExtension.TabConfiguration(),
            for: context
        ) { tab, error in
            tabFired = true
            tabError = error
            precondition(tab == nil)
        }
        precondition(tabFired)
        precondition(isPortableUnknown(tabError))
        var windowFired = false
        var windowError: (any Error)?
        delegate.webExtensionController(
            controller,
            openNewWindowUsing: WKWebExtension.WindowConfiguration(),
            for: context
        ) { window, error in
            windowFired = true
            windowError = error
            precondition(window == nil)
        }
        precondition(windowFired)
        precondition(isPortableUnknown(windowError))
        var optionsFired = false
        var optionsError: (any Error)?
        delegate.webExtensionController(
            controller,
            openOptionsPageFor: context
        ) { error in
            optionsFired = true
            optionsError = error
        }
        precondition(optionsFired)
        precondition(isPortableUnknown(optionsError))
    }
}

func testExtensionDelegatePromptCompletionHandlers() {
    wkExtCompleteMain {
        let delegate = StubExtensionDelegate()
        let (controller, context) = extCompletionContext()
        var granted: Set<WKWebExtension.Permission> = []
        var grantedExpiry: Date? = .distantFuture
        var grantedExpiryObserved = false
        delegate.webExtensionController(
            controller,
            promptForPermissions: [.storage, .tabs],
            in: nil,
            for: context
        ) { permissions, expiry in
            granted = permissions
            grantedExpiry = expiry
            grantedExpiryObserved = true
        }
        precondition(grantedExpiryObserved)
        precondition(granted == [.storage, .tabs])
        precondition(grantedExpiry == nil)
        let pattern = try WKWebExtension.MatchPattern(string: "*://example.com/*")
        var grantedPatterns: Set<WKWebExtension.MatchPattern> = []
        var patternsFired = false
        delegate.webExtensionController(
            controller,
            promptForPermissionMatchPatterns: [pattern],
            in: nil,
            for: context
        ) { matchPatterns, expiry in
            grantedPatterns = matchPatterns
            patternsFired = true
            precondition(expiry == nil)
        }
        precondition(patternsFired)
        precondition(grantedPatterns == [pattern])
        let urls: Set<URL> = [URL(string: "https://example.com/")!]
        var grantedURLs: Set<URL> = []
        var urlsFired = false
        delegate.webExtensionController(
            controller,
            promptForPermissionToAccess: urls,
            in: nil,
            for: context
        ) { grantedSets, expiry in
            grantedURLs = grantedSets
            urlsFired = true
            precondition(expiry == nil)
        }
        precondition(urlsFired)
        precondition(grantedURLs == urls)
    }
}

func testExtensionDelegatePopupMessageCompletionHandlers() {
    wkExtCompleteMain {
        let delegate = StubExtensionDelegate()
        let (controller, context) = extCompletionContext()
        var popupFired = false
        var popupError: (any Error)?
        delegate.webExtensionController(
            controller,
            presentActionPopup: WKWebExtension.Action(),
            for: context
        ) { error in
            popupFired = true
            popupError = error
        }
        precondition(popupFired)
        precondition(isPortableUnknown(popupError))
        var messageFired = false
        var messageReply: Any?
        var messageError: (any Error)?
        delegate.webExtensionController(
            controller,
            sendMessage: "ping",
            toApplicationWithIdentifier: nil,
            for: context
        ) { reply, error in
            messageFired = true
            messageReply = reply
            messageError = error
        }
        precondition(messageFired)
        precondition(messageReply == nil)
        precondition(isPortableUnknown(messageError))
        var connectFired = false
        var connectError: (any Error)?
        delegate.webExtensionController(
            controller,
            connectUsing: WKWebExtension.MessagePort(),
            for: context
        ) { error in
            connectFired = true
            connectError = error
        }
        precondition(connectFired)
        precondition(isPortableUnknown(connectError))
    }
}

func testExtensionTabNavigationCompletionHandlers() {
    wkExtCompleteMain {
        let tab = StubExtensionTab()
        let (_, context) = extCompletionContext()
        var backError: (any Error)?
        var backFired = false
        tab.goBack(for: context) { error in
            backFired = true
            backError = error
        }
        precondition(backFired)
        precondition(isPortableUnknown(backError))
        var forwardError: (any Error)?
        var forwardFired = false
        tab.goForward(for: context) { error in
            forwardFired = true
            forwardError = error
        }
        precondition(forwardFired)
        precondition(isPortableUnknown(forwardError))
        var loadError: (any Error)?
        var loadFired = false
        tab.loadURL(URL(string: "https://example.com/")!, for: context) { error in
            loadFired = true
            loadError = error
        }
        precondition(loadFired)
        precondition(isPortableUnknown(loadError))
        var reloadError: (any Error)?
        var reloadFired = false
        tab.reload(fromOrigin: true, for: context) { error in
            reloadFired = true
            reloadError = error
        }
        precondition(reloadFired)
        precondition(isPortableUnknown(reloadError))
    }
}

func testExtensionTabStateCompletionHandlers() {
    wkExtCompleteMain {
        let tab = StubExtensionTab()
        let (_, context) = extCompletionContext()
        var activated: (any Error)? = nil
        var activatedFired = false
        tab.activate(for: context) { error in
            activatedFired = true
            activated = error
        }
        precondition(activatedFired)
        precondition(isPortableUnknown(activated))
        var closed: (any Error)? = nil
        var closedFired = false
        tab.close(for: context) { error in
            closedFired = true
            closed = error
        }
        precondition(closedFired)
        precondition(isPortableUnknown(closed))
        var muted: (any Error)? = nil
        var mutedFired = false
        tab.setMuted(true, for: context) { error in
            mutedFired = true
            muted = error
        }
        precondition(mutedFired)
        precondition(isPortableUnknown(muted))
        var parented: (any Error)? = nil
        var parentedFired = false
        tab.setParentTab(nil, for: context) { error in
            parentedFired = true
            parented = error
        }
        precondition(parentedFired)
        precondition(isPortableUnknown(parented))
        var pinned: (any Error)? = nil
        var pinnedFired = false
        tab.setPinned(true, for: context) { error in
            pinnedFired = true
            pinned = error
        }
        precondition(pinnedFired)
        precondition(isPortableUnknown(pinned))
        var readerMode: (any Error)? = nil
        var readerModeFired = false
        tab.setReaderModeActive(true, for: context) { error in
            readerModeFired = true
            readerMode = error
        }
        precondition(readerModeFired)
        precondition(isPortableUnknown(readerMode))
        var selected: (any Error)? = nil
        var selectedFired = false
        tab.setSelected(true, for: context) { error in
            selectedFired = true
            selected = error
        }
        precondition(selectedFired)
        precondition(isPortableUnknown(selected))
        var zoomed: (any Error)? = nil
        var zoomedFired = false
        tab.setZoomFactor(2.0, for: context) { error in
            zoomedFired = true
            zoomed = error
        }
        precondition(zoomedFired)
        precondition(isPortableUnknown(zoomed))
    }
}

func testExtensionTabValueAndWindowCompletionHandlers() {
    wkExtCompleteMain {
        let tab = StubExtensionTab()
        let window = StubExtensionWindow()
        let (_, context) = extCompletionContext()
        var localeFired = false
        var locale: Locale?
        var localeError: (any Error)?
        tab.detectWebpageLocale(for: context) { value, error in
            localeFired = true
            locale = value
            localeError = error
        }
        precondition(localeFired)
        precondition(locale == nil)
        precondition(isPortableUnknown(localeError))
        var duplicateFired = false
        var duplicateError: (any Error)?
        tab.duplicate(using: WKWebExtension.TabConfiguration(), for: context) { value, error in
            duplicateFired = true
            duplicateError = error
            precondition(value == nil)
        }
        precondition(duplicateFired)
        precondition(isPortableUnknown(duplicateError))
        var snapshotFired = false
        var snapshotError: (any Error)?
        tab.snapshot(using: WKSnapshotConfiguration(), for: context) { image, error in
            snapshotFired = true
            snapshotError = error
            precondition(image == nil)
        }
        precondition(snapshotFired)
        precondition(isPortableUnknown(snapshotError))
        var windowClosed: (any Error)? = nil
        var windowClosedFired = false
        window.close(for: context) { error in
            windowClosedFired = true
            windowClosed = error
        }
        precondition(windowClosedFired)
        precondition(isPortableUnknown(windowClosed))
        var focused: (any Error)? = nil
        var focusedFired = false
        window.focus(for: context) { error in
            focusedFired = true
            focused = error
        }
        precondition(focusedFired)
        precondition(isPortableUnknown(focused))
        var framed: (any Error)? = nil
        var framedFired = false
        window.setFrame(CGRect(x: 0, y: 0, width: 800, height: 600), for: context) { error in
            framedFired = true
            framed = error
        }
        precondition(framedFired)
        precondition(isPortableUnknown(framed))
        var windowState: (any Error)? = nil
        var windowStateFired = false
        window.setWindowState(.maximized, for: context) { error in
            windowStateFired = true
            windowState = error
        }
        precondition(windowStateFired)
        precondition(isPortableUnknown(windowState))
    }
}
