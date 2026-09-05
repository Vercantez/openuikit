@_exported import Foundation

#if canImport(Contacts)
import Contacts
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Linux starting point for Apple's public `ContactsUI` module.
///
/// Isolated host compilation has Foundation only. Contacts / UIKit / SwiftUI
/// APIs use the lookalikes in `ContactsUILookalikes.swift` until those modules
/// are on the link line. Linux has no address book, contact-picker chrome, or
/// limited-access grant sheet: every path that would reveal or persist contact
/// records stays fail-closed.

/// Linux host-test control. Hidden from ordinary `import ContactsUI` clients
/// and not part of Apple's public ContactsUI surface.
@_spi(OpenUIKitHost)
@MainActor
public enum ContactsUIHostControl {
    /// Delivers `contactPickerDidCancel` through the existential delegate.
    /// Never fabricates a selected `CNContact`.
    public static func reportPickerCancel(_ picker: CNContactPickerViewController) {
        picker.delegate?.contactPickerDidCancel(picker)
    }

    /// Scripts a single-contact selection. Darwin would present picker chrome;
    /// Linux only delivers the delegate callback after evaluating the enabling
    /// and selection predicates. A failing predicate is fail-closed: no
    /// `didSelect` callback.
    @discardableResult
    public static func reportPickerSelection(
        _ picker: CNContactPickerViewController,
        contact: CNContact
    ) -> Bool {
        picker.hostSelect(contact: contact)
    }

    /// Scripts a multi-contact selection.
    @discardableResult
    public static func reportPickerSelection(
        _ picker: CNContactPickerViewController,
        contacts: [CNContact]
    ) -> Bool {
        picker.hostSelect(contacts: contacts)
    }

    /// Scripts a single property selection.
    @discardableResult
    public static func reportPickerSelection(
        _ picker: CNContactPickerViewController,
        property: CNContactProperty
    ) -> Bool {
        picker.hostSelect(property: property)
    }

    /// Scripts a multi-property selection.
    @discardableResult
    public static func reportPickerSelection(
        _ picker: CNContactPickerViewController,
        properties: [CNContactProperty]
    ) -> Bool {
        picker.hostSelect(properties: properties)
    }

    /// Records a fail-closed editor completion. The Darwin `didCompleteWith`
    /// callback is invoked with `nil` (no saved contact).
    public static func reportViewControllerCompletion(
        _ viewController: CNContactViewController
    ) {
        viewController.linuxCompletedWithoutSaving = true
        viewController.delegate?.contactViewController(viewController, didCompleteWith: nil)
    }

    /// Asks the editor whether a property should perform its default action.
    public static func shouldPerformDefaultAction(
        _ viewController: CNContactViewController,
        for property: CNContactProperty
    ) -> Bool {
        viewController.delegate?.contactViewController(
            viewController,
            shouldPerformDefaultActionFor: property
        ) ?? false
    }

    /// Invokes the access-button approval callback with an empty identifier
    /// list. Linux has no limited-access authorization.
    @discardableResult
    public static func invokeAccessApproval(_ button: ContactAccessButton) -> [String] {
        button.invokeFailClosedApproval()
    }

    public static func highlightedPropertyKey(
        _ viewController: CNContactViewController
    ) -> String? {
        viewController.linuxHighlightedPropertyKey
    }

    public static func highlightedPropertyIdentifier(
        _ viewController: CNContactViewController
    ) -> String? {
        viewController.linuxHighlightedPropertyIdentifier
    }

    public static func linuxModifierTags(_ button: ContactAccessButton) -> [String] {
        button.linuxModifiers
    }

    public static func linuxContactSections(
        _ viewController: CNContactViewController
    ) -> [ContactsUIContactSection] {
        viewController.linuxRebuildSections()
        return viewController.linuxSections
    }

    /// Builds an `NSPredicate` for the portable format subset Darwin apps
    /// write as `NSPredicate(format:)`. swift-corelibs-foundation does not
    /// parse predicate strings; this returns an `NSPredicate(block:)`.
    public static func predicate(format: String, argument: String? = nil) -> NSPredicate {
        ContactsUIPredicateEvaluation.makePredicate(format: format, argument: argument)
    }

    public static func evaluate(_ predicate: NSPredicate?, contact: CNContact) -> Bool {
        ContactsUIPredicateEvaluation.evaluate(predicate, contact: contact)
    }

    public static func evaluate(_ predicate: NSPredicate?, property: CNContactProperty) -> Bool {
        ContactsUIPredicateEvaluation.evaluate(predicate, property: property)
    }

    public static func shortcutContactIdentifier(_ icon: UIApplicationShortcutIcon) -> String? {
        #if canImport(UIKit)
        _ = icon
        return nil
        #else
        return icon.linuxContactIdentifier
        #endif
    }
}

/// Portable `NSPredicate` format subset used by picker enabling/selection
/// predicates. Darwin evaluates these with KVC against `CNContact` /
/// `CNContactProperty`. Linux Foundation cannot parse format strings, so this
/// interpreter is the documented host path.
public enum ContactsUIPredicateEvaluation {
    public static func makePredicate(format: String, argument: String? = nil) -> NSPredicate {
        NSPredicate { object, _ in
            evaluate(format: format, argument: argument, object: object)
        }
    }

    public static func evaluate(_ predicate: NSPredicate?, contact: CNContact) -> Bool {
        guard let predicate else { return true }
        return predicate.evaluate(with: contact.linuxPredicateSnapshot())
    }

    public static func evaluate(_ predicate: NSPredicate?, property: CNContactProperty) -> Bool {
        guard let predicate else { return true }
        return predicate.evaluate(with: property.linuxPredicateSnapshot())
    }

    static func evaluate(format: String, argument: String?, object: Any?) -> Bool {
        guard let snapshot = object as? [String: Any] else { return false }
        let trimmed = format.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.compare("TRUEPREDICATE", options: .caseInsensitive) == .orderedSame {
            return true
        }
        if trimmed.compare("FALSEPREDICATE", options: .caseInsensitive) == .orderedSame {
            return false
        }

        if let countMatch = parseCollectionCount(trimmed) {
            let values = array(snapshot[countMatch.key])
            switch countMatch.op {
            case ">": return values.count > countMatch.value
            case ">=": return values.count >= countMatch.value
            case "<": return values.count < countMatch.value
            case "<=": return values.count <= countMatch.value
            case "==": return values.count == countMatch.value
            case "!=": return values.count != countMatch.value
            default: return false
            }
        }

        if let comparison = parseStringComparison(trimmed, argument: argument) {
            let actual = string(snapshot[comparison.key]) ?? ""
            let expected = comparison.value
            let foldedActual: String
            let foldedExpected: String
            if comparison.caseInsensitive {
                foldedActual = actual.lowercased()
                foldedExpected = expected.lowercased()
            } else {
                foldedActual = actual
                foldedExpected = expected
            }
            switch comparison.op {
            case "EQUAL": return foldedActual == foldedExpected
            case "BEGINSWITH": return foldedActual.hasPrefix(foldedExpected)
            case "CONTAINS": return foldedActual.contains(foldedExpected)
            case "ENDSWITH": return foldedActual.hasSuffix(foldedExpected)
            default: return false
            }
        }
        return false
    }

    private struct CountClause {
        var key: String
        var op: String
        var value: Int
    }

    private struct StringClause {
        var key: String
        var op: String
        var value: String
        var caseInsensitive: Bool
    }

    private static func parseCollectionCount(_ format: String) -> CountClause? {
        let pattern = #"^([A-Za-z][A-Za-z0-9]*)\.@count\s*(==|!=|>=|<=|>|<)\s*([0-9]+)$"#
        guard let match = firstMatch(pattern, in: format) else { return nil }
        return CountClause(key: match[0], op: match[1], value: Int(match[2]) ?? 0)
    }

    private static func parseStringComparison(_ format: String, argument: String?) -> StringClause? {
        let ops = "BEGINSWITH(?:\\[cd\\])?|CONTAINS(?:\\[cd\\])?|ENDSWITH(?:\\[cd\\])?|=="
        let pattern = "^([A-Za-z][A-Za-z0-9]*)\\s*(\(ops))\\s*(.+)$"
        guard let match = firstMatch(pattern, in: format) else { return nil }
        var opToken = match[1]
        var caseInsensitive = false
        if opToken.hasSuffix("[cd]") {
            caseInsensitive = true
            opToken = String(opToken.dropLast(4))
        }
        var value = stripQuotes(match[2])
        if value == "%@" {
            value = argument ?? ""
        }
        let op = opToken == "==" ? "EQUAL" : opToken
        return StringClause(
            key: match[0],
            op: op,
            value: value,
            caseInsensitive: caseInsensitive
        )
    }

    private static func firstMatch(_ pattern: String, in text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges > 1 else {
            return nil
        }
        var parts: [String] = []
        for index in 1..<match.numberOfRanges {
            guard let slice = Range(match.range(at: index), in: text) else { return nil }
            parts.append(String(text[slice]))
        }
        return parts
    }

    private static func stripQuotes(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count >= 2, trimmed.hasPrefix("'"), trimmed.hasSuffix("'") {
            return String(trimmed.dropFirst().dropLast())
        }
        if trimmed.count >= 2, trimmed.hasPrefix("\""), trimmed.hasSuffix("\"") {
            return String(trimmed.dropFirst().dropLast())
        }
        return trimmed
    }

    private static func array(_ value: Any?) -> [Any] {
        value as? [Any] ?? []
    }

    private static func string(_ value: Any?) -> String? {
        if let text = value as? String { return text }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }
}

#if canImport(Contacts)
extension CNContact {
    /// Dictionary snapshot used by portable picker predicates when the real
    /// Contacts module is linked. Not Apple KVC.
    public func linuxPredicateSnapshot() -> [String: Any] {
        [
            CNContactGivenNameKey: givenName,
            CNContactFamilyNameKey: familyName,
            CNContactOrganizationNameKey: organizationName,
            CNContactIdentifierKey: identifier,
            CNContactPhoneNumbersKey: phoneNumbers.map(\.value.stringValue),
            CNContactEmailAddressesKey: emailAddresses.map { $0.value as String },
            CNContactPostalAddressesKey: postalAddresses.map {
                [$0.value.street, $0.value.city, $0.value.state, $0.value.postalCode]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            },
        ]
    }
}

extension CNContactProperty {
    public func linuxPredicateSnapshot() -> [String: Any] {
        var snapshot: [String: Any] = [
            "key": key,
            "identifier": identifier ?? "",
            "label": label ?? "",
        ]
        if let value {
            snapshot["value"] = value
        }
        return snapshot
    }
}
#endif
