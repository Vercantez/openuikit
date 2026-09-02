#!/usr/bin/env python3
"""Static teeth for the raw-swiftc census/generated-build boundary."""

import hashlib
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("build_census.sh")
CENSUS = Path(__file__).with_name("census-swiftui-s15-2026-08-28.txt")
SUBJECT_TOOL = Path(__file__).with_name("focus_subject.py")


class BuildCensusTests(unittest.TestCase):
    def test_exact_main_driver_is_fresh_pinned_and_not_the_broad_row(self) -> None:
        driver = (SCRIPT.parent / "build_exact_main_census.sh").read_text()
        build = SCRIPT.read_text()
        self.assertIn("CENSUS_SOURCE_MODE=exact-main", driver)
        self.assertIn("--expected-support-commit", driver)
        self.assertIn("--expected-uikit-commit", driver)
        self.assertIn("[ ! -e \"$OUTPUT\" ]", driver)
        self.assertIn('CENSUS_SOURCE_MODE=${CENSUS_SOURCE_MODE:-broad}', build)
        self.assertIn('TARGET=arm64-apple-macos15.0', build)
        self.assertIn('exact-main target must be arm64-apple-macos15.0', build)
        self.assertIn('"$HERE/focus_main_sources.py"', build)
        self.assertIn('"${#files[@]}" -eq 129', build)
        self.assertIn('"$OUT/logs/exact-main.log"', build)
        self.assertIn('"$OUT/exact-main-primary.tsv"', build)
        self.assertIn('diagnostics\\traw-log-sha256', build)
        self.assertIn("printf 'target\\t%s\\n' \"$TARGET\"", build)
        self.assertIn('"$OUT/exact-main-delta.tsv"', build)
        self.assertIn('"$HERE/diagnostics.py" delta', build)
        self.assertIn('git clone -q --no-hardlinks', build)
        self.assertIn('git -C "$SML" archive HEAD:uikit', build)
        self.assertIn('assert_vendor_tree "$SML" uikit', build)
        self.assertIn('HEAD:uikit', build)
        self.assertIn('format\\tfocus-exact-main-census-v1', build)

    def test_bundle_accessor_is_narrow_generated_build_support(self) -> None:
        text = SCRIPT.read_text()
        self.assertIn("DesignSystem|Widget|Licenses|Onboarding", text)
        self.assertIn("$OUT/generated-build-support/$target", text)
        self.assertIn("Generated build support: normalized Bundle.module census accessor", text)
        self.assertIn('fatalError("compile-only census accessor")', text)

    def test_generated_accessor_is_an_extra_compiler_input_not_an_app_copy(self) -> None:
        text = SCRIPT.read_text()
        self.assertIn('srcs+=("$accessor")', text)
        self.assertIn('find "$srcdir" -name \'*.swift\' -print0', text)
        self.assertNotRegex(
            text,
            r"(?m)^\s*(cp|mv|sed|perl)\b.*(?:\$APP|\$P)/",
        )

    def test_every_census_compile_remains_whole_module_optimization(self) -> None:
        text = SCRIPT.read_text()
        self.assertIn("-wmo -target", text)
        self.assertIn("swiftc -typecheck -wmo", text)

    def test_first_party_attribution_is_opt_in_and_provenance_gated(self) -> None:
        text = SCRIPT.read_text()
        self.assertIn("FIRST_PARTY_FRAMEWORKS_SRC=${FIRST_PARTY_FRAMEWORKS_SRC:-}", text)
        self.assertIn('if [ -n "$FIRST_PARTY_FRAMEWORKS_SRC" ]; then', text)
        provenance = text.index('python3 -B "$FIRST_PARTY_TOOL" production')
        compiler = text.index(
            'build_mod_list "$framework" "first-party-$framework" "$resolved"'
        )
        self.assertLess(provenance, compiler)
        for framework in (
            "LocalAuthentication",
            "SafariServices",
            "Network",
            "StoreKit",
            "AudioToolbox",
            "CoreHaptics",
            "PassKit",
        ):
            self.assertIn(framework, text)

    def test_webkit_is_the_attested_production_module_not_a_focus_stub(self) -> None:
        text = SCRIPT.read_text()
        webkit = SCRIPT.parents[1] / "webkit"
        self.assertFalse((SCRIPT.parent / "stubs/WebKit/WebKit.swift").exists())
        self.assertEqual(
            (webkit / "webkit_guest_sources.txt").read_text().splitlines(),
            [
                "full/webkit/WebKitError.swift",
                "full/webkit/WebKitConfiguration.swift",
                "full/webkit/WebKitContent.swift",
                "full/webkit/WebKitNavigation.swift",
                "full/webkit/WebKitWebView.swift",
            ],
        )
        self.assertIn("build_mod_list WebKit webkit", text)
        self.assertEqual(text.count('"$WEBKIT_PROVENANCE" production'), 2)
        self.assertEqual(text.count('"$WEBKIT_PROVENANCE" focus'), 2)
        self.assertIn('cmp -s "$OUT/webkit-sources-before.tsv"', text)
        self.assertIn('cmp -s "$OUT/focus-webkit-before.tsv"', text)

    def test_focus_subject_is_attested_before_and_after_all_compilers(self) -> None:
        text = SCRIPT.read_text()
        before = text.index('"$OUT/focus-subject-before.json"')
        broad_compile = text.index("swiftc -typecheck -wmo")
        after = text.index('"$OUT/focus-subject-after.json"')
        classification = text.index('"$HERE/classify.py"')
        self.assertLess(before, broad_compile)
        self.assertLess(broad_compile, after)
        self.assertLess(after, classification)
        self.assertIn(
            'cmp -s "$OUT/focus-subject-before.json" '
            '"$OUT/focus-subject-after.json"',
            text,
        )

    def test_focus_subject_rejects_status_hidden_and_ignored_swift_changes(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            repo = Path(temporary) / "focus"
            app = repo / "focus-ios"
            source = app / "Sources" / "Screen.swift"
            source.parent.mkdir(parents=True)
            source.write_text("struct Screen {}\n")
            (app / "Package.swift").write_text("// package\n")
            (repo / ".gitignore").write_text("focus-ios/ignored/\n")
            self.git(repo, "init", "-q")
            self.git(repo, "add", ".")
            self.git(
                repo,
                "-c",
                "user.name=Census Test",
                "-c",
                "user.email=census@example.invalid",
                "commit",
                "-qm",
                "fixture",
            )
            revision = self.git(repo, "rev-parse", "HEAD").stdout.strip()
            report = Path(temporary) / "subject.json"

            clean = self.subject(app, revision, report)
            self.assertEqual(clean.returncode, 0, clean.stderr)
            clean_report = json.loads(report.read_text())
            self.assertEqual(clean_report["swift_source_count"], 2)
            self.assertRegex(clean_report["swift_subject_sha256"], r"^[0-9a-f]{64}$")

            self.git(repo, "update-index", "--assume-unchanged", "focus-ios/Sources/Screen.swift")
            source.write_text("struct EditedScreen {}\n")
            hidden = self.subject(app, revision, report)
            self.assertNotEqual(hidden.returncode, 0)
            self.assertIn("bytes differ from pinned commit", hidden.stderr)

            source.write_text("struct Screen {}\n")
            self.git(repo, "update-index", "--no-assume-unchanged", "focus-ios/Sources/Screen.swift")
            self.git(repo, "update-index", "--skip-worktree", "focus-ios/Sources/Screen.swift")
            source.write_text("struct SkipWorktreeEdit {}\n")
            skipped = self.subject(app, revision, report)
            self.assertNotEqual(skipped.returncode, 0)
            self.assertIn("bytes differ from pinned commit", skipped.stderr)

            source.write_text("struct Screen {}\n")
            self.git(repo, "update-index", "--no-skip-worktree", "focus-ios/Sources/Screen.swift")
            ignored = app / "ignored" / "Injected.swift"
            ignored.parent.mkdir()
            ignored.write_text("struct Injected {}\n")
            injected = self.subject(app, revision, report)
            self.assertNotEqual(injected.returncode, 0)
            self.assertIn("inventory differs from the pinned tree", injected.stderr)

    def test_reviewed_s15_classification_is_pinned(self) -> None:
        payload = CENSUS.read_bytes()
        self.assertEqual(
            hashlib.sha256(payload).hexdigest(),
            "667821b62719a422997f4b364a5c71d082fbc4568ae000b049f59311e75a1f03",
        )
        text = payload.decode()
        self.assertIn("target-DesignSystem            0 primary diagnostics", text)
        self.assertIn("target-Onboarding             64 primary diagnostics", text)
        self.assertIn("app                          696 primary diagnostics", text)

    def subject(self, app: Path, revision: str, output: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["python3", str(SUBJECT_TOOL), str(app), revision, str(output)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def git(self, repo: Path, *arguments: str) -> subprocess.CompletedProcess[str]:
        environment = os.environ.copy()
        environment.setdefault("GIT_CONFIG_NOSYSTEM", "1")
        return subprocess.run(
            ["git", "-C", str(repo), *arguments],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=environment,
            check=True,
        )


if __name__ == "__main__":
    unittest.main()
