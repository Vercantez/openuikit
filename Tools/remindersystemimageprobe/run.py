#!/usr/bin/env python3
"""Pinned unchanged-Reminder diagnostic delta for UIImage(systemName:).

The probe performs no app or vendor writes. It typechecks the exact 22 Swift
sources at the pinned upstream revision against an exact clean UIKit base and
the candidate, then compares diagnostic multisets. Only the eleven errors at
the system-image call surface may disappear.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import pathlib
import re
import subprocess
import sys


BASE_COMMIT = "35652719dc4ba7c163c285c4e5d82e495a9b57bf"
REMINDER_COMMIT = "2edfc88c386b8dec1683339f58e05054c5e9ce1f"
REMINDER_TREE = "66474f2d47cc80ee551da990d748ddcc1b32aa1b"

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

Diagnostic = tuple[str, int, int, str]

SYSTEM_IMAGE_ERRORS: collections.Counter[Diagnostic] = collections.Counter(
    {
        ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 73, 27,
         "no exact matches in call to initializer"): 1,
        ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 96, 27,
         "no exact matches in call to initializer"): 1,
        ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 129, 25,
         "no exact matches in call to initializer"): 1,
        ("Reminder/Reminder/Scenes/Home/HomeTopView.swift", 53, 27,
         "no exact matches in call to initializer"): 1,
        ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 66, 30,
         "type 'UIImage' has no member 'SymbolConfiguration'"): 1,
        ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 66, 74,
         "cannot infer contextual base in reference to member 'regular'"): 1,
        ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 74, 27,
         "no exact matches in call to initializer"): 1,
        ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 104, 106,
         "no exact matches in call to initializer"): 1,
        ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 104, 59,
         "no exact matches in call to initializer"): 1,
        ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 166, 40,
         "no exact matches in call to initializer"): 1,
        ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 174, 40,
         "no exact matches in call to initializer"): 1,
    }
)

CALL_SITE_LINES = {
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 73):
        'imageView.image = UIImage(systemName: "calendar")',
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 96):
        'imageView.image = UIImage(systemName: "clock")',
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 129):
        'button.setImage(UIImage(systemName: "multiply"), for: .normal)',
    ("Reminder/Reminder/Scenes/Home/HomeTopView.swift", 53):
        'imageView.image = UIImage(systemName: "calendar")',
    ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 66):
        'let config = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)',
    ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 67):
        'let image = UIImage(systemName: "plus.circle.fill", withConfiguration: config)',
    ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 74):
        'imageView.image = UIImage(systemName: "circlebadge")',
    ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 104):
        'checkmarkImageView.image = reminder.isCompleted ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circlebadge")',
    ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 166):
        'checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")?',
    ("Reminder/Reminder/Scenes/Home/ReminderCell.swift", 174):
        'checkmarkImageView.image = UIImage(systemName: "circlebadge")',
}

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
                             candidate: pathlib.Path) -> None:
    reminder_head = git(reminder, "rev-parse", "HEAD")
    reminder_tree = git(reminder, "rev-parse", "HEAD^{tree}")
    if reminder_head != REMINDER_COMMIT or reminder_tree != REMINDER_TREE:
        fail(f"Reminder pin mismatch: {reminder_head} tree {reminder_tree}")
    if git(reminder, "status", "--porcelain"):
        fail("Reminder source repository is not clean")

    base_head = git(base, "rev-parse", "HEAD")
    if base_head != BASE_COMMIT:
        fail(f"UIKit base mismatch: {base_head}")
    if git(base, "status", "--porcelain"):
        fail("UIKit base repository is not clean")

    candidate_head = git(candidate, "rev-parse", "HEAD")
    candidate_parent = (candidate_head if candidate_head == BASE_COMMIT else
                        git(candidate, "rev-parse", "HEAD^"))
    if candidate_parent != BASE_COMMIT:
        fail(f"candidate is not based directly on {BASE_COMMIT}: {candidate_head}")


def validate_sources(reminder: pathlib.Path) -> str:
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


def build_uikit(repo: pathlib.Path) -> pathlib.Path:
    subprocess.run(["swift", "build", "--target", "UIKit"], cwd=repo,
                   check=True)
    return pathlib.Path(checked_output(["swift", "build", "--show-bin-path"],
                                       repo))


def typecheck(reminder: pathlib.Path, uikit: pathlib.Path,
              bin_path: pathlib.Path, shim: pathlib.Path) -> tuple[int, str]:
    command = [
        "swiftc", "-typecheck", "-continue-building-after-errors",
        "-parse-as-library", "-module-name", "ReminderSystemImageProbe",
        "-default-isolation", "MainActor",
        "-I", str(bin_path / "Modules"),
        "-Xcc", f"-fmodule-map-file={uikit}/Sources/CQuartz/include/module.modulemap",
        "-Xcc", f"-I{uikit}/Sources/CQuartz/include",
        "-Xcc", f"-fmodule-map-file={bin_path}/CSTBTrueType.build/module.modulemap",
        "-Xcc", f"-fmodule-map-file={bin_path}/CPortableIO.build/module.modulemap",
        *SOURCES,
        str(shim),
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

    validate_repository_pins(reminder, base, candidate)
    subject_hash = validate_sources(reminder)
    base_bin = build_uikit(base)
    candidate_bin = build_uikit(candidate)
    base_exit, base_output = typecheck(reminder, base, base_bin, shim)
    candidate_exit, candidate_output = typecheck(
        reminder, candidate, candidate_bin, shim
    )
    if base_exit == 0 or candidate_exit == 0:
        fail("the broad compatibility census unexpectedly had no diagnostics")

    before = diagnostics(base_output)
    after = diagnostics(candidate_output)
    if before & SYSTEM_IMAGE_ERRORS != SYSTEM_IMAGE_ERRORS:
        missing = SYSTEM_IMAGE_ERRORS - before
        fail(f"base is missing pinned system-image diagnostics: {missing}")
    if before - SYSTEM_IMAGE_ERRORS != after:
        removed = before - after
        added = after - before
        fail(f"non-system diagnostic delta: removed={removed}, added={added}")
    if sum(before.values()) != 45 or sum(after.values()) != 34:
        fail(f"unexpected totals: {sum(before.values())} -> {sum(after.values())}")

    print(f"reminder_commit={REMINDER_COMMIT}")
    print(f"reminder_tree={REMINDER_TREE}")
    print(f"source_subject_sha256={subject_hash}")
    print("sources=22 app_edits=0")
    print("diagnostics=45->34 removed=11 added=0")
    for file, line, column, message in sorted(SYSTEM_IMAGE_ERRORS.elements()):
        print(f"removed\t{file}:{line}:{column}\t{message}")
    print("remaining=UIDatePicker,Preview,traits,text-optionality,Notification,"
          "modal-transition,table-row-move,objc-selector")
    print("REMINDER_SYSTEM_IMAGE_DELTA_OK")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"REMINDER_SYSTEM_IMAGE_DELTA_FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
