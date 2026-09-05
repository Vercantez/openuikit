import XCTest
import Foundation
@testable import OpenUIKit

#if !os(Linux)
@MainActor
#endif
final class TextInputTraitsTests: XCTestCase {
    private func offsets(_ field: UITextField) -> [Int] {
        guard let range = field.selectedTextRange else { return [] }
        return [field.offset(from: field.beginningOfDocument, to: range.start),
                field.offset(from: field.beginningOfDocument, to: range.end)]
    }

    func testTraitRawValuesDefaultsAndStorage() {
        XCTAssertEqual([
            UIKeyboardType.default.rawValue,
            UIKeyboardType.asciiCapable.rawValue,
            UIKeyboardType.numbersAndPunctuation.rawValue,
            UIKeyboardType.URL.rawValue,
            UIKeyboardType.numberPad.rawValue,
            UIKeyboardType.phonePad.rawValue,
            UIKeyboardType.namePhonePad.rawValue,
            UIKeyboardType.emailAddress.rawValue,
            UIKeyboardType.decimalPad.rawValue,
            UIKeyboardType.twitter.rawValue,
            UIKeyboardType.webSearch.rawValue,
            UIKeyboardType.asciiCapableNumberPad.rawValue,
        ], Array(0...11))
        XCTAssertEqual([
            UIKeyboardAppearance.default.rawValue,
            UIKeyboardAppearance.dark.rawValue,
            UIKeyboardAppearance.light.rawValue,
        ], Array(0...2))
        XCTAssertEqual([
            UITextAutocapitalizationType.none.rawValue,
            UITextAutocapitalizationType.words.rawValue,
            UITextAutocapitalizationType.sentences.rawValue,
            UITextAutocapitalizationType.allCharacters.rawValue,
        ], Array(0...3))
        XCTAssertEqual([
            UITextAutocorrectionType.default.rawValue,
            UITextAutocorrectionType.no.rawValue,
            UITextAutocorrectionType.yes.rawValue,
        ], Array(0...2))
        XCTAssertEqual([
            UIReturnKeyType.default.rawValue,
            UIReturnKeyType.go.rawValue,
            UIReturnKeyType.google.rawValue,
            UIReturnKeyType.join.rawValue,
            UIReturnKeyType.next.rawValue,
            UIReturnKeyType.route.rawValue,
            UIReturnKeyType.search.rawValue,
            UIReturnKeyType.send.rawValue,
            UIReturnKeyType.yahoo.rawValue,
            UIReturnKeyType.done.rawValue,
            UIReturnKeyType.emergencyCall.rawValue,
            UIReturnKeyType.continue.rawValue,
        ], Array(0...11))

        let field = UITextField()
        let view = UITextView()
        for editor in [field as Any, view as Any] {
            if let field = editor as? UITextField {
                XCTAssertEqual(field.keyboardType, .default)
                XCTAssertEqual(field.autocapitalizationType, .sentences)
                XCTAssertEqual(field.autocorrectionType, .default)
                XCTAssertEqual(field.keyboardAppearance, .default)
                XCTAssertEqual(field.returnKeyType, .default)
                XCTAssertFalse(field.enablesReturnKeyAutomatically)
            } else if let view = editor as? UITextView {
                XCTAssertEqual(view.keyboardType, .default)
                XCTAssertEqual(view.autocapitalizationType, .sentences)
                XCTAssertEqual(view.autocorrectionType, .default)
                XCTAssertEqual(view.keyboardAppearance, .default)
                XCTAssertEqual(view.returnKeyType, .default)
                XCTAssertFalse(view.enablesReturnKeyAutomatically)
            }
        }

        field.keyboardType = .webSearch
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardAppearance = .dark
        field.returnKeyType = .search
        field.enablesReturnKeyAutomatically = true
        XCTAssertEqual(field.keyboardType, .webSearch)
        XCTAssertEqual(field.autocapitalizationType, .none)
        XCTAssertEqual(field.autocorrectionType, .no)
        XCTAssertEqual(field.keyboardAppearance, .dark)
        XCTAssertEqual(field.returnKeyType, .search)
        XCTAssertTrue(field.enablesReturnKeyAutomatically)

        view.keyboardType = .URL
        view.keyboardAppearance = .light
        XCTAssertEqual(view.keyboardType, .URL)
        XCTAssertEqual(view.keyboardAppearance, .light)
    }

    func testAttributedAndPlainPlaceholderAreOneCoupledValue() {
        let field = UITextField()
        XCTAssertNil(field.placeholder)
        XCTAssertNil(field.attributedPlaceholder)

        field.placeholder = "Plain"
        XCTAssertEqual(field.attributedPlaceholder?.string, "Plain")
        let generated = field.attributedPlaceholder!.attributes(at: 0,
                                                                 effectiveRange: nil)
        XCTAssertEqual(generated[.font] as? UIFont, field.font)
        XCTAssertNotNil(generated[.foregroundColor] as? UIColor)

        let custom = NSAttributedString(
            string: "Styled",
            attributes: [OpenUIKit.NSAttributedString.Key.foregroundColor:
                            UIColor.systemRed])
        field.attributedPlaceholder = custom
        XCTAssertEqual(field.placeholder, "Styled")
        XCTAssertEqual(field.attributedPlaceholder?.string, "Styled")
        XCTAssertNotNil(field.attributedPlaceholder?.attribute(
            .foregroundColor, at: 0, effectiveRange: nil) as? UIColor)
        XCTAssertNil(field.attributedPlaceholder?.attribute(
            .font, at: 0, effectiveRange: nil))

        field.placeholder = "Replacement"
        XCTAssertEqual(field.attributedPlaceholder?.string, "Replacement")
        XCTAssertNotNil(field.attributedPlaceholder?.attribute(
            .font, at: 0, effectiveRange: nil))

        field.attributedPlaceholder = nil
        XCTAssertNil(field.placeholder)
        XCTAssertNil(field.attributedPlaceholder)
        field.placeholder = "Again"
        field.placeholder = nil
        XCTAssertNil(field.attributedPlaceholder)
    }

    func testViewModeRawValuesAndMeasuredAccessoryGeometry() {
        XCTAssertEqual([
            UITextField.ViewMode.never.rawValue,
            UITextField.ViewMode.whileEditing.rawValue,
            UITextField.ViewMode.unlessEditing.rawValue,
            UITextField.ViewMode.always.rawValue,
        ], Array(0...3))

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 34))
        field.borderStyle = .roundedRect
        field.text = "accessory"
        let left = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
        let right = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 22))
        field.leftView = left
        field.leftViewMode = .always
        field.rightView = right
        field.rightViewMode = .always
        window.addSubview(field)
        window.layoutIfNeeded()

        XCTAssertEqual(field.leftViewRect(forBounds: field.bounds),
                       CGRect(x: 0, y: 7, width: 10, height: 20))
        XCTAssertEqual(field.rightViewRect(forBounds: field.bounds),
                       CGRect(x: 188, y: 6, width: 12, height: 22))
        XCTAssertEqual(field.textRect(forBounds: field.bounds),
                       CGRect(x: 17, y: 2, width: 171, height: 30))
        XCTAssertEqual(field.editingRect(forBounds: field.bounds),
                       CGRect(x: 17, y: 2, width: 171, height: 30))
        XCTAssertEqual(left.frame, field.leftViewRect(forBounds: field.bounds))
        XCTAssertEqual(right.frame, field.rightViewRect(forBounds: field.bounds))

        left.isHidden = true
        field.leftViewMode = .whileEditing
        field.rightViewMode = .unlessEditing
        window.layoutIfNeeded()
        XCTAssertNil(left.superview)
        XCTAssertEqual(left.frame, CGRect(x: 0, y: 7, width: 10, height: 20),
                       "inactive UIKit accessories detach without losing geometry")
        XCTAssertTrue(right.superview === field)
        XCTAssertNotEqual(right.frame, .zero)
        XCTAssertTrue(left.isHidden, "layout must preserve app-controlled hidden state")

        XCTAssertTrue(field.becomeFirstResponder())
        window.layoutIfNeeded()
        XCTAssertTrue(left.superview === field)
        XCTAssertNotEqual(left.frame, .zero)
        XCTAssertNil(right.superview)
        XCTAssertEqual(right.frame, CGRect(x: 188, y: 6, width: 12, height: 22))
        XCTAssertTrue(left.isHidden)

        XCTAssertTrue(field.resignFirstResponder())
        window.layoutIfNeeded()
        XCTAssertNil(left.superview)
        XCTAssertTrue(right.superview === field)

        let odd = UIView(frame: CGRect(x: 0, y: 0, width: 13, height: 17))
        field.leftView = odd
        field.leftViewMode = .always
        window.layoutIfNeeded()
        let displayScale = field.traitCollection.displayScale
        let expectedY = FontEngine.ceilToPixel(
            (field.bounds.height - 17) / 2,
            scale: displayScale > 0 ? displayScale : 2)
        XCTAssertEqual(field.leftViewRect(forBounds: field.bounds).minY, expectedY)
    }

    private final class ClearDelegate: UITextFieldDelegate {
        var permitsClear = false
        var clearRequests = 0
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            clearRequests += 1
            return permitsClear
        }
    }

    private final class ChangeOrderingDelegate: UITextFieldDelegate {
        var events: [String] = []
        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            events.append("shouldChange")
            return true
        }
        func textFieldDidChangeSelection(_ textField: UITextField) {
            events.append("selection")
        }
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            events.append("shouldClear")
            return true
        }
    }

    func testTextDidChangeNotificationPostingAndOrdering() {
        XCTAssertEqual(UITextField.textDidChangeNotification.rawValue,
                       "UITextFieldTextDidChangeNotification")

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 100))
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 34))
        let delegate = ChangeOrderingDelegate()
        field.delegate = delegate
        window.addSubview(field)
        field.addTarget(for: .editingChanged) { _, _ in
            delegate.events.append("editingChanged")
        }
        let center = OpenUIKit.NotificationCenter.default
        let token = center.addObserver(forName: UITextField.textDidChangeNotification,
                                       object: field, queue: nil) { note in
            XCTAssertTrue((note.object as? UITextField) === field)
            XCTAssertNil(note.userInfo)
            delegate.events.append("notification")
        }
        defer { center.removeObserver(token) }

        field.text = "A"
        field.attributedText = NSAttributedString(string: "AB")
        XCTAssertTrue(delegate.events.isEmpty,
                      "programmatic content assignment does not post or emit")

        XCTAssertTrue(field.becomeFirstResponder())
        delegate.events.removeAll()
        field.insertText("C")
        XCTAssertEqual(delegate.events,
                       ["shouldChange", "selection", "editingChanged", "notification"])

        delegate.events.removeAll()
        field.deleteBackward()
        XCTAssertEqual(delegate.events,
                       ["shouldChange", "selection", "editingChanged", "notification"])

        field.text = "clear"
        delegate.events.removeAll()
        XCTAssertTrue(field._clear())
        XCTAssertEqual(delegate.events,
                       ["shouldClear", "editingChanged", "notification"])
    }

    func testClearButtonNormalFillPreservesTertiaryLabelAlpha() {
        let savedBackend = CanvasBackendSelection.current
        defer { CanvasBackendSelection.current = savedBackend }
        CanvasBackendSelection.current = .swift

        let button = UITextFieldClearButton(frame: CGRect(x: 0, y: 0,
                                                          width: 19, height: 19))
        let bitmap = Bitmap(width: 19, height: 19)
        button.drawContent(in: Canvas(bitmap: bitmap, scale: 1),
                           bounds: button.bounds)

        // This interior point is fully covered by the circle and lies above
        // the X strokes. It therefore exposes the circle color's exact alpha.
        let offset = (2 * bitmap.width + 9) * 4
        let renderedAlpha = Int(bitmap.pixels[offset + 3])
        let resolvedAlpha = UIColor.tertiaryLabel
            .resolvedCGColor(with: button.traitCollection).alpha
        XCTAssertEqual(renderedAlpha, Int((resolvedAlpha * 255).rounded()),
                       "normal rendering must not square tertiaryLabel alpha")
    }

    private func makeRightAndClearField(clearAssignedFirst: Bool,
                                        clearMode: UITextField.ViewMode)
        -> (UIWindow, UITextField, UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 100))
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 34))
        let right = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 22))
        field.borderStyle = .roundedRect
        field.text = "right wins"
        if clearAssignedFirst {
            field.clearButtonMode = clearMode
            field.rightView = right
            field.rightViewMode = .always
        } else {
            field.rightView = right
            field.rightViewMode = .always
            field.clearButtonMode = clearMode
        }
        window.addSubview(field)
        window.layoutIfNeeded()
        return (window, field, right)
    }

    private func assertRightViewSuppressesClear(_ field: UITextField,
                                                right: UIView,
                                                file: StaticString = #filePath,
                                                line: UInt = #line) {
        XCTAssertEqual(field.rightViewRect(forBounds: field.bounds),
                       CGRect(x: 188, y: 6, width: 12, height: 22),
                       file: file, line: line)
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds),
                       CGRect(x: 176, y: 8, width: 19, height: 19),
                       file: file, line: line)
        XCTAssertEqual(field.textRect(forBounds: field.bounds),
                       CGRect(x: 7, y: 2, width: 181, height: 30),
                       file: file, line: line)
        XCTAssertEqual(field.editingRect(forBounds: field.bounds),
                       CGRect(x: 7, y: 2, width: 181, height: 30),
                       file: file, line: line)
        XCTAssertTrue(right.superview === field, file: file, line: line)
        XCTAssertEqual(right.frame, CGRect(x: 188, y: 6, width: 12, height: 22),
                       file: file, line: line)
        XCTAssertFalse(field.subviews.contains { $0 is UITextFieldClearButton },
                       "a visible right view removes the clear control hierarchy",
                       file: file, line: line)
    }

    func testVisibleRightViewSuppressesAlwaysClearIndependentOfAssignmentOrder() {
        for clearAssignedFirst in [true, false] {
            let (window, field, right) = makeRightAndClearField(
                clearAssignedFirst: clearAssignedFirst, clearMode: .always)
            assertRightViewSuppressesClear(field, right: right)

            // Removing the precedence condition must reattach the retained
            // clear control and restore its ordinary measured geometry.
            field.rightViewMode = .never
            window.layoutIfNeeded()
            let clear = field.subviews.compactMap { $0 as? UITextFieldClearButton }.first
            XCTAssertNotNil(clear)
            XCTAssertEqual(clear?.frame,
                           CGRect(x: 175, y: 8, width: 59.0 / 3.0, height: 19))
        }
    }

    func testVisibleRightViewSuppressesWhileEditingClearIndependentOfAssignmentOrder() {
        for clearAssignedFirst in [true, false] {
            let (window, field, right) = makeRightAndClearField(
                clearAssignedFirst: clearAssignedFirst, clearMode: .whileEditing)
            XCTAssertTrue(field.becomeFirstResponder())
            window.layoutIfNeeded()
            assertRightViewSuppressesClear(field, right: right)
            XCTAssertTrue(field.resignFirstResponder())
        }
    }

    func testClearButtonRectFollowsModeActivityIndependentOfTextPresence() {
        let compact = CGRect(x: 176, y: 8, width: 19, height: 19)
        let active = CGRect(x: 175, y: 8, width: 59.0 / 3.0, height: 19)
        let field = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 34))
        field.borderStyle = .roundedRect
        field.text = "oracle"

        field.clearButtonMode = .never
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds), compact)
        field.clearButtonMode = .whileEditing
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds), compact,
                       "whileEditing is inactive before focus")
        field.clearButtonMode = .unlessEditing
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds), active)
        field.clearButtonMode = .always
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds), active)
        field.text = ""
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds), active,
                       "active-mode hook geometry is independent of text emptiness")

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 100))
        field.text = "oracle"
        field.clearButtonMode = .whileEditing
        window.addSubview(field)
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds), active)
        field.clearButtonMode = .unlessEditing
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds), compact,
                       "unlessEditing becomes inactive during focus")
        XCTAssertTrue(field.resignFirstResponder())
    }

    func testClearButtonModeGeometryVisibilityAndDelegateInteraction() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 240, height: 100))
        let field = UITextField(frame: CGRect(x: 10, y: 10, width: 200, height: 34))
        field.borderStyle = .roundedRect
        field.clearButtonMode = .always
        field.text = "clear me"
        let delegate = ClearDelegate()
        field.delegate = delegate
        window.addSubview(field)
        window.layoutIfNeeded()

        let expected = CGRect(x: 175, y: 8, width: 59.0 / 3.0, height: 19)
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds).minX,
                       expected.minX, accuracy: 1e-9)
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds).minY,
                       expected.minY, accuracy: 1e-9)
        XCTAssertEqual(field.clearButtonRect(forBounds: field.bounds).width,
                       expected.width, accuracy: 1e-9)
        let button = field.subviews.compactMap { $0 as? UITextFieldClearButton }.first
        XCTAssertNotNil(button)
        XCTAssertFalse(button!.isHidden)
        XCTAssertEqual(button!.frame, expected)
        XCTAssertEqual(field.textRect(forBounds: field.bounds).maxX,
                       165.0 + 1.0 / 3.0, accuracy: 1e-9)

        button!.sendActions(for: .touchUpInside)
        XCTAssertEqual(delegate.clearRequests, 1)
        XCTAssertEqual(field.text, "clear me")

        delegate.permitsClear = true
        button!.sendActions(for: .touchUpInside)
        window.layoutIfNeeded()
        XCTAssertEqual(delegate.clearRequests, 2)
        XCTAssertEqual(field.text, "", "UIKit clear leaves a non-nil empty string")
        XCTAssertTrue(button!.isHidden)
        XCTAssertEqual(field.textRect(forBounds: field.bounds),
                       CGRect(x: 7, y: 2, width: 186, height: 30))

        field.text = "again"
        field.clearButtonMode = .whileEditing
        window.layoutIfNeeded()
        XCTAssertTrue(button!.isHidden)
        XCTAssertTrue(field.becomeFirstResponder())
        window.layoutIfNeeded()
        XCTAssertFalse(button!.isHidden)

        field.clearButtonMode = .unlessEditing
        window.layoutIfNeeded()
        XCTAssertTrue(button!.isHidden)
        XCTAssertTrue(field.resignFirstResponder())
        window.layoutIfNeeded()
        XCTAssertFalse(button!.isHidden)

        field.clearButtonMode = .never
        window.layoutIfNeeded()
        XCTAssertTrue(button!.isHidden)
        field.clearButtonMode = .always
        window.layoutIfNeeded()
        XCTAssertFalse(button!.isHidden)
    }

    func testAssistantItemIdentityStorageAndExclusiveGroupOwnership() {
        let field = UITextField()
        let assistant = field.inputAssistantItem
        XCTAssertTrue(assistant === field.inputAssistantItem)
        XCTAssertTrue(assistant.allowsHidingShortcuts)
        XCTAssertTrue(assistant.leadingBarButtonGroups.isEmpty)
        XCTAssertTrue(assistant.trailingBarButtonGroups.isEmpty)

        let first = UIBarButtonItem(title: "First")
        let representative = UIBarButtonItem(title: "Representative")
        let original = UIBarButtonItemGroup(barButtonItems: [first],
                                            representativeItem: representative)
        XCTAssertTrue(first.buttonGroup === original)
        XCTAssertTrue(representative.buttonGroup === original)

        assistant.leadingBarButtonGroups = [original]
        assistant.trailingBarButtonGroups = []
        XCTAssertTrue(assistant.leadingBarButtonGroups.first === original)

        let replacement = UIBarButtonItemGroup(barButtonItems: [first],
                                               representativeItem: nil)
        XCTAssertTrue(first.buttonGroup === replacement)
        XCTAssertTrue(original.barButtonItems.isEmpty)
        replacement.representativeItem = first
        XCTAssertTrue(replacement.barButtonItems.isEmpty)
        XCTAssertTrue(replacement.representativeItem === first)
        XCTAssertTrue(first.buttonGroup === replacement)

        original.barButtonItems = [first]
        XCTAssertNil(replacement.representativeItem)
        XCTAssertTrue(first.buttonGroup === original)
    }

    func testSelectAllFocusesAttachedFieldButNotDetachedField() {
        let detached = UITextField()
        detached.text = "detached"
        detached.selectAll(nil)
        XCTAssertFalse(detached.isFirstResponder)
        XCTAssertEqual(offsets(detached), [0, 0])

        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 80))
        let attached = UITextField(frame: CGRect(x: 0, y: 0, width: 180, height: 34))
        attached.text = "A😀B"
        window.addSubview(attached)
        attached.selectAll(nil)
        XCTAssertTrue(attached.isFirstResponder)
        XCTAssertEqual(offsets(attached), [0, 4], "selection offsets are UTF-16")
    }

    private final class RefusingEndDelegate: UITextFieldDelegate {
        var shouldEnd = 0
        var legacyDidEnd = 0
        var reasonDidEnd = 0
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            shouldEnd += 1
            return false
        }
        func textFieldDidEndEditing(_ textField: UITextField) { legacyDidEnd += 1 }
        func textFieldDidEndEditing(_ textField: UITextField,
                                    reason: UITextField.DidEndEditingReason) {
            reasonDidEnd += 1
        }
    }

    private final class AllowingEndDelegate: UITextFieldDelegate {
        var shouldEnd = 0
        var legacyDidEnd = 0
        var reasonDidEnd = 0
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            shouldEnd += 1
            return true
        }
        func textFieldDidEndEditing(_ textField: UITextField) { legacyDidEnd += 1 }
        func textFieldDidEndEditing(_ textField: UITextField,
                                    reason: UITextField.DidEndEditingReason) {
            reasonDidEnd += 1
        }
    }

    private final class LegacyEndDelegate: UITextFieldDelegate {
        var shouldEnd = 0
        var legacyDidEnd = 0
        func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
            shouldEnd += 1
            return true
        }
        func textFieldDidEndEditing(_ textField: UITextField) { legacyDidEnd += 1 }
    }

    func testEndEditingMatchesMeasuredForceSubtreeAndCallbackContract() {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 160))
        let inside = UIView(frame: CGRect(x: 0, y: 0, width: 150, height: 100))
        let outside = UIView(frame: CGRect(x: 160, y: 0, width: 150, height: 100))
        let field = UITextField(frame: CGRect(x: 0, y: 0, width: 120, height: 34))
        window.addSubview(inside)
        window.addSubview(outside)
        inside.addSubview(field)

        XCTAssertTrue(window.endEditing(false))
        XCTAssertTrue(window.endEditing(true))
        XCTAssertTrue(UIView().endEditing(false))
        XCTAssertTrue(UIView().endEditing(true))

        let refusing = RefusingEndDelegate()
        field.delegate = refusing
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertFalse(outside.endEditing(false))
        XCTAssertFalse(outside.endEditing(true))
        XCTAssertEqual(refusing.shouldEnd, 0)

        XCTAssertFalse(inside.endEditing(false))
        XCTAssertTrue(field.isFirstResponder)
        XCTAssertTrue(field.isEditing)
        XCTAssertEqual(refusing.shouldEnd, 1)
        XCTAssertEqual(refusing.legacyDidEnd, 0)
        XCTAssertEqual(refusing.reasonDidEnd, 0)

        // Despite the SDK header's “optionally force” comment, iOS 26.1
        // reports true without bypassing a text delegate's refusal.
        XCTAssertTrue(inside.endEditing(true))
        XCTAssertTrue(field.isFirstResponder)
        XCTAssertTrue(field.isEditing)
        XCTAssertEqual(refusing.shouldEnd, 2)
        XCTAssertEqual(refusing.legacyDidEnd, 0)
        XCTAssertEqual(refusing.reasonDidEnd, 0)

        field.delegate = nil
        XCTAssertTrue(field.resignFirstResponder())
        let allowing = AllowingEndDelegate()
        field.delegate = allowing
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertTrue(inside.endEditing(false))
        XCTAssertFalse(field.isFirstResponder)
        XCTAssertFalse(field.isEditing)
        XCTAssertEqual(allowing.shouldEnd, 2,
                       "non-force preflights canResign, then resigns")
        XCTAssertEqual(allowing.legacyDidEnd, 0)
        XCTAssertEqual(allowing.reasonDidEnd, 1)

        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertTrue(inside.endEditing(true))
        XCTAssertEqual(allowing.shouldEnd, 3,
                       "force calls resign directly rather than preflighting")
        XCTAssertEqual(allowing.legacyDidEnd, 0)
        XCTAssertEqual(allowing.reasonDidEnd, 2)

        let legacy = LegacyEndDelegate()
        field.delegate = legacy
        XCTAssertTrue(field.becomeFirstResponder())
        XCTAssertTrue(inside.endEditing(true))
        XCTAssertEqual(legacy.shouldEnd, 1)
        XCTAssertEqual(legacy.legacyDidEnd, 1,
                       "default reason callback forwards to the legacy spelling")
    }

    func testFocusTextFieldOverrideSurfaceCompilesAndDispatches() {
        final class FocusHooks: UITextField {
            override var placeholder: String? {
                didSet {
                    attributedPlaceholder = NSAttributedString(
                        string: placeholder ?? "",
                        attributes: [OpenUIKit.NSAttributedString.Key.foregroundColor:
                                        UIColor.secondaryLabel])
                }
            }

            override func textRect(forBounds bounds: CGRect) -> CGRect {
                bounds.insetBy(dx: 3, dy: 2)
            }

            override func editingRect(forBounds bounds: CGRect) -> CGRect {
                textRect(forBounds: bounds)
            }

            override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
                super.rightViewRect(forBounds: bounds).offsetBy(dx: -4, dy: 0)
            }
        }

        let field = FocusHooks(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        field.placeholder = "Focus"
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        XCTAssertEqual(field.attributedPlaceholder?.string, "Focus")
        XCTAssertEqual(field.textRect(forBounds: field.bounds),
                       CGRect(x: 3, y: 2, width: 94, height: 26))
        XCTAssertEqual(field.editingRect(forBounds: field.bounds),
                       CGRect(x: 3, y: 2, width: 94, height: 26))
        XCTAssertEqual(field.rightViewRect(forBounds: field.bounds),
                       CGRect(x: 86, y: 10, width: 10, height: 10))
    }

    func testSDKOverrideableResponderAndViewHooksCompileAndDispatch() {
        final class AssistantResponder: UIResponder {
            let customItem = UITextInputAssistantItem()
            var readCount = 0
            override var inputAssistantItem: UITextInputAssistantItem {
                readCount += 1
                return customItem
            }
        }

        final class EditingView: UIView {
            var descendantCalls = 0
            var descendantResult = false
            var endEditingArguments: [Bool] = []

            override func isDescendant(of view: UIView) -> Bool {
                descendantCalls += 1
                return descendantResult
            }

            override func endEditing(_ force: Bool) -> Bool {
                endEditingArguments.append(force)
                return !force
            }
        }

        let assistantResponder = AssistantResponder()
        let responder: UIResponder = assistantResponder
        XCTAssertTrue(responder.inputAssistantItem === assistantResponder.customItem)
        XCTAssertEqual(assistantResponder.readCount, 1)

        let editingView = EditingView()
        let view: UIView = editingView
        editingView.descendantResult = true
        XCTAssertTrue(view.isDescendant(of: UIView()))
        XCTAssertEqual(editingView.descendantCalls, 1)
        XCTAssertTrue(view.endEditing(false))
        XCTAssertFalse(view.endEditing(true))
        XCTAssertEqual(editingView.endEditingArguments, [false, true])
    }
}
