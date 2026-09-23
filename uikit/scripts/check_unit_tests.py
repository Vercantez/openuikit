#!/usr/bin/env python3
"""Grade a `swift test` log against scripts/known_test_failures.txt.

    swift test 2>&1 | tee /tmp/t.log; python3 scripts/check_unit_tests.py /tmp/t.log --rc $?

The merge gate (scripts/agent_merge.sh, "unit tests" stage) runs this on the
merged tree. It refuses (exit 1) when
  * a test failed that is not listed in the known-failures file;
  * a listed test now PASSES (the list must shrink with the fix);
  * a listed test did not run at all (renamed or deleted: a stale entry);
  * swift test exited non-zero with no failing test case (a crash or a hang
    killed by the gate's timeout): the test that was running is named.
Known-failures format: one `Class/testName` per line, then the reason
(required). `#` starts a comment line.
"""
import argparse
import re
import sys

# Darwin: Test Case '-[OpenUIKitTests.FooTests testBar]' passed (0.001 seconds).
# Linux:  Test Case 'FooTests.testBar' passed (0.001 seconds)
CASE = re.compile(r"^Test Case '(?:-\[(?:[\w]+\.)?(\w+) (\w+)\]|(\w+)\.(\w+))' "
                  r"(started|passed|failed|skipped)")
EXECUTED = re.compile(r"Executed (\d+) tests?, with (\d+) tests? skipped and (\d+) failures?"
                      r"|Executed (\d+) tests?, with (\d+) failures?")


def load_known(path):
    known, problems = {}, []
    for n, raw in enumerate(open(path, encoding="utf-8"), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        name, _, reason = line.partition(" ")
        if not re.fullmatch(r"\w+/\w+", name):
            problems.append(f"{path}:{n}: expected `Class/testName reason`, got {line!r}")
        elif not reason.strip():
            problems.append(f"{path}:{n}: {name} has no reason")
        else:
            known[name] = reason.strip()
    return known, problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log")
    ap.add_argument("--known", default="scripts/known_test_failures.txt")
    ap.add_argument("--rc", type=int, default=0, help="swift test's exit status")
    a = ap.parse_args()

    status, running, total = {}, None, None
    for line in open(a.log, encoding="utf-8", errors="replace"):
        m = CASE.match(line)
        if m:
            cls, test = (m.group(1), m.group(2)) if m.group(1) else (m.group(3), m.group(4))
            name, what = f"{cls}/{test}", m.group(5)
            if what == "started":
                running = name
            else:
                # a test that failed stays failed even if a retry line follows
                if status.get(name) != "failed":
                    status[name] = what
                running = None
            continue
        e = EXECUTED.search(line)
        if e:
            total = int(e.group(1) or e.group(4))

    known, problems = load_known(a.known)
    failed = sorted(n for n, s in status.items() if s == "failed")
    unexpected = [n for n in failed if n not in known]
    now_pass = sorted(n for n in known if status.get(n) == "passed")
    missing = sorted(n for n in known if n not in status)
    still = [n for n in failed if n in known]

    print(f"   unit tests: {len(status)} cases ({total if total is not None else '?'} executed), "
          f"{len(failed)} failed, {len(still)} of them known")
    for n in still:
        print(f"   known failure: {n} — {known[n]}")
    bad = list(problems)
    for n in unexpected:
        bad.append(f"NEW FAILURE: {n}")
    for n in now_pass:
        bad.append(f"KNOWN FAILURE NOW PASSES: {n} — remove it from {a.known}")
    for n in missing:
        bad.append(f"KNOWN FAILURE DID NOT RUN: {n} (renamed or deleted?) — update {a.known}")
    if a.rc != 0 and not failed:
        bad.append("swift test exited %d with no failing test case (crash or timeout)%s"
                   % (a.rc, f"; last test running: {running}" if running else ""))
    if not status:
        bad.append("no test cases found in the log")
    if bad:
        print("\n".join("   " + b for b in bad))
        # the assertion lines of the new failures, so the refusal is readable
        with open(a.log, encoding="utf-8", errors="replace") as f:
            shown = 0
            for line in f:
                if " error: -[" in line or ": error: " in line and "XCT" in line:
                    if any(f"{n.split('/')[0]} {n.split('/')[1]}]" in line for n in unexpected):
                        print("     " + line.rstrip()[:300])
                        shown += 1
                        if shown >= 12:
                            break
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
