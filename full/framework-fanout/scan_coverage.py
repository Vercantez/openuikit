#!/usr/bin/env python3
"""Scan full/*/coverage.tsv — one row per public iPhoneOS 26.1 precise ID.

Statuses: implemented, declared, deferred, unavailable, not-applicable.
Actionable leftover is declared + deferred.

Examples:
  python3 -B full/framework-fanout/scan_coverage.py
  python3 -B full/framework-fanout/scan_coverage.py --slug accelerate
  python3 -B full/framework-fanout/scan_coverage.py --leftover accelerate --limit 30
  python3 -B full/framework-fanout/scan_coverage.py --lowest 20 --min-total 200
"""

from __future__ import annotations

import argparse
import collections
import csv
import sys
from pathlib import Path

STATUSES = (
    "implemented",
    "declared",
    "deferred",
    "unavailable",
    "not-applicable",
)

# Frameworks whose public surface is primarily UI / rendering / storefront.
# Used only for the optional --non-ui filter; every coverage.tsv is still scanned.
UI_SLUGS = {
    "uikit",
    "swiftui",
    "photosui",
    "intentsui",
    "healthkitui",
    "contactsui",
    "eventkitui",
    "mapkit",
    "charts",
    "widgetkit",
    "avkit",
    "carplay",
    "addressbookui",
    "corelocationui",
    "fileproviderui",
    "financekitui",
    "identitydocumentservicesui",
    "identitylookupui",
    "devicediscoveryui",
    "appkit",
    "safari",
    "safariservices",
    "messageui",
    "quicklook",
    "storekit",
    "passkit",
    "photos",
    "spritekit",
    "scenekit",
    "realitykit",
    "arkit",
    "gamekit",
    "gamecontroller",
    "pencilkit",
    "watchkit",
    "clockkit",
    "activitykit",
    "alarmkit",
    "imageplayground",
    "browserkit",
    "browserenginekit",
    "swiftuicore",
}


def repo_root() -> Path:
    here = Path(__file__).resolve()
    for parent in here.parents:
        if (parent / "full").is_dir() and (parent / "full" / "framework-fanout").is_dir():
            return parent
    raise SystemExit("cannot locate repository root from scan_coverage.py")


def read_coverage(path: Path) -> list[list[str]]:
    with path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter="\t", quoting=csv.QUOTE_NONE))
    if not rows or rows[0][:4] != ["precise", "status", "evidence", "notes"]:
        raise SystemExit(f"bad coverage header: {path}")
    return [row for row in rows[1:] if len(row) >= 2]


def load_frameworks(full: Path) -> list[dict]:
    out = []
    for directory in sorted(p for p in full.iterdir() if p.is_dir()):
        coverage = directory / "coverage.tsv"
        if not coverage.is_file():
            continue
        rows = read_coverage(coverage)
        counts = collections.Counter(row[1] for row in rows)
        total = sum(counts[status] for status in STATUSES)
        if total == 0:
            continue
        implemented = counts["implemented"]
        out.append(
            {
                "slug": directory.name,
                "total": total,
                "implemented": implemented,
                "declared": counts["declared"],
                "deferred": counts["deferred"],
                "unavailable": counts["unavailable"],
                "not_applicable": counts["not-applicable"],
                "actionable": counts["declared"] + counts["deferred"],
                "pct": implemented / total,
                "ui": directory.name in UI_SLUGS,
                "rows": rows,
            }
        )
    return out


def print_summary(label: str, frameworks: list[dict]) -> None:
    total = sum(item["total"] for item in frameworks)
    if total == 0:
        print(f"=== {label} (0 frameworks) ===")
        return
    implemented = sum(item["implemented"] for item in frameworks)
    declared = sum(item["declared"] for item in frameworks)
    deferred = sum(item["deferred"] for item in frameworks)
    unavailable = sum(item["unavailable"] for item in frameworks)
    not_applicable = sum(item["not_applicable"] for item in frameworks)
    print(f"=== {label} ({len(frameworks)} frameworks) ===")
    print(f"  symbols      {total:,}")
    print(f"  implemented  {implemented:,}  ({implemented / total * 100:.1f}%)")
    print(f"  declared     {declared:,}  ({declared / total * 100:.1f}%)")
    print(f"  deferred     {deferred:,}  ({deferred / total * 100:.1f}%)")
    print(f"  unavailable  {unavailable:,}")
    print(f"  n/a          {not_applicable:,}")
    print(f"  actionable   {declared + deferred:,}  (declared+deferred)")
    print()


def print_table(frameworks: list[dict], limit: int) -> None:
    print(
        f"{'slug':32} {'tot':6} {'impl':6} {'decl':6} {'def':6} "
        f"{'unav':5} {'na':5} {'impl%':7} action"
    )
    for item in frameworks[:limit]:
        print(
            f"{item['slug']:32} {item['total']:6} {item['implemented']:6} "
            f"{item['declared']:6} {item['deferred']:6} {item['unavailable']:5} "
            f"{item['not_applicable']:5} {item['pct'] * 100:6.1f}% {item['actionable']}"
        )
    print()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--slug", help="print one framework's status counts")
    parser.add_argument(
        "--leftover",
        metavar="SLUG",
        help="print declared/deferred/unavailable rows for one framework",
    )
    parser.add_argument("--limit", type=int, default=25)
    parser.add_argument("--lowest", type=int, default=0, help="N lowest impl%")
    parser.add_argument("--actionable", type=int, default=0, help="N most leftover")
    parser.add_argument("--min-total", type=int, default=0)
    parser.add_argument("--non-ui", action="store_true")
    args = parser.parse_args()

    full = repo_root() / "full"
    frameworks = load_frameworks(full)
    if args.non_ui:
        frameworks = [item for item in frameworks if not item["ui"]]

    if args.slug:
        match = next((item for item in frameworks if item["slug"] == args.slug), None)
        if match is None:
            raise SystemExit(f"no coverage.tsv for {args.slug}")
        print_summary(args.slug, [match])
        return 0

    if args.leftover:
        match = next((item for item in frameworks if item["slug"] == args.leftover), None)
        if match is None:
            raise SystemExit(f"no coverage.tsv for {args.leftover}")
        printed = 0
        for row in match["rows"]:
            if row[1] in {"implemented", "not-applicable"}:
                continue
            note = row[3] if len(row) > 3 else ""
            print(f"{row[1]:12} {row[0]}")
            if note:
                print(f"             {note}")
            printed += 1
            if printed >= args.limit:
                break
        if printed == 0:
            print(f"{args.leftover}: no leftover rows in the first {args.limit}")
        return 0

    print_summary("ALL", frameworks)
    if not args.non_ui:
        print_summary("non-UI", [item for item in frameworks if not item["ui"]])
        print_summary("UI-ish", [item for item in frameworks if item["ui"]])

    complete = [
        item for item in frameworks if item["pct"] == 1.0 and item["unavailable"] == 0
    ]
    print(
        f"{len(complete)} frameworks are 100% implemented "
        f"({sum(item['total'] for item in complete):,} symbols)."
    )
    print()

    pool = [item for item in frameworks if item["total"] >= args.min_total]
    if args.lowest:
        print(f"=== lowest implementation % (min total {args.min_total}) ===")
        print_table(sorted(pool, key=lambda item: item["pct"])[: args.lowest], args.lowest)
    if args.actionable:
        print("=== most remaining declared+deferred ===")
        print_table(
            sorted(pool, key=lambda item: item["actionable"], reverse=True)[: args.actionable],
            args.actionable,
        )
    if not args.lowest and not args.actionable:
        print("=== most remaining declared+deferred ===")
        print_table(
            sorted(pool, key=lambda item: item["actionable"], reverse=True),
            args.limit,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
