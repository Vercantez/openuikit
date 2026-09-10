#!/usr/bin/env python3
"""APP LADDER census -- per-app distance-from-runnable, measured six ways.

This is NOT a new method. It is the three existing instruments
(`~/uikit/Tools/apicensus/census.py`, `full/census/model_census.py`,
`full/census/swiftui_census.py`) re-cut PER APP instead of aggregated, plus two
things none of them measure: `#selector`/`@objc` density with a wiring-vs-deep
classification, and build-system shape.

EACH NUMBER'S BLINDNESS, STATED HERE SO IT TRAVELS WITH THE NUMBER:

  uikit_types   apicensus's `\\b((?:UI|NS|CA)[A-Z]\\w*)\\b` filtered against the
                737 @interface/@protocol names in the Mac Catalyst UIKit
                headers. Blind to: types referenced only via inference
                (`let v = UIView()` is seen, `view.addSubview(x)` where x's
                type is inferred is not), protocol conformances written
                indirectly, and anything in a string. Over-counts dead code.
                Line comments are stripped; block comments are NOT.

  model_syms    model_census's alphabet: Foundation's ObjC header names (all
                NS*-prefixed, unambiguous) plus a curated set of Swift value
                types. Blind to: the difference between `Foundation.Data` and
                an app's own `Data`. Families and rankings robust; individual
                counts are order-of-magnitude.

  swiftui       swiftui_census's UNAMBIGUOUS-ONLY signals: `: View` /
                `some View` / `var body:` / `@State`-family attributes. It
                deliberately produces NO API-use count -- see that script's
                docstring. `import SwiftUI` is reported separately because it
                OVER-counts adoption (a file can import and declare nothing).

  selectors     Textual. `#selector(` and `@objc` occurrences, classified by
                what else is on the same line. A site whose wiring is on
                another line lands in `unclassified`, which is therefore a
                floor on both categories, not a residue.

  build         File-existence and line-grep. `pod '` counts Podfile lines,
                not resolved transitive pods; SPM deps are counted from
                Package.resolved pins (transitive) and from xcodeproj
                repositoryURL entries (direct). These are different
                denominators and are reported separately.

  size          `.swift`/`.m`/`.mm`/`.h` file and line counts. Lines include
                blanks and comments.

TWO WALKS, TWO DENOMINATORS, ON PURPOSE. The UIKit census walk excludes
Tests/ (apicensus's SKIP_DIRS) so its numbers are comparable to the recorded
census; the model/SwiftUI walk does not (those scripts' skip set). Every count
below names which walk produced it.

TARGET SCOPE (optional, `--target-scope=FILE`). The default walk is the WHOLE
repository, which for a repo shipping a Mac app and an iOS app from one tree
counts AppKit demand as phone demand (NetNewsWire: `NSToolbarItem` 48 uses,
all under Mac/ or `#if os(macOS)`). A scope file -- written by
`target_scope.py` from the .xcodeproj -- lists, per app name, the source files
ONE target compiles plus its local packages. For an app named in the file,
every per-file walk here (UIKit, model/SwiftUI/selector, language mix) is
restricted to that list; `build` (repo shape) is not, because it is a
property of the repository. Apps NOT named in the file are walked exactly as
before -- the control is that their output is byte-identical with and without
the flag. The census records the scope's provenance under `_scope` so a scoped
JSON cannot be mistaken for a whole-repo one.
"""
import json, os, re, sys
from collections import defaultdict

# ---------------------------------------------------------------- walks

# apicensus's SKIP_DIRS, verbatim -- this is what makes the control reproduce.
SKIP_UIKIT = {".git", "Pods", "Carthage", "build", ".build", "DerivedData",
              "node_modules", "vendor", "Tests", "TestsSupport"}
# model_census / swiftui_census's skip set, verbatim.
SKIP_MODEL = {".git", "Carthage", "Pods", ".build"}


def walk(root, skip, exts, scope=None):
    """Yield files under root. `scope` (a set of POSIX relpaths) restricts the
    walk to exactly those files; the skip set still applies on top of it."""
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in skip]
        for f in filenames:
            if os.path.splitext(f)[1] in exts:
                path = os.path.join(dirpath, f)
                if scope is not None and \
                        os.path.relpath(path, root).replace(os.sep, "/") not in scope:
                    continue
                yield path


def read(path):
    try:
        return open(path, encoding="utf-8", errors="ignore").read()
    except OSError:
        return ""


# ---------------------------------------------------------------- 1. UIKit

SYMBOL_RE = re.compile(r'\b((?:UI|NS|CA)[A-Z][A-Za-z0-9_]*)\b')
MEMBER_RE = re.compile(r'\b(UI[A-Z][A-Za-z0-9_]*)\s*\.\s*([a-z][A-Za-z0-9_]*)')


def uikit_census(root, sdk_types, scope=None):
    types, members = defaultdict(int), defaultdict(int)
    nfiles = 0
    for path in walk(root, SKIP_UIKIT, {".swift"}, scope):
        nfiles += 1
        src = re.sub(r'//[^\n]*', '', read(path))
        for m in SYMBOL_RE.finditer(src):
            if m.group(1) in sdk_types:
                types[m.group(1)] += 1
        for m in MEMBER_RE.finditer(src):
            if m.group(1) in sdk_types:
                members[(m.group(1), m.group(2))] += 1
    return types, members, nfiles


# ---------------------------------------------------------------- 2. model

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
for _fam, _names in FAMILIES:
    for _n in _names:
        FAMILY_OF.setdefault(_n, _fam)

SYM = re.compile(r'\b([A-Z][A-Za-z0-9_]*)\b')
IMPORT = re.compile(r'^\s*(?:@[a-zA-Z_]+\s+)*import\s+([A-Za-z_][A-Za-z0-9_.]*)', re.M)

# ---------------------------------------------------------------- 3. SwiftUI

WRAPPERS = ["State", "Binding", "StateObject", "ObservedObject", "EnvironmentObject",
            "Environment", "Published", "AppStorage", "SceneStorage", "FocusState",
            "GestureState", "Namespace", "ViewBuilder", "Bindable", "Observable",
            "MainActor", "FetchRequest", "ScaledMetric"]
WRAPPER_RE = {w: re.compile(r'@' + w + r'\b') for w in WRAPPERS}
SOME_VIEW = re.compile(r'\bsome\s+View\b')
CONFORM_VIEW = re.compile(r'\b(?:struct|enum|class)\s+\w+\s*:[^{\n]*\bView\b')
BODY_DECL = re.compile(r'\bvar\s+body\s*:')
PREVIEW = re.compile(r'#Preview\b|\bPreviewProvider\b')
COMBINE_TYPES = ["AnyCancellable", "PassthroughSubject", "CurrentValueSubject",
                 "AnyPublisher", "ObservableObject"]
COMBINE_RE = {c: re.compile(r'\b' + c + r'\b') for c in COMBINE_TYPES}
IMPORT_SWIFTUI = re.compile(r'^\s*import\s+SwiftUI\s*$', re.M)
IMPORT_COMBINE = re.compile(r'^\s*import\s+Combine\s*$', re.M)
IMPORT_UIKIT = re.compile(r'^\s*import\s+UIKit\s*$', re.M)
TESTISH = re.compile(r'(?:^|/)(?:Tests?|Specs?)[^/]*/|Tests?\.swift$|Spec\.swift$', re.I)

# UIKit-declaring signal, the mirror of `: View`: a type that subclasses a
# UIKit view/controller. Unambiguous in the same way -- the superclass name is
# UIKit's and nobody else's.
UIKIT_SUBCLASS = re.compile(
    r'\bclass\s+\w+\s*:\s*[^{\n]*\b(UIView|UIViewController|UITableViewController|'
    r'UICollectionViewController|UITableViewCell|UICollectionViewCell|UIControl|'
    r'UILabel|UIButton|UIImageView|UIScrollView|UIStackView|UITextField|UITextView|'
    r'UINavigationController|UITabBarController|UIWindow|UIResponder|UIApplication)\b')

# ---------------------------------------------------------------- 4. selectors

SELECTOR_RE = re.compile(r'#selector\s*\(')
OBJC_RE = re.compile(r'@objc\b')
OBJC_DYNAMIC = re.compile(r'@objc\s+dynamic\b')
OBJC_PROTOCOL = re.compile(r'@objc\s+(?:public\s+|private\s+|internal\s+)?protocol\b')
OBJC_NAMED = re.compile(r'@objc\s*\(')
OBJC_MEMBERS = re.compile(r'@objcMembers\b')

WIRING_HINTS = re.compile(
    r'addTarget|GestureRecognizer|UIBarButtonItem|barButtonSystemItem|'
    r'scheduledTimer|Timer\s*\(|addObserver|NotificationCenter|'
    r'UIAction|addAction|refreshControl|UIMenuItem|UIKeyCommand|'
    r'UIApplicationShortcut|displayLink|CADisplayLink|action:')
DEEP_HINTS = re.compile(
    r'forKeyPath|observeValue|\bperform\s*\(|responds\s*\(\s*to|'
    r'class_addMethod|method_exchangeImplementations|method_getImplementation|'
    r'NSInvocation|objc_|value\s*\(\s*forKey|setValue\s*\(.*forKey|'
    r'NSSortDescriptor|NSPredicate\s*\(\s*format|conformsToProtocol')

IBOUTLET = re.compile(r'@IBOutlet\b')
IBACTION = re.compile(r'@IBAction\b')

# ---------------------------------------------------------------- 5. build

POD_LINE = re.compile(r'^\s*pod\s+[\'"]', re.M)
SPM_PIN_IDENTITY = re.compile(r'"identity"\s*:')
SPM_REPO_URL = re.compile(r'repositoryURL\s*=\s*"([^"]+)"')
SPM_DEP_URL = re.compile(r'\.package\s*\(\s*(?:name:[^,]+,\s*)?url\s*:\s*"([^"]+)"')


def build_shape(root):
    b = {"spm_manifests": 0, "xcodeproj": 0, "xcworkspace": 0, "podfile": False,
         "pods_declared": 0, "pods_vendored": False, "cartfile": False,
         "carthage_vendored": False, "tuist": False, "bazel": 0,
         "spm_pins": 0, "spm_direct_urls": 0, "submodules": 0,
         "xcassets": 0, "xib_storyboard": 0, "strings_files": 0}
    seen_urls = set()
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in {".git", "node_modules"}]
        base = os.path.basename(dirpath)
        if base == "Pods":
            b["pods_vendored"] = True
            dirnames[:] = []
            continue
        if base == "Carthage":
            b["carthage_vendored"] = True
            dirnames[:] = []
            continue
        for d in list(dirnames):
            if d.endswith(".xcodeproj"):
                b["xcodeproj"] += 1
                pbx = os.path.join(dirpath, d, "project.pbxproj")
                if os.path.exists(pbx):
                    seen_urls |= set(SPM_REPO_URL.findall(read(pbx)))
                dirnames.remove(d)
            elif d.endswith(".xcworkspace"):
                b["xcworkspace"] += 1
                dirnames.remove(d)
            elif d.endswith(".xcassets"):
                b["xcassets"] += 1
                dirnames.remove(d)
            elif d == "Tuist":
                b["tuist"] = True
        for f in filenames:
            if f == "Package.swift":
                b["spm_manifests"] += 1
                seen_urls |= set(SPM_DEP_URL.findall(read(os.path.join(dirpath, f))))
            elif f == "Package.resolved":
                b["spm_pins"] += len(SPM_PIN_IDENTITY.findall(read(os.path.join(dirpath, f))))
            elif f == "Podfile":
                b["podfile"] = True
                b["pods_declared"] += len(POD_LINE.findall(read(os.path.join(dirpath, f))))
            elif f == "Cartfile":
                b["cartfile"] = True
            elif f == "Project.swift":
                b["tuist"] = True
            elif f in ("BUILD", "BUILD.bazel", "WORKSPACE"):
                b["bazel"] += 1
            elif f == ".gitmodules":
                b["submodules"] += read(os.path.join(dirpath, f)).count("[submodule")
            elif f.endswith((".xib", ".storyboard")):
                b["xib_storyboard"] += 1
            elif f.endswith(".strings"):
                b["strings_files"] += 1
    b["spm_direct_urls"] = len(seen_urls)
    b["_dep_urls"] = sorted(seen_urls)
    return b


# ---------------------------------------------------------------- driver

def census_app(root, sdk_types, ours, scope=None):
    r = {}

    # --- walk 1: apicensus's, Tests excluded ---
    types, members, uikit_files = uikit_census(root, sdk_types, scope)
    missing = {t: c for t, c in types.items() if t not in ours}
    have = {t: c for t, c in types.items() if t in ours}
    r["uikit"] = {
        "walk": "apicensus SKIP_DIRS (Tests excluded)",
        "swift_files": uikit_files,
        "uses": sum(types.values()),
        "distinct_types": len(types),
        "implemented_types": len(have), "implemented_uses": sum(have.values()),
        "missing_types": len(missing), "missing_uses": sum(missing.values()),
        "missing": sorted(missing.items(), key=lambda kv: -kv[1]),
        "top_used": sorted(types.items(), key=lambda kv: -kv[1])[:40],
        "missing_members_of_implemented": sorted(
            ({"type": t, "member": m, "uses": c}
             for (t, m), c in members.items() if t in ours),
            key=lambda d: -d["uses"])[:40],
    }

    # --- walk 2: model/swiftui, Tests included ---
    m = defaultdict(int)
    model_uses, model_apps_syms = defaultdict(int), set()
    imports = defaultdict(int)
    swift_lines = 0
    for path in walk(root, SKIP_MODEL, {".swift"}, scope):
        rel = os.path.relpath(path, root)
        src = read(path)
        m["files"] += 1
        swift_lines += src.count("\n") + 1
        is_test = bool(TESTISH.search(rel))
        if is_test:
            m["test_files"] += 1
        for name in IMPORT.findall(src):
            imports[name.split(".")[0]] += 1
        for s in SYM.findall(src):
            if s in FAMILY_OF:
                model_uses[s] += 1
                model_apps_syms.add(s)
        imp_sui = bool(IMPORT_SWIFTUI.search(src))
        if imp_sui:
            m["import_swiftui"] += 1
            if is_test:
                m["import_swiftui_test"] += 1
        if IMPORT_COMBINE.search(src):
            m["import_combine"] += 1
        if IMPORT_UIKIT.search(src):
            m["import_uikit"] += 1
        views = len(CONFORM_VIEW.findall(src))
        someview = len(SOME_VIEW.findall(src))
        if views or someview:
            m["view_bearing_files"] += 1
            if is_test:
                m["view_bearing_test_files"] += 1
        m["view_types"] += views
        m["some_view"] += someview
        m["body_decls"] += len(BODY_DECL.findall(src))
        m["previews"] += len(PREVIEW.findall(src))
        subs = len(UIKIT_SUBCLASS.findall(src))
        if subs:
            m["uikit_subclass_files"] += 1
            if is_test:
                m["uikit_subclass_test_files"] += 1
        m["uikit_subclasses"] += subs
        for w, rx in WRAPPER_RE.items():
            n = len(rx.findall(src))
            if n:
                m["wrapper:" + w] += n
        for c, rx in COMBINE_RE.items():
            n = len(rx.findall(src))
            if n:
                m["combine:" + c] += n

        # selectors, same walk
        sels = SELECTOR_RE.findall(src)
        if sels:
            m["selector_files"] += 1
        m["selector_sites"] += len(sels)
        for line in src.splitlines():
            if "#selector" in line:
                if DEEP_HINTS.search(line):
                    m["selector_deep"] += line.count("#selector")
                elif WIRING_HINTS.search(line):
                    m["selector_wiring"] += line.count("#selector")
                else:
                    m["selector_unclassified"] += line.count("#selector")
        nobjc = len(OBJC_RE.findall(src))
        if nobjc:
            m["objc_files"] += 1
        m["objc_sites"] += nobjc
        m["objc_dynamic"] += len(OBJC_DYNAMIC.findall(src))
        m["objc_protocol"] += len(OBJC_PROTOCOL.findall(src))
        m["objc_named"] += len(OBJC_NAMED.findall(src))
        m["objcmembers"] += len(OBJC_MEMBERS.findall(src))
        m["iboutlet"] += len(IBOUTLET.findall(src))
        m["ibaction"] += len(IBACTION.findall(src))

    r["swift_lines"] = swift_lines
    r["swiftui"] = {k: m[k] for k in m if not k.startswith(("wrapper:", "combine:"))}
    r["swiftui"]["wrappers"] = {k.split(":")[1]: m[k] for k in m if k.startswith("wrapper:")}
    r["swiftui"]["combine"] = {k.split(":")[1]: m[k] for k in m if k.startswith("combine:")}

    byfam, famsyms = defaultdict(int), defaultdict(list)
    for s, c in model_uses.items():
        byfam[FAMILY_OF[s]] += c
        famsyms[FAMILY_OF[s]].append((s, c))
    r["model"] = {
        "walk": "model_census skip set (Tests included)",
        "uses": sum(model_uses.values()),
        "families": dict(sorted(byfam.items(), key=lambda kv: -kv[1])),
        "top": sorted(model_uses.items(), key=lambda kv: -kv[1])[:40],
        "all": dict(sorted(model_uses.items(), key=lambda kv: -kv[1])),
    }
    r["imports"] = dict(sorted(imports.items(), key=lambda kv: -kv[1])[:30])

    # --- ObjC / other language mix ---
    lang = defaultdict(int)
    langlines = defaultdict(int)
    for path in walk(root, SKIP_MODEL,
                     {".m", ".mm", ".h", ".swift", ".c", ".cpp", ".cc", ".kt", ".java"}, scope):
        ext = os.path.splitext(path)[1]
        lang[ext] += 1
        langlines[ext] += read(path).count("\n") + 1
    r["languages"] = {"files": dict(lang), "lines": dict(langlines)}

    r["build"] = build_shape(root)
    if scope is not None:
        r["_scope"] = {"files": len(scope),
                       "note": "per-file walks restricted to target_scope.py's list; "
                               "`build` is repo-wide"}
    return r


def main():
    # `--target-scope=FILE` may appear anywhere; it is removed before the
    # positional arguments are read, so every existing invocation is unchanged.
    scopes, argv = {}, []
    for a in sys.argv[1:]:
        if a.startswith("--target-scope="):
            doc = json.load(open(a.split("=", 1)[1]))
            for app, s in doc["apps"].items():
                scopes[app] = {"files": set(s["files"]), "source": a.split("=", 1)[1],
                               "target": s.get("target"), "rule": s.get("rule")}
        else:
            argv.append(a)
    sys.argv = [sys.argv[0]] + argv
    corpus, sdk_file, ours_file, out_file = sys.argv[1:5]
    # Optional 5th arg: extra directory names to skip, in BOTH walks.
    #
    # THIS EXISTS BECAUSE OF A MEASURED DEFECT, not as a convenience. Run over
    # DEPENDENCY repos the census read their demo apps and documentation as
    # library code: Alamofire's `watchOS Example/ContentView.swift` and GRDB's
    # `Documentation/DemoApps/` each declare `struct X: View`, which classified
    # two pure-Swift libraries as SwiftUI-bound. Kingfisher's `Demo/` did the
    # same on top of a REAL SwiftUI surface, so the false positive sat invisibly
    # next to a true positive. Apps do not have this problem -- a demo app
    # inside an app repo is part of the app -- so the 20-app corpus run passes
    # NO extra skips and its numbers are unchanged by this option.
    if len(sys.argv) > 5:
        extra = {d for d in sys.argv[5].split(",") if d}
        SKIP_UIKIT.update(extra)
        SKIP_MODEL.update(extra)
        print(f"extra skip dirs: {sorted(extra)}", file=sys.stderr)
    sdk_types = set(open(sdk_file).read().split())
    ours = set(open(ours_file).read().split())
    print(f"UIKit SDK types: {len(sdk_types)}   OpenUIKit types: {len(ours)}", file=sys.stderr)

    out = {"_meta": {"sdk_types": len(sdk_types), "ours": len(ours)}, "apps": {}}
    if scopes:
        out["_scope"] = {app: {k: v for k, v in s.items() if k != "files"} | {"files": len(s["files"])}
                         for app, s in scopes.items()}
    for app in sorted(os.listdir(corpus)):
        adir = os.path.join(corpus, app)
        if not os.path.isdir(adir) or not os.path.isdir(os.path.join(adir, ".git")):
            continue
        scope = scopes.get(app, {}).get("files")
        print(f"  {app} ..." + (f" [scope: {len(scope)} files]" if scope else ""),
              file=sys.stderr, flush=True)
        out["apps"][app] = census_app(adir, sdk_types, ours, scope)
    json.dump(out, open(out_file, "w"), indent=1)
    print(f"wrote {out_file}", file=sys.stderr)


main()
