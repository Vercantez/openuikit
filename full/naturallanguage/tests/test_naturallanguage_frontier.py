import hashlib
import pathlib
import unittest


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
RUNTIME = ROOT / "full/naturallanguage/NaturalLanguage.swift"
MANIFEST = ROOT / "full/naturallanguage/naturallanguage_guest_sources.txt"
ORACLE = HERE / "NaturalLanguageIceCubesOracle.swift"
GOLDEN = HERE / "naturallanguage-apple-26.1.txt"
GENERALIZATION = HERE / "NaturalLanguageGeneralizationOracle.swift"
GENERALIZATION_GOLDEN = HERE / "naturallanguage-generalization-apple-26.1.txt"
FRONTIER = HERE / "icecubes_naturallanguage_frontier.tsv"
NATIVE = HERE / "test_naturallanguage_native.sh"
HOST_BUILDER = HERE / "build_naturallanguage_guest.sh"
GUEST_BUILDER = HERE / "build_naturallanguage_guest_in_container.sh"


class NaturalLanguageFrontierTests(unittest.TestCase):
    def test_guest_source_manifest_is_exact(self):
        self.assertEqual(
            MANIFEST.read_text(encoding="utf-8").splitlines(),
            [
                "full/naturallanguage/NLContextualEmbedding.swift",
                "full/naturallanguage/NLEmbedding.swift",
                "full/naturallanguage/NLGazetteer.swift",
                "full/naturallanguage/NLModel.swift",
                "full/naturallanguage/NLTagger.swift",
                "full/naturallanguage/NLTokenizer.swift",
                "full/naturallanguage/NLTypes.swift",
                "full/naturallanguage/NaturalLanguage.swift",
            ],
        )

    def test_classifier_is_substantive_local_inference(self):
        source = RUNTIME.read_text(encoding="utf-8")
        for token in (
            "public struct NLLanguage: RawRepresentable",
            "public final class NLLanguageRecognizer: NSObject",
            "public func processString(_ string: String)",
            "public func reset()",
            "public var dominantLanguage: NLLanguage?",
            "public func languageHypotheses(",
            "languageHints",
            "languageConstraints",
            "scriptLanguage(in:",
            "trigramCounts(",
            "cosine(",
            "private static let latinProfiles",
        ):
            self.assertIn(token, source)
        self.assertGreaterEqual(source.count("Profile("), 19)
        self.assertNotIn("return [.english: 1", source)
        self.assertNotIn("Process(", source)

    def test_language_constants_match_the_apple_bcp47_surface(self):
        source = RUNTIME.read_text(encoding="utf-8")
        expected = {
            "undetermined": "und",
            "english": "en",
            "french": "fr",
            "spanish": "es",
            "german": "de",
            "italian": "it",
            "portuguese": "pt",
            "japanese": "ja",
            "korean": "ko",
            "simplifiedChinese": "zh-Hans",
            "traditionalChinese": "zh-Hant",
            "russian": "ru",
            "ukrainian": "uk",
        }
        for name, tag in expected.items():
            self.assertIn(
                f'public static let {name} = Self(rawValue: "{tag}")', source
            )

    def test_oracle_drives_the_exact_untouched_icecubes_behavior(self):
        oracle = ORACLE.read_text(encoding="utf-8")
        for token in (
            "detectLanguage(text: text)",
            "NLLanguageRecognizer.dominantLanguage(for:",
            "incremental.processString",
            "incremental.reset()",
            "languageConstraints = [.french, .spanish]",
            "languageHints = [.english: 0.99, .french: 0.01]",
            '("short", "ok")',
            '("symbols", "#Swift @friend :wave:")',
        ):
            self.assertIn(token, oracle)
        native = NATIVE.read_text(encoding="utf-8")
        self.assertIn("$CONSUMER", native)
        self.assertNotIn("cp \"$CONSUMER\"", native)
        self.assertIn("cmp \"$WORK/apple.txt\" \"$WORK/portable.txt\"", native)

    def test_apple_golden_is_exact_and_hash_stable(self):
        contents = GOLDEN.read_bytes()
        self.assertEqual(len(contents.splitlines()), 17)
        self.assertEqual(
            hashlib.sha256(contents).hexdigest(),
            "bff76de14ca81a7e2216381f8fb1f2e224f4e69d5f4449b200234b0881e90215",
        )
        self.assertEqual(contents.count(b"=nil"), 2)

    def test_generalization_oracle_matches_29_apple_decisions(self):
        oracle = GENERALIZATION.read_text(encoding="utf-8")
        golden = GENERALIZATION_GOLDEN.read_bytes()
        self.assertEqual(len(golden.splitlines()), 29)
        self.assertEqual(golden.count(b",high"), 29)
        for line in golden.decode().splitlines():
            self.assertIn(f'"{line.split("=", 1)[0]}"', oracle)
        self.assertEqual(
            hashlib.sha256(golden).hexdigest(),
            "a3f2c93e68040d85d3795bfef736575a0189da98e8b81ef4f379034cf34bb6f5",
        )
        for tag in (
            "en", "fr", "es", "de", "it", "pt", "nl", "ca", "sv",
            "da", "nb", "fi", "pl", "cs", "hr", "ro", "tr", "id",
            "vi", "ja", "ko", "zh-Hans", "ru", "uk", "el", "ar", "he",
            "hi", "th",
        ):
            self.assertIn(f"={tag},high".encode(), golden)

    def test_upstream_import_and_usage_census_is_frozen(self):
        rows = [line.split("\t") for line in FRONTIER.read_text().splitlines()]
        self.assertEqual(rows[0], ["format", "icecubes-naturallanguage-frontier-v1"])
        imports = [row for row in rows if row[0] == "import"]
        self.assertEqual(len(imports), 3)
        self.assertEqual({row[1] for row in imports}, {"NaturalLanguage"})
        self.assertEqual(
            {field for row in imports for field in row if field.startswith("lines=")},
            {"lines=34", "lines=979", "lines=506"},
        )
        for row in imports:
            digest = next(field.removeprefix("sha256=") for field in row if field.startswith("sha256="))
            self.assertEqual(len(digest), 64)
            int(digest, 16)
        self.assertIn(
            [
                "usage",
                "NLLanguageRecognizer",
                "init,processString,languageHypotheses(withMaximum:)",
                "callsite=Packages/StatusKit/Sources/StatusKit/LanguageDetection/LanguageDetection.swift:20-30",
            ],
            rows,
        )

    def test_linux_arm64_builder_is_cold_attested_and_non_mutating(self):
        host = HOST_BUILDER.read_text(encoding="utf-8")
        guest = GUEST_BUILDER.read_text(encoding="utf-8")
        for token in (
            "NaturalLanguage source tranche must be committed and clean",
            "OUTPUT=$(mktemp -d /private/tmp/naturallanguage-arm64-proof.",
            '"$ROOT:/w:ro"',
            '"$PLATFORM:/platform:ro"',
            '"$ICECUBES:/icecubes:ro"',
        ):
            self.assertIn(token, host)
        for token in (
            "TARGET=arm64-apple-ios18.0-simulator",
            "libNaturalLanguage.dylib",
            "MH_MAGIC_64",
            "IceCubes checkout is not untouched",
            "portable dylib loads Apple NaturalLanguage.framework",
            "source-subject.before.tsv",
            "source-subject.after.tsv",
            "MACHORUN_ROOT",
            "cmp \"$AUDIT/runtime.log\" \"$APPLE_GOLDEN\"",
            "NaturalLanguageGeneralizationOracle",
            "generalization-runtime.log",
            "generalization=29/29",
            "NATURALLANGUAGE_ARM64_PLATFORM_OK",
        ):
            self.assertIn(token, guest)
        self.assertIn("OUTPUT must not contain stale artifacts", guest)
        self.assertNotIn("rm -rf", guest)


if __name__ == "__main__":
    unittest.main()
