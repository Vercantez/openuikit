import hashlib
import pathlib
import unittest


HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parents[2]
RUNTIME = ROOT / "full/foundationmodels/FoundationModels.swift"
MACROS = ROOT / "full/foundationmodels/FoundationModelsMacros.swift"
CONSUMER = HERE / "IceCubesFoundationModelsConsumer.swift"
BUILDER = HERE / "build_foundationmodels_guest_in_container.sh"
FRONTIER = HERE / "icecubes_foundationmodels_frontier.tsv"
GOLDEN = HERE / "foundationmodels-apple-26.1.txt"


class FoundationModelsFrontierTests(unittest.TestCase):
    def test_guest_source_manifest_is_exact(self):
        manifest = (
            ROOT / "full/foundationmodels/foundationmodels_guest_sources.txt"
        ).read_text(encoding="utf-8").splitlines()
        self.assertEqual(manifest, ["full/foundationmodels/FoundationModels.swift"])

    def test_runtime_is_real_data_model_and_fail_closed_service(self):
        source = RUNTIME.read_text(encoding="utf-8")
        for token in (
            "public struct GeneratedContent",
            "case structure(properties:",
            "public protocol Generable",
            "public struct GenerationSchema",
            "public struct GenerationGuide",
            "public struct ResponseStream<Content>: AsyncSequence",
            "throw LanguageModelSession.unavailableError",
            "public var isAvailable: Bool { false }",
            ".unavailable(.deviceNotEligible)",
        ):
            self.assertIn(token, source)
        self.assertNotIn("return Response(content: Content", source)
        self.assertNotIn('Response(content: "', source)

    def test_compiler_plugin_expands_schema_content_partial_and_conformance(self):
        source = MACROS.read_text(encoding="utf-8")
        for token in (
            "public struct GenerableMacro: MemberMacro, ExtensionMacro",
            "static var generationSchema",
            "var generatedContent",
            "struct PartiallyGenerated",
            "FoundationModels.Generable",
            "public struct GuideMacro: PeerMacro",
        ):
            self.assertIn(token, source)
        self.assertNotIn("import Foundation\n", source)

    def test_consumer_covers_the_exact_icecubes_calls(self):
        source = CONSUMER.read_text(encoding="utf-8")
        for token in (
            "@Generable",
            ".count(5)",
            "SystemLanguageModel.default",
            "LanguageModelSession(model: .init(useCase: .general))",
            "session.prewarm()",
            "session.respond(",
            "session.streamResponse(",
            "GenerationOptions(temperature: 0.3)",
            "LanguageModelSession.ResponseStream<String>",
        ):
            self.assertIn(token, source)

    def test_linux_arm64_builder_is_a_full_publish_and_cold_run_gate(self):
        source = BUILDER.read_text(encoding="utf-8")
        for token in (
            "TARGET=arm64-apple-ios18.0-simulator",
            "libFoundationModels.dylib",
            "libFoundationModelsMacros.so",
            "ELF 64-bit",
            "MH_MAGIC_64",
            "MACHORUN_ROOT",
            "apple-comparable.txt",
            "FOUNDATIONMODELS_ARM64_PLATFORM_OK",
        ):
            self.assertIn(token, source)
        self.assertIn("OUTPUT must not contain stale artifacts", source)
        self.assertIn("portable dylib loads Apple FoundationModels.framework", source)

    def test_upstream_frontier_is_frozen(self):
        rows = [line.split("\t") for line in FRONTIER.read_text().splitlines()]
        self.assertEqual(rows[0], ["format", "icecubes-foundationmodels-frontier-v1"])
        values = {row[0] + ":" + row[1]: row[2:] for row in rows[1:]}
        self.assertEqual(
            values["commit:b2db3033fbf67a97b54d25d6dac2df8a029b26b1"], []
        )
        source_rows = [row for row in rows if row[0] == "source"]
        self.assertEqual(len(source_rows), 2)
        self.assertEqual({int(row[3]) for row in source_rows}, {105, 979})
        for row in source_rows:
            self.assertEqual(len(row[2]), 64)
            int(row[2], 16)

    def test_apple_golden_is_narrow_and_hash_stable(self):
        contents = GOLDEN.read_bytes()
        self.assertEqual(
            hashlib.sha256(contents).hexdigest(),
            "5cabd032687f12555ddf70ba0b17c4b0bc2393a1428fa651b41b28601a2f6c49",
        )
        self.assertEqual(len(contents.splitlines()), 4)


if __name__ == "__main__":
    unittest.main()
