#!/usr/bin/env python3
"""Reconcile machine-derived declarations against the public/private split.

    reconcile.py <derived.h> <public-private.txt> <out.h>

The derived declarations come from CoreFoundation's call sites, which are
authoritative for DISPATCH but not for TYPE IDENTITY (docs/CF_TRIAGE.md §28):
CF asks for `- (CFIndex)count` because that is what CF does with the result;
Foundation declares `NSUInteger count`. Same width, same register, different
contract.

So:
  PRIVATE selector -> adopt the derived declaration verbatim. Nothing else exists.
  PUBLIC  selector -> the derived RETURN TYPE is replaced by Foundation's, using
                      the small reconciliation table below, which is written from
                      documented API rather than extracted from Apple's headers.
                      Anything public and not in the table is EMITTED WITH A
                      MARKER rather than silently adopted.

The table is deliberately small and hand-written. Its entries are the ones where
CF's local type and Foundation's declared type genuinely differ; everywhere else
the derived type already agrees and needs no override.
"""
import re, sys, collections

DERIVED, SPLIT, OUT = sys.argv[1], sys.argv[2], sys.argv[3]

# Foundation's declared return type where it differs from CF's local one.
# Written from documented Foundation API; verified with scripts/verify_sigs.py.
RECONCILE = {
    # CF uses CFIndex (signed long); Foundation declares NSUInteger (unsigned).
    "count":                    "NSUInteger",
    "length":                   "NSUInteger",
    "countForKey:":             "NSUInteger",
    "countForObject:":          "NSUInteger",
    "firstWeekday":             "NSUInteger",
    "minimumDaysInFirstWeek":   "NSUInteger",
    # MEASURED, and not one I would have predicted: CFStreamStatus is SIGNED,
    # NSStreamStatus is UNSIGNED. The names look like a straight rename, which
    # is exactly why it needed measuring rather than reading.
    "streamStatus":             "NSStreamStatus",
    # CF uses UniChar; Foundation declares unichar. Same type, Foundation spelling.
    "characterAtIndex:":        "unichar",
    # CF uses Boolean (unsigned char); Foundation declares BOOL (signed char).
    # Same width; BOOL is the contract.
    "containsKey:":             "BOOL",
    "containsObject:":          "BOOL",
    "isEqual:":                 "BOOL",
    "hasBytesAvailable":        "BOOL",
    "hasSpaceAvailable":        "BOOL",
    "isValid":                  "BOOL",
    "isFileReferenceURL":       "BOOL",
    # CFTimeInterval and NSTimeInterval are both double; NSTimeInterval is the
    # Foundation spelling.
    "timeIntervalSinceReferenceDate": "NSTimeInterval",
    "timeIntervalSinceDate:":         "NSTimeInterval",
    "timeInterval":                   "NSTimeInterval",
    "tolerance":                      "NSTimeInterval",
}

public, private = set(), set()
cur = None
for line in open(SPLIT):
    s = line.strip()
    if s.startswith("## PUBLIC"):   cur = public
    elif s.startswith("## PRIVATE"): cur = private
    elif cur is not None and s and not s.startswith("#"):
        cur.add(s)

DECL = re.compile(r'^\s*([-+])\s*\(([^)]*)\)\s*(.*?);\s*(/\*.*\*/)?\s*$')

def selector_of(body):
    parts = re.findall(r'(\w+):', body)
    return "".join(p + ":" for p in parts) if parts else body.strip()

out, cls = [], None
stats = collections.Counter()
for line in open(DERIVED):
    if line.startswith("@interface"):
        cls = line.split()[1]; out.append(line.rstrip()); continue
    if line.startswith("@end"):
        out.append("@end\n"); continue
    m = DECL.match(line)
    if not m:
        continue
    sign, ret, body, cite = m.group(1), m.group(2).strip(), m.group(3), m.group(4) or ""
    sel = selector_of(body)
    if sel in private:
        stats["private-adopted"] += 1
        out.append(f"    {sign} ({ret}){body};  {cite}")
    elif sel in public:
        if sel in RECONCILE:
            stats["public-reconciled"] += 1
            out.append(f"    {sign} ({RECONCILE[sel]}){body};  {cite} /* reconciled from ({ret}) */")
        else:
            stats["public-unreviewed"] += 1
            out.append(f"    {sign} ({ret}){body};  {cite} /* PUBLIC, UNREVIEWED */")
    else:
        stats["unclassified"] += 1
        out.append(f"    {sign} ({ret}){body};  {cite} /* not in split */")

open(OUT, "w").write("\n".join(out) + "\n")
for k, v in sorted(stats.items()):
    print(f"  {k:<20} {v}")
