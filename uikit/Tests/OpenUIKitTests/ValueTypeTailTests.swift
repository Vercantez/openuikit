// Value-type / process-local cluster (APP_LADDER.md §4 #2 #4 #5 #6 #13 #14).
// MEASURED ValuesProbe / ValuesProbe2 / ValuesProbe3, iPhone SE 3rd gen /
// iOS 26.1 (`OpenUIKit-2x-uikit-tail-values`).
import Dispatch
import Foundation
import XCTest
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class ValueTypeTailTests: XCTestCase {
    override func tearDown() {
        UIImpactFeedbackGenerator.onImpact = nil
        UINotificationFeedbackGenerator.onNotification = nil
        UISelectionFeedbackGenerator.onSelection = nil
        UIApplication.shared.shortcutItems = []
        super.tearDown()
    }

    // MARK: - Pasteboard notifications (#2)

    func testPasteboardPostsNilThenTypedChangedNotifications() {
        let pasteboard = UIPasteboard.withUniqueName()
        var posts: [(object: AnyObject?, info: [AnyHashable: Any]?)] = []
        let token = OpenUIKit.NotificationCenter.default.addObserver(
            forName: UIPasteboard.changedNotification, object: pasteboard, queue: nil
        ) { note in
            posts.append((note.object as AnyObject?, note.userInfo))
        }
        defer { OpenUIKit.NotificationCenter.default.removeObserver(token) }

        pasteboard.string = "hello"
        XCTAssertEqual(posts.count, 2)
        XCTAssertTrue(posts[0].object === pasteboard)
        XCTAssertNil(posts[0].info)
        let added = posts[1].info?[UIPasteboard.changedTypesAddedUserInfoKey] as? [String]
        XCTAssertEqual(added, ["public.utf8-plain-text"])
        XCTAssertNil(posts[1].info?[UIPasteboard.changedTypesRemovedUserInfoKey])

        posts.removeAll()
        pasteboard.string = "hello"
        XCTAssertEqual(posts.count, 1, "same-string set posts only the nil-userInfo note")
        XCTAssertNil(posts[0].info)

        posts.removeAll()
        pasteboard.string = nil
        XCTAssertEqual(posts.count, 2)
        let removed = posts[1].info?[UIPasteboard.changedTypesRemovedUserInfoKey] as? [String]
        XCTAssertEqual(removed, ["public.utf8-plain-text"])
    }

    func testPasteboardRemovePostsRemovedNotificationOnly() {
        let pasteboard = UIPasteboard.withUniqueName()
        let name = pasteboard.name
        pasteboard.string = "gone"
        var changed = 0
        var removed = 0
        var removedObject: AnyObject?
        let changedToken = OpenUIKit.NotificationCenter.default.addObserver(
            forName: UIPasteboard.changedNotification, object: nil, queue: nil
        ) { _ in changed += 1 }
        let removedToken = OpenUIKit.NotificationCenter.default.addObserver(
            forName: UIPasteboard.removedNotification, object: nil, queue: nil
        ) { note in
            removed += 1
            removedObject = note.object as AnyObject?
        }
        defer {
            OpenUIKit.NotificationCenter.default.removeObserver(changedToken)
            OpenUIKit.NotificationCenter.default.removeObserver(removedToken)
        }
        let beforeChanged = changed
        UIPasteboard.remove(withName: name)
        XCTAssertEqual(removed, 1)
        XCTAssertTrue(removedObject === pasteboard)
        XCTAssertEqual(changed, beforeChanged)
    }

    func testPasteboardChangedNotificationOnBackgroundThread() {
        let pasteboard = UIPasteboard.withUniqueName()
        let sawBackground = expectation(description: "changed on background")
        let token = OpenUIKit.NotificationCenter.default.addObserver(
            forName: UIPasteboard.changedNotification, object: pasteboard, queue: nil
        ) { _ in
            if !Thread.isMainThread { sawBackground.fulfill() }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            pasteboard.string = "bg"
        }
        wait(for: [sawBackground], timeout: 2)
        OpenUIKit.NotificationCenter.default.removeObserver(token)
    }

    func testPasteboardItemProvidersPopulateStringSynchronously() {
        let pasteboard = UIPasteboard.withUniqueName()
#if os(Linux)
        let provider = NSItemProvider(object: "provider-text")
#else
        let provider = NSItemProvider(object: "provider-text" as NSString)
#endif
        pasteboard.itemProviders = [provider]
        XCTAssertEqual(pasteboard.string, "provider-text")
        XCTAssertEqual(pasteboard.types, ["public.utf8-plain-text"])
    }

    // MARK: - Haptics (#4)

    func testNotificationAndSelectionGeneratorsRecordCalls() {
        var notes: [UINotificationFeedbackGenerator.Notification] = []
        UINotificationFeedbackGenerator.onNotification = { notes.append($0) }
        let notifier = UINotificationFeedbackGenerator()
        notifier.prepare()
        XCTAssertTrue(notifier.isPrepared)
        notifier.notificationOccurred(.success)
        XCTAssertFalse(notifier.isPrepared)
        XCTAssertEqual(notes, [.init(type: .success)])
        XCTAssertEqual(UINotificationFeedbackGenerator.FeedbackType.warning.rawValue, 1)
        XCTAssertEqual(UINotificationFeedbackGenerator.FeedbackType.error.rawValue, 2)

        var selections: [UISelectionFeedbackGenerator.Selection] = []
        UISelectionFeedbackGenerator.onSelection = { selections.append($0) }
        let selector = UISelectionFeedbackGenerator()
        selector.selectionChanged()
        selector.selectionChanged(at: CGPoint(x: 4, y: 8))
        XCTAssertEqual(selections, [.init(), .init(location: CGPoint(x: 4, y: 8))])
    }

    func testImpactGeneratorAttachesAsInteractionAndRecordsLocation() {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        var events: [UIImpactFeedbackGenerator.Impact] = []
        UIImpactFeedbackGenerator.onImpact = { events.append($0) }
        let generator = UIImpactFeedbackGenerator(style: .heavy, view: view)
        XCTAssertTrue(view.interactions.contains { $0 === generator })
        XCTAssertTrue(generator.view === view)
        XCTAssertEqual(UIImpactFeedbackGenerator.FeedbackStyle.medium.rawValue, 1)
        generator.impactOccurred(intensity: 0.5, at: CGPoint(x: 1, y: 2))
        XCTAssertEqual(events.last?.style, .heavy)
        XCTAssertEqual(events.last?.intensity, 0.5)
        XCTAssertEqual(events.last?.location, CGPoint(x: 1, y: 2))
    }

    // MARK: - Shortcuts (#5)

    func testShortcutItemCopyIsImmutableAndShortcutItemsDefaultEmpty() {
        let icon = UIApplicationShortcutIcon(type: .compose)
        let item = UIMutableApplicationShortcutItem(
            type: "org.example.erase", localizedTitle: "Erase",
            localizedSubtitle: "now", icon: icon)
        item.targetContentIdentifier = "note-1"
        XCTAssertEqual(item.type, "org.example.erase")
        XCTAssertEqual(item.targetContentIdentifier as? String, "note-1")

        let copied = item.copy() as! UIApplicationShortcutItem
        XCTAssertFalse(copied is UIMutableApplicationShortcutItem)
        XCTAssertEqual(copied.type, "org.example.erase")
        XCTAssertEqual(copied.targetContentIdentifier as? String, "note-1")

        let mutable = copied.mutableCopy() as! UIMutableApplicationShortcutItem
        mutable.type = "org.example.wipe"
        XCTAssertEqual(copied.type, "org.example.erase")
        XCTAssertEqual(mutable.type, "org.example.wipe")

        XCTAssertEqual(UIApplication.shared.shortcutItems?.count, 0)
        UIApplication.shared.shortcutItems = nil
        XCTAssertEqual(UIApplication.shared.shortcutItems?.count, 0)
        UIApplication.shared.shortcutItems = [copied]
        XCTAssertEqual(UIApplication.shared.shortcutItems?.count, 1)
    }

    func testShortcutDeliveryPrefersWindowSceneDelegate() {
        final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
            var seen: String?
            func windowScene(_ windowScene: UIWindowScene,
                             performActionFor shortcutItem: UIApplicationShortcutItem,
                             completionHandler: @escaping (Bool) -> Void) {
                seen = shortcutItem.type
                completionHandler(true)
            }
        }
        final class AppDelegate: UIResponder, UIApplicationDelegate {
            var window: UIWindow?
            var seen = false
            func application(_ application: UIApplication,
                             performActionFor shortcutItem: UIApplicationShortcutItem,
                             completionHandler: @escaping (Bool) -> Void) {
                seen = true
                completionHandler(false)
            }
        }
        let app = UIApplication.shared
        let previous = app.delegate
        let appDelegate = AppDelegate()
        app.delegate = appDelegate
        let sceneDelegate = SceneDelegate()
        let scene = app._hostConnectWindowScene(delegate: sceneDelegate)
        let item = UIApplicationShortcutItem(type: "org.example.go",
                                             localizedTitle: "Go")
        let done = expectation(description: "shortcut completion")
        app._hostPerformShortcut(item) { ok in
            XCTAssertTrue(ok)
            done.fulfill()
        }
        wait(for: [done], timeout: 1)
        XCTAssertEqual(sceneDelegate.seen, "org.example.go")
        XCTAssertFalse(appDelegate.seen)
        app._disconnect(scene: scene)
        app.delegate = previous
    }

    // MARK: - NSItemProvider (#6)

    func testItemProviderStringLoadCompletesOffMain() {
        let done = expectation(description: "loadObject")
#if os(Linux)
        let provider = NSItemProvider(object: "hello")
        XCTAssertEqual(provider.registeredTypeIdentifiers, ["public.utf8-plain-text"])
        XCTAssertTrue(provider.canLoadObject(ofClass: String.self))
        _ = provider.loadObject(ofClass: String.self) { object, error in
            XCTAssertEqual(object, "hello")
            XCTAssertNil(error)
            XCTAssertFalse(Thread.isMainThread)
            done.fulfill()
        }
#else
        let provider = NSItemProvider(object: "hello" as NSString)
        XCTAssertTrue(provider.registeredTypeIdentifiers.contains("public.utf8-plain-text"))
        _ = provider.loadObject(ofClass: NSString.self) { object, error in
            XCTAssertEqual(object as? String, "hello")
            XCTAssertNil(error)
            XCTAssertFalse(Thread.isMainThread)
            done.fulfill()
        }
#endif
        wait(for: [done], timeout: 2)
    }

    func testItemProviderImageAndColorHelpers() {
        let image = UIImage(bitmap: Bitmap(width: 2, height: 2), scale: 1)
        let provider = NSItemProvider(object: image)
        XCTAssertTrue(provider.canLoadObject(ofClass: UIImage.self))
        let loaded = expectation(description: "image")
        _ = provider.loadObject(ofClass: UIImage.self) { result, error in
            XCTAssertNil(error)
            XCTAssertEqual(result?.bitmap.width, 2)
            loaded.fulfill()
        }
        wait(for: [loaded], timeout: 2)

        let colorProvider = NSItemProvider(object: UIColor.red)
        XCTAssertTrue(colorProvider.canLoadObject(ofClass: UIColor.self))
        let colorDone = expectation(description: "color")
        _ = colorProvider.loadObject(ofClass: UIColor.self) { color, error in
            XCTAssertNil(error)
            XCTAssertNotNil(color)
            colorDone.fulfill()
        }
        wait(for: [colorDone], timeout: 2)
    }

    func testActivityItemProviderReturnsPlaceholder() {
        let provider = UIActivityItemProvider(placeholderItem: "share")
        XCTAssertEqual(provider.placeholderItem as? String, "share")
        XCTAssertEqual(provider.item as? String, "share")
        let sheet = UIActivityViewController(activityItems: [provider],
                                             applicationActivities: nil)
        XCTAssertEqual(
            provider.activityViewControllerPlaceholderItem(sheet) as? String,
            "share"
        )
    }

    // MARK: - Accessibility custom actions (#13)

    func testCustomActionNameAndAttributedNameStayInLockstep() {
        let action = UIAccessibilityCustomAction(name: "Delete") { _ in true }
        XCTAssertEqual(action.name, "Delete")
        XCTAssertEqual(action.attributedName.string, "Delete")
        XCTAssertNil(action.category)
        XCTAssertEqual(UIAccessibilityCustomAction.editCategory,
                       "UIAccessibilityCustomActionCategoryEdit")
        action.attributedName = NSAttributedString(string: "Erase")
        XCTAssertEqual(action.name, "Erase")
        action.name = "Wipe"
        XCTAssertEqual(action.attributedName.string, "Wipe")
        XCTAssertTrue(action.perform())

        let view = UIView()
        view.accessibilityCustomActions = [action]
        XCTAssertEqual(view.accessibilityCustomActions?.count, 1)

        let rotor = UIAccessibilityCustomRotor(name: "Headings") { _ in nil }
        XCTAssertEqual(rotor.systemRotorType, .none)
        XCTAssertEqual(UIAccessibilityCustomSystemRotorType.none.rawValue, 0)
        view.accessibilityCustomRotors = [rotor]
        XCTAssertEqual(view.accessibilityCustomRotors?.count, 1)
    }

    // MARK: - Scene lifecycle (#14)

    func testSceneConfigurationCopyDoesNotShareMutation() {
        let configuration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: .windowApplication
        )
        XCTAssertEqual(configuration.name, "Default Configuration")
        configuration.delegateClass = AppDelegateProbe.self
        let copied = configuration.copy() as! UISceneConfiguration
        XCTAssertEqual(copied.name, "Default Configuration")
        copied.delegateClass = nil
        XCTAssertTrue(configuration.delegateClass == AppDelegateProbe.self)
    }

    func testActivationConditionsDefaultPredicates() {
        let conditions = UISceneActivationConditions()
        XCTAssertEqual(
            conditions.canActivateForTargetContentIdentifierPredicate.predicateFormat,
            "TRUEPREDICATE"
        )
        XCTAssertEqual(
            conditions.prefersToActivateForTargetContentIdentifierPredicate.predicateFormat,
            "FALSEPREDICATE"
        )
        let scene = UIScene()
        XCTAssertEqual(
            scene.activationConditions.canActivateForTargetContentIdentifierPredicate.predicateFormat,
            "TRUEPREDICATE"
        )
    }

    func testOpenURLContextRoundTrips() {
        let url = URL(string: "https://example.com/item")!
        let options = UISceneOpenURLOptions(sourceApplication: "org.example.sender",
                                            openInPlace: true)
        let context = UIOpenURLContext(url: url, options: options)
        XCTAssertEqual(context.url, url)
        XCTAssertEqual(context.options.sourceApplication, "org.example.sender")
        XCTAssertTrue(context.options.openInPlace)
        XCTAssertNil(context.options.eventAttribution)
    }
}

#if !os(Linux)
@MainActor
#endif
private final class AppDelegateProbe: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
}
