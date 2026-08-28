import XCTest
@testable import OpenUIKit

@MainActor
final class UIEnvironmentCompatTests: XCTestCase {
    private final class WindowDelegate: UIResponder, UIApplicationDelegate {
        var window: UIWindow?
    }

    private class WindowStorageBase: UIResponder {
        var window: UIWindow?
    }

    private final class InheritedWindowDelegate: WindowStorageBase,
                                                     UIApplicationDelegate {}

    private final class WindowlessDelegate: UIResponder, UIApplicationDelegate {}

    private var savedBounds: CGRect = .zero
    private var savedScale: CGFloat = 1
    private var savedLanguage: String?

    override func setUp() {
        super.setUp()
        savedBounds = UIScreen.main.bounds
        savedScale = UIScreen.main.scale
        savedLanguage = UITextInputMode.activeInputModes.first?.primaryLanguage
    }

    override func tearDown() {
        UIScreen.main._hostConfigure(bounds: savedBounds, scale: savedScale)
        UITextInputMode._hostConfigure(primaryLanguage: savedLanguage)
        UIWindowScene()._hostConfigure(interfaceOrientation: nil)
        super.tearDown()
    }

    func testOrientationRawValuesAndClassificationMatchUIKit() {
        XCTAssertEqual(UIInterfaceOrientation.unknown.rawValue, 0)
        XCTAssertEqual(UIInterfaceOrientation.portrait.rawValue, 1)
        XCTAssertEqual(UIInterfaceOrientation.portraitUpsideDown.rawValue, 2)
        XCTAssertEqual(UIInterfaceOrientation.landscapeLeft.rawValue, 3)
        XCTAssertEqual(UIInterfaceOrientation.landscapeRight.rawValue, 4)
        XCTAssertTrue(UIInterfaceOrientation.portrait.isPortrait)
        XCTAssertTrue(UIInterfaceOrientation.landscapeRight.isLandscape)
        XCTAssertFalse(UIInterfaceOrientation.unknown.isLandscape)
    }

    func testWindowSceneOrientationFollowsHostSurface() {
        let scene = UIWindowScene()
        UIScreen.main._hostConfigure(
            bounds: CGRect(x: 0, y: 0, width: 390, height: 844), scale: 3)
        XCTAssertEqual(scene.interfaceOrientation, .portrait)

        UIScreen.main._hostConfigure(
            bounds: CGRect(x: 0, y: 0, width: 844, height: 390), scale: 3)
        XCTAssertEqual(scene.interfaceOrientation, .unknown)

        scene._hostConfigure(interfaceOrientation: .landscapeLeft)
        XCTAssertEqual(scene.interfaceOrientation, .landscapeLeft)
        scene._hostConfigure(interfaceOrientation: .landscapeRight)
        XCTAssertEqual(scene.interfaceOrientation, .landscapeRight)
        scene._hostConfigure(interfaceOrientation: nil)

        UIScreen.main._hostConfigure(
            bounds: CGRect(x: 0, y: 0, width: 500, height: 500), scale: 2)
        XCTAssertEqual(scene.interfaceOrientation, .unknown)
    }

    func testOnlySceneAssociatedWindowHasAnOrientationPath() {
        let legacyWindow = UIWindow(frame: CGRect(x: 0, y: 0,
                                                  width: 390, height: 844))
        XCTAssertNil(legacyWindow.windowScene)

        let scene = UIWindowScene()
        scene._hostConfigure(interfaceOrientation: .portraitUpsideDown)
        let sceneWindow = UIWindow(windowScene: scene)
        XCTAssertTrue(sceneWindow.windowScene === scene)
        XCTAssertEqual(sceneWindow.windowScene?.interfaceOrientation,
                       .portraitUpsideDown)
    }

    func testWindowTextInputModeIsHostConfigured() {
        let window = UIWindow()
        XCTAssertNotNil(window.textInputMode)

        UITextInputMode._hostConfigure(primaryLanguage: "fr-CA")
        XCTAssertEqual(window.textInputMode?.primaryLanguage, "fr-CA")
        XCTAssertEqual(UITextInputMode.activeInputModes.count, 1)
    }

    func testApplicationDelegateWindowUsesExistentialDispatch() {
        let concrete = WindowDelegate()
        let existential: any UIApplicationDelegate = concrete

        // The outer optional represents whether the ObjC-optional property
        // exists. A present stored property whose value is nil must therefore
        // remain distinguishable from a delegate with no window member.
        let storedNil = existential.window
        XCTAssertNotNil(storedNil as Any?)
        XCTAssertNil(storedNil!)

        concrete.window = UIWindow()
        XCTAssertNotNil(existential.window as Any?)
        XCTAssertTrue(existential.window! === concrete.window)
        XCTAssertNotNil(existential.window??.textInputMode)

        // ObjC UIKit's property is optional. The Swift-only default keeps a
        // delegate that does not declare window source-compatible.
        let windowless: any UIApplicationDelegate = WindowlessDelegate()
        XCTAssertNil(windowless.window as Any?)
        windowless.window = .some(UIWindow()) // default setter is intentionally inert
        XCTAssertNil(windowless.window as Any?)
    }

    func testApplicationDelegateWindowFindsInheritedStoredProperty() {
        let concrete = InheritedWindowDelegate()
        concrete.window = UIWindow()
        let existential: any UIApplicationDelegate = concrete

        XCTAssertNotNil(existential.window as Any?)
        XCTAssertTrue(existential.window! === concrete.window)
        XCTAssertNotNil(existential.window??.textInputMode)
    }
}
