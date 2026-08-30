#!/usr/bin/env python3
"""Fail-closed unchanged-Reminder 2-to-1 Notification identity delta.

The exact app and framework base are immutable inputs. Full mode makes fresh
no-hardlink clones, serially rebuilds literal UIKit, and compares complete
diagnostic multisets. Static/captured modes exercise the same pins, source
census, changed-path boundary, parsers, and tamper negatives cheaply.
"""

from __future__ import annotations

import argparse
import collections
import importlib.util
import pathlib
import shutil
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True


BASE_COMMIT = "b8531df000f35a4580a9f239bb0348d04552053f"

ALLOWED_CHANGED_PATHS = frozenset({
    "Sources/OpenUIKit/FoundationTypes.swift",
    "Sources/OpenUIKit/NotificationCenter.swift",
    "Sources/OpenUIKit/UIApplication.swift",
    "Sources/OpenUIKit/UITextField.swift",
    "Sources/OpenUIKit/Timer.swift",
    "Sources/UIKitShim/UIKit.swift",
    "Tests/OpenUIKitTests/ActorIsolationTests.swift",
    "Tests/OpenUIKitTests/NotificationFoundationExtensionProbe.swift",
    "Tests/OpenUIKitTests/NotificationSourceCompatibilityTests.swift",
    "Tests/OpenUIKitTests/NotificationTimerTests.swift",
    "Tests/OpenUIKitTests/NotificationUIKitOnlyConsumerProbe.swift",
    "Tools/notificationbridgeprobe/Info.plist",
    "Tools/notificationbridgeprobe/expected.txt",
    "Tools/notificationbridgeprobe/foundation-extension.swift",
    "Tools/notificationbridgeprobe/foundation-shim.swift",
    "Tools/notificationbridgeprobe/focus-client.swift",
    "Tools/notificationbridgeprobe/guest.expected.txt",
    "Tools/notificationbridgeprobe/guest.sh",
    "Tools/notificationbridgeprobe/guest.swift",
    "Tools/notificationbridgeprobe/main.swift",
    "Tools/notificationbridgeprobe/native-elf.expected.txt",
    "Tools/notificationbridgeprobe/native-elf.swift",
    "Tools/notificationbridgeprobe/run.sh",
    "Tools/remindernotificationprobe/EntryPointShim.swift",
    "Tools/remindernotificationprobe/run.py",
    "docs/APP_COMPAT.md",
    "docs/ARCHITECTURE.md",
    "docs/KNOWN_GAPS.md",
    "docs/OBJC_RUNTIME.md",
    "docs/PORTABILITY.md",
    "docs/REAL_APP_TEST.md",
    "docs/ROADMAP.md",
})
REQUIRED_CHANGED_PATHS = ALLOWED_CHANGED_PATHS
EXPECTED_EXECUTABLE_MODES = {
    "Tools/notificationbridgeprobe/guest.sh": 0o755,
    "Tools/notificationbridgeprobe/run.sh": 0o755,
    "Tools/remindernotificationprobe/run.py": 0o755,
}

Diagnostic = tuple[str, int, int, str]


def counter(entries: list[tuple[Diagnostic, int]]) -> collections.Counter[Diagnostic]:
    return collections.Counter(dict(entries))


REMOVED_ERRORS = counter([
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 233, 62,
      "'Notification' is ambiguous for type lookup in this context"), 1),
])
ADDED_ERRORS: collections.Counter[Diagnostic] = collections.Counter()
UNCHANGED_ERRORS = counter([
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 355, 2,
      "no macro named 'Preview'"), 1),
])


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


def validate_executable_modes(candidate: pathlib.Path) -> None:
    for relative, expected in EXPECTED_EXECUTABLE_MODES.items():
        actual = stat.S_IMODE((candidate / relative).stat().st_mode)
        if actual != expected:
            G.fail(
                f"candidate executable mode mismatch: {relative} "
                f"expected={expected:o} actual={actual:o}"
            )


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
        G.run_tamper_negatives()
        print("parser=counter-multiplicity warnings-ignored")
        print("REMINDER_NOTIFICATION_SELF_TEST_OK")
        return 0

    if arguments.before_output is not None or arguments.after_output is not None:
        if arguments.before_output is None or arguments.after_output is None:
            G.fail("--before-output and --after-output must be supplied together")
        if any((arguments.reminder, arguments.base_uikit,
                arguments.candidate_uikit, arguments.static_candidate)):
            G.fail("captured-output mode cannot be mixed with repository modes")
        G.run_tamper_negatives()
        before = G.diagnostics(arguments.before_output.read_text(encoding="utf-8"))
        after = G.diagnostics(arguments.after_output.read_text(encoding="utf-8"))
        G.validate_multisets(before, after)
        print("diagnostics=2->1 removed=1 added=0 unchanged=1")
        print("REMINDER_NOTIFICATION_CAPTURED_DELTA_OK")
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
        G.run_tamper_negatives(reminder)
        G.validate_candidate_worktree(candidate)
        validate_executable_modes(candidate)
        G.run_diff_check(candidate)
        print(f"base_commit={BASE_COMMIT}")
        print(f"source_subject_sha256={subject_hash}")
        print("sources=22 call_sites=26 required_paths=32 app_edits=0")
        print("parser=counter-multiplicity diff_check=clean modes=0755x3 "
              "tamper_negatives=10")
        print("REMINDER_NOTIFICATION_STATIC_OK")
        return 0

    require_paths(arguments, ("reminder", "base_uikit", "candidate_uikit"))
    reminder = arguments.reminder.resolve()
    base = arguments.base_uikit.resolve()
    candidate = arguments.candidate_uikit.resolve()
    G.validate_reminder_pin(reminder)
    G.validate_base_pin(base)
    candidate_head = G.validate_candidate_commit(candidate)
    validate_executable_modes(candidate)
    subject_hash = G.source_subject_hash(reminder)
    G.validate_subject_hash(subject_hash)
    G.run_tamper_negatives(reminder)

    shim = pathlib.Path(__file__).with_name("EntryPointShim.swift").resolve()
    with tempfile.TemporaryDirectory(prefix="reminder-notification-probe-") as raw:
        temporary = pathlib.Path(raw)
        reminder_copy = temporary / "reminder"
        base_copy = temporary / "base"
        candidate_copy = temporary / "candidate"
        G.clone(reminder, reminder_copy, G.REMINDER_COMMIT)
        G.clone(base, base_copy, BASE_COMMIT)
        base_bin = G.build_uikit(base_copy)
        base_exit, base_output = G.typecheck(
            reminder_copy, base_copy, base_bin, shim
        )
        shutil.rmtree(base_copy)
        G.clone(candidate, candidate_copy, candidate_head)
        candidate_bin = G.build_uikit(candidate_copy)
        candidate_exit, candidate_output = G.typecheck(
            reminder_copy, candidate_copy, candidate_bin, shim
        )

    if base_exit == 0 or candidate_exit == 0:
        G.fail("compatibility census unexpectedly had no diagnostics")
    G.validate_multisets(G.diagnostics(base_output), G.diagnostics(candidate_output))

    print(f"base_commit={BASE_COMMIT}")
    print(f"candidate_commit={candidate_head}")
    print(f"reminder_commit={G.REMINDER_COMMIT}")
    print(f"reminder_tree={G.REMINDER_TREE}")
    print(f"source_subject_sha256={subject_hash}")
    print("sources=22 call_sites=26 app_edits=0")
    print("diagnostics=2->1 removed=1 added=0 unchanged=1")
    G.print_counter("removed", REMOVED_ERRORS)
    G.print_counter("added", ADDED_ERRORS)
    G.print_counter("unchanged", UNCHANGED_ERRORS)
    print("tamper_negatives=10")
    print("executable_modes=0755x3")
    print("remaining=Preview")
    print("REMINDER_NOTIFICATION_DELTA_OK")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"REMINDER_NOTIFICATION_DELTA_FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
