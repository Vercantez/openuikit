#!/usr/bin/env python3
"""Static fail-closed checks for the production Foundation facade manifest."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
MANIFEST = ROOT / "full/foundation/foundation_guest_sources.txt"
ONBOARDING = ROOT / "full/swiftui/build_focus_onboarding_guest.sh"

EXPECTED = [
    "full/appshim/FoundationGuest.swift",
    "full/appshim/FoundationOpenUIKitAliases.swift",
    "full/appshim/FoundationOpenUIKitServiceAliases.swift",
    "full/appshim/FoundationOpenUIKitValueAliases.swift",
    "full/foundation/NSString.swift",
    "full/foundation/CharacterSet.swift",
    "full/foundation/NSLock.swift",
    "full/foundation/NotificationCenter+Combine.swift",
    "full/foundation/Progress.swift",
    "full/foundation/NSCache.swift",
    "full/foundation/FileHandle.swift",
    "full/foundation/Data+Searching.swift",
    "full/foundation/CoreFoundationCompatibility.swift",
    "full/foundation/NSURL.swift",
    "full/foundation/String+CharacterSet.swift",
    "full/foundation/String+FoundationCompatibility.swift",
    "full/foundation/Bundle+Localization.swift",
    "full/foundation/Stream.swift",
    "full/foundation/URLLoading.swift",
    "full/foundation/URLSession.swift",
    "full/foundation/Scanner.swift",
    "full/foundation/NSError.swift",
    "full/foundation/CFError+Error.swift",
    "full/foundation/NSNumber.swift",
    "full/foundation/Error+LocalizedDescription.swift",
    "full/foundation/JSONSerialization.swift",
    "full/foundation/NSRegularExpression.swift",
    "full/foundation/DateFormatter.swift",
    "full/foundation/ByteCountFormatter.swift",
    "full/foundation/UserDefaults.swift",
    "full/foundation/UbiquitousKeyValueStore.swift",
    "full/foundation/RelativeDateTimeFormatter.swift",
    "full/foundation/FileManager+Enumeration.swift",
]


class FoundationGuestServicesTests(unittest.TestCase):
    def test_manifest_is_exact_and_production_only(self) -> None:
        self.assertEqual(MANIFEST.read_text().splitlines(), EXPECTED)
        self.assertTrue(MANIFEST.read_bytes().endswith(b"\n"))
        self.assertEqual(len(EXPECTED), len(set(EXPECTED)))
        for relative in EXPECTED:
            path = ROOT / relative
            self.assertTrue(path.is_file(), relative)
            self.assertFalse(path.is_symlink(), relative)
            self.assertNotIn("/tests/", relative)
            self.assertNotIn("probe", relative.lower())

    def test_onboarding_consumes_and_validates_manifest(self) -> None:
        source = ONBOARDING.read_text()
        self.assertIn("FOUNDATION_GUEST_MANIFEST=", source)
        self.assertIn("mapfile -t FOUNDATION_GUEST_RELATIVE_SOURCES", source)
        self.assertIn('"${#FOUNDATION_GUEST_RELATIVE_SOURCES[@]}" -eq 33', source)
        self.assertIn("COpenFoundationCore/module.modulemap", source)
        self.assertIn('"${FOUNDATION_GUEST_SOURCES[@]}"', source)
        self.assertIn("duplicate Foundation guest source", source)
        self.assertIn("escaped production source roots", source)
        compile_region = source[source.index("== compile the bounded Foundation umbrella"):]
        compile_region = compile_region[:compile_region.index("== FoundationGuest/UIKit")]
        self.assertNotIn('"$W/full/appshim/FoundationGuest.swift"', compile_region)
        self.assertNotIn('"$W/full/appshim/FoundationOpenUIKitAliases.swift"', compile_region)

    def test_date_formatter_is_calendar_backed_and_bounded(self) -> None:
        source = (ROOT / "full/foundation/DateFormatter.swift").read_text()
        self.assertIn("Calendar", source)
        self.assertIn("dateComponents", source)
        self.assertIn("TimeZone", source)
        for token in ('case "M", "L"', 'case "E"', 'case "h"', 'case "S"', 'case "X"'):
            self.assertIn(token, source)
        self.assertNotIn("Date(timeIntervalSince1970: 0)", source)

    def test_byte_count_formatter_has_real_unit_and_rounding_semantics(self) -> None:
        source = (ROOT / "full/foundation/ByteCountFormatter.swift").read_text()
        self.assertIn("public struct Units: OptionSet", source)
        self.assertIn("public enum CountStyle: UInt", source)
        self.assertIn("private func _selectedUnit(", source)
        self.assertIn("rounded(.toNearestOrAwayFromZero)", source)
        self.assertIn("includesActualByteCount", source)

    def test_user_defaults_has_real_persistence_and_value_round_trips(self) -> None:
        source = (ROOT / "full/foundation/UserDefaults.swift").read_text()
        self.assertIn("Data(contentsOf:", source)
        self.assertIn("data.write", source)
        self.assertIn("_userDefaultsRename", source)
        self.assertIn("same-directory rename", source)
        self.assertNotIn("options: .atomic", source)
        self.assertIn("JSONEncoder", source)
        self.assertIn("JSONDecoder", source)
        self.assertIn("Mutex<", source)
        self.assertIn("open class UserDefaults: @unchecked Sendable", source)
        self.assertIn("case data(Data)", source)
        self.assertIn("case date(Date)", source)
        self.assertNotIn("static var storage", source)

        oracle = (
            ROOT
            / "full/oracle-userdefaults/darwin-sendability-2026-08-31.txt"
        ).read_text()
        self.assertIn("xcrun swiftc -swift-version 6 -typecheck", oracle)
        self.assertIn("compiler exits 0 with empty diagnostics", oracle)
        self.assertIn(
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            oracle,
        )

    def test_notification_publisher_uses_the_canonical_opencombine_identity(self) -> None:
        source = (
            ROOT / "full/foundation/NotificationCenter+Combine.swift"
        ).read_text()
        defaults = (ROOT / "full/foundation/UserDefaults.swift").read_text()
        for token in (
            "import OpenCombine",
            "import OpenUIKit",
            "struct Publisher: OpenCombine.Publisher",
            "OpenCombine.Subscription",
            "OpenCombine.Subscribers.Demand",
            "center.addObserver(",
            "center.removeObserver(observation)",
            "private let downstreamLock = _FoundationRecursiveLock()",
            "PTHREAD_MUTEX_RECURSIVE",
            '"name": name',
            "lhs.center === rhs.center",
            "lhs.object === rhs.object",
        ):
            self.assertIn(token, source)
        self.assertNotIn("PassthroughSubject", source)
        self.assertIn(
            'Notification.Name("NSUserDefaultsDidChangeNotification")',
            defaults,
        )
        self.assertIn("object: self", defaults)

        oracle = (
            ROOT
            / "full/oracle-userdefaults/darwin-notifications-2026-08-31.txt"
        ).read_text()
        self.assertIn("constant=NSUserDefaultsDidChangeNotification", oracle)
        for mutation in (
            "set-new",
            "set-same",
            "remove-existing",
            "remove-missing",
            "register",
            "set-persistent",
            "remove-persistent",
            "set-volatile",
            "remove-volatile",
        ):
            self.assertIn(f"step {mutation} delta=1", oracle)
        for nonmutation in ("add-suite", "remove-suite", "synchronize"):
            self.assertIn(f"step {nonmutation} delta=0", oracle)

    def test_progress_has_typed_lifetime_bound_observation(self) -> None:
        source = (ROOT / "full/foundation/Progress.swift").read_text()
        for token in (
            "public struct NSKeyValueObservingOptions: OptionSet",
            "public struct NSKeyValueObservedChange<Value>",
            "public final class NSKeyValueObservation: NSObject",
            "private final class _WeakProgressObservation",
            "open class Progress: NSObject",
            "open func observe<Value>(",
            "weak var value: NSKeyValueObservation?",
            "deinit { invalidate() }",
            "state.totalUnitCount < 0 || state.completedUnitCount < 0",
            "Double(state.completedUnitCount) / Double(state.totalUnitCount)",
        ):
            self.assertIn(token, source)
        self.assertNotIn("addObserver(forName:", source)

    def test_hackers_frontier_uses_real_lock_file_and_reexport_surfaces(self) -> None:
        umbrella = (ROOT / "full/appshim/FoundationGuest.swift").read_text()
        value_compatibility = (
            ROOT / "full/appshim/FoundationOpenUIKitValueAliases.swift"
        ).read_text()
        lock = (ROOT / "full/foundation/NSLock.swift").read_text()
        file_handle = (ROOT / "full/foundation/FileHandle.swift").read_text()
        data_search = (ROOT / "full/foundation/Data+Searching.swift").read_text()
        core_foundation = (
            ROOT / "full/foundation/CoreFoundationCompatibility.swift"
        ).read_text()
        character_set = (ROOT / "full/foundation/CharacterSet.swift").read_text()
        self.assertIn("@_exported import OpenCoreGraphics", umbrella)
        self.assertIn("@_exported import Dispatch", umbrella)
        self.assertIn("@_exported import os", umbrella)
        for token in (
            "public func NSMaxRange(",
            "public func NSLocationInRange(",
            "public func NSEqualRanges(",
            "public func NSUnionRange(",
            "public func NSIntersectionRange(",
            "public struct InlinePresentationIntent: OptionSet",
            "public static let emphasized = Self(rawValue: 1 << 0)",
            "public static let stronglyEmphasized = Self(rawValue: 1 << 1)",
            "public static let code = Self(rawValue: 1 << 2)",
            "enum InlinePresentationIntentAttribute: CodableAttributedStringKey",
            'public static let name = "NSInlinePresentationIntent"',
            "var inlinePresentationIntent: InlinePresentationIntentAttribute",
            "open class NSSortDescriptor: NSObject, @unchecked Sendable",
            "public init(key: String?, ascending: Bool)",
            "public let key: String?",
            "public let ascending: Bool",
            "open var reversedSortDescriptor: Any",
        ):
            self.assertIn(token, value_compatibility)
        compatibility_probe = (
            ROOT / "full/frameworks/FoundationHackersCompatibilityProbe.swift"
        ).read_text()
        for token in (
            'NSSortDescriptor(',
            'key: "creationDate"',
            "sortDescriptor.key == \"creationDate\"",
            "!sortDescriptor.ascending",
            "sortDescriptor.reversedSortDescriptor as! NSSortDescriptor",
            "reversedSortDescriptor.ascending",
        ):
            self.assertIn(token, compatibility_probe)
        for token in (
            "public protocol NSLocking",
            "public final class NSLock",
            "os_unfair_lock_lock(&storage)",
            "os_unfair_lock_trylock(&storage)",
            "func withLock<Result>",
        ):
            self.assertIn(token, lock)
        for token in (
            "public final class FileHandle",
            "Darwin.open",
            "Darwin.read",
            "Darwin.write",
            "Darwin.lseek",
            "Darwin.fsync",
            "Darwin.close",
        ):
            self.assertIn(token, file_handle)
        for name in (
            "uppercaseLetters",
            "lowercaseLetters",
            "letters",
            "alphanumerics",
            "symbols",
            "decimalDigits",
        ):
            self.assertIn(f"public static var {name}", character_set)
        for token in (
            "public extension Data",
            "public extension Data.SearchOptions",
            "static let backwards",
            "static let anchored",
            "options: Data.SearchOptions = []",
            "func range(",
            "elementsEqual(dataToFind)",
            "guard !dataToFind.isEmpty",
        ):
            self.assertIn(token, data_search)
        for token in (
            "public typealias CFString = String",
            "public typealias CFURL = URL",
            "public func CFURLCreateWithString(",
            "encodingInvalidCharacters: false",
            "return URL(string: normalized, relativeTo: baseURL)",
            "else { return nil }",
        ):
            self.assertIn(token, core_foundation)
        self.assertNotIn("import CoreFoundation", core_foundation)

    def test_url_loading_values_and_transport_are_separate_production_sources(self) -> None:
        source = (ROOT / "full/foundation/URLLoading.swift").read_text()
        session = (ROOT / "full/foundation/URLSession.swift").read_text()
        for token in (
            "public struct URLRequest: Hashable",
            "public var cachePolicy: CachePolicy",
            "public var httpBodyStream: InputStream?",
            "public func value(forHTTPHeaderField field: String)",
            "public mutating func setValue",
            "open class URLResponse: NSObject",
            "open var suggestedFilename: String?",
        ):
            self.assertIn(token, source)
        self.assertNotIn("open class URLSession", source)
        for token in (
            "open class URLSession: NSObject",
            "open class HTTPURLResponse: URLResponse",
            "open class HTTPCookieStorage: NSObject",
            "open class URLCache: NSObject",
            "open class URLProtocol: NSObject",
            "openui_url_transport_v1_perform",
            "withTaskCancellationHandler",
        ):
            self.assertIn(token, session)

    def test_nsurl_bridge_and_nscache_are_production_sources(self) -> None:
        url = (ROOT / "full/foundation/NSURL.swift").read_text()
        cache = (ROOT / "full/foundation/NSCache.swift").read_text()
        self.assertIn("open class NSURL: ObjectiveC.NSObject", url)
        self.assertIn("extension URL: @retroactive ReferenceConvertible", url)
        self.assertIn("@retroactive _ObjectiveCBridgeable", url)
        self.assertIn(
            "open class NSCache<KeyType: AnyObject, ObjectType: AnyObject>",
            cache,
        )
        self.assertIn("private let _lock = NSLock()", cache)
        self.assertIn("open weak var delegate", cache)

    def test_host_gate_is_cross_process_and_mutation_sensitive(self) -> None:
        source = (
            ROOT / "full/foundation/tests/test_foundation_guest_services_host.sh"
        ).read_text()
        self.assertIn('"$WORK/defaults" write "$SUITE"', source)
        self.assertIn('"$WORK/defaults" read "$SUITE"', source)
        self.assertIn("DateFormatter mutation escaped", source)
        self.assertIn("cmp \"$WORK/oracle.txt\"", source)


if __name__ == "__main__":
    unittest.main()
