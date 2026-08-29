#!/usr/bin/env python3
"""Positive, adversarial, and exact controls for resource normalization."""

from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import platform
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import onboarding_resources_proof as subject


HERE = Path(__file__).resolve().parent
SWIFT_MACHO_LINUX = HERE.parent.parent
FOCUS_SOURCE = SWIFT_MACHO_LINUX / "scratch" / "ladder-corpus" / "focus-ios"
POLICY_PATH = HERE / "onboarding-resources-proof.json"


def run(command: list[str]) -> None:
    result = subprocess.run(
        command,
        check=False,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=subject.GIT_ENVIRONMENT,
    )
    if result.returncode:
        raise AssertionError(result.stderr.decode("utf-8", errors="replace"))


def clone_focus(destination: Path) -> Path:
    run(["/usr/bin/git", "clone", "--quiet", "--shared", "--no-checkout", str(FOCUS_SOURCE), str(destination)])
    run([
        "/usr/bin/git", "-c", "core.fsmonitor=false", "-c", f"core.hooksPath={os.devnull}",
        "-C", str(destination), "checkout", "--quiet", "--detach", subject.FOCUS_COMMIT,
    ])
    return destination / subject.FOCUS_PREFIX


def has_reviewed_rasterizer() -> bool:
    try:
        subject.discover_rasterizer(subject.expected_policy())
    except (OSError, subject.ProofError):
        return False
    return True


class PolicyAndPrimitiveTests(unittest.TestCase):
    def setUp(self) -> None:
        self.raw, self.policy = subject.load_policy(POLICY_PATH)

    def test_policy_is_exact_canonical_and_narrow(self) -> None:
        self.assertEqual(self.policy, subject.expected_policy())
        self.assertEqual(self.raw, subject.canonical_json(self.policy))
        self.assertEqual(sum(item["file_count"] for item in self.policy["catalogs"].values()), 23)
        self.assertEqual(sum(item["byte_count"] for item in self.policy["catalogs"].values()), 32_428_522)
        self.assertEqual(len(self.policy["normalization"]["pdf_outputs"]), 24)
        self.assertEqual(len(self.policy["normalization"]["symbol_outputs"]), 12)
        claims = self.policy["claims"]
        self.assertFalse(claims["actool_or_asset_car_emission"])
        self.assertFalse(claims["apple_bundle_equivalence"])
        self.assertFalse(claims["foundation_or_ui_framework_runtime_lookup"])
        self.assertFalse(claims["current_openuikit_automatic_luminosity_image_selection"])
        self.assertFalse(claims["current_openuikit_system_symbol_api"])
        self.assertTrue(claims["current_openuikit_loose_image_layout"])
        self.assertEqual(
            claims["cross_host_reproducibility"],
            "bounded-to-exact-reviewed-outputs-on-two-observed-front-end-profiles",
        )
        self.assertFalse(claims["rasterizer_dependency_byte_identity"])
        self.assertFalse(claims["rasterizer_path_immutability_during_rendering"])

    def test_policy_drift_and_path_widening_refuse(self) -> None:
        changed = copy.deepcopy(self.policy)
        changed["normalization"]["pdf_outputs"]["Onboarding/icon_logo/default/1x"]["sha256"] = "0" * 64
        with self.assertRaisesRegex(subject.ProofError, "reviewed Focus resource policy"):
            subject.validate_policy(changed)
        changed = copy.deepcopy(self.policy)
        changed["catalogs"]["onboarding-images"]["root"] = "../escape"
        with self.assertRaisesRegex(subject.ProofError, "reviewed Focus resource policy"):
            subject.validate_policy(changed)
        with tempfile.TemporaryDirectory(prefix="focus-resource-policy.") as temporary:
            noncanonical = Path(temporary) / "policy.json"
            noncanonical.write_text(json.dumps(self.policy), encoding="utf-8")
            with self.assertRaisesRegex(subject.ProofError, "not canonical"):
                subject.load_policy(noncanonical)

    def test_stale_output_is_preserved_and_refused(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-resource-output.") as temporary:
            output = Path(temporary) / "proof"
            output.mkdir()
            sentinel = output / "keep"
            sentinel.write_bytes(b"user data")
            with self.assertRaisesRegex(subject.ProofError, "stale proof output"):
                subject._resolve_new_output(str(output))
            self.assertEqual(sentinel.read_bytes(), b"user data")

        in_repo = HERE / "onboarding-resources-forbidden-output"
        self.assertFalse(in_repo.exists())
        with self.assertRaisesRegex(subject.ProofError, "outside source and policy repositories"):
            subject._resolve_new_output(str(in_repo), (SWIFT_MACHO_LINUX, FOCUS_SOURCE))
        self.assertFalse(in_repo.exists())

    def test_unsafe_output_parent_refuses(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-resource-parent.") as temporary:
            unsafe = Path(temporary) / "unsafe"
            unsafe.mkdir(mode=0o700)
            unsafe.chmod(0o777)
            with self.assertRaisesRegex(subject.ProofError, "owned.*private mode 0700"):
                subject._resolve_new_output(str(unsafe / "proof"))

    @unittest.skipUnless(sys.platform == "darwin", "macOS ACL semantics")
    def test_acl_bearing_output_parent_refuses(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-resource-acl.") as temporary:
            parent = Path(temporary) / "parent"
            parent.mkdir(mode=0o700)
            run(["/bin/chmod", "+a", "everyone allow read,write", str(parent)])
            try:
                with self.assertRaisesRegex(subject.ProofError, "extended ACL"):
                    subject._resolve_new_output(str(parent / "proof"))
            finally:
                run(["/bin/chmod", "-N", str(parent)])

    def test_original_symbols_are_deterministic_rgba_with_alpha(self) -> None:
        policy_outputs = self.policy["normalization"]["symbol_outputs"]
        for target, mapping in subject.SYMBOL_MAPPINGS.items():
            for name in mapping:
                for scale in subject.SCALES:
                    first = subject.generate_symbol_png(name, scale)
                    second = subject.generate_symbol_png(name, scale)
                    self.assertEqual(first, second)
                    inspected = subject.inspect_png(first)
                    key = subject._output_key(target, name, "default", scale)
                    self.assertEqual(subject._reviewed_png_subset({"path": policy_outputs[key]["path"], **inspected}), policy_outputs[key])
                    self.assertEqual(inspected["color_type"], "rgba")
                    self.assertEqual(inspected["alpha"]["minimum"], 0)
                    self.assertEqual(inspected["alpha"]["maximum"], 255)
                    self.assertGreater(inspected["alpha"]["partial_pixels"], 0)

    def test_png_crc_and_payload_tampering_refuse(self) -> None:
        data = bytearray(subject.generate_symbol_png("magnifyingglass", 1))
        data[-5] ^= 1
        with self.assertRaisesRegex(subject.ProofError, "CRC"):
            subject.inspect_png(bytes(data))
        with self.assertRaisesRegex(subject.ProofError, "truncated|terminator"):
            subject.inspect_png(subject.generate_symbol_png("magnifyingglass", 1)[:-3])

    def test_environment_and_profile_discovery_do_not_trust_path(self) -> None:
        with patch.dict(os.environ, {"PATH": "/tmp/fake-bin", "LD_PRELOAD": "/tmp/fake.so", "DYLD_INSERT_LIBRARIES": "/tmp/fake.dylib"}, clear=False):
            environment = dict(subject.SAFE_ENVIRONMENT)
        self.assertEqual(environment["PATH"], "/usr/bin:/bin")
        self.assertNotIn("LD_PRELOAD", environment)
        self.assertNotIn("DYLD_INSERT_LIBRARIES", environment)
        matches = [
            item for item in self.policy["rasterizer_profiles"]
            if item["system"] == platform.system() and item["machine"] == platform.machine()
        ]
        if matches and Path(matches[0]["path"]).is_file():
            rasterizer = subject.discover_rasterizer(self.policy)
            self.assertEqual(rasterizer.profile, matches[0])
            self.assertEqual(subject.sha256(rasterizer.version), matches[0]["version_sha256"])
            provenance = rasterizer.audit()["provenance_scope"]
            self.assertFalse(provenance["dependency_bytes_hashed"])
            self.assertFalse(provenance["path_continuously_attested_between_discoveries"])

    def test_linux_loader_report_removes_only_aslr_addresses(self) -> None:
        first = b"\tlibcairo.so.2 => /lib/libcairo.so.2 (0x0000aaaa)\n\tlinux-vdso.so.1 (0xffff0000)\n"
        second = b"\tlibcairo.so.2 => /lib/libcairo.so.2 (0x0000bbbb)\n\tlinux-vdso.so.1 (0xffff1111)\n"
        self.assertEqual(
            subject._canonicalize_loader_report(first, "Linux"),
            subject._canonicalize_loader_report(second, "Linux"),
        )
        canonical = subject._canonicalize_loader_report(first, "Linux")
        self.assertIn(b"libcairo.so.2 => /lib/libcairo.so.2", canonical)
        self.assertNotIn(b"0x0000aaaa", canonical)
        self.assertEqual(subject._canonicalize_loader_report(first, "Darwin"), first)


@unittest.skipUnless(FOCUS_SOURCE.is_dir(), "pinned Focus repository is unavailable")
class FocusCaptureAndMappingTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory(prefix="focus-resource-source.")
        self.root = Path(self.temporary.name)
        self.repo = clone_focus(self.root / "focus")
        _, self.policy = subject.load_policy(POLICY_PATH)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_exact_complete_capture_and_catalog_semantics(self) -> None:
        capture = subject.capture_focus(self.repo, self.policy)
        self.assertEqual(capture.commit, subject.FOCUS_COMMIT)
        self.assertEqual(capture.ignored_untracked_file_count, 0)
        self.assertEqual(capture.ignored_untracked_state_sha256, subject.sha256(b""))
        self.assertEqual(len(capture.catalog_files), 23)
        self.assertEqual(sum(len(item.data) for item in capture.catalog_files), 32_428_522)
        self.assertEqual(len(capture.lookup_sources), 3)
        subject.verify_lookup_sources(capture)
        subject.verify_image_catalog_mappings(capture)
        onboarding = subject.parse_color_catalog(capture, "onboarding-colors", subject.COLOR_MAPPINGS["Onboarding"]["names"])
        widget = subject.parse_color_catalog(capture, "widget-media", subject.COLOR_MAPPINGS["Widget"]["names"])
        self.assertEqual(onboarding["actionButton"]["default"]["rgba8"], [0, 96, 223, 255])
        self.assertEqual(onboarding["actionButton"]["dark"]["rgba8"], [0, 221, 255, 255])
        self.assertEqual(widget["GradientFirst"]["default"]["rgba8"], [89, 42, 203, 255])
        self.assertEqual(widget["GradientFirst"]["dark"]["rgba8"], [43, 42, 51, 255])

    def test_default_and_dark_pdf_mapping_is_exact(self) -> None:
        capture = subject.capture_focus(self.repo, self.policy)
        subject.verify_image_catalog_mappings(capture)
        mappings = {(item[0], item[1], item[2]): Path(item[3]).name for item in subject.PDF_MAPPINGS}
        self.assertEqual(mappings[("Onboarding", "icon_background", "default")], "icon_onboarding_background.pdf")
        self.assertEqual(mappings[("Onboarding", "icon_background", "dark")], "background_icon_dark.pdf")
        self.assertEqual(mappings[("Onboarding", "icon_close", "default")], "icon_close_light.pdf")
        self.assertEqual(mappings[("Onboarding", "icon_close", "dark")], "icon_close.pdf")

    def test_hidden_byte_drift_and_extra_catalog_file_refuse(self) -> None:
        record = self.policy["catalogs"]["onboarding-images"]["files"][0]
        git_path = f"{subject.FOCUS_PREFIX}/{record['path']}"
        path = self.repo / record["path"]
        original = path.read_bytes()
        run(["/usr/bin/git", "-C", str(self.repo.parent), "update-index", "--assume-unchanged", "--", git_path])
        path.write_bytes(original + b"drift")
        try:
            with self.assertRaisesRegex(
                subject.ProofError, "assume-unchanged or skip-worktree",
            ):
                subject.capture_focus(self.repo, self.policy)
        finally:
            path.write_bytes(original)
            run([
                "/usr/bin/git", "-C", str(self.repo.parent), "update-index",
                "--no-assume-unchanged", "--", git_path,
            ])

        extra = self.repo / subject.CATALOGS["onboarding-images"]["root"] / "extra.pdf"
        extra.write_bytes(b"untracked catalog widening")
        with self.assertRaisesRegex(subject.ProofError, "worktree is not clean|filesystem inventory"):
            subject.capture_focus(self.repo, self.policy)

    def test_ignored_generated_xcode_source_refuses(self) -> None:
        relative = f"{subject.FOCUS_PREFIX}/Blockzilla/Generated/AppNimbus.swift"
        generated = self.repo / "Blockzilla/Generated/AppNimbus.swift"
        generated.parent.mkdir(parents=True, exist_ok=True)
        generated.write_bytes(b'func ignoredGeneratedSource() { fatalError("must refuse") }\n')

        self.assertEqual(
            subject._git(
                self.repo.parent,
                ["status", "--porcelain=v1", "-z", "--untracked-files=all"],
            ),
            b"",
        )
        ignored = subject._git(
            self.repo.parent,
            ["ls-files", "--others", "--ignored", "--exclude-standard", "-z"],
        ).split(b"\0")
        self.assertIn(relative.encode("utf-8"), ignored)
        with self.assertRaisesRegex(subject.ProofError, "ignored untracked file"):
            subject.capture_focus(self.repo, self.policy)

    def test_unrelated_focus_source_edit_refuses(self) -> None:
        unrelated = self.repo / "Shared/AppInfo.swift"
        git_path = f"{subject.FOCUS_PREFIX}/Shared/AppInfo.swift"
        original = unrelated.read_bytes()
        run([
            "/usr/bin/git", "-C", str(self.repo.parent), "update-index",
            "--assume-unchanged", "--", git_path,
        ])
        unrelated.write_bytes(original + b"\n// resource proof drift\n")
        try:
            with self.assertRaisesRegex(
                subject.ProofError, "assume-unchanged or skip-worktree",
            ):
                subject.capture_focus(self.repo, self.policy)
        finally:
            unrelated.write_bytes(original)
            run([
                "/usr/bin/git", "-C", str(self.repo.parent), "update-index",
                "--no-assume-unchanged", "--", git_path,
            ])

    def test_stage_is_byte_exact_and_post_stage_tampering_refuses(self) -> None:
        capture = subject.capture_focus(self.repo, self.policy)
        output = self.root / "stage"
        output.mkdir(mode=0o700)
        records = subject.stage_inputs(output, capture)
        self.assertEqual(len(records), 27)
        subject.verify_staged_inputs(output, capture, records)
        staged = output / records[0]["stage_path"]
        self.assertEqual(staged.stat().st_mode & 0o777, 0o444)
        with self.assertRaises(PermissionError):
            staged.write_bytes(b"compiler-time tamper")
        staged.chmod(0o644)
        staged.write_bytes(staged.read_bytes() + b"tamper")
        with self.assertRaisesRegex(subject.ProofError, "became writable|staged input bytes changed"):
            subject.verify_staged_inputs(output, capture, records)


@unittest.skipUnless(
    FOCUS_SOURCE.is_dir() and has_reviewed_rasterizer(),
    "exact integration requires the pinned Focus checkout and reviewed Poppler profile",
)
class ExactNormalizationIntegrationTest(unittest.TestCase):
    def test_exact_resource_normalization_and_loose_layout(self) -> None:
        with tempfile.TemporaryDirectory(prefix="focus-resource-integration.") as temporary:
            root = Path(temporary)
            repo = clone_focus(root / "focus")
            output = root / "proof"
            audit = subject.prove(str(repo), str(POLICY_PATH), str(output))
            self.assertEqual(audit["focus"]["catalog_file_count"], 23)
            self.assertEqual(audit["focus"]["catalog_byte_count"], 32_428_522)
            self.assertEqual(audit["focus"]["ignored_untracked_file_count"], 0)
            self.assertEqual(audit["focus"]["ignored_untracked_state_sha256"], subject.sha256(b""))
            self.assertEqual(len(audit["staged_inputs"]), 27)
            self.assertEqual(len(audit["rasterizer_invocations"]), 24)
            self.assertEqual(len(audit["pdf_outputs"]), 24)
            self.assertEqual(len(audit["original_symbol_outputs"]), 12)
            self.assertEqual(len(audit["current_openuikit_loose_aliases"]), 36)
            self.assertEqual(len(audit["raw_color_catalog_copies"]), 8)
            self.assertEqual(len(audit["resource_indexes"]), 2)
            self.assertEqual(audit["focus"]["shipping_source_edits"], [])
            provenance = audit["rasterizer"]["provenance_scope"]
            self.assertFalse(provenance["dependency_bytes_hashed"])
            self.assertFalse(provenance["path_continuously_attested_between_discoveries"])

            onboarding = output / "bundles" / "Focus_Onboarding.bundle"
            widget = output / "bundles" / "Focus_Widget.bundle"
            self.assertTrue((onboarding / "Colors.xcassets/actionButton.colorset/Contents.json").is_file())
            self.assertTrue((widget / "Media.xcassets/GradientFirst.colorset/Contents.json").is_file())
            self.assertEqual((onboarding / "icon_background.png").read_bytes(), (onboarding / "images/icon_background/default@1x.png").read_bytes())
            self.assertEqual((onboarding / "icon_background.dark.png").read_bytes(), (onboarding / "images/icon_background/dark@1x.png").read_bytes())
            self.assertEqual((onboarding / "icon_close.png").read_bytes(), (onboarding / "images/icon_close/default@1x.png").read_bytes())
            self.assertEqual((onboarding / "icon_close.dark.png").read_bytes(), (onboarding / "images/icon_close/dark@1x.png").read_bytes())
            self.assertEqual((onboarding / "step_one.png").read_bytes(), (onboarding / "symbols/1.circle.fill/default@1x.png").read_bytes())
            self.assertEqual((widget / "icon_magnifying_glass.png").read_bytes(), (widget / "symbols/magnifyingglass/default@1x.png").read_bytes())
            self.assertFalse((onboarding / "1.circle.fill.png").exists())

            default_logo = subject.resolve_indexed_resource(output, "Onboarding", "images", "icon_logo", "default", 2)
            dark_fallback_logo = subject.resolve_indexed_resource(output, "Onboarding", "images", "icon_logo", "dark", 2)
            self.assertEqual(default_logo, dark_fallback_logo)
            index = subject.load_index(output, "Onboarding")
            status = index["runtime_loader_status"]
            self.assertIn("manual/overlay", status["dark_loose_images"])
            self.assertIn("not wired", status["system_symbol_replacements"])
            self.assertIn("proof-only", status["explicit_index"])

            audit_path = output / "onboarding-resources-audit.json"
            self.assertEqual(json.loads(audit_path.read_bytes()), audit)


if __name__ == "__main__":
    unittest.main()
