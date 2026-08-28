#!/usr/bin/env python3
"""Model-layer DEMAND (20 apps) against SUPPLY (what this stack actually has).

THE SUPPLY SIDE IS DERIVED, NOT ASSERTED. Every name below is placed by one of:
  * the 202-file FoundationEssentials compile -- the directory it lives in under
    `scratch/swift-foundation/Sources/FoundationEssentials/` (COMPILED-UNVERIFIED)
  * a passing oracle (PROVEN: URL, 802/802 non-IDNA rows, host and guest)
  * an open task (#77 json-oracle IN-FLIGHT; #69 FileManager STUBBED;
    #48 libc++/ICU)
  * a completed port (#45 _Concurrency, #47 libdispatch: SUBSTRATE-PRESENT)
  * `Sources/OpenUIKit` declaring its own (OPENUIKIT-SHADOWS)
  * foundation-macho's emitted ObjC classes -- NSURL + 19 `__NSCF*`
    (CF-BRIDGE-ONLY: plumbing exists, a Swift-visible surface does not)
  * nothing (ABSENT)

WHAT THIS CANNOT TELL YOU. "COMPILED-UNVERIFIED" means 0 compile errors and
nothing else: only URL has been run against an oracle. The project's own record
(`false-green-verification-pattern`) is that a clean compile has repeatedly
meant less than it looked like. Read the band, not the percentage.
"""
import json, sys
from collections import defaultdict

PROVEN = {"URL"}
INFLIGHT = {"JSONDecoder", "JSONEncoder", "JSONSerialization", "Codable", "Decodable",
            "Encodable", "CodingKey", "CodingKeys", "Decoder", "Encoder",
            "KeyedDecodingContainer", "KeyedEncodingContainer", "UnkeyedDecodingContainer",
            "SingleValueDecodingContainer", "DecodingError", "EncodingError"}
# One per FoundationEssentials source directory / file that survived the compile.
COMPILED = {"Data", "Date", "DateComponents", "DateInterval", "Calendar", "TimeZone",
            "TimeInterval", "Locale", "UUID", "Decimal", "IndexPath", "Error",
            "AttributedString", "PropertyListDecoder", "PropertyListEncoder",
            "PropertyListSerialization", "Measurement"}
STUBBED = {"FileManager", "Bundle", "FileHandle", "FileWrapper", "DirectoryEnumerator",
           "NSSearchPathDirectory"}
# ICU-backed: locale-dependent formatting lives in FoundationInternationalization,
# which needs ICU, which is blocked on #48's libc++ link wall.
ICU = {"DateFormatter", "ISO8601DateFormatter", "NumberFormatter", "ByteCountFormatter",
       "DateComponentsFormatter", "RelativeDateTimeFormatter", "MeasurementFormatter",
       "Formatter", "PersonNameComponentsFormatter", "NSNumberFormatter",
       "NSDateFormatter", "Unicode"}
SUBSTRATE = {"DispatchQueue", "DispatchGroup", "DispatchSemaphore", "DispatchWorkItem",
             "DispatchSource", "Task", "TaskGroup"}
OPENUIKIT = {"NotificationCenter", "Notification", "Timer", "RunLoop", "OperationQueue",
             "NSAttributedString", "NSMutableAttributedString"}
# foundation-macho emits NSURL + 19 __NSCF* classes: the bridge exists, the
# Swift-visible API does not. This is the "plumbing without a surface" middle row.
CFBRIDGE = {"NSString", "NSMutableString", "NSNumber", "NSValue", "NSArray",
            "NSMutableArray", "NSDictionary", "NSMutableDictionary", "NSSet",
            "NSMutableSet", "NSData", "NSMutableData", "NSDate", "NSError", "NSURL",
            "NSNull", "NSOrderedSet", "NSObject", "NSCoder"}

ORDER = ["PROVEN", "IN-FLIGHT", "COMPILED-UNVERIFIED", "SUBSTRATE-PRESENT",
         "OPENUIKIT-SHADOWS", "STUBBED (#69)", "CF-BRIDGE-ONLY", "ICU-BLOCKED (#48)",
         "ABSENT"]


def tag(s):
    if s in PROVEN: return "PROVEN"
    if s in INFLIGHT: return "IN-FLIGHT"
    if s in COMPILED: return "COMPILED-UNVERIFIED"
    if s in SUBSTRATE: return "SUBSTRATE-PRESENT"
    if s in OPENUIKIT: return "OPENUIKIT-SHADOWS"
    if s in STUBBED: return "STUBBED (#69)"
    if s in CFBRIDGE: return "CF-BRIDGE-ONLY"
    if s in ICU: return "ICU-BLOCKED (#48)"
    return "ABSENT"


def main():
    L = json.load(open(sys.argv[1]))["apps"]
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
               "bands": {b: {"uses": band_uses[b],
                             "symbols": sorted(band_syms[b], key=lambda t: -t[2])}
                         for b in ORDER}},
              open(sys.argv[2], "w"), indent=1)


main()
