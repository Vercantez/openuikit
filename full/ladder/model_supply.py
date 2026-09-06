#!/usr/bin/env python3
"""Model-layer DEMAND (20 apps) against SUPPLY (what this stack actually has).

THE SUPPLY SIDE IS DERIVED, NOT ASSERTED. Every name below is placed by one of
(first match wins):

  * GUEST-ORACLE — declared in a file listed by
    `full/foundation/foundation_guest_sources.txt` AND named in
    guest-app-path.md / foundation-oracles.md as carrying a Darwin golden
    (DateFormatter, NumberFormatter, ISO8601DateFormatter,
    DateComponentsFormatter, JSONSerialization, NSRegularExpression,
    URLSession, ByteCountFormatter, UserDefaults, HTTPCookie,
    URLComponents).
  * GUEST-FOUNDATION — any other type declared `open`/`public` in those
    guest source files. Identifier-level: URLSession is here because
    `open class URLSession` is in URLSession.swift; URLSessionDataTask is
    GUEST-FOUNDATION once declared there.
  * LEDGER-IMPLEMENTED — the type name is the top-level title of a
    `coverage.tsv` row whose status is exactly `implemented`. `declared` /
    `deferred` / `unavailable` / `not-applicable` are not supply.
  * PACKAGE-PRODUCT — declared in the Combine or `os` OpenUIKit package
    product sources (uikit/Sources/Combine, uikit/Sources/os).
  * PROVEN (oracle passes, host and guest): URL
  * IN-FLIGHT (#77 json-oracle) — leftover names not in guest
  * COMPILED-UNVERIFIED (FoundationEssentials compile set from the 08-27
    measurement; kept as a floor, not re-derived — scratch/swift-foundation
    is not in this worktree)
  * SUBSTRATE-PRESENT (#45 _Concurrency, #47 libdispatch)
  * OPENUIKIT-SHADOWS
  * STUBBED (#69)
  * CF-BRIDGE-ONLY
  * ICU-BLOCKED (#48) — only names that are still not in guest Foundation
  * ABSENT

    ./model_supply.py <ladder-census.json> <out.json>
"""
import json, os, sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ledger_supply import (
    GUEST_ORACLE_FAMILIES, load_guest_foundation, load_ledgers, load_product_types,
)

PROVEN = {"URL"}
INFLIGHT = {"JSONDecoder", "JSONEncoder", "JSONSerialization", "Codable", "Decodable",
            "Encodable", "CodingKey", "CodingKeys", "Decoder", "Encoder",
            "KeyedDecodingContainer", "KeyedEncodingContainer", "UnkeyedDecodingContainer",
            "SingleValueDecodingContainer", "DecodingError", "EncodingError"}
COMPILED = {"Data", "Date", "DateComponents", "DateInterval", "Calendar", "TimeZone",
            "TimeInterval", "Locale", "UUID", "Decimal", "IndexPath", "Error",
            "AttributedString", "PropertyListDecoder", "PropertyListEncoder",
            "PropertyListSerialization", "Measurement"}
STUBBED = {"FileManager", "Bundle", "FileHandle", "FileWrapper", "DirectoryEnumerator",
           "NSSearchPathDirectory"}
ICU = {"DateFormatter", "ISO8601DateFormatter", "NumberFormatter", "ByteCountFormatter",
       "DateComponentsFormatter", "RelativeDateTimeFormatter", "MeasurementFormatter",
       "Formatter", "PersonNameComponentsFormatter", "NSNumberFormatter",
       "NSDateFormatter", "Unicode"}
SUBSTRATE = {"DispatchQueue", "DispatchGroup", "DispatchSemaphore", "DispatchWorkItem",
             "DispatchSource", "Task", "TaskGroup"}
OPENUIKIT = {"NotificationCenter", "Notification", "Timer", "RunLoop", "OperationQueue",
             "NSAttributedString", "NSMutableAttributedString"}
CFBRIDGE = {"NSString", "NSMutableString", "NSNumber", "NSValue", "NSArray",
            "NSMutableArray", "NSDictionary", "NSMutableDictionary", "NSSet",
            "NSMutableSet", "NSData", "NSMutableData", "NSDate", "NSError", "NSURL",
            "NSNull", "NSOrderedSet", "NSObject", "NSCoder"}

ORDER = ["PROVEN", "GUEST-ORACLE", "GUEST-FOUNDATION", "LEDGER-IMPLEMENTED",
         "PACKAGE-PRODUCT", "IN-FLIGHT", "COMPILED-UNVERIFIED", "SUBSTRATE-PRESENT",
         "OPENUIKIT-SHADOWS", "STUBBED (#69)", "CF-BRIDGE-ONLY", "ICU-BLOCKED (#48)",
         "ABSENT"]


def make_tagger(guest_types, oracle_types, ledger_types, product_types):
    def tag(s):
        if s in PROVEN:
            return "PROVEN"
        if s in oracle_types and s in guest_types:
            return "GUEST-ORACLE"
        if s in guest_types:
            return "GUEST-FOUNDATION"
        if s in ledger_types:
            return "LEDGER-IMPLEMENTED"
        if s in product_types:
            return "PACKAGE-PRODUCT"
        if s in INFLIGHT:
            return "IN-FLIGHT"
        if s in COMPILED:
            return "COMPILED-UNVERIFIED"
        if s in SUBSTRATE:
            return "SUBSTRATE-PRESENT"
        if s in OPENUIKIT:
            return "OPENUIKIT-SHADOWS"
        if s in STUBBED:
            return "STUBBED (#69)"
        if s in CFBRIDGE:
            return "CF-BRIDGE-ONLY"
        if s in ICU:
            return "ICU-BLOCKED (#48)"
        return "ABSENT"
    return tag


def main():
    L = json.load(open(sys.argv[1]))["apps"]
    here = os.path.dirname(os.path.abspath(__file__))
    full_root = os.path.abspath(os.path.join(here, ".."))
    uikit_src = os.path.join(os.path.dirname(full_root), "uikit", "Sources")
    guest_types, gfiles = load_guest_foundation(full_root)
    guest_types = set(guest_types)
    ledgers = load_ledgers(full_root)
    # A CoreData public-surface title `Data` is not Foundation.Data. Only
    # types the ledger's module owns may count as model-layer supply.
    COREDATA_PREFIX = ("NSManaged", "NSFetch", "NSPersistent", "NSEntity",
                      "NSBatch", "NSAtomic", "NSMigration", "NSMapping",
                      "NSConstraint", "NSRelationship", "NSAttribute",
                      "NSExpressionDescription", "NSPropertyDescription")
    ledger_types = set()
    for rec in ledgers["lanes"]:
        if rec["module"] == "CoreData":
            ledger_types.update(t for t in rec["implemented_types"]
                             if t.startswith(COREDATA_PREFIX))
        elif rec["module"] in ("Network", "OSLog", "Security", "CryptoKit"):
            ledger_types.update(rec["implemented_types"])
    prod = load_product_types(uikit_src)
    product_types = set()
    for names in prod.values():
        product_types.update(names)
    oracle_types = set(GUEST_ORACLE_FAMILIES)
    tag = make_tagger(guest_types, oracle_types, ledger_types, product_types)

    print(f"supply overlay: guest Foundation {len(gfiles)} files / {len(guest_types)} types; "
          f"ledger implemented type-names {len(ledger_types)}; "
          f"package-product types {len(product_types)}")

    apps, uses = defaultdict(set), defaultdict(int)
    for a, v in L.items():
        for s, c in v["model"]["all"].items():
            apps[s].add(a)
            uses[s] += c
    total = sum(uses.values())
    band_uses, band_syms = defaultdict(int), defaultdict(list)
    for s, c in uses.items():
        t = tag(s)
        band_uses[t] += c
        band_syms[t].append((s, len(apps[s]), c))

    print(f"MODEL-LAYER DEMAND vs SUPPLY -- {len(L)} apps, {total:,} references\n")
    print(f"{'band':<22}{'uses':>9}{'share':>8}   biggest members (apps/uses)")
    for b in ORDER:
        ms = sorted(band_syms[b], key=lambda t: -t[2])[:6]
        print(f"{b:<22}{band_uses[b]:>9}{100.0*band_uses[b]/total:>7.1f}%   "
              + ", ".join(f"{s}({a}/{c})" for s, a, c in ms))

    print("\nABSENT, ranked by how many of the 20 apps reference it:")
    ab = sorted(band_syms["ABSENT"], key=lambda t: (-t[1], -t[2]))
    print(f"  {'symbol':<28}{'apps':>5}{'uses':>8}")
    for s, a, c in ab[:35]:
        print(f"  {s:<28}{a:>5}{c:>8}")

    json.dump({"total": total,
               "supply": {
                   "guest_foundation_files": len(gfiles),
                   "guest_foundation_types": sorted(guest_types),
                   "ledger_implemented_type_names": sorted(ledger_types),
                   "package_product_types": sorted(product_types),
                   "n_ledgers": ledgers["n_ledgers"],
                   "supplied_modules": ledgers["supplied_modules"],
               },
               "bands": {b: {"uses": band_uses[b],
                              "symbols": sorted(band_syms[b], key=lambda t: -t[2])}
                         for b in ORDER}},
              open(sys.argv[2], "w"), indent=1)


if __name__ == "__main__":
    main()
