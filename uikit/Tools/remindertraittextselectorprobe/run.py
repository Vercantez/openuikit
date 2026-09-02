#!/usr/bin/env python3
"""Fail-closed unchanged-Reminder 7-to-4 trait/text/selector delta.

The app and input repositories stay read-only. Full mode clones exact clean
revisions, rebuilds both UIKit modules without stale products, and typechecks
all 22 pinned app sources with only the external entry-point shim. Static and
captured-output modes exercise the same parsers/contracts before the candidate
is committed or before an expensive rebuild.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile


BASE_COMMIT = "99c0e9a65bcfbab9041b76782b0d390c435b2725"
REMINDER_COMMIT = "2edfc88c386b8dec1683339f58e05054c5e9ce1f"
REMINDER_TREE = "66474f2d47cc80ee551da990d748ddcc1b32aa1b"
SOURCE_SUBJECT_SHA256 = (
    "3a29a577f6290d27c09206798ab6446335eeb18a06502bfaa4d2f835850858d4"
)

ALLOWED_CHANGED_PATHS = frozenset({
    "Sources/OpenUIKit/UIGestureRecognizer.swift",
    "Sources/OpenUIKit/UISelector.swift",
    "Sources/OpenUIKit/UITextView.swift",
    "Sources/OpenUIKit/UIView.swift",
    "Sources/OpenUIKit/UIViewCompat.swift",
    "Sources/OpenUIKit/UIViewController.swift",
    "Tests/OpenUIKitTests/DynamicTypeTests.swift",
    "Tests/OpenUIKitTests/ReminderTailSourceCompatibilityTests.swift",
    "Tests/OpenUIKitTests/SelectorDispatchTests.swift",
    "Tests/OpenUIKitTests/TextInputTests.swift",
    "Tests/OpenUIKitTests/TraitCollectionTests.swift",
    "Tools/traittextselectorprobe/Info.plist",
    "Tools/traittextselectorprobe/expected.txt",
    "Tools/traittextselectorprobe/main.swift",
    "Tools/traittextselectorprobe/run.sh",
    "Tools/remindertraittextselectorprobe/EntryPointShim.swift",
    "Tools/remindertraittextselectorprobe/run.py",
    "docs/APP_COMPAT.md",
    "docs/KNOWN_GAPS.md",
    "docs/OBJC_RUNTIME.md",
    "docs/ROADMAP.md",
})
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
    ("Reminder/Reminder/Managers/DatePickerManager.swift", 72):
        "popover.backgroundColor = .systemBackground",
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
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 239):
        "registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, previousTraitCollection: UITraitCollection) in",
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
    ("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 292):
        "guard let title = reminderTextView.text,",
    ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 229):
        "createVC.modalTransitionStyle = .crossDissolve",
    ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 248):
        "self.reminderTableView.moveRow(",
    ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 326):
        "pickerMode: .date,",
    ("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 327):
        "pickerStyle: .inline,",
    ("Reminder/Reminder/Utilities/Extensions/UIView.swift", 14):
        "let tapGesture = UITapGestureRecognizer(target: self, action: #selector(UIView.endEditing))",
}

Diagnostic = tuple[str, int, int, str]


def counter(entries: list[tuple[Diagnostic, int]]) -> collections.Counter[Diagnostic]:
    return collections.Counter(dict(entries))


REMOVED_ERRORS = counter([
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 239, 9,
      "cannot find 'registerForTraitChanges' in scope"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 292, 15,
      "initializer for conditional binding must have Optional type, not 'String'"), 1),
    (("Reminder/Reminder/Utilities/Extensions/UIView.swift", 14, 71,
      "argument of '#selector' refers to instance method 'endEditing' that is not exposed to Objective-C"), 1),
])

ADDED_ERRORS: collections.Counter[Diagnostic] = collections.Counter()

UNCHANGED_ERRORS = counter([
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 24, 40,
      "argument of '#selector' refers to instance method 'dateChanged' that is not exposed to Objective-C"), 1),
    (("Reminder/Reminder/Views/DatePickerViewController.swift", 80, 16,
      "method cannot be marked '@objc' because the type of the parameter cannot be represented in Objective-C"), 1),
    (("Reminder/Reminder/Scenes/Create/CreateViewController.swift", 355, 2,
      "no macro named 'Preview'"), 1),
    (("Reminder/Reminder/Scenes/Home/HomeViewController.swift", 233, 62,
      "'Notification' is ambiguous for type lookup in this context"), 1),
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


def validate_changed_paths(changed: frozenset[str]) -> None:
    unexpected = changed - ALLOWED_CHANGED_PATHS
    missing = REQUIRED_CHANGED_PATHS - changed
    if unexpected or missing:
        fail(f"candidate changed-path boundary mismatch: missing={sorted(missing)}, "
             f"unexpected={sorted(unexpected)}")


def validate_reminder_pin(reminder: pathlib.Path) -> None:
    if git(reminder, "rev-parse", "HEAD") != REMINDER_COMMIT:
        fail("Reminder commit pin mismatch")
    if git(reminder, "rev-parse", "HEAD^{tree}") != REMINDER_TREE:
        fail("Reminder tree pin mismatch")
    if git(reminder, "status", "--porcelain"):
        fail("Reminder repository is not clean")


def validate_base_pin(base: pathlib.Path) -> None:
    if git(base, "rev-parse", "HEAD") != BASE_COMMIT:
        fail("UIKit base pin mismatch")
    if git(base, "status", "--porcelain"):
        fail("UIKit base repository is not clean")


def validate_candidate_commit(candidate: pathlib.Path) -> str:
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


def worktree_changed_paths(candidate: pathlib.Path) -> frozenset[str]:
    tracked = set(git(candidate, "diff", "--name-only", BASE_COMMIT).splitlines())
    untracked = set(git(candidate, "ls-files", "--others",
                        "--exclude-standard").splitlines())
    return frozenset(tracked | untracked)


def validate_candidate_worktree(candidate: pathlib.Path) -> None:
    head = git(candidate, "rev-parse", "HEAD")
    count = git(candidate, "rev-list", "--count", f"{BASE_COMMIT}..{head}")
    if head != BASE_COMMIT and count != "1":
        fail("static candidate must be at base or exactly one commit beyond it")
    if head != BASE_COMMIT:
        parents = git(candidate, "show", "-s", "--format=%P", head).split()
        if parents != [BASE_COMMIT]:
            fail("static candidate commit does not have the exact base parent")
    validate_changed_paths(worktree_changed_paths(candidate))


def run_diff_check(candidate: pathlib.Path) -> None:
    result = subprocess.run(
        ["git", "diff", "--check", BASE_COMMIT, "--"],
        cwd=candidate, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    if result.returncode != 0:
        fail(f"git diff --check failed:\n{result.stdout}")
    for relative in git(candidate, "ls-files", "--others",
                        "--exclude-standard").splitlines():
        data = (candidate / relative).read_bytes()
        if data and not data.endswith(b"\n"):
            fail(f"untracked file lacks final newline: {relative}")
        for number, line in enumerate(data.splitlines(), 1):
            if line.endswith((b" ", b"\t")):
                fail(f"untracked file has trailing whitespace: {relative}:{number}")


def validate_call_sites(reminder: pathlib.Path,
                        expected: dict[tuple[str, int], str]) -> None:
    if len(expected) != 26:
        fail(f"expected exact 26-call-site census, found {len(expected)}")
    for (relative, line_number), expected_line in expected.items():
        lines = (reminder / relative).read_text(encoding="utf-8").splitlines()
        actual_line = lines[line_number - 1].strip()
        if actual_line != expected_line:
            fail(f"call-site mismatch {relative}:{line_number}: {actual_line!r}")


def source_subject_hash(reminder: pathlib.Path) -> str:
    actual = tuple(sorted(
        path.relative_to(reminder).as_posix()
        for path in (reminder / "Reminder" / "Reminder").rglob("*.swift")
    ))
    if actual != SOURCES:
        fail(f"expected exact 22-source census, found {len(actual)}: {actual}")
    validate_call_sites(reminder, CALL_SITE_LINES)
    digest = hashlib.sha256()
    for relative in SOURCES:
        digest.update(relative.encode("utf-8"))
        digest.update(b"\0")
        digest.update((reminder / relative).read_bytes())
        digest.update(b"\0")
    return digest.hexdigest()


def validate_subject_hash(actual: str) -> None:
    if actual != SOURCE_SUBJECT_SHA256:
        fail(f"source subject hash mismatch: {actual}")


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
    if before - after != REMOVED_ERRORS or after - before != ADDED_ERRORS:
        fail("diagnostic delta partition mismatch")


def parser_self_test() -> None:
    synthetic: collections.Counter[Diagnostic] = collections.Counter({
        ("Synthetic.swift", 1, 2, "first"): 2,
        ("Nested/Other.swift", 30, 4, "second"): 1,
    })
    lines = ["Synthetic.swift:1:2: warning: ignored"]
    for file, line, column, message in synthetic.elements():
        lines.append(f"{file}:{line}:{column}: error: {message}")
    if diagnostics("\n".join(lines) + "\n") != synthetic:
        fail("diagnostic parser multiplicity self-test failed")


def run_tamper_negatives(reminder: pathlib.Path | None = None) -> None:
    before = REMOVED_ERRORS + UNCHANGED_ERRORS
    after = ADDED_ERRORS + UNCHANGED_ERRORS
    tamper = collections.Counter({("Tamper.swift", 1, 1, "tamper"): 1})
    probes = [
        (before - collections.Counter({next(iter(before)): 1}), after),
        (before + tamper, after),
        (before, after - collections.Counter({next(iter(after)): 1})),
        (before, after + tamper),
    ]
    for tampered_before, tampered_after in probes:
        try:
            validate_multisets(tampered_before, tampered_after)
        except RuntimeError:
            continue
        fail("diagnostic tamper negative was accepted")

    for bad_hash in ("0" * 64, SOURCE_SUBJECT_SHA256[:-1]):
        try:
            validate_subject_hash(bad_hash)
        except RuntimeError:
            continue
        fail("source-hash tamper negative was accepted")

    try:
        validate_changed_paths(REQUIRED_CHANGED_PATHS | {"Sources/DemoApp/Tamper.swift"})
    except RuntimeError:
        pass
    else:
        fail("unexpected changed-path tamper negative was accepted")
    omitted = sorted(REQUIRED_CHANGED_PATHS)[0]
    try:
        validate_changed_paths(REQUIRED_CHANGED_PATHS - {omitted})
    except RuntimeError:
        pass
    else:
        fail("missing required changed-path tamper negative was accepted")

    if reminder is not None:
        missing_site = dict(CALL_SITE_LINES)
        missing_site.pop(next(iter(missing_site)))
        try:
            validate_call_sites(reminder, missing_site)
        except RuntimeError:
            pass
        else:
            fail("missing call-site tamper negative was accepted")
        wrong_site = dict(CALL_SITE_LINES)
        key = next(iter(wrong_site))
        wrong_site[key] += " TAMPER"
        try:
            validate_call_sites(reminder, wrong_site)
        except RuntimeError:
            pass
        else:
            fail("changed call-site tamper negative was accepted")


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
        "-parse-as-library", "-module-name", "ReminderTraitTextSelectorProbe",
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


def print_counter(label: str, values: collections.Counter[Diagnostic]) -> None:
    for file, line, column, message in sorted(values.elements()):
        print(f"{label}\t{file}:{line}:{column}\t{message}")


def require_paths(arguments: argparse.Namespace, names: tuple[str, ...]) -> None:
    missing = [name for name in names if getattr(arguments, name) is None]
    if missing:
        fail(f"missing required arguments for this mode: {missing}")


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

    parser_self_test()

    if arguments.self_test:
        if any((arguments.reminder, arguments.base_uikit, arguments.candidate_uikit,
                arguments.static_candidate, arguments.before_output,
                arguments.after_output)):
            fail("--self-test cannot be mixed with repository or output modes")
        run_tamper_negatives()
        print("parser=counter-multiplicity warnings-ignored")
        print("REMINDER_TRAIT_TEXT_SELECTOR_SELF_TEST_OK")
        return 0

    if arguments.before_output is not None or arguments.after_output is not None:
        if arguments.before_output is None or arguments.after_output is None:
            fail("--before-output and --after-output must be supplied together")
        if any((arguments.reminder, arguments.base_uikit, arguments.candidate_uikit,
                arguments.static_candidate)):
            fail("captured-output mode cannot be mixed with repository modes")
        run_tamper_negatives()
        before = diagnostics(arguments.before_output.read_text(encoding="utf-8"))
        after = diagnostics(arguments.after_output.read_text(encoding="utf-8"))
        validate_multisets(before, after)
        print("diagnostics=7->4 removed=3 added=0 unchanged=4")
        print("REMINDER_TRAIT_TEXT_SELECTOR_CAPTURED_DELTA_OK")
        return 0

    if arguments.static_candidate:
        require_paths(arguments, ("reminder", "candidate_uikit"))
        if arguments.base_uikit is not None:
            fail("--static-candidate does not accept --base-uikit")
        reminder = arguments.reminder.resolve()
        candidate = arguments.candidate_uikit.resolve()
        validate_reminder_pin(reminder)
        subject_hash = source_subject_hash(reminder)
        validate_subject_hash(subject_hash)
        run_tamper_negatives(reminder)
        validate_candidate_worktree(candidate)
        run_diff_check(candidate)
        print(f"base_commit={BASE_COMMIT}")
        print(f"source_subject_sha256={subject_hash}")
        print("sources=22 call_sites=26 required_paths=21 app_edits=0")
        print("parser=counter-multiplicity diff_check=clean tamper_negatives=10")
        print("REMINDER_TRAIT_TEXT_SELECTOR_STATIC_OK")
        return 0

    require_paths(arguments, ("reminder", "base_uikit", "candidate_uikit"))
    reminder = arguments.reminder.resolve()
    base = arguments.base_uikit.resolve()
    candidate = arguments.candidate_uikit.resolve()
    validate_reminder_pin(reminder)
    validate_base_pin(base)
    candidate_head = validate_candidate_commit(candidate)
    subject_hash = source_subject_hash(reminder)
    validate_subject_hash(subject_hash)
    run_tamper_negatives(reminder)

    shim = pathlib.Path(__file__).with_name("EntryPointShim.swift").resolve()
    with tempfile.TemporaryDirectory(prefix="reminder-trait-text-selector-probe-") as raw:
        temporary = pathlib.Path(raw)
        reminder_copy = temporary / "reminder"
        base_copy = temporary / "base"
        candidate_copy = temporary / "candidate"
        clone(reminder, reminder_copy, REMINDER_COMMIT)
        clone(base, base_copy, BASE_COMMIT)
        base_bin = build_uikit(base_copy)
        base_exit, base_output = typecheck(
            reminder_copy, base_copy, base_bin, shim
        )
        # The two fresh UIKit builds are intentionally sequential so this
        # fail-closed gate does not require room for two complete build trees.
        shutil.rmtree(base_copy)
        clone(candidate, candidate_copy, candidate_head)
        candidate_bin = build_uikit(candidate_copy)
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
    print("sources=22 call_sites=26 app_edits=0")
    print("diagnostics=7->4 removed=3 added=0 unchanged=4")
    print_counter("removed", REMOVED_ERRORS)
    print_counter("added", ADDED_ERRORS)
    print_counter("unchanged", UNCHANGED_ERRORS)
    print("tamper_negatives=missing-before,unexpected-before,missing-after,"
          "unexpected-after,source-hash,unexpected-changed-path,"
          "missing-changed-path,missing-call-site,changed-call-site")
    print("remaining=datepicker-objc-selector,Preview,Notification")
    print("REMINDER_TRAIT_TEXT_SELECTOR_DELTA_OK")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, subprocess.CalledProcessError, RuntimeError) as error:
        print(f"REMINDER_TRAIT_TEXT_SELECTOR_DELTA_FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
