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

# Selectors ADJUDICATED against Apple's headers by scripts/check_public.py and
# found EQUIVALENT: the spellings differ, the representation does not (measured
# on macOS: CFIndex/NSInteger both 8B signed; Boolean/BOOL both 1B unsigned;
# CFComparisonResult/NSComparisonResult both 8B signed; CFStringRef, id,
# CFTypeRef, void const * all 8B pointers). Left as CF spells them, because
# rewriting them would churn declarations without changing a single register.
EQUIVALENT = {
    "addCharactersInString:",
    "addObject:",
    "appendBytes:length:",
    "appendString:",
    "boolValue",
    "calendarIdentifier",
    "code",
    "compare:",
    "data",
    "domain",
    "exchangeObjectAtIndex:withObjectAtIndex:",
    "formIntersectionWithCharacterSet:",
    "formUnionWithCharacterSet:",
    "hasMemberInPlane:",
    "increaseLengthBy:",
    "insertObject:atIndex:",
    "insertString:atIndex:",
    "longCharacterIsMember:",
    "member:",
    "name",
    "objectForKey:",
    "propertyForKey:",
    "read:maxLength:",
    "removeCharactersInString:",
    "removeObject:",
    "removeObjectAtIndex:",
    "removeObjectForKey:",
    "setObject:atIndex:",
    "setProperty:forKey:",
    "setString:",
    "setTimeZone:",
    "string",
    "userInfo",
    "write:maxLength:",
}

# Selectors with NO public reference at all -- SPI wearing public-looking names.
# The call site governs; "it looks like public API" is not evidence that it is.
NO_REFERENCE = {
    "baseURL",
    "bytes",
    "invertedSet",
    "localeIdentifier",
    "mutableBytes",
    "mutableString",
    "relativeString",
    "streamError",
}

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

# ENFORCED INVARIANT, not a comment. Reconciling a signature to Foundation's
# SPELLING requires Foundation's TYPEDEF to exist, or every file fails with
# "expected a type". That took the census to zero TWICE -- NSTimeInterval, then
# NSStreamStatus -- so it is now checked rather than remembered: every target
# type in RECONCILE must be declared in CFFoundationTypes.h, or this refuses to
# run. A note I forget twice is not a safeguard.
import os as _os
_types = _os.path.join(_os.path.dirname(_os.path.abspath(__file__)),
                       "..", "include", "CFFoundationTypes.h")
try:
    _decls = open(_types).read()
except OSError:
    _decls = ""
_builtin = {"BOOL", "unichar", "NSUInteger", "NSInteger", "id"}
_missing = sorted({t for t in RECONCILE.values()
                   if t not in _builtin and f"{t};" not in _decls})
if _missing:
    sys.exit(f"reconcile: target type(s) not declared in CFFoundationTypes.h: "
             f"{', '.join(_missing)}\n"
             f"           add the typedef before reconciling a signature to it.")

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
        elif sel in EQUIVALENT:
            stats["public-equivalent"] += 1
            out.append(f"    {sign} ({ret}){body};  {cite} /* public; measured equivalent */")
        elif sel in NO_REFERENCE:
            stats["public-no-reference"] += 1
            out.append(f"    {sign} ({ret}){body};  {cite} /* no public reference; SPI */")
        else:
            stats["public-unreviewed"] += 1
            out.append(f"    {sign} ({ret}){body};  {cite} /* PUBLIC, UNREVIEWED */")
    else:
        stats["unclassified"] += 1
        out.append(f"    {sign} ({ret}){body};  {cite} /* not in split */")

open(OUT, "w").write("\n".join(out) + "\n")
for k, v in sorted(stats.items()):
    print(f"  {k:<20} {v}")
