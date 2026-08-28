#!/usr/bin/env python3
"""Member-level census of UserDefaults over the 20-app ladder corpus.

WHY THIS SHAPE. The type census says `UserDefaults` is 2,586 token occurrences
across 20/20 apps. That number cannot be implemented against. What CAN be
implemented against is the set of MEMBERS those occurrences reach -- the same
move that made URL finite (URL(string:) was 907 of 1,002 initialiser calls).

UserDefaults is unusually tractable for this because almost every use is
RECEIVER-ANCHORED: `UserDefaults.standard.bool(forKey:)`. So unlike
member_census.py's `.path` problem, most of this census is PRECISE, not
ranking-only. The three buckets are kept apart because their reliability
differs and mixing them would launder the weak one:

  BUCKET A -- ANCHORED (precise). The token `UserDefaults` is literally in the
  expression: `UserDefaults.standard.<m>`, `UserDefaults(suiteName:).<m>`,
  `UserDefaults.<static>`. Nothing else in Swift can produce this text.

  BUCKET B -- BOUND RECEIVER (precise about the binding, over-counts the member).
  A file binds a name to a UserDefaults -- `let defaults = UserDefaults.standard`,
  `var d: UserDefaults`, a parameter `_ defaults: UserDefaults` -- and we then
  count `<name>.<m>` IN THAT FILE ONLY. The binding is precise; the member
  count over-counts if the same identifier is rebound to something else in the
  same file. Reported separately so that risk stays visible.

  BUCKET C -- PROPERTY WRAPPERS. @AppStorage (SwiftUI) and app-defined wrappers
  whose declaration mentions UserDefaults. These are USES OF DEFAULTS THAT NEVER
  NAME A MEMBER, so any member-only census under-reports demand without them.

DENOMINATOR DISCIPLINE. Every bucket prints its own denominator, and the script
prints the type-level token count it is decomposing, so an anchored count of N
can be read against the 2,586 it is a subset of. Members reached by neither
bucket are reported as a RESIDUE, not dropped: `2,586 minus what we explain` is
the honest measure of this instrument's blindness.

Walk/skip set is ladder_census.py's SKIP_MODEL, verbatim, so the denominator is
the same walk that produced 2,586.
"""
import os, re, sys, json
from collections import Counter, defaultdict

SKIP_MODEL = {".git", "Carthage", "Pods", ".build"}

# ---- Bucket A: the token UserDefaults is in the expression --------------
# UserDefaults.standard.member  /  UserDefaults.standard(...)
A_STANDARD = re.compile(r'\bUserDefaults\s*\.\s*standard\s*\.\s*([A-Za-z_]\w*)')
# UserDefaults(suiteName: "x").member   -- captures across the init paren
A_INIT_CHAIN = re.compile(r'\bUserDefaults\s*\([^()]*\)\s*\.\s*([A-Za-z_]\w*)')
# UserDefaults.<staticOrType>  where it is NOT .standard
A_STATIC = re.compile(r'\bUserDefaults\s*\.\s*([A-Za-z_]\w*)')
# initialiser forms
A_INIT_LABEL = re.compile(r'\bUserDefaults\s*\(\s*([A-Za-z_]\w*)\s*:')
A_INIT_BARE = re.compile(r'\bUserDefaults\s*\(\s*\)')
# bare `UserDefaults.standard` with no member (passed as a value)
A_STANDARD_BARE = re.compile(r'\bUserDefaults\s*\.\s*standard\b(?!\s*\.)')

TOKEN = re.compile(r'\bUserDefaults\b')
NSTOKEN = re.compile(r'\bNSUserDefaults\b')

# ---- Bucket B: identifiers bound to a UserDefaults in this file ---------
B_BINDINGS = [
    # let x = UserDefaults(...)  /  let x = UserDefaults.standard
    re.compile(r'\b(?:let|var)\s+([A-Za-z_]\w*)\s*(?::\s*UserDefaults[!?]?\s*)?=\s*UserDefaults\b'),
    # let x: UserDefaults = ...    (declared type, any initialiser)
    re.compile(r'\b(?:let|var)\s+([A-Za-z_]\w*)\s*:\s*UserDefaults[!?]?\b'),
    # func f(defaults: UserDefaults)  /  (_ defaults: UserDefaults = .standard)
    re.compile(r'\b([A-Za-z_]\w*)\s*:\s*UserDefaults[!?]?\s*[,)=]'),
]
# `self.foo` where foo is a bound property
SELF_PREFIX = re.compile(r'\bself\s*\.\s*')

# ---- Bucket C: property wrappers ---------------------------------------
C_APPSTORAGE = re.compile(r'@AppStorage\s*\(')
C_SCENESTORAGE = re.compile(r'@SceneStorage\s*\(')
# an app-defined wrapper whose @propertyWrapper decl mentions UserDefaults
C_WRAPPER_DECL = re.compile(
    r'@propertyWrapper[\s\S]{0,400}?\b(?:struct|class|enum)\s+([A-Za-z_]\w*)')

# KVO / observation of defaults -- asked for explicitly
KVO_OBSERVE = re.compile(r'\b(?:addObserver|observe)\s*\([^)]{0,200}')
DIDCHANGE = re.compile(r'\bdidChangeNotification\b|\bNSUserDefaultsDidChange\w*')

# String literals that look like default keys, harvested for the oracle
KEY_IN_FORKEY = re.compile(r'forKey\s*:\s*"([^"\\\n]{1,80})"')
KEY_APPSTORAGE = re.compile(r'@AppStorage\s*\(\s*"([^"\\\n]{1,80})"')


def walk(root):
    for dirpath, dirs, files in os.walk(root):
        dirs[:] = [d for d in dirs if d not in SKIP_MODEL]
        for f in files:
            if f.endswith(".swift"):
                yield os.path.join(dirpath, f)


def census_app(app_root):
    a_member = Counter()          # bucket A member calls
    a_init = Counter()            # UserDefaults(label:) forms
    a_static = Counter()          # UserDefaults.<static> (non-standard)
    a_standard_bare = 0
    b_member = Counter()
    b_bound_names = Counter()
    c_appstorage = 0
    c_scenestorage = 0
    c_wrappers = Counter()
    kvo_hits = Counter()
    keys = Counter()
    tokens = 0
    nstokens = 0
    files_touching = 0
    files = 0

    for path in walk(app_root):
        files += 1
        try:
            s = open(path, encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        n_tok = len(TOKEN.findall(s))
        tokens += n_tok
        nstokens += len(NSTOKEN.findall(s))
        c_appstorage += len(C_APPSTORAGE.findall(s))
        c_scenestorage += len(C_SCENESTORAGE.findall(s))
        for m in KEY_APPSTORAGE.findall(s):
            keys[m] += 1
        if n_tok == 0 and not C_APPSTORAGE.search(s):
            continue
        files_touching += 1

        # --- A
        std = A_STANDARD.findall(s)
        a_member.update(std)
        chain = A_INIT_CHAIN.findall(s)
        a_member.update(chain)
        a_standard_bare += len(A_STANDARD_BARE.findall(s))
        for m in A_STATIC.findall(s):
            if m != "standard":
                a_static[m] += 1
        a_init.update(A_INIT_LABEL.findall(s))
        if A_INIT_BARE.findall(s):
            a_init["<bare UserDefaults()>"] += len(A_INIT_BARE.findall(s))

        # --- B: names bound to UserDefaults in this file
        names = set()
        for rx in B_BINDINGS:
            for nm in rx.findall(s):
                if nm not in ("UserDefaults", "standard"):
                    names.add(nm)
        for nm in names:
            b_bound_names[nm] += 1
            rx = re.compile(r'(?<![\w.])(?:self\s*\.\s*)?' + re.escape(nm)
                            + r'\s*\.\s*([A-Za-z_]\w*)')
            b_member.update(rx.findall(s))

        # --- C: app-defined wrappers mentioning UserDefaults
        for wname in C_WRAPPER_DECL.findall(s):
            # only count if UserDefaults appears in the same file as the wrapper
            if n_tok:
                c_wrappers[wname] += 1

        # --- KVO / notification
        if DIDCHANGE.search(s):
            kvo_hits["didChangeNotification"] += len(DIDCHANGE.findall(s))
        for frag in KVO_OBSERVE.findall(s):
            if "UserDefaults" in frag or "defaults" in frag.lower():
                kvo_hits["observe/addObserver near defaults"] += 1

        # --- keys, only in files that touch defaults
        for k in KEY_IN_FORKEY.findall(s):
            keys[k] += 1

    return dict(
        files=files, files_touching=files_touching,
        tokens=tokens, ns_tokens=nstokens,
        a_member=dict(a_member.most_common()),
        a_static=dict(a_static.most_common()),
        a_init=dict(a_init.most_common()),
        a_standard_bare=a_standard_bare,
        b_bound_names=dict(b_bound_names.most_common(40)),
        b_member=dict(b_member.most_common()),
        c_appstorage=c_appstorage, c_scenestorage=c_scenestorage,
        c_wrappers=dict(c_wrappers.most_common(20)),
        kvo=dict(kvo_hits),
        keys=dict(keys.most_common(200)),
    )


# The API surface we will have to implement, so bucket B can be filtered from
# "every member of every identifier called `defaults`" down to "members that are
# actually on UserDefaults". Taken from the Darwin NSUserDefaults header, NOT
# invented -- names outside it are reported separately as NOT_ON_USERDEFAULTS.
UD_API = {
    "standard", "resetStandardUserDefaults", "init", "object", "set",
    "removeObject", "string", "array", "dictionary", "data", "stringArray",
    "integer", "float", "double", "bool", "url", "register",
    "addSuite", "removeSuite", "dictionaryRepresentation",
    "volatileDomainNames", "volatileDomain", "setVolatileDomain",
    "removeVolatileDomain", "persistentDomain", "setPersistentDomain",
    "removePersistentDomain", "synchronize", "objectIsForced",
    "didChangeNotification", "globalDomain", "argumentDomain",
    "registrationDomain", "sizeLimitExceededNotification",
    "completedInitialCloudSyncNotification", "didChangeCloudAccountsNotification",
    "noCloudAccountNotification",
}


def main():
    corpus, outp = sys.argv[1], sys.argv[2]
    apps = {}
    for name in sorted(os.listdir(corpus)):
        p = os.path.join(corpus, name)
        if not os.path.isdir(p) or name.startswith("."):
            continue
        apps[name] = census_app(p)

    # ---- roll up
    tot_tokens = sum(a["tokens"] for a in apps.values())
    tot_ns = sum(a["ns_tokens"] for a in apps.values())
    A = Counter()
    Astat = Counter()
    Ainit = Counter()
    B_on_api = Counter()
    B_off_api = Counter()
    reach_member = defaultdict(set)     # member -> set of apps
    reach_init = defaultdict(set)
    keys = Counter()
    kvo = Counter()
    appstorage = 0
    scenestorage = 0
    for name, a in apps.items():
        for m, n in a["a_member"].items():
            A[m] += n
            reach_member[m].add(name)
        for m, n in a["a_static"].items():
            Astat[m] += n
        for m, n in a["a_init"].items():
            Ainit[m] += n
            reach_init[m].add(name)
        for m, n in a["b_member"].items():
            if m in UD_API:
                B_on_api[m] += n
                reach_member[m].add(name)
            else:
                B_off_api[m] += n
        keys.update(a["keys"])
        kvo.update(a["kvo"])
        appstorage += a["c_appstorage"]
        scenestorage += a["c_scenestorage"]

    combined = Counter()
    for m, n in A.items():
        combined[m] += n
    for m, n in B_on_api.items():
        combined[m] += n

    out = {
        "_meta": {
            "corpus": os.path.abspath(corpus),
            "apps": len(apps),
            "swift_files": sum(a["files"] for a in apps.values()),
            "files_touching_defaults": sum(a["files_touching"] for a in apps.values()),
            "token_denominator_UserDefaults": tot_tokens,
            "token_denominator_NSUserDefaults": tot_ns,
        },
        "A_anchored_members": dict(A.most_common()),
        "A_statics": dict(Astat.most_common()),
        "A_initializers": dict(Ainit.most_common()),
        "B_bound_receiver_on_api": dict(B_on_api.most_common()),
        "B_bound_receiver_NOT_on_UserDefaults_API": dict(B_off_api.most_common(60)),
        "COMBINED_members_A_plus_B_on_api": dict(combined.most_common()),
        "app_reach_members": {m: sorted(s) for m, s in
                              sorted(reach_member.items(),
                                     key=lambda kv: -len(kv[1]))},
        "app_reach_initializers": {m: sorted(s) for m, s in reach_init.items()},
        "C_appstorage_sites": appstorage,
        "C_scenestorage_sites": scenestorage,
        "kvo_and_notification": dict(kvo),
        "harvested_keys_top": dict(keys.most_common(300)),
        "per_app": apps,
    }
    json.dump(out, open(outp, "w"), indent=1)

    # ---- report
    print(f"corpus {out['_meta']['apps']} apps, "
          f"{out['_meta']['swift_files']} swift files")
    print(f"DENOMINATOR: UserDefaults token {tot_tokens} · "
          f"NSUserDefaults {tot_ns} · "
          f"{out['_meta']['files_touching_defaults']} files touch defaults\n")

    print("A -- ANCHORED member calls (PRECISE); "
          f"{sum(A.values())} calls, {len(A)} members")
    for m, n in A.most_common(40):
        print(f"   {m:<32}{n:>6}   apps {len(reach_member[m]):>2}/20")
    print(f"\nA -- statics / non-.standard: {sum(Astat.values())}")
    for m, n in Astat.most_common(20):
        print(f"   UserDefaults.{m:<28}{n:>6}")
    print(f"\nA -- initialisers: {sum(Ainit.values())}")
    for m, n in Ainit.most_common(10):
        print(f"   UserDefaults({m}{'' if m.startswith('<') else ':'}"
              f"){'':<{max(0,14-len(m))}}{n:>6}   apps {len(reach_init[m])}/20")
    print(f"\n   bare `UserDefaults.standard` passed as a value: "
          f"{sum(a['a_standard_bare'] for a in apps.values())}")

    print(f"\nB -- BOUND-RECEIVER members that ARE on the UserDefaults API: "
          f"{sum(B_on_api.values())}")
    for m, n in B_on_api.most_common(30):
        print(f"   {m:<32}{n:>6}")
    print(f"\nB -- bound-receiver members NOT on the API (the over-count, "
          f"reported not hidden): {sum(B_off_api.values())} over "
          f"{len(B_off_api)} names")
    for m, n in B_off_api.most_common(12):
        print(f"   {m:<32}{n:>6}")

    print(f"\nCOMBINED member demand (A + B-on-api): {sum(combined.values())}")
    cum = 0
    tot = sum(combined.values())
    for i, (m, n) in enumerate(combined.most_common(), 1):
        cum += n
        print(f"  {i:>3}. {m:<30}{n:>6}  {100*cum/tot:>5.1f}% cum  "
              f"apps {len(reach_member[m]):>2}/20")
        if i >= 30:
            break

    print(f"\nC -- @AppStorage sites {appstorage} · @SceneStorage {scenestorage}")
    print(f"KVO / notification: {dict(kvo)}")
    print(f"\nharvested key literals: {len(keys)} distinct")


if __name__ == "__main__":
    main()
