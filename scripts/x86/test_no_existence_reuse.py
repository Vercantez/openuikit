#!/usr/bin/env python3
"""Fail if a producer reuses an artefact because the path exists.

Scans scripts/x86/*.inc, scripts/x86/*.sh, full/scripts/build_full.sh for
if-blocks gated by `[ -f` / `[ -e` / `phase2_is_x86_macho` that `return 0`
(or set a skip-ok flag) without calling `stamp_reuse` in the same then-block.

Also refuses live `-nt` freshness gates in those files (mtime is not a key).
The stub-list-vs-dylib CANNOT in ud_guest.inc is a staleness refusal, not reuse.

Usage: python3 scripts/x86/test_no_existence_reuse.py
       bash scripts/x86/test_no_existence_reuse.sh
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCAN = [
    *sorted((ROOT / "scripts" / "x86").glob("*.inc")),
    *sorted((ROOT / "scripts" / "x86").glob("*.sh")),
    ROOT / "full" / "scripts" / "build_full.sh",
]
SKIP_NAMES = {
    "test_no_existence_reuse.sh",
    "test_no_existence_reuse.py",
    "test_phase2.sh",
    "test_gen_swift_tbd.sh",
    "test_stamp.sh",
}

REUSE_COND = re.compile(
    r"""(?:
        \[\s*-f\s+ |
        \[\s*-e\s+ |
        phase2_is_x86_macho\s+
    )""",
    re.VERBOSE,
)
NEG_EXIST = re.compile(r"\[\s*!\s*-[ef]\b")
NEG_MACHO = re.compile(r"!\s*phase2_is_x86_macho")
POST_BUILD = re.compile(r"\$(?:st|cst|rc)\b|exit\s+\$")
NT_CODE = re.compile(r"""[^\n#]*-nt\s+""")
SKIP_OK = re.compile(r"\b(?:darwin_ok|host_ok|already)\s*=\s*1\b")
PRODUCT_HINT = re.compile(
    r"\.(?:o|dylib|so|tbd)\b|/machorun\b|libSystem|libobjc|libquartz|"
    r"FoundationEssentials|removefile_compat|OrderedCollections|uuid\.o|os\.o"
)
FINDER = re.compile(r"""printf '%s\\n'""")
SHADOW = re.compile(r"would shadow|skip arm64|skip non-x86")
ALLOW_NT = re.compile(r"phase2_cftest_stub_list_stale")


def strip_comments(line: str) -> str:
    in_s = in_d = False
    out = []
    i = 0
    while i < len(line):
        c = line[i]
        if c == "'" and not in_d:
            in_s = not in_s
            out.append(c)
        elif c == '"' and not in_s:
            in_d = not in_d
            out.append(c)
        elif c == "#" and not in_s and not in_d:
            break
        else:
            out.append(c)
        i += 1
    return "".join(out)


def then_block(lines: list[str], start: int) -> tuple[str, int, int]:
    """Return (body, start_line_1based, end_line_1based) of the then-block."""
    depth = 0
    body: list[str] = []
    i = start
    seen_then = False
    while i < len(lines):
        raw = lines[i]
        code = strip_comments(raw)
        tokens = re.findall(
            r"\b(?:if|then|fi|else|elif)\b",
            code,
        )
        for tok in tokens:
            if tok == "if":
                depth += 1
            elif tok == "then":
                if depth == 1 and not seen_then:
                    seen_then = True
            elif tok in ("else", "elif") and depth == 1:
                return "\n".join(body), start + 1, i + 1
            elif tok == "fi":
                depth -= 1
                if depth == 0:
                    return "\n".join(body), start + 1, i + 1
        if seen_then and depth >= 1:
            body.append(code)
        i += 1
    return "\n".join(body), start + 1, i


def condition_of(lines: list[str], start: int) -> str:
    parts = []
    i = start
    while i < len(lines):
        code = strip_comments(lines[i])
        parts.append(code)
        if re.search(r"\bthen\b", code):
            break
        i += 1
    return " ".join(parts)


def scan_file(path: pathlib.Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    try:
        rel = path.relative_to(ROOT).as_posix()
    except ValueError:
        rel = str(path)
    hits: list[str] = []
    i = 0
    func = ""
    while i < len(lines):
        code = strip_comments(lines[i])
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(\)\s*\{", code.strip())
        if m:
            func = m.group(1)
        if func == "phase2_cftest_stub_list_stale" or ALLOW_NT.search(code):
            i += 1
            continue
        if NT_CODE.search(code) and "-nt" in code:
            hits.append(f"{rel}:{i + 1}: live -nt freshness gate (mtime is not a stamp)")
        if re.search(r"^\s*if\b", code) or re.search(r";\s*if\b", code):
            cond = condition_of(lines, i)
            if (
                REUSE_COND.search(cond)
                and not NEG_EXIST.search(cond)
                and not NEG_MACHO.search(cond)
                and not POST_BUILD.search(cond)
                and (
                    PRODUCT_HINT.search(cond)
                    or "phase2_is_x86_macho" in cond
                )
            ):
                body, start_ln, _end = then_block(lines, i)
                if "stamp_reuse" not in body and "stamp_reuse" not in cond:
                    if FINDER.search(body) or SHADOW.search(body):
                        i += 1
                        continue
                    if "stamp_write" in body:
                        i += 1
                        continue
                    if re.search(r"\breturn 0\b", body) or SKIP_OK.search(body):
                        if not re.search(
                            r"\b(?:clang|swiftc|bash |sh |ld64|ninja|cmake|git clone)\b",
                            body,
                        ):
                            hits.append(
                                f"{rel}:{start_ln}: existence/macho skip without stamp_reuse"
                            )
        i += 1
    return hits


def main() -> int:
    hits: list[str] = []
    scanned = 0
    for path in SCAN:
        if not path.is_file() or path.name in SKIP_NAMES:
            continue
        scanned += 1
        hits.extend(scan_file(path))
    if hits:
        print("FAIL: existence-reuse without stamp_reuse:", file=sys.stderr)
        for h in hits:
            print(h, file=sys.stderr)
        return 1
    print(f"PASS: no existence-reuse skip without stamp_reuse ({scanned} files)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
