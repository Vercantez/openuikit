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

/// TBD exports `_CNContactPickerViewControllerPickerDidShowNotification` and
/// `_CNContactPickerViewControllerPickerDidHideNotification`. Raw values match
/// those ObjC constant names. Linux posts them only from host SPI, never from
/// an address-book presentation.
public extension NSNotification.Name {
    static let CNContactPickerViewControllerPickerDidShow = NSNotification.Name(
        "CNContactPickerViewControllerPickerDidShowNotification"
    )
    static let CNContactPickerViewControllerPickerDidHide = NSNotification.Name(
        "CNContactPickerViewControllerPickerDidHideNotification"
    )
}

public let CNContactPickerViewControllerPickerDidShowNotification =
    NSNotification.Name.CNContactPickerViewControllerPickerDidShow
public let CNContactPickerViewControllerPickerDidHideNotification =
    NSNotification.Name.CNContactPickerViewControllerPickerDidHide

/// Fail-closed model of Darwin's limited-access contact picker sheet.
/// Isolated Linux never presents chrome and never grants identifiers.
@_spi(OpenUIKitHost)
public struct ContactAccessPickerModel: Equatable, Hashable, Sendable {
    public var queryString: String
    public var ignoredEmails: Set<String>
    public var ignoredPhoneNumbers: Set<String>

    public init(
        queryString: String = "",
        ignoredEmails: Set<String> = [],
        ignoredPhoneNumbers: Set<String> = []
    ) {
        self.queryString = queryString
        self.ignoredEmails = ignoredEmails
        self.ignoredPhoneNumbers = ignoredPhoneNumbers
    }

    /// Darwin delivers identifiers the user approved. Linux always returns `[]`.
    public func failClosedApprovedIdentifiers() -> [String] {
        []
    }
}

/// Linux host-test control. Hidden from ordinary `import ContactsUI` clients
/// and not part of Apple's public ContactsUI surface.
@_spi(OpenUIKitHost)
@MainActor
public enum ContactsUIHostControl {
    /// Posts `CNContactPickerViewControllerPickerDidShowNotification`. Darwin
    /// would post this when picker chrome appears; Linux has no chrome.
    public static func reportPickerDidShow(_ picker: CNContactPickerViewController) {
        picker.hostAppear()
    }

    /// Delivers `contactPickerDidCancel` through the existential delegate.
    /// Never fabricates a selected `CNContact`. Posts hide if the picker was shown.
    public static func reportPickerCancel(_ picker: CNContactPickerViewController) {
        picker.hostCancel()
    }

    public static func pickerIsVisible(_ picker: CNContactPickerViewController) -> Bool {
        picker.linuxPickerVisible
    }

    public static func accessPickerModel(_ button: ContactAccessButton) -> ContactAccessPickerModel {
        button.linuxAccessPickerModel()
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

    /// Records an editor completion. Pass `nil` for the Darwin cancel path
    /// (no saved contact). Pass a caller-owned `CNContact` to script Done;
    /// Linux never writes `contactStore`.
    public static func reportViewControllerCompletion(
        _ viewController: CNContactViewController,
        contact: CNContact? = nil
    ) {
        viewController.linuxCompletedWithoutSaving = (contact == nil)
        viewController.delegate?.contactViewController(viewController, didCompleteWith: contact)
    }

    /// Darwin Cancel. Equivalent to `reportViewControllerCompletion(_:contact: nil)`.
    public static func reportViewControllerDidCancel(_ viewController: CNContactViewController) {
        reportViewControllerCompletion(viewController, contact: nil)
    }

    /// Asks the editor whether a property should perform its default action.
    /// `allowsActions == false` is fail-closed: the delegate is not asked.
    public static func shouldPerformDefaultAction(
        _ viewController: CNContactViewController,
        for property: CNContactProperty
    ) -> Bool {
        guard viewController.allowsActions else { return false }
        return viewController.delegate?.contactViewController(
            viewController,
            shouldPerformDefaultActionFor: property
        ) ?? false
    }

    /// Darwin would consult `contactStore` for unified/linked cards.
    /// Isolated Linux always returns `0`.
    public static func linkedContactCount(_ viewController: CNContactViewController) -> Int {
        _ = viewController.shouldShowLinkedContacts
        _ = viewController.contactStore
        return 0
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
        predicate(format: format, arguments: argument.map { [$0] } ?? [])
    }

    /// Same portable subset with left-to-right `%@` substitution, including
    /// `AND` / `OR` compounds (`AND` binds tighter).
    public static func predicate(format: String, arguments: [String]) -> NSPredicate {
        ContactsUIPredicateEvaluation.makePredicate(format: format, arguments: arguments)
    }

    public static func evaluate(_ predicate: NSPredicate?, contact: CNContact) -> Bool {
        ContactsUIPredicateEvaluation.evaluate(predicate, contact: contact)
    }

    public static func evaluate(_ predicate: NSPredicate?, property: CNContactProperty) -> Bool {
        ContactsUIPredicateEvaluation.evaluate(predicate, property: property)
    }

    /// Conjunction of two portable picker predicates. Darwin would write
    /// `NSCompoundPredicate(andPredicateWithSubpredicates:)`.
    public static func and(_ lhs: NSPredicate, _ rhs: NSPredicate) -> NSPredicate {
        NSPredicate { object, bindings in
            lhs.evaluate(with: object, substitutionVariables: bindings)
                && rhs.evaluate(with: object, substitutionVariables: bindings)
        }
    }

    /// Disjunction of two portable picker predicates.
    public static func or(_ lhs: NSPredicate, _ rhs: NSPredicate) -> NSPredicate {
        NSPredicate { object, bindings in
            lhs.evaluate(with: object, substitutionVariables: bindings)
                || rhs.evaluate(with: object, substitutionVariables: bindings)
        }
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
        makePredicate(format: format, arguments: argument.map { [$0] } ?? [])
    }

    public static func makePredicate(format: String, arguments: [String]) -> NSPredicate {
        NSPredicate { object, _ in
            evaluate(format: format, arguments: arguments, object: object)
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
        evaluate(format: format, arguments: argument.map { [$0] } ?? [], object: object)
    }

    static func evaluate(format: String, arguments: [String], object: Any?) -> Bool {
        guard let snapshot = object as? [String: Any] else { return false }
        let bound = bindArguments(format, arguments: arguments)
        return evaluateBound(bound, snapshot: snapshot)
    }

    private static func evaluateBound(_ format: String, snapshot: [String: Any]) -> Bool {
        let trimmed = format.trimmingCharacters(in: .whitespacesAndNewlines)
        let orParts = splitKeyword(trimmed, keyword: "OR")
        if orParts.count > 1 {
            return orParts.contains { evaluateBound($0, snapshot: snapshot) }
        }
        let andParts = splitKeyword(trimmed, keyword: "AND")
        if andParts.count > 1 {
            return andParts.allSatisfy { evaluateBound($0, snapshot: snapshot) }
        }
        return evaluateLeaf(trimmed, snapshot: snapshot)
    }

    private static func evaluateLeaf(_ trimmed: String, snapshot: [String: Any]) -> Bool {
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

        if let comparison = parseStringComparison(trimmed, argument: nil) {
            if let values = snapshot[comparison.key] as? [String] {
                return evaluateCollection(values, comparison: comparison)
            }
            let actual = string(snapshot[comparison.key]) ?? ""
            return evaluateString(actual, comparison: comparison)
        }
        return false
    }

    /// Left-to-right `%@` substitution. Values are wrapped in double quotes so
    /// the leaf parser can `stripQuotes`.
    private static func bindArguments(_ format: String, arguments: [String]) -> String {
        var result = ""
        var index = format.startIndex
        var argumentIndex = 0
        while index < format.endIndex {
            if format[index...].hasPrefix("%@") {
                let value = argumentIndex < arguments.count ? arguments[argumentIndex] : ""
                argumentIndex += 1
                result += quoted(value)
                index = format.index(index, offsetBy: 2)
            } else {
                result.append(format[index])
                index = format.index(after: index)
            }
        }
        return result
    }

    private static func quoted(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    private static func splitKeyword(_ text: String, keyword: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: "\\s+\(keyword)\\s+",
            options: .caseInsensitive
        ) else {
            return [text]
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: range)
        if matches.isEmpty {
            return [text]
        }
        var parts: [String] = []
        var cursor = text.startIndex
        for match in matches {
            guard let slice = Range(match.range, in: text) else { continue }
            parts.append(String(text[cursor..<slice.lowerBound]))
            cursor = slice.upperBound
        }
        parts.append(String(text[cursor...]))
        return parts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func evaluateCollection(_ values: [String], comparison: StringClause) -> Bool {
        let expected = comparison.caseInsensitive ? comparison.value.lowercased() : comparison.value
        let folded = comparison.caseInsensitive ? values.map { $0.lowercased() } : values
        switch comparison.op {
        case "EQUAL":
            return folded.contains(expected)
        case "CONTAINS":
            return folded.contains { $0.contains(expected) }
        case "BEGINSWITH":
            return folded.contains { $0.hasPrefix(expected) }
        case "ENDSWITH":
            return folded.contains { $0.hasSuffix(expected) }
        default:
            return false
        }
    }

    private static func evaluateString(_ actual: String, comparison: StringClause) -> Bool {
        let foldedActual: String
        let foldedExpected: String
        if comparison.caseInsensitive {
            foldedActual = actual.lowercased()
            foldedExpected = comparison.value.lowercased()
        } else {
            foldedActual = actual
            foldedExpected = comparison.value
        }
        switch comparison.op {
        case "EQUAL": return foldedActual == foldedExpected
        case "BEGINSWITH": return foldedActual.hasPrefix(foldedExpected)
        case "CONTAINS": return foldedActual.contains(foldedExpected)
        case "ENDSWITH": return foldedActual.hasSuffix(foldedExpected)
        default: return false
        }
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
