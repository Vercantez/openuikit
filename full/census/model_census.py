#!/usr/bin/env python3
"""Model-layer API census -- the half Tools/apicensus cannot see.

~/uikit's census scans for `\\b((?:UI|NS|CA)[A-Z]...)` filtered against UIKit
SDK headers. Modern Swift Foundation is invisible to it by construction:
URLSession, JSONDecoder, Date, Data, FileManager, Codable and UserDefaults do
not start with UI/NS/CA and are not UIKit types. So it measured the
presentation half and said nothing about the model layer.

Same corpus, same weighting (uses + how many distinct apps), different alphabet:
Foundation's own types, taken from the SDK rather than hand-listed --
@interface/@protocol names from Foundation.framework/Headers plus the public
types declared in Foundation's .swiftinterface.
"""
import json, os, re, sys
from collections import defaultdict

SYM = re.compile(r'\b([A-Z][A-Za-z0-9_]*)\b')
IMPORT = re.compile(r'^\s*(?:@[a-zA-Z_]+\s+)*import\s+([A-Za-z_][A-Za-z0-9_.]*)', re.M)

# Families, so the result is actionable rather than a flat 300-row table.
# A type may appear in only one family; first match wins.
FAMILIES = [
    ("networking",   {"URLSession","URLSessionTask","URLSessionDataTask","URLSessionDownloadTask",
                      "URLSessionUploadTask","URLSessionConfiguration","URLSessionDelegate",
                      "URLSessionTaskDelegate","URLSessionDataDelegate","URLRequest","URLResponse",
                      "HTTPURLResponse","URLComponents","URLQueryItem","URLCache","URLCredential",
                      "URLProtectionSpace","URLAuthenticationChallenge","NSURLSession","NSURLRequest",
                      "NSURLResponse","NSHTTPURLResponse","NSURLComponents","NSURLConnection",
                      "URLProtocol","NSURLProtocol","URLError"}),
    ("json/coding",  {"JSONDecoder","JSONEncoder","JSONSerialization","Codable","Decodable",
                      "Encodable","CodingKey","CodingKeys","Decoder","Encoder","KeyedDecodingContainer",
                      "KeyedEncodingContainer","UnkeyedDecodingContainer","SingleValueDecodingContainer",
                      "PropertyListDecoder","PropertyListEncoder","PropertyListSerialization",
                      "NSJSONSerialization","DecodingError","EncodingError"}),
    ("dates",        {"Date","DateFormatter","ISO8601DateFormatter","DateComponents","DateInterval",
                      "Calendar","TimeZone","DateComponentsFormatter","RelativeDateTimeFormatter",
                      "NSDate","NSDateFormatter","NSCalendar","NSTimeZone","NSDateComponents",
                      "TimeInterval","DateFormatterStyle"}),
    ("files",        {"FileManager","FileHandle","URL","NSURL","NSFileManager","NSFileHandle",
                      "Bundle","NSBundle","FileWrapper","DirectoryEnumerator","NSSearchPathDirectory"}),
    ("persistence",  {"UserDefaults","NSUserDefaults","NSKeyedArchiver","NSKeyedUnarchiver",
                      "NSCoding","NSSecureCoding","NSCoder","NSManagedObject","NSManagedObjectContext",
                      "NSPersistentContainer","NSFetchRequest","NSEntityDescription","NSPredicate",
                      "NSSortDescriptor","NSFetchedResultsController","NSManagedObjectModel"}),
    ("text/format",  {"NumberFormatter","ByteCountFormatter","MeasurementFormatter","Measurement",
                      "PersonNameComponentsFormatter","Formatter","NSNumberFormatter","Locale",
                      "NSLocale","CharacterSet","NSCharacterSet","Scanner","NSScanner",
                      "NSAttributedString","NSMutableAttributedString","NSRegularExpression",
                      "NSTextCheckingResult","NSString","NSMutableString","Unicode"}),
    ("concurrency",  {"OperationQueue","Operation","BlockOperation","DispatchQueue","DispatchGroup",
                      "DispatchSemaphore","DispatchWorkItem","DispatchSource","Task","TaskGroup",
                      "NSOperationQueue","NSOperation","NSLock","NSRecursiveLock","NSCondition",
                      "Thread","NSThread","RunLoop","NSRunLoop","Timer","NSTimer"}),
    ("collections",  {"NSArray","NSMutableArray","NSDictionary","NSMutableDictionary","NSSet",
                      "NSMutableSet","NSOrderedSet","NSCache","NSNull","NSNumber","NSValue",
                      "NSData","Data","NSMutableData","IndexSet","NSIndexSet","UUID","NSUUID",
                      "Decimal","NSDecimalNumber","NSError","Error","NSException"}),
    ("notification", {"NotificationCenter","NSNotificationCenter","Notification","NSNotification",
                      "NSNotificationName","KeyValueObservingPublisher","NSKeyValueObserving"}),
]
FAMILY_OF = {}
for fam, names in FAMILIES:
    for n in names:
        FAMILY_OF.setdefault(n, fam)


def sdk_foundation_types(sdk):
    types = set()
    hdrs = os.path.join(sdk, "System/Library/Frameworks/Foundation.framework/Headers")
    rx = re.compile(r'^@(?:interface|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)', re.M)
    for root, _, files in os.walk(hdrs):
        for f in files:
            if f.endswith(".h"):
                try:
                    types |= set(rx.findall(open(os.path.join(root, f),
                                                 encoding="utf-8", errors="ignore").read()))
                except OSError:
                    pass
    # The .swiftinterface is DELIBERATELY NOT scraped. Doing so sweeps in every
    # nested/generic type name Foundation happens to declare -- Message,
    # Category, Field, Language, Currency, Style, Value, Code, Encoding -- which
    # then match APP-DEFINED types of the same name and get reported as
    # Foundation gaps. Measured: it inflated "nothing at all" by ~2,900 uses,
    # nearly all of them app types. The alphabet is therefore the ObjC header
    # names (unambiguously Foundation, all NS*-prefixed) plus the explicitly
    # curated Swift value types in FAMILIES, each of which is a name Foundation
    # genuinely owns.
    return types


def main():
    corpus, sdk = sys.argv[1], sys.argv[2]
    ftypes = sdk_foundation_types(sdk)
    # The families name things the SDK lists under other modules (Dispatch,
    # Swift). Count them too -- a model layer that calls DispatchQueue is
    # exercising the same substrate question.
    ftypes |= set(FAMILY_OF)
    print(f"Foundation-ish type alphabet: {len(ftypes)}", file=sys.stderr)

    uses = defaultdict(int)
    apps_with = defaultdict(set)
    imports = defaultdict(lambda: defaultdict(int))
    per_app_files = {}

    for app in sorted(os.listdir(corpus)):
        adir = os.path.join(corpus, app)
        if not os.path.isdir(adir):
            continue
        n = 0
        for root, dirs, files in os.walk(adir):
            dirs[:] = [d for d in dirs if d not in (".git", "Carthage", "Pods", ".build")]
            for f in files:
                if not f.endswith(".swift"):
                    continue
                n += 1
                try:
                    src = open(os.path.join(root, f), encoding="utf-8", errors="ignore").read()
                except OSError:
                    continue
                for m in IMPORT.findall(src):
                    imports[app][m.split(".")[0]] += 1
                for s in SYM.findall(src):
                    if s in ftypes:
                        uses[s] += 1
                        apps_with[s].add(app)
        per_app_files[app] = n

    rows = sorted(uses.items(), key=lambda kv: (-len(apps_with[kv[0]]), -kv[1]))
    out = {
        "apps": {a: {"files": per_app_files[a]} for a in per_app_files},
        "symbols": [{"symbol": s, "apps": len(apps_with[s]), "uses": c} for s, c in rows],
        "imports": {a: dict(sorted(d.items(), key=lambda kv: -kv[1])[:25]) for a, d in imports.items()},
    }
    json.dump(out, open(sys.argv[3], "w"), indent=1)

    total = sum(uses.values())
    print(f"\ntotal model-layer symbol references: {total}\n")
    byfam = defaultdict(int)
    famapps = defaultdict(set)
    for s, c in uses.items():
        fam = FAMILY_OF.get(s)
        if fam:
            byfam[fam] += c
            famapps[fam] |= apps_with[s]
    print(f"{'family':<14}{'uses':>8}{'apps':>6}   share")
    for fam, c in sorted(byfam.items(), key=lambda kv: -kv[1]):
        print(f"{fam:<14}{c:>8}{len(famapps[fam]):>6}   {100.0*c/total:5.1f}%")
    print(f"\nTOP 30 individual symbols (all 4 apps first):")
    for r in rows[:30]:
        print(f"  {r[0]:<28} apps={len(apps_with[r[0]])} uses={r[1]}")


main()
