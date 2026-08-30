#!/usr/bin/env python3
"""Fail-closed unchanged-Reminder diagnostic delta for UIDatePicker.

The input repositories are read-only. Exact clean revisions are cloned into a
temporary directory, UIKit modules are rebuilt without stale products, and all
22 pinned app sources are typechecked with only the external entry-point shim.
The complete before/after diagnostic multisets are part of the contract.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import pathlib
import re
import subprocess
import sys
import tempfile


BASE_COMMIT = "8f98af2e53af566923de6616f3629bec0661aa8c"
REMINDER_COMMIT = "2edfc88c386b8dec1683339f58e05054c5e9ce1f"
REMINDER_TREE = "66474f2d47cc80ee551da990d748ddcc1b32aa1b"
SOURCE_SUBJECT_SHA256 = (
    "3a29a577f6290d27c09206798ab6446335eeb18a06502bfaa4d2f835850858d4"
)

ALLOWED_CHANGED_PATHS = frozenset({
    "Sources/OpenUIKit/UIDatePicker.swift",
    "Tests/OpenUIKitTests/DatePickerSourceCompatibilityTests.swift",
    "Tests/OpenUIKitTests/DatePickerTests.swift",
    "Tests/OpenUIKitTests/FoundationCoexistenceTests.swift",
    "Tools/datepickerhiddenprobe/expected.txt",
    "Tools/datepickerhiddenprobe/main.swift",
    "Tools/datepickerhiddenprobe/runtime.sh",
    "Tools/datepickerprobe/Info.plist",
    "Tools/datepickerprobe/expected.txt",
    "Tools/datepickerprobe/main.swift",
    "Tools/datepickerprobe/run.sh",
    "Tools/reminderdatepickerprobe/EntryPointShim.swift",
    "Tools/reminderdatepickerprobe/run.py",
    "docs/APP_COMPAT.md",
    "docs/KNOWN_GAPS.md",
    "docs/ROADMAP.md",
})
# The accepted candidate is this evidence-bearing slice exactly. Keeping the
# required set equal to the allowlist prevents a reduced implementation from
# retaining only the probe while silently dropping native/source/docs gates.
REQUIRED_CHANGED_PATHS = ALLOWED_CHANGED_PATHS

SOURCES = (
    "Reminder/Reminder/App/AppDelegate.swift",
    "Reminder/Reminder/App/SceneDelegate.swift",
    "Reminder/Reminder/Managers/DateManager.swift",
    "Reminder/Reminder/Managers/DatePickerManager.swift",
    "Reminder/Reminder/Managers/StorageManager.swift",
    "Reminder/Reminder/Models/Reminder.swift",
    "Reminder/Reminder/Scenes/Create/CreateViewController.swift",
    "Reminder/Reminder/Scenes/Create/CreateViewModel.swift",
    "Reminder/Reminder/Scenes/Home/DateCell.swift",
    "Reminder/Reminder/Scenes/Home/HomeTopFooterView.swift",
    "Reminder/Reminder/Scenes/Home/HomeTopView.swift",
    "Reminder/Reminder/Scenes/Home/HomeViewController.swift",
    "Reminder/Reminder/Scenes/Home/HomeViewModel.swift",
    "Reminder/Reminder/Scenes/Home/ReminderCell.swift",
    "Reminder/Reminder/Utilities/Extensions/Collection.swift",
    "Reminder/Reminder/Utilities/Extensions/Notification.swift",
    "Reminder/Reminder/Utilities/Extensions/String.swift",
    "Reminder/Reminder/Utilities/Extensions/UIColor.swift",
    "Reminder/Reminder/Utilities/Extensions/UIImage.swift",
    "Reminder/Reminder/Utilities/Extensions/UITableView.swift",
    "Reminder/Reminder/Utilities/Extensions/UIView.swift",
    "Reminder/Reminder/Views/DatePickerViewController.swift",
)

CALL_SITE_LINES = {
    ("Reminder/Reminder/Managers/DatePickerManager.swift", 50):
        "pickerMode: UIDatePicker.Mode,",
    ("Reminder/Reminder/Managers/DatePickerManager.swift", 51):
        "pickerStyle: UIDatePickerStyle,",
    ("Reminder/Reminder/Managers/DatePickerManager.swift", 52):
        "popoverSize: CGSize = CGSize(width: 320, height: 320),",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 15):
        "private var pickerMode: UIDatePicker.Mode = .date",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 16):
        "private var pickerStyle: UIDatePickerStyle = .inline",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 19):
        "private lazy var datePicker: UIDatePicker = {",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 20):
        "let picker = UIDatePicker()",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 21):
        "picker.datePickerMode = pickerMode",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 22):
        "picker.preferredDatePickerStyle = pickerStyle",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 24):
        "picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 58):
        "datePicker.date = initialDate",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 80):
        "@objc func dateChanged(_ sender: UIDatePicker) {",
    ("Reminder/Reminder/Views/DatePickerViewController.swift", 81):
        "onDateSelected?(sender.date)",
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 265):
        "pickerMode: .date,",
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 266):
        "pickerStyle: .inline,",
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 278):
        "pickerMode: .time,",
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 279):
        "pickerStyle: .wheels,",
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 280):
        "popoverSize: CGSize(width: 160, height: 160),",
    ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 326):
        "pickerMode: .date,",
    ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 327):
        "pickerStyle: .inline,",
}

Diagnostic = tuple[str, int, int, str]


def counter(entries: list[tuple[Diagnostic, int]]) -> collections.Counter[Diagnostic]:
    return collections.Counter(dict(entries))


REMOVED_ERRORS = counter([
    (("Reminder/Reminder/Managers/DatePickerManager.swift", 50, 21,
      "cannot find type 'UIDatePicker' in scope"), 3),
    (("Reminder/Reminder/Managers/DatePickerManager.swift", 51, 22,
      "cannot find type 'UIDatePickerStyle' in scope"), 3),
    (("Reminder/Reminder/Managers/DatePickerManager.swift", 55, 52,
      "extra arguments at positions #1, #2, #3 in call"), 1),
    (("Reminder/Reminder/Managers/DatePickerManager.swift", 56, 13,
      "missing argument for parameter 'coder' in call"), 1),
    (("Reminder/Reminder/Managers/DatePickerManager.swift", 64, 48,
      "cannot infer contextual base in reference to member 'popover'"), 1),
    (("Reminder/Reminder/Managers/DatePickerManager.swift", 70, 49,
      "cannot infer contextual base in reference to member 'up'"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 265, 26,
      "cannot infer contextual base in reference to member 'date'"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 266, 27,
      "cannot infer contextual base in reference to member 'inline'"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 278, 26,
      "cannot infer contextual base in reference to member 'time'"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 279, 27,
      "cannot infer contextual base in reference to member 'wheels'"), 1),
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 326, 26,
      "cannot infer contextual base in reference to member 'date'"), 1),
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 327, 27,
      "cannot infer contextual base in reference to member 'inline'"), 1),
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 328, 43,
      "cannot infer type of closure parameter 'date' without a type annotation"), 1),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 15, 29,
      "cannot find type 'UIDatePicker' in scope"), 1),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 16, 30,
      "cannot find type 'UIDatePickerStyle' in scope"), 1),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 19, 34,
      "cannot find type 'UIDatePicker' in scope"), 1),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 31, 21,
      "cannot find type 'UIDatePicker' in scope"), 2),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 32, 22,
      "cannot find type 'UIDatePickerStyle' in scope"), 2),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 80, 38,
      "cannot find type 'UIDatePicker' in scope"), 1),
])

ADDED_ERRORS = counter([
    (("Reminder/Reminder/Managers/DatePickerManager.swift", 72, 21,
      "value of type 'UIPopoverPresentationController' has no member 'backgroundColor'"), 1),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 24, 40,
      "argument of '#selector' refers to instance method 'dateChanged' that is not exposed to Objective-C"), 1),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 80, 16,
      "method cannot be marked '@objc' because the type of the parameter cannot be represented in Objective-C"), 1),
])

UNCHANGED_ERRORS = counter([
    (("Reminder/Reminder/Managers/DatePickerManager.swift", 72, 40,
      "cannot infer contextual base in reference to member 'systemBackground'"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 239, 9,
      "cannot find 'registerForTraitChanges' in scope"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 292, 15,
      "initializer for conditional binding must have Optional type, not 'String'"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 355, 2,
      "no macro named 'Preview'"), 1),
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 229, 18,
      "value of type 'CreateViewController' has no member 'modalTransitionStyle'"), 1),
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 229, 42,
      "cannot infer contextual base in reference to member 'crossDissolve'"), 1),
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 233, 62,
      "'Notification' is ambiguous for type lookup in this context"), 1),
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 248, 32,
      "value of type 'UITableView' has no member 'moveRow'"), 1),
    (("Reminder/Reminder/Utilities/Extensions/UIView.swift", 14, 71,
      "argument of '#selector' refers to instance method 'endEditing' that is not exposed to Objective-C"), 1),
])

ERROR_RE = re.compile(
    r"^(?P<file>.+?\.swift):(?P<line>\d+):(?P<column>\d+): error: (?P<message>.+)$",
    re.MULTILINE,
)


def checked_output(args: list[str], cwd: pathlib.Path) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def git(repo: pathlib.Path, *args: str) -> str:
    return checked_output(["git", *args], repo)


def fail(message: str) -> None:
    raise RuntimeError(message)


def validate_repository_pins(reminder: pathlib.Path, base: pathlib.Path,
                             candidate: pathlib.Path) -> str:
    if git(reminder, "rev-parse", "HEAD") != REMINDER_COMMIT:
        fail("Reminder commit pin mismatch")
    if git(reminder, "rev-parse", "HEAD^{tree}") != REMINDER_TREE:
        fail("Reminder tree pin mismatch")
    if git(reminder, "status", "--porcelain"):
        fail("Reminder repository is not clean")

    if git(base, "rev-parse", "HEAD") != BASE_COMMIT:
        fail("UIKit base pin mismatch")
    if git(base, "status", "--porcelain"):
        fail("UIKit base repository is not clean")

    candidate_head = git(candidate, "rev-parse", "HEAD")
    parents = git(candidate, "show", "-s", "--format=%P", candidate_head).split()
    if parents != [BASE_COMMIT]:
        fail(f"candidate must have sole parent {BASE_COMMIT}: {parents}")
    if git(candidate, "rev-list", "--count", f"{BASE_COMMIT}..{candidate_head}") != "1":
        fail("candidate must be exactly one commit beyond the base")
    if git(candidate, "status", "--porcelain"):
        fail("UIKit candidate repository is not clean")
    changed = frozenset(git(candidate, "diff", "--name-only",
                            f"{BASE_COMMIT}..{candidate_head}").splitlines())
    validate_changed_paths(changed)
    return candidate_head


def validate_changed_paths(changed: frozenset[str]) -> None:
    unexpected = changed - ALLOWED_CHANGED_PATHS
    missing = REQUIRED_CHANGED_PATHS - changed
    if unexpected or missing:
        fail(f"candidate changed-path boundary mismatch: missing={sorted(missing)}, "
             f"unexpected={sorted(unexpected)}")


def source_subject_hash(reminder: pathlib.Path) -> str:
    actual = tuple(sorted(
        path.relative_to(reminder).as_posix()
        for path in (reminder / "Reminder" / "Reminder").rglob("*.swift")
    ))
    if actual != SOURCES:
        fail(f"expected exact 22-source census, found {len(actual)}: {actual}")
    for (relative, line_number), expected in CALL_SITE_LINES.items():
        lines = (reminder / relative).read_text(encoding="utf-8").splitlines()
        actual_line = lines[line_number - 1].strip()
        if actual_line != expected:
            fail(f"call-site mismatch {relative}:{line_number}: {actual_line!r}")
    digest = hashlib.sha256()
    for relative in SOURCES:
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update((reminder / relative).read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def clone(repo: pathlib.Path, destination: pathlib.Path, revision: str) -> None:
    subprocess.run(["git", "clone", "--quiet", "--no-hardlinks",
                    str(repo), str(destination)], check=True)
    subprocess.run(["git", "checkout", "--quiet", "--detach", revision],
                   cwd=destination, check=True)


def build_uikit(repo: pathlib.Path) -> pathlib.Path:
    subprocess.run(["swift", "build", "--target", "UIKit",
                    "--disable-index-store", "-Xswiftc", "-gnone"],
                   cwd=repo, check=True)
    return pathlib.Path(checked_output(["swift", "build", "--show-bin-path"], repo))


def typecheck(reminder: pathlib.Path, uikit: pathlib.Path,
              bin_path: pathlib.Path, shim: pathlib.Path) -> tuple[int, str]:
    command = [
        "swiftc", "-typecheck", "-continue-building-after-errors",
        "-parse-as-library", "-module-name", "ReminderDatePickerProbe",
        "-default-isolation", "MainActor", "-I", str(bin_path / "Modules"),
        "-Xcc", f"-fmodule-map-file={uikit}/Sources/CQuartz/include/module.modulemap",
        "-Xcc", f"-I{uikit}/Sources/CQuartz/include",
        "-Xcc", f"-fmodule-map-file={bin_path}/CSTBTrueType.build/module.modulemap",
        "-Xcc", f"-fmodule-map-file={bin_path}/CPortableIO.build/module.modulemap",
        *SOURCES, str(shim),
    ]
    result = subprocess.run(command, cwd=reminder, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return result.returncode, result.stdout


def diagnostics(output: str) -> collections.Counter[Diagnostic]:
    return collections.Counter(
        (match.group("file"), int(match.group("line")),
         int(match.group("column")), match.group("message").rstrip())
        for match in ERROR_RE.finditer(output)
    )


def validate_multisets(before: collections.Counter[Diagnostic],
                       after: collections.Counter[Diagnostic]) -> None:
    expected_before = REMOVED_ERRORS + UNCHANGED_ERRORS
    expected_after = ADDED_ERRORS + UNCHANGED_ERRORS
    if before != expected_before:
        fail(f"base diagnostic multiset mismatch: missing={expected_before-before}, "
             f"unexpected={before-expected_before}")
    if after != expected_after:
        fail(f"candidate diagnostic multiset mismatch: missing={expected_after-after}, "
             f"unexpected={after-expected_after}")


def validate_subject_hash(actual: str) -> None:
    if actual != SOURCE_SUBJECT_SHA256:
        fail(f"source subject hash mismatch: {actual}")


def run_tamper_negatives() -> None:
    before = REMOVED_ERRORS + UNCHANGED_ERRORS
    after = ADDED_ERRORS + UNCHANGED_ERRORS
    probes = [
        (before - collections.Counter({next(iter(before)): 1}), after),
        (before, after + collections.Counter({("Tamper.swift", 1, 1, "tamper"): 1})),
    ]
    for tampered_before, tampered_after in probes:
        try:
            validate_multisets(tampered_before, tampered_after)
        except RuntimeError:
            continue
        fail("diagnostic tamper negative was accepted")
    try:
        validate_subject_hash("0" * 64)
    except RuntimeError:
        pass
    else:
        fail("source-hash tamper negative was accepted")
    try:
        validate_changed_paths(REQUIRED_CHANGED_PATHS | {"Sources/DemoApp/Tamper.swift"})
    except RuntimeError:
        pass
    else:
        fail("changed-path tamper negative was accepted")
    omitted = sorted(REQUIRED_CHANGED_PATHS)[0]
    try:
        validate_changed_paths(REQUIRED_CHANGED_PATHS - {omitted})
    except RuntimeError:
        pass
    else:
        fail("missing required changed path tamper negative was accepted")


def print_counter(label: str, values: collections.Counter[Diagnostic]) -> None:
    for file, line, column, message in sorted(values.elements()):
        print(f"{label}\t{file}:{line}:{column}\t{message}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--reminder", type=pathlib.Path, required=True)
    parser.add_argument("--base-uikit", type=pathlib.Path, required=True)
    parser.add_argument("--candidate-uikit", type=pathlib.Path, required=True)
    arguments = parser.parse_args()
    reminder = arguments.reminder.resolve()
    base = arguments.base_uikit.resolve()
    candidate = arguments.candidate_uikit.resolve()
    shim = pathlib.Path(__file__).with_name("EntryPointShim.swift").resolve()

    candidate_head = validate_repository_pins(reminder, base, candidate)
    subject_hash = source_subject_hash(reminder)
    validate_subject_hash(subject_hash)
    run_tamper_negatives()

    with tempfile.TemporaryDirectory(prefix="reminder-datepicker-probe-") as raw:
        temporary = pathlib.Path(raw)
        reminder_copy = temporary / "reminder"
        base_copy = temporary / "base"
        candidate_copy = temporary / "candidate"
        clone(reminder, reminder_copy, REMINDER_COMMIT)
        clone(base, base_copy, BASE_COMMIT)
        clone(candidate, candidate_copy, candidate_head)
        base_bin = build_uikit(base_copy)
        candidate_bin = build_uikit(candidate_copy)
        base_exit, base_output = typecheck(
            reminder_copy, base_copy, base_bin, shim
        )
        candidate_exit, candidate_output = typecheck(
            reminder_copy, candidate_copy, candidate_bin, shim
        )

    if base_exit == 0 or candidate_exit == 0:
        fail("broad compatibility census unexpectedly had no diagnostics")
    before = diagnostics(base_output)
    after = diagnostics(candidate_output)
    validate_multisets(before, after)

    print(f"base_commit={BASE_COMMIT}")
    print(f"candidate_commit={candidate_head}")
    print(f"reminder_commit={REMINDER_COMMIT}")
    print(f"reminder_tree={REMINDER_TREE}")
    print(f"source_subject_sha256={subject_hash}")
    print("sources=22 call_sites=20 app_edits=0")
    print("diagnostics=34->12 removed=25 added=3 unchanged=9")
    print_counter("removed", REMOVED_ERRORS)
    print_counter("added", ADDED_ERRORS)
    print_counter("unchanged", UNCHANGED_ERRORS)
    print("tamper_negatives=missing-diagnostic,unexpected-diagnostic,source-hash,"
          "unexpected-changed-path,missing-changed-path")
    print("remaining=popover-background,objc-selector,Preview,traits,text-optionality,"
          "Notification,modal-transition,table-row-move,endEditing-selector")
    print("REMINDER_DATEPICKER_DELTA_OK")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"REMINDER_DATEPICKER_DELTA_FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
