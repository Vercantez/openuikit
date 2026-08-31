#!/usr/bin/env python3
"""Lightweight structural teeth for the Foundation text/error facade."""

from __future__ import annotations

import hashlib
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[3]
FOUNDATION = ROOT / "full/foundation"
TESTS = FOUNDATION / "tests"
HOST_GATE = TESTS / "test_foundation_guest_text_host.sh"
GOLDEN = TESTS / "foundation-guest-text-apple-2026-08-30.txt"
COMPAT_GOLDEN = TESTS / "foundation-guest-compatibility-apple-2026-08-30.txt"
STRUCTURED_GOLDEN = TESTS / "foundation-guest-structured-data-apple-2026-08-30.txt"
NSSTRING_GOLDEN = TESTS / "foundation-guest-nsstring-apple-2026-08-30.txt"
NSSTRING = FOUNDATION / "NSString.swift"
PRODUCTION = (
    FOUNDATION / "CharacterSet.swift",
    FOUNDATION / "String+CharacterSet.swift",
    FOUNDATION / "String+FoundationCompatibility.swift",
    FOUNDATION / "Bundle+Localization.swift",
    FOUNDATION / "Scanner.swift",
    FOUNDATION / "Error+LocalizedDescription.swift",
)
STRUCTURED_PRODUCTION = (
    FOUNDATION / "NSError.swift",
    FOUNDATION / "NSNumber.swift",
    FOUNDATION / "JSONSerialization.swift",
    FOUNDATION / "NSRegularExpression.swift",
    ROOT / "full/appshim/FoundationOpenUIKitValueAliases.swift",
)
ATTESTED = PRODUCTION + (NSSTRING,) + STRUCTURED_PRODUCTION + (
    TESTS / "FoundationGuestTextTestRoot.swift",
    TESTS / "FoundationGuestTextUIKit.swift",
    TESTS / "FoundationGuestTextUIKitClient.swift",
    TESTS / "FoundationGuestTextOracle.swift",
    TESTS / "FoundationGuestTextRuntime.swift",
    TESTS / "FoundationGuestTextMissingScanner.swift",
    TESTS / "FoundationGuestCompatibilityOracle.swift",
    TESTS / "FoundationGuestBundleRuntime.swift",
    TESTS / "FoundationGuestServicesOpenUIKitStub.swift",
    TESTS / "FoundationGuestServicesTestRoot.swift",
    TESTS / "FoundationGuestServiceIdentityProbe.swift",
    TESTS / "FoundationGuestStructuredDataOracle.swift",
    TESTS / "FoundationGuestStructuredDataNegative.swift",
    TESTS / "FoundationGuestNSStringOracle.swift",
    TESTS / "FoundationGuestNSStringNegative.swift",
    GOLDEN,
    COMPAT_GOLDEN,
    STRUCTURED_GOLDEN,
    NSSTRING_GOLDEN,
)


def source_digest() -> str:
    outer = hashlib.sha256()
    for source in ATTESTED:
        relative = source.relative_to(ROOT).as_posix()
        inner = hashlib.sha256(source.read_bytes()).hexdigest()
        outer.update(f"{relative}\t{inner}\n".encode())
    return outer.hexdigest()


class FoundationGuestTextTests(unittest.TestCase):
    def test_host_gate_has_valid_shell_syntax(self) -> None:
        subprocess.run(["bash", "-n", str(HOST_GATE)], check=True)

    def test_source_manifest_is_exact_and_hash_attested(self) -> None:
        gate = HOST_GATE.read_text()
        expected = re.search(
            r"^EXPECTED_SOURCE_DIGEST=([0-9a-f]{64})$", gate, re.MULTILINE
        )
        self.assertIsNotNone(expected)
        self.assertEqual(source_digest(), expected.group(1))
        self.assertEqual(
            hashlib.sha256(GOLDEN.read_bytes()).hexdigest(),
            "da4a06b171c7474c8f3eec6febec9f217dffe47c28feaa42bb8346ddaab5f980",
        )
        self.assertEqual(len(GOLDEN.read_text().splitlines()), 51)
        self.assertEqual(
            hashlib.sha256(COMPAT_GOLDEN.read_bytes()).hexdigest(),
            "07a1d25c7707614ae7cf8b18d847f7da2fd008e4c3879ded01830085985611ac",
        )
        self.assertEqual(len(COMPAT_GOLDEN.read_text().splitlines()), 35)
        self.assertEqual(
            hashlib.sha256(STRUCTURED_GOLDEN.read_bytes()).hexdigest(),
            "5ceca8b4b92d4fe59ecee2751bb0996cc20b453309f6a9d75105e7517ac8d46e",
        )
        self.assertEqual(len(STRUCTURED_GOLDEN.read_text().splitlines()), 77)
        self.assertEqual(
            hashlib.sha256(NSSTRING_GOLDEN.read_bytes()).hexdigest(),
            "472ce641b97e460a14b19e80a10bb60af3fa532df6d0383799a9e58ba2d87486",
        )
        self.assertEqual(len(NSSTRING_GOLDEN.read_text().splitlines()), 46)

    def test_character_set_inventory_is_exact_and_not_app_specific(self) -> None:
        source = PRODUCTION[0].read_text()
        inventory = re.search(
            r"whitespacesAndNewlines = CharacterSet\(\n\s*scalarValues: \[\n(.*?)\n\s*\]",
            source,
            re.DOTALL,
        )
        self.assertIsNotNone(inventory)
        values = re.findall(r"0x[0-9A-F]{4}", inventory.group(1))
        self.assertEqual(len(values), 26)
        self.assertEqual(len(set(values)), 26)
        self.assertIn("0x200B", values)
        self.assertIn("init(charactersIn aString: String)", source)
        self.assertIn("contains(_ member: Unicode.Scalar)", source)
        for name in (
            "urlUserAllowed", "urlPasswordAllowed", "urlHostAllowed",
            "urlPathAllowed", "urlQueryAllowed", "urlFragmentAllowed",
        ):
            self.assertIn(name, source)
        self.assertIn("removeCharacters(in aString: String)", source)
        for app_token in ("Reminder", "C0FFEE"):
            self.assertNotIn(app_token, source)

    def test_trimming_keeps_upstream_attribution_and_scalar_algorithm(self) -> None:
        source = PRODUCTION[1].read_text()
        self.assertIn(
            "c6793ef0c19c2cbaeba5a0e52078f129afc7dcfc", source
        )
        self.assertIn("Licensed under Apache License v2.0", source)
        self.assertIn("let scalars = unicodeScalars", source)
        self.assertIn("set.contains(scalars[lower])", source)
        self.assertIn("set.contains(scalars[upper])", source)

    def test_search_percent_and_format_are_native_differentially_pinned(self) -> None:
        source = PRODUCTION[2].read_text()
        for token in (
            "addingPercentEncoding",
            "removingPercentEncoding",
            "func range(",
            "replacingOccurrences",
            "init(format: String, _ arguments: Any...)",
            "match.range.lowerBound != match.range.upperBound",
        ):
            self.assertIn(token, source)
        self.assertNotIn("public typealias NSString = String", source)
        oracle = (TESTS / "FoundationGuestCompatibilityOracle.swift").read_text()
        self.assertIn("CharacterSet.urlUserAllowed", oracle)
        self.assertIn("%C3%28", oracle)
        self.assertIn("%2$@/%1$@", oracle)

    def test_bundle_parser_and_localization_fail_closed(self) -> None:
        source = PRODUCTION[3].read_text()
        self.assertIn("var infoDictionary: [String: Any]?", source)
        self.assertIn("func localizedString(", source)
        self.assertIn("return nil", source[source.index('if scalars[index] == "&"'):])
        runtime = (TESTS / "FoundationGuestBundleRuntime.swift").read_text()
        self.assertIn("&unknown;", runtime)
        self.assertIn("malformed.infoDictionary == nil", runtime)

    def test_scanner_is_cursor_based_and_saturating(self) -> None:
        source = PRODUCTION[4].read_text()
        for token in (
            "public var currentIndex: String.Index",
            "public var charactersToBeSkipped: CharacterSet?",
            "scanHexInt64(_ result: UnsafeMutablePointer<UInt64>?)",
            "multipliedReportingOverflow(by: 16)",
            "UInt64.max",
            "currentIndex = original",
            "result?.pointee = value",
        ):
            self.assertIn(token, source)
        self.assertNotIn("pureString", source)
        self.assertNotIn("count == 6", source)

    def test_error_bridge_is_explicit_about_the_nserror_boundary(self) -> None:
        source = PRODUCTION[5].read_text()
        self.assertIn("_convertErrorToNSError(self).localizedDescription", source)
        self.assertIn("self._getEmbeddedNSError() as? NSError", source)

    def test_nserror_bridge_preserves_identity_and_error_metadata(self) -> None:
        source = STRUCTURED_PRODUCTION[0].read_text()
        for token in (
            "public protocol CustomNSError: Error",
            "public protocol RecoverableError: Error",
            "public let domain: String",
            "public let code: Int",
            "public let userInfo: [String: Any]",
            "public func _convertErrorToNSError(_ error: any Error) -> NSError",
            "public func _convertNSErrorToError(_ error: NSError?) -> any Error",
            "error._getEmbeddedNSError() as? NSError",
            "error as? any LocalizedError",
            "error as? any RecoverableError",
            "NSLocalizedRecoveryOptionsErrorKey",
            "NSUnderlyingErrorKey",
        ):
            self.assertIn(token, source)
        self.assertNotRegex(source, r"return\s+error\s+as\s+NSError")

    def test_nsstring_is_a_real_immutable_reference_bridge(self) -> None:
        source = NSSTRING.read_text()
        for token in (
            "open class NSString: NSObject, NSCopying",
            "public init(string aString: String)",
            "public required convenience init(stringLiteral value: String)",
            "open var length: Int",
            "open func character(at index: Int) -> unichar",
            "open func substring(from index: Int) -> String",
            "open func substring(to index: Int) -> String",
            "open func substring(with range: NSRange) -> String",
            "open func compare(_ string: String) -> ComparisonResult",
            "open override func isEqual(_ object: Any?) -> Bool",
            "open override var hash: Int",
            "open var utf8String: UnsafePointer<CChar>?",
            "open func copy(with zone: NSZone? = nil) -> Any",
            "extension String: _ObjectiveCBridgeable",
            "public typealias _ObjectiveCType = NSString",
            "encoding == String.Encoding.utf8.rawValue",
        ):
            self.assertIn(token, source)
        self.assertIn("return nil", source)
        self.assertNotIn("fatalError", source)
        self.assertNotIn("public typealias NSString = String", source)

    def test_nsnumber_is_a_real_reference_bridge_for_scalar_values(self) -> None:
        source = STRUCTURED_PRODUCTION[1].read_text()
        for token in (
            "open class NSNumber: NSObject",
            "public convenience init(value: Bool)",
            "public convenience init<T: BinaryInteger>(value: T)",
            "public convenience init<T: BinaryFloatingPoint>(value: T)",
            "public convenience init(value: Decimal)",
            "open var boolValue: Bool",
            "open var intValue: Int",
            "open var doubleValue: Double",
            "open var decimalValue: Decimal",
            "open func compare(_ otherNumber: NSNumber) -> ComparisonResult",
            "extension Bool: _ObjectiveCBridgeable",
            "extension Int: _ObjectiveCBridgeable",
            "extension Double: _ObjectiveCBridgeable",
            "extension CGFloat: _ObjectiveCBridgeable",
        ):
            self.assertIn(token, source)
        bridge_types = re.findall(r"^extension (\w+): _ObjectiveCBridgeable", source, re.MULTILINE)
        self.assertEqual(
            bridge_types,
            [
                "Int8", "UInt8", "Int16", "UInt16", "Int32", "UInt32",
                "Int64", "UInt64", "Int", "UInt", "Float", "Double",
                "CGFloat", "Bool",
            ],
        )

    def test_objc_runtime_name_conversion_uses_the_real_runtime(self) -> None:
        source = STRUCTURED_PRODUCTION[4].read_text()
        for token in (
            "public func NSClassFromString(_ aClassName: String) -> AnyClass?",
            "aClassName.withCString({ objc_getClass($0) })",
            "as? AnyClass",
            "public func NSStringFromClass(_ aClass: AnyClass) -> String",
            "String(cString: class_getName(aClass))",
            "public func NSSelectorFromString(_ aSelectorName: String) -> Selector",
            "public func NSStringFromSelector(_ aSelector: Selector) -> String",
            "Selector(aSelectorName)",
            "String(_sel: aSelector)",
        ):
            self.assertIn(token, source)
        self.assertNotIn('aClassName == "CAFilter"', source)

    def test_json_serialization_has_mutability_options_and_fails_with_nserror(self) -> None:
        source = STRUCTURED_PRODUCTION[2].read_text()
        for token in (
            "public static let mutableContainers",
            "public static let mutableLeaves",
            "public static let fragmentsAllowed",
            "public static let prettyPrinted",
            "public static let sortedKeys",
            "public static let withoutEscapingSlashes",
            "JSONDecoder().decode(_FoundationGuestJSONValue.self, from: data)",
            "JSONEncoder.OutputFormatting",
            "number.isFinite",
            "if value is NSNull",
            "if let value = value as? NSNumber",
            "domain: NSCocoaErrorDomain",
            "code: NSPropertyListReadCorruptError",
        ):
            self.assertIn(token, source)
        self.assertNotIn("fatalError", source)
        self.assertNotIn("try!", source)

    def test_regex_surface_uses_utf16_ranges_and_rejects_unimplemented_options(self) -> None:
        source = STRUCTURED_PRODUCTION[3].read_text()
        for token in (
            "Regex<AnyRegexOutput>",
            "range(withName name: String)",
            "enumerateMatches(",
            "stringByReplacingMatches(",
            "replacementString(",
            "string.utf16.distance",
            "options.subtracting(known).isEmpty",
            "Unsupported regular-expression option",
        ):
            self.assertIn(token, source)
        known = re.search(r"let known: Options = \[(.*?)\n\s*\]", source, re.DOTALL)
        self.assertIsNotNone(known)
        self.assertNotIn("useUnixLineSeparators", known.group(1))
        self.assertNotIn("useUnicodeWordBoundaries", known.group(1))
        self.assertIn("scope.matches(of: regex)", source)

    def test_structured_data_oracle_is_corpus_shaped_and_adversarial(self) -> None:
        oracle = (TESTS / "FoundationGuestStructuredDataOracle.swift").read_text()
        for token in (
            "NSNumber(value: UInt64.max)",
            "swiftInteger as? NSNumber",
            "objectNumber as? Int",
            "JSONSerialization.isValidJSONObject([\"x\": Double.nan])",
            "error as NSError",
            "(existential as NSError) === plain",
            "range(withName: \"word\")",
            "options: [.reportCompletion]",
            "pattern: \"(?=a)|$\"",
            "stringByReplacingMatches(",
        ):
            self.assertIn(token, oracle)

    def test_gate_rebuilds_and_has_adversarial_teeth(self) -> None:
        gate = HOST_GATE.read_text()
        for token in (
            "mktemp -d",
            "pinned_inputs.pl",
            "-module-cache-path",
            "Apple oracle drifted from golden",
            "portable output differs from Apple golden",
            "missing-Scanner adversarial compile unexpectedly succeeded",
            "U+200B mutation did not perturb the oracle",
            "Apple compatibility oracle drifted from golden",
            "malformed-entity=rejected",
            "FoundationGuestServiceIdentityProbe.swift",
            "foundation-guest-structured-data-apple-2026-08-30.txt",
            "foundation-guest-nsstring-apple-2026-08-30.txt",
            "portable structured-data output differs from Apple golden",
            "portable NSString output differs from Apple golden",
            "FOUNDATION_GUEST_NSSTRING_NEGATIVE_OK",
            "FOUNDATION_GUEST_STRUCTURED_NEGATIVE_OK",
            "Foundation|CoreFoundation",
            "FOUNDATION_GUEST_TEXT_HOST_OK",
        ):
            self.assertIn(token, gate)
        self.assertNotIn("/w/build/full", gate)
        self.assertNotIn("scratch/fe4_out", gate)

    def test_candidate_contains_no_build_residue(self) -> None:
        forbidden = {".build", "Package.resolved", "__pycache__"}
        tracked = subprocess.run(
            ["git", "-C", str(ROOT), "ls-files"],
            check=True,
            text=True,
            capture_output=True,
        ).stdout.splitlines()
        for path in tracked:
            self.assertFalse(forbidden.intersection(Path(path).parts), path)


if __name__ == "__main__":
    unittest.main()
