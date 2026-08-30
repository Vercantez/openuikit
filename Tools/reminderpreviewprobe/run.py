#!/usr/bin/env python3
"""Fail-closed unchanged-Reminder 1-to-0 #Preview diagnostic delta.

The exact app and framework base are immutable inputs. Full mode makes fresh
no-hardlink clones, builds each UIKit in a separate scratch tree, loads the
candidate's native host macro plugin explicitly, and compares complete
diagnostic multisets. Static/captured modes exercise the same pins, source
census, changed-path boundary, provenance, and tamper negatives cheaply.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import importlib.util
import os
import pathlib
import platform
import re
import shutil
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True


BASE_COMMIT = "83fbcbe2204eb836968d4e73ecfecec7b20c68ef"
SWIFT_SYNTAX_REVISION = "4799286537280063c85a32f09884cfbca301b1a1"
SWIFT_SYNTAX_TREE = "4c96b84ec6f59391ca70d18191500c14854d3d91"
OPEN_SWIFTUI_URL = "https://github.com/OpenSwiftUIProject/OpenSwiftUI.git"
OPEN_SWIFTUI_COMMIT = "7dc2cee2132bdf59d1fa0dc851121aede28f2edf"
OPEN_SWIFTUI_TREE = "dfae759d9a119afd1e5ccd5c4dfe0edc51699e85"
OPEN_SWIFTUI_MACRO_SHA256 = (
    "f506cda6af95cd94bd4e7054c022a3c760ed776d688ff526733c67078136577f"
)
OPEN_SWIFTUI_DECLARATION_SHA256 = (
    "3c7df2e251c29e396be7d1cde64994cef3e9fd343075782bc69d939e17a6acb1"
)
OPEN_SWIFTUI_LICENSE_SHA256 = (
    "e3976a926431bd88d2ababcf89764f4ae5b6e7da9be4cda979dc1e50d05f2586"
)
NATIVE_ORACLE_SOURCE_SHA256 = (
    "47a06df5611da3a0052a75950c4c9d8e79bd220293dcb5fbbde933acf8802d1a"
)
NATIVE_ORACLE_EXPANSION_SHA256 = (
    "da72eaeb522c4464ac048cc00c1680c4fe62dcc2235446c4a8526305f14e0867"
)
NATIVE_DTS_INTERFACE_SHA256 = (
    "e3204dbc116fc410ff9623abdf0c7cb01245b3c9076ded2bbeeda3b701144c88"
)
NATIVE_UIKIT_INTERFACE_SHA256 = (
    "c1c37f1c73b89a95485a8c1adc8ee82a68c722bf1181e0830d25eb5e6806f956"
)
REMINDER_INVENTORY_SHA256 = (
    "2e099b5f7b67e7f48deb9bc59219d2fede6cd138daf00a3e2f7d078822006e2b"
)
SUPPORT_COMMIT = "39643c4cf824f5ef6b62eb1d24c253e7290c0e50"
SUPPORT_TREE = "3bf0334c0dd264ec07e77d7b33aff10436be812d"
MACHORUN_COMMIT = "e6b1745bef09ac8f1e2d6e6c83f7c70d6dbe49a5"
MACHORUN_TREE = "1b41ede32d9a3ba2a5ec2d37685dc64b4eee9b43"
DOCKER_IMAGE_ID = (
    "sha256:85f9d4c5089ef811c53c55be5e8683f0f582cc9b158f9d9c5348331f3dec4044"
)
LINUX_SWIFTC_SHA256 = (
    "5a7209655c37a4f4937ea5219a4af59a7c9fc52dd13c615f26682642bc3a83ff"
)
REMINDER_PLAN_SHA256 = (
    "9d8f727b088a93514342aca4f056df8add9dcb40823bd526439f8301c6515cca"
)
REMINDER_BOOTSTRAP_SHA256 = (
    "224c87feb842c5a7bced67f6ce6a4fd1512f458f6b61090e3f11db754f424859"
)
REMINDER_SOURCE_LIST_SHA256 = (
    "964801e9db1d7e690d0bdce18c5993e23879b7f2cb3a8d2fb055108b66fd0e01"
)
REMINDER_PREPARED_INPUTS_SHA256 = (
    "0d100cac034975110e64b5c162cbc88debf178d3c6002498b7cde940e0291df8"
)

ALLOWED_CHANGED_PATHS = frozenset({
    "Package.swift",
    "Sources/DeveloperToolsSupport/Preview.swift",
    "Sources/OpenUIKitPreviewMacros/OpenUIKitPreviewMacrosPlugin.swift",
    "Sources/OpenUIKitPreviewMacros/UIKitPreviewMacro.swift",
    "Sources/UIKitShim/UIKit.swift",
    "THIRD_PARTY_LICENSES/OpenSwiftUI.txt",
    "Tools/previewprobe/Fixture/Package.swift",
    "Tools/previewprobe/Fixture/Sources/BodyNegative/BodyNegative.swift",
    "Tools/previewprobe/Fixture/Sources/NamedNegative/NamedNegative.swift",
    "Tools/previewprobe/Fixture/Sources/PreviewClient/Client.swift",
    "Tools/previewprobe/Fixture/Sources/PreviewRuntime/Runtime.swift",
    "Tools/previewprobe/Fixture/Sources/SPINegative/SPINegative.swift",
    "Tools/previewprobe/expected.txt",
    "Tools/previewprobe/run.sh",
    "Tools/reminderpreviewprobe/EntryPointShim.swift",
    "Tools/reminderpreviewprobe/guest.sh",
    "Tools/reminderpreviewprobe/run.py",
    "docs/APP_COMPAT.md",
    "docs/ARCHITECTURE.md",
    "docs/KNOWN_GAPS.md",
    "docs/PORTABILITY.md",
    "docs/PREVIEW.md",
    "docs/ROADMAP.md",
})
REQUIRED_CHANGED_PATHS = ALLOWED_CHANGED_PATHS
EXPECTED_EXECUTABLE_MODES = {
    "Tools/previewprobe/run.sh": 0o755,
    "Tools/reminderpreviewprobe/guest.sh": 0o755,
    "Tools/reminderpreviewprobe/run.py": 0o755,
}

Diagnostic = tuple[str, int, int, str]


def counter(entries: list[tuple[Diagnostic, int]]) -> collections.Counter[Diagnostic]:
    return collections.Counter(dict(entries))


REMOVED_ERRORS = counter([
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 355, 2,
      "no macro named 'Preview'"), 1),
])
ADDED_ERRORS: collections.Counter[Diagnostic] = collections.Counter()
UNCHANGED_ERRORS: collections.Counter[Diagnostic] = collections.Counter()
PREVIEW_SOURCE_LINES = {
    355: "#Preview {",
    356: "CreateViewController(initialDate: Date())",
    357: "}",
}


def load_shared_gate():
    helper = (pathlib.Path(__file__).resolve().parents[1]
              / "remindertraittextselectorprobe" / "run.py")
    spec = importlib.util.spec_from_file_location("reminder_gate_shared", helper)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load shared gate helpers: {helper}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.BASE_COMMIT = BASE_COMMIT
    module.ALLOWED_CHANGED_PATHS = ALLOWED_CHANGED_PATHS
    module.REQUIRED_CHANGED_PATHS = REQUIRED_CHANGED_PATHS
    module.REMOVED_ERRORS = REMOVED_ERRORS
    module.ADDED_ERRORS = ADDED_ERRORS
    module.UNCHANGED_ERRORS = UNCHANGED_ERRORS
    return module


G = load_shared_gate()


def require_paths(arguments: argparse.Namespace, names: tuple[str, ...]) -> None:
    missing = [name for name in names if getattr(arguments, name) is None]
    if missing:
        G.fail(f"missing required arguments for this mode: {missing}")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def validate_package_text(text: str) -> None:
    dependency = re.compile(
        r"\.package\(\s*"
        r"url:\s*\"https://github\.com/swiftlang/swift-syntax\.git\",\s*"
        rf"revision:\s*\"{SWIFT_SYNTAX_REVISION}\"\s*\)",
        re.DOTALL,
    )
    if len(dependency.findall(text)) != 1:
        G.fail("SwiftSyntax dependency is not pinned exactly once")
    required_products = (
        'name: "OpenUIKitPreviewMacros"',
        '.product(name: "SwiftCompilerPlugin", package: "swift-syntax")',
        '.product(name: "SwiftSyntax", package: "swift-syntax")',
        '.product(name: "SwiftSyntaxBuilder", package: "swift-syntax")',
        '.product(name: "SwiftSyntaxMacros", package: "swift-syntax")',
        '.target(name: "DeveloperToolsSupport")',
    )
    for spelling in required_products:
        if text.count(spelling) != 1:
            G.fail(f"Preview manifest spelling drifted: {spelling}")


def validate_provenance(candidate: pathlib.Path) -> None:
    validate_package_text((candidate / "Package.swift").read_text(encoding="utf-8"))
    license_data = (candidate / "THIRD_PARTY_LICENSES/OpenSwiftUI.txt").read_bytes()
    validate_license_data(license_data)
    preview_doc = (candidate / "docs/PREVIEW.md").read_text(encoding="utf-8")
    for pin in (
        OPEN_SWIFTUI_URL,
        OPEN_SWIFTUI_COMMIT,
        OPEN_SWIFTUI_TREE,
        OPEN_SWIFTUI_MACRO_SHA256,
        OPEN_SWIFTUI_DECLARATION_SHA256,
        OPEN_SWIFTUI_LICENSE_SHA256,
        SWIFT_SYNTAX_REVISION,
        SWIFT_SYNTAX_TREE,
        NATIVE_ORACLE_SOURCE_SHA256,
        NATIVE_ORACLE_EXPANSION_SHA256,
        NATIVE_DTS_INTERFACE_SHA256,
        NATIVE_UIKIT_INTERFACE_SHA256,
        REMINDER_INVENTORY_SHA256,
        SUPPORT_COMMIT,
        SUPPORT_TREE,
        MACHORUN_COMMIT,
        MACHORUN_TREE,
        DOCKER_IMAGE_ID,
        LINUX_SWIFTC_SHA256,
        REMINDER_PLAN_SHA256,
        REMINDER_BOOTSTRAP_SHA256,
        REMINDER_SOURCE_LIST_SHA256,
        REMINDER_PREPARED_INPUTS_SHA256,
    ):
        if preview_doc.count(pin) != 1:
            G.fail(f"Preview provenance pin missing or duplicated: {pin}")

    guest_text = (candidate / "Tools/reminderpreviewprobe/guest.sh").read_text(
        encoding="utf-8"
    )
    guest_pins = (
        BASE_COMMIT,
        SUPPORT_COMMIT,
        SUPPORT_TREE,
        MACHORUN_COMMIT,
        MACHORUN_TREE,
        G.REMINDER_COMMIT,
        G.REMINDER_TREE,
        REMINDER_INVENTORY_SHA256,
        DOCKER_IMAGE_ID,
        LINUX_SWIFTC_SHA256,
        SWIFT_SYNTAX_REVISION,
        SWIFT_SYNTAX_TREE,
        REMINDER_PLAN_SHA256,
        REMINDER_BOOTSTRAP_SHA256,
        REMINDER_SOURCE_LIST_SHA256,
        REMINDER_PREPARED_INPUTS_SHA256,
    )
    for pin in guest_pins:
        if guest_text.count(pin) != 1:
            G.fail(f"Preview guest pin missing or duplicated: {pin}")
    for spelling in (
        "full/frameworks/run_core_guest_package_docker.sh",
        "full/xcodeplan/build_portable_application_guest.sh",
        "--developer-tools-support-module",
        "--developer-tools-support-object",
        "--preview-macro-plugin",
        "--preview-plugin",
        "app-macro-expansions.stderr",
        "PORTABLE_UIKIT_HOST_LOOP_OK turns=3 paced=true",
    ):
        if guest_text.count(spelling) < 1:
            G.fail(f"Preview guest composition contract drifted: {spelling}")


def validate_license_data(data: bytes) -> None:
    if sha256(data) != OPEN_SWIFTUI_LICENSE_SHA256:
        G.fail("OpenSwiftUI license bytes drifted")


def validate_hygiene(candidate: pathlib.Path) -> None:
    forbidden_names = {".build", "Package.resolved", "__pycache__"}
    residue: list[str] = []
    for path in candidate.rglob("*"):
        try:
            relative = path.relative_to(candidate)
        except ValueError:
            continue
        if relative.parts and relative.parts[0] == ".git":
            continue
        if path.name in forbidden_names or path.suffix == ".pyc":
            residue.append(relative.as_posix())
    if residue:
        G.fail(f"candidate contains build/cache/resolution residue: {sorted(residue)}")


def validate_modes(candidate: pathlib.Path) -> None:
    for relative, expected in EXPECTED_EXECUTABLE_MODES.items():
        actual = stat.S_IMODE((candidate / relative).stat().st_mode)
        if actual != expected:
            G.fail(
                f"candidate executable mode mismatch: {relative} "
                f"expected={expected:o} actual={actual:o}"
            )


def validate_candidate_shape(candidate: pathlib.Path) -> None:
    validate_modes(candidate)
    validate_provenance(candidate)
    validate_hygiene(candidate)
    if G.git(candidate, "remote"):
        G.fail("candidate must have no remotes")
    git_path = pathlib.Path(G.git(candidate, "rev-parse", "--git-dir"))
    if not git_path.is_absolute():
        git_path = candidate / git_path
    if (git_path / "objects/info/alternates").exists():
        G.fail("candidate must have no object alternates")


def validate_delta(before: collections.Counter[Diagnostic],
                   after: collections.Counter[Diagnostic]) -> None:
    G.validate_multisets(before, after)
    if sum(before.values()) != 1 or sum(after.values()) != 0:
        G.fail("Preview diagnostic totals drifted from exact 1-to-0")


def validate_preview_source(reminder: pathlib.Path,
                            expected: dict[int, str] = PREVIEW_SOURCE_LINES) -> None:
    if len(expected) != 3:
        G.fail(f"expected exact 3-line Preview census, found {len(expected)}")
    source = reminder / "Reminder/Reminder/Scenes/Create/CreateViewController.swift"
    lines = source.read_text(encoding="utf-8").splitlines()
    for line_number, expected_line in expected.items():
        actual = lines[line_number - 1].strip()
        if actual != expected_line:
            G.fail(
                f"Preview source mismatch at {source}:{line_number}: {actual!r}"
            )


def run_tamper_negatives(reminder: pathlib.Path | None = None) -> int:
    before = REMOVED_ERRORS.copy()
    after: collections.Counter[Diagnostic] = collections.Counter()
    tamper = collections.Counter({("Tamper.swift", 1, 1, "tamper"): 1})
    probes = (
        (before - REMOVED_ERRORS, after),
        (before + tamper, after),
        (before, after + tamper),
        (before, after + REMOVED_ERRORS),
    )
    for tampered_before, tampered_after in probes:
        try:
            validate_delta(tampered_before, tampered_after)
        except RuntimeError:
            continue
        G.fail("diagnostic tamper negative was accepted")

    for bad_hash in ("0" * 64, G.SOURCE_SUBJECT_SHA256[:-1]):
        try:
            G.validate_subject_hash(bad_hash)
        except RuntimeError:
            continue
        G.fail("source-hash tamper negative was accepted")

    for changed in (
        REQUIRED_CHANGED_PATHS | {"Sources/DemoApp/Tamper.swift"},
        REQUIRED_CHANGED_PATHS - {sorted(REQUIRED_CHANGED_PATHS)[0]},
    ):
        try:
            G.validate_changed_paths(changed)
        except RuntimeError:
            continue
        G.fail("changed-path tamper negative was accepted")

    manifest = (
        '.package(url: "https://github.com/swiftlang/swift-syntax.git", '
        f'revision: "{SWIFT_SYNTAX_REVISION}")\n'
        'name: "OpenUIKitPreviewMacros"\n'
        '.product(name: "SwiftCompilerPlugin", package: "swift-syntax")\n'
        '.product(name: "SwiftSyntax", package: "swift-syntax")\n'
        '.product(name: "SwiftSyntaxBuilder", package: "swift-syntax")\n'
        '.product(name: "SwiftSyntaxMacros", package: "swift-syntax")\n'
        '.target(name: "DeveloperToolsSupport")\n'
    )
    for bad_manifest in (
        manifest.replace(SWIFT_SYNTAX_REVISION, "0" * 40),
        manifest.replace("https://github.com/swiftlang/swift-syntax.git",
                         "https://example.invalid/swift-syntax.git"),
    ):
        try:
            validate_package_text(bad_manifest)
        except RuntimeError:
            continue
        G.fail("manifest-pin tamper negative was accepted")

    try:
        validate_license_data(b"tampered license")
    except RuntimeError:
        pass
    else:
        G.fail("license tamper negative was accepted")

    count = 11
    if reminder is not None:
        missing_site = dict(G.CALL_SITE_LINES)
        missing_site.pop(next(iter(missing_site)))
        wrong_site = dict(G.CALL_SITE_LINES)
        key = next(iter(wrong_site))
        wrong_site[key] += " TAMPER"
        for sites in (missing_site, wrong_site):
            try:
                G.validate_call_sites(reminder, sites)
            except RuntimeError:
                continue
            G.fail("call-site tamper negative was accepted")
        missing_preview = dict(PREVIEW_SOURCE_LINES)
        missing_preview.pop(next(iter(missing_preview)))
        wrong_preview = dict(PREVIEW_SOURCE_LINES)
        preview_key = next(iter(wrong_preview))
        wrong_preview[preview_key] += " TAMPER"
        for preview_lines in (missing_preview, wrong_preview):
            try:
                validate_preview_source(reminder, preview_lines)
            except RuntimeError:
                continue
            G.fail("Preview-source tamper negative was accepted")
        count += 4
    return count


def build_uikit(repo: pathlib.Path, scratch: pathlib.Path) -> tuple[pathlib.Path, pathlib.Path | None]:
    subprocess.run(
        ["swift", "build", "--target", "UIKit", "--scratch-path", str(scratch),
         "--disable-index-store", "-Xswiftc", "-gnone"],
        cwd=repo, check=True,
    )
    bin_path = pathlib.Path(G.checked_output(
        ["swift", "build", "--scratch-path", str(scratch), "--show-bin-path"],
        repo,
    ))
    plugin = bin_path / "OpenUIKitPreviewMacros-tool"
    return bin_path, plugin if plugin.is_file() else None


def typecheck(reminder: pathlib.Path, uikit: pathlib.Path,
              bin_path: pathlib.Path, shim: pathlib.Path,
              plugin: pathlib.Path | None,
              dump_expansion: bool = False) -> tuple[int, str]:
    command = [
        "swiftc", "-typecheck", "-continue-building-after-errors",
        "-parse-as-library", "-module-name", "ReminderPreviewProbe",
        "-default-isolation", "MainActor", "-I", str(bin_path / "Modules"),
        "-Xcc", f"-fmodule-map-file={uikit}/Sources/CQuartz/include/module.modulemap",
        "-Xcc", f"-I{uikit}/Sources/CQuartz/include",
        "-Xcc", f"-fmodule-map-file={bin_path}/CSTBTrueType.build/module.modulemap",
        "-Xcc", f"-fmodule-map-file={bin_path}/CPortableIO.build/module.modulemap",
    ]
    if plugin is not None:
        command.extend(["-load-plugin-executable",
                        f"{plugin}#OpenUIKitPreviewMacros"])
    if dump_expansion:
        command.extend(["-Xfrontend", "-dump-macro-expansions"])
    command.extend([*G.SOURCES, str(shim)])
    result = subprocess.run(
        command, cwd=reminder, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    return result.returncode, result.stdout


def validate_expansion(output: str) -> None:
    if G.diagnostics(output):
        G.fail(f"candidate macro expansion produced diagnostics: {G.diagnostics(output)}")
    required = (
        '"Reminder/CreateViewController.swift"',
        "static var line: Int {\n        355\n    }",
        "static var column: Int {\n        1\n    }",
        "struct $s",
        ": DeveloperToolsSupport.PreviewRegistry",
        "static func makePreview() throws -> DeveloperToolsSupport.Preview",
        "DeveloperToolsSupport.Preview {",
        "CreateViewController(initialDate: Date())",
    )
    for spelling in required:
        if spelling not in output:
            G.fail(f"Reminder Preview expansion drifted: {spelling}")
    if output.count("DeveloperToolsSupport.PreviewRegistry") != 1:
        G.fail("Reminder must emit exactly one PreviewRegistry")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reminder", type=pathlib.Path)
    parser.add_argument("--base-uikit", dest="base_uikit", type=pathlib.Path)
    parser.add_argument("--candidate-uikit", dest="candidate_uikit", type=pathlib.Path)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--static-candidate", action="store_true")
    parser.add_argument("--before-output", type=pathlib.Path)
    parser.add_argument("--after-output", type=pathlib.Path)
    arguments = parser.parse_args()

    G.parser_self_test()

    if arguments.self_test:
        if any((arguments.reminder, arguments.base_uikit, arguments.candidate_uikit,
                arguments.static_candidate, arguments.before_output,
                arguments.after_output)):
            G.fail("--self-test cannot be mixed with repository or output modes")
        count = run_tamper_negatives()
        print("parser=counter-multiplicity warnings-ignored empty-after-supported")
        print(f"tamper_negatives={count}")
        print("REMINDER_PREVIEW_SELF_TEST_OK")
        return 0

    if arguments.before_output is not None or arguments.after_output is not None:
        if arguments.before_output is None or arguments.after_output is None:
            G.fail("--before-output and --after-output must be supplied together")
        if any((arguments.reminder, arguments.base_uikit,
                arguments.candidate_uikit, arguments.static_candidate)):
            G.fail("captured-output mode cannot be mixed with repository modes")
        count = run_tamper_negatives()
        before = G.diagnostics(arguments.before_output.read_text(encoding="utf-8"))
        after = G.diagnostics(arguments.after_output.read_text(encoding="utf-8"))
        validate_delta(before, after)
        print("diagnostics=1->0 removed=1 added=0 unchanged=0")
        print(f"tamper_negatives={count}")
        print("REMINDER_PREVIEW_CAPTURED_DELTA_OK")
        return 0

    if arguments.static_candidate:
        require_paths(arguments, ("reminder", "candidate_uikit"))
        if arguments.base_uikit is not None:
            G.fail("--static-candidate does not accept --base-uikit")
        reminder = arguments.reminder.resolve()
        candidate = arguments.candidate_uikit.resolve()
        G.validate_reminder_pin(reminder)
        subject_hash = G.source_subject_hash(reminder)
        G.validate_subject_hash(subject_hash)
        validate_preview_source(reminder)
        count = run_tamper_negatives(reminder)
        G.validate_candidate_worktree(candidate)
        validate_candidate_shape(candidate)
        G.run_diff_check(candidate)
        print(f"base_commit={BASE_COMMIT}")
        print(f"source_subject_sha256={subject_hash}")
        print("sources=22 call_sites=26 preview_lines=3 required_paths=23 app_edits=0")
        print(f"swift_syntax_revision={SWIFT_SYNTAX_REVISION}")
        print(f"swift_syntax_tree={SWIFT_SYNTAX_TREE}")
        print("provenance=OpenSwiftUI-exact-license-and-source-pins")
        print(f"tamper_negatives={count} modes=0755x3 residue=0")
        print("REMINDER_PREVIEW_STATIC_OK")
        return 0

    require_paths(arguments, ("reminder", "base_uikit", "candidate_uikit"))
    reminder = arguments.reminder.resolve()
    base = arguments.base_uikit.resolve()
    candidate = arguments.candidate_uikit.resolve()
    G.validate_reminder_pin(reminder)
    G.validate_base_pin(base)
    candidate_head = G.validate_candidate_commit(candidate)
    validate_candidate_shape(candidate)
    subject_hash = G.source_subject_hash(reminder)
    G.validate_subject_hash(subject_hash)
    validate_preview_source(reminder)
    count = run_tamper_negatives(reminder)

    shim = pathlib.Path(__file__).with_name("EntryPointShim.swift").resolve()
    temporary = pathlib.Path(tempfile.mkdtemp(prefix="reminder-preview-probe-"))
    keep_output = os.environ.get("REMINDER_PREVIEW_KEEP_OUTPUT", "0") == "1"
    try:
        reminder_copy = temporary / "reminder"
        base_copy = temporary / "base"
        candidate_copy = temporary / "candidate"
        G.clone(reminder, reminder_copy, G.REMINDER_COMMIT)
        G.clone(base, base_copy, BASE_COMMIT)
        base_bin, base_plugin = build_uikit(base_copy, temporary / "base-build")
        if base_plugin is not None:
            G.fail("Preview predecessor unexpectedly built a macro plugin")
        base_exit, base_output = typecheck(
            reminder_copy, base_copy, base_bin, shim, None
        )
        (temporary / "base.diagnostics.txt").write_text(
            base_output, encoding="utf-8"
        )
        shutil.rmtree(base_copy)
        shutil.rmtree(temporary / "base-build")

        G.clone(candidate, candidate_copy, candidate_head)
        candidate_bin, candidate_plugin = build_uikit(
            candidate_copy, temporary / "candidate-build"
        )
        if (candidate_plugin is None or not candidate_plugin.is_file()
                or not os.access(candidate_plugin, os.X_OK)):
            G.fail("candidate native host macro plugin is missing")
        resolved_syntax = temporary / "candidate-build/checkouts/swift-syntax"
        if G.git(resolved_syntax, "rev-parse", "HEAD") != SWIFT_SYNTAX_REVISION:
            G.fail("resolved SwiftSyntax checkout revision drifted")
        if G.git(resolved_syntax, "rev-parse", "HEAD^{tree}") != SWIFT_SYNTAX_TREE:
            G.fail("resolved SwiftSyntax checkout tree drifted")
        plugin_format = G.checked_output(["file", str(candidate_plugin)], temporary)
        if platform.system() == "Darwin":
            if "Mach-O 64-bit executable" not in plugin_format:
                G.fail(f"candidate plugin is not native Mach-O: {plugin_format}")
        elif platform.system() == "Linux":
            if "ELF 64-bit" not in plugin_format:
                G.fail(f"candidate plugin is not native ELF: {plugin_format}")
        else:
            G.fail(f"unsupported plugin host: {platform.system()}")
        candidate_exit, candidate_output = typecheck(
            reminder_copy, candidate_copy, candidate_bin, shim, candidate_plugin
        )
        expansion_exit, expansion_output = typecheck(
            reminder_copy, candidate_copy, candidate_bin, shim,
            candidate_plugin, dump_expansion=True,
        )
        plugin_sha = sha256(candidate_plugin.read_bytes())
        (temporary / "candidate.diagnostics.txt").write_text(
            candidate_output, encoding="utf-8"
        )
        (temporary / "candidate.expansion.txt").write_text(
            expansion_output, encoding="utf-8"
        )
        (temporary / "evidence.txt").write_text(
            f"base_exit={base_exit}\n"
            f"candidate_exit={candidate_exit}\n"
            f"expansion_exit={expansion_exit}\n"
            f"base_commit={BASE_COMMIT}\n"
            f"candidate_commit={candidate_head}\n"
            f"reminder_commit={G.REMINDER_COMMIT}\n"
            f"reminder_tree={G.REMINDER_TREE}\n"
            f"source_subject_sha256={subject_hash}\n"
            f"swift_syntax_revision={SWIFT_SYNTAX_REVISION}\n"
            f"swift_syntax_tree={SWIFT_SYNTAX_TREE}\n"
            f"plugin_sha256={plugin_sha}\n"
            f"plugin_format={plugin_format}\n",
            encoding="utf-8",
        )
    finally:
        if keep_output:
            print(f"REMINDER_PREVIEW_OUTPUT={temporary}", file=sys.stderr)
        else:
            shutil.rmtree(temporary)

    if base_exit == 0:
        G.fail("Preview predecessor unexpectedly compiled without diagnostics")
    if candidate_exit != 0 or candidate_output:
        G.fail(
            "Preview candidate did not typecheck with zero front-end output: "
            f"exit={candidate_exit} output={candidate_output!r}"
        )
    if expansion_exit != 0:
        G.fail(f"Reminder macro expansion failed: exit={expansion_exit}")
    validate_delta(G.diagnostics(base_output), G.diagnostics(candidate_output))
    validate_expansion(expansion_output)
    G.validate_reminder_pin(reminder)
    G.validate_base_pin(base)
    if G.validate_candidate_commit(candidate) != candidate_head:
        G.fail("candidate changed during full Preview proof")
    validate_candidate_shape(candidate)

    print(f"base_commit={BASE_COMMIT}")
    print(f"candidate_commit={candidate_head}")
    print(f"reminder_commit={G.REMINDER_COMMIT}")
    print(f"reminder_tree={G.REMINDER_TREE}")
    print(f"source_subject_sha256={subject_hash}")
    print(f"swift_syntax_revision={SWIFT_SYNTAX_REVISION}")
    print(f"swift_syntax_tree={SWIFT_SYNTAX_TREE}")
    print(f"plugin_sha256={plugin_sha}")
    print(f"expansion_sha256={sha256(expansion_output.encode('utf-8'))}")
    print("sources=22 call_sites=26 preview_lines=3 app_edits=0")
    print("diagnostics=1->0 removed=1 added=0 unchanged=0")
    G.print_counter("removed", REMOVED_ERRORS)
    print(f"tamper_negatives={count}")
    print("executable_modes=0755x3 residue=0")
    print("remaining=none")
    print("REMINDER_PREVIEW_DELTA_OK")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"REMINDER_PREVIEW_DELTA_FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
