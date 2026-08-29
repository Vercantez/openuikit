# focus-ios — measured scope (#93 phase 1)

**Pin:** `mozilla-mobile/focus-ios` @ `a2832521c1daa0c23419c73705ae043ed60c9791`
(2024-03-05), clean tree, verified by commit not tag.
**OpenUIKit:** `4f76a8c`, built fresh from a clone into a private workdir
(`~/uikit` never written to). The prebuilt module in `~/uikit/.build` was
**stale — 12 `Sources/` files newer than it** — so nothing here was measured
against it.

**Later #94 policy:** this remains a historical first-screen scope. The full
source-unchanged port now includes SwiftUI and every measured Apple first-party
module in the [framework roadmap](../framework-roadmap/FRAMEWORK-ROADMAP.md);
the exact Focus boundary is in the [SwiftUI contract](../swiftui/ROADMAP.md).
OpenUIKit `3cde5ad` now covers the first two-file Focus widget slice; neither
document implies the complete frameworks already work.

**Bottom line: the app was chosen on a premise that is false, and the wall that
was named is not the biggest one.** WebKit is small and stub-able for
launch-to-first-screen. The real blockers are two prebuilt **Rust
xcframeworks** on the launch path, and a member/signature-level UIKit gap that
no type census can see.

---

## 0. The denominator

| class | files | note |
|---|---|---|
| app (shipping) | 180 | of which 1 is a build script, so **179** compile |
| test | 40 | excluded from every figure below, and counted here so you can see they were |
| tool | 3 | `ContentBlockerGen`, a build-time generator |
| preview | 4 | SwiftUI `#Preview` files |
| **total `.swift`** | **227** | 23,912 lines |

---

## 1. ★ THE LADDER'S PREMISE FOR PICKING THIS APP IS FALSE

`app-ladder.md` says focus-ios is "the ONLY route-(a) NEAR" app and "earns it by
having **no load-bearing external dependency at all**."

It has **five**, and three are on the launch path:

| package | files | what it is | verified how |
|---|---|---|---|
| **Glean** | 15 | **`.binaryTarget`** — prebuilt `Glean.xcframework.zip` (Rust) | fetched its `Package.swift` |
| **rust-components-swift** (`FocusAppServices`) | 4 | **`.binaryTarget`** — prebuilt `FocusRustComponents.xcframework.zip` from Mozilla Taskcluster | fetched its `Package.swift` |
| SnapKit | 7 | pure-Swift layout DSL, UIKit-bound | cloned in ladder-deps |
| Sentry | 2 | ObjC + Swift crash reporter | cloned in ladder-deps |
| Fuzi | 1 | libxml2 wrapper (C) | — |

**Glean is imported by `AppDelegate.swift`, `BrowserViewController.swift` and
`URLBar.swift`. `NimbusWrapper.shared.initialize()` is called from
`AppDelegate` line 377.** Both Mozilla packages are **binary targets**: there is
no source to recompile, and the artifacts are iOS-ABI Rust static libraries.
That is a strictly harder wall than WebKit, and it is on the launch path.

*Why the ladder missed it:* its dependency census scored the **30 heaviest**
deps by file count. Glean (15 files) and rust-components (4) were below that
cut, so the app scored as dependency-free. Same shape as the ladder's own
recorded blindness about eidolon's networking — **a threshold instrument reports
"none" for everything under the threshold.**

---

## 2. WebKit — the question the task asked, answered with data

**Surface: 28 distinct types, 78 uses, 6 files.** 47 of the 78 are in one file.

| file | uses |
|---|---|
| `Modules/WebView/WebViewController.swift` | 47 |
| `Settings/Controller/SettingsContentViewController.swift` | 13 |
| `Utilities/WebCacheUtils.swift` | 10 |
| `Utilities/LocalContentBlocker.swift` | 6 |
| `Utilities/SearchInContentTelemetry.swift` | 1 |
| `Utilities/AdsTelemetryHelper.swift` | 1 |

Heaviest names: `WKWebView` 23, `WKNavigation` 9, `WKNavigationActionPolicy` 5,
`WKContentRuleList` 5, `WKWebpagePreferences` 4, `WKWebViewConfiguration` 3,
`WKNavigationAction` 3. The rest are 1–2 each.

**Is a WKWebView constructed before first render? YES — traced, not assumed:**

```
BrowserViewController.viewDidLoad()          (line 169)
  → line 189  webViewController.delegate = self     ← forces the `lazy var`
      → WebViewController.init                      (line 93)
          → line 101  setupWebview()
              → line 168  browserView = WKWebView(frame:configuration:)
```

**But it is not VISIBLE at first render:** `viewDidLoad` line 197 sets
`webViewContainer.isHidden = true`, and it only becomes visible at line 930,
inside the URL-submission path. The first interactive screen is
`HomeViewController` + the URL bar.

**ANSWER: yes, the app can launch to its first interactive screen without a web
engine — but not without a WKWebView OBJECT.** What is needed is an inert
`WKWebView` that is constructible, is a view, and answers a handful of property
sets (`allowsBackForwardNavigationGestures`, `allowsLinkPreview`, `scrollView`,
`navigationDelegate`, `uiDelegate`), plus `WKWebViewConfiguration`,
`WKWebsiteDataStore.nonPersistent()`, `WKUserContentController` and
`WKUserScript`. Roughly **8 of the 28 types are launch-blocking; the other 20 are
browsing-only** and can be deny-list stubs that die loudly on first call.

---

## 3. UIKit — recomputed against OpenUIKit `4f76a8c`, not the v2 snapshot

Static sweep, over-matched on `UI[A-Z]\w*` then inspected:

- 124 distinct `UI*` tokens in app files, 1,876 uses.
- **6 of those are the app's own or module names** — `UIConstants` (536 uses!),
  `UIKit`, `UIHelpers`, `UIComponents`, `UIControlPublisher`,
  `UIControlSubscription` — 661 uses that are not UIKit at all.
- **Genuinely missing: 45 names / 94 uses. Weighted coverage 92.3 %.**

*An error I made and corrected, because it moved a number the wrong way:* my
first pass treated `extension UIPasteboard` as "the app declares it", which
pushed a real 16-use gap into the not-our-problem bucket. **`extension X` means
the app EXTENDS Apple's type; only `class/struct/enum/protocol/typealias`
declares one.**

This confirms the ladder's headline — UIKit is not the blocker — at 92.3 % on
the current tree.

---

## 4. Foundation

81 distinct names, 1,101 uses. Top: `URL` 288, `NSLocalizedString` 230,
`NSLayoutConstraint` 59, **`UserDefaults` 56 (done, #78/#92)**, `NSCoder` 53,
`Bundle` 52, `DispatchQueue` 39, `NSAttributedString` 25.

**Networking is TINY and that is a real finding for the roadmap:** `URLRequest`
10, `URLSessionDataTask` 2, `URLSession` 2, `HTTPURLResponse` 1, `URLCache` 1,
`HTTPCookieStorage` 1 — **6 names, 17 uses.** A browser does its fetching inside
WebKit, so **URLSession is NOT a wall for this app**, despite being the ladder's
#3 roadmap item at 19/20 apps. `NSLocalizedString` at 230 uses is a bigger
Foundation surface here than all of networking put together.

---

## 5. EXECUTION — and it caught a false green that would have been reported

### 5a. Baseline: does the app typecheck against Apple's own iOS SDK?

`swiftc -typecheck -target arm64-apple-ios15.0`, 179 shipping files, deps
unresolved → **the only error is `no such module 'Glean'`.** The source is
well-formed; every wall is an external module.

Partitioned by imports:

| | files |
|---|---|
| blocked by an EXTERNAL package | 24 |
| blocked only by an own SPM target (an artifact of single-module compiling) | 17 |
| import SDK modules only | **138** |
| …of those, import only UIKit/Foundation/CoreGraphics/QuartzCore/os | **104** |

The 138 typecheck against Apple's SDK with **3 errors, all `EraseIntent*`** —
Xcode-**generated** SiriKit types from an `.intentdefinition`, i.e. a
build-system code-generation step, not a framework gap.

### 5b. ★ THE FALSE GREEN — `swiftc -typecheck` STOPS AT THE FIRST BAD FILE

Compiling the 104 pure-UIKit files against OpenUIKit reported **4 errors**, all
"could not infer type of image literal". Read naively: *focus-ios almost
compiles against OpenUIKit.*

It does not. **A positive control killed it:** 21 of the types I had measured as
MISSING appear in those same 104 files, so 4 errors was impossible. Re-run with
the compile mode varied:

| mode | errors |
|---|---|
| default | **4** |
| `-enable-batch-mode` | **1,072** |
| `-wmo` | **1,066** |

Default mode compiles file-by-file and **stops after the first file with
errors** — the 4 came from one file (`AppConfig.swift`) and the other 103 were
never checked. **Reporting "104 files, 4 errors" would have been wrong by 266×.**
Standing rule: *never quote a `swiftc` error count without `-wmo` or
`-enable-batch-mode`; the default is a first-failure count, not a census.*

### 5c. The real census: 1,066 errors, and the shape is the finding

| error kind | n |
|---|---|
| cannot find `X` in scope | 172 |
| **value of type `X` has no member `X`** | **140** |
| cannot find type `X` in scope | 120 |
| **type `X` has no member `X`** | **92** |
| cannot use optional chaining on non-optional value | 86 |
| cannot infer contextual base in reference to member | 66 |
| `X` requires a contextual type | 44 |
| main actor-isolated property cannot be referenced/mutated | 74 |
| call to main actor-isolated method/initializer | 34 |
| incorrect argument label in call | 24 |
| refers to instance method not exposed to Objective-C | 18 |
| argument passed to call that takes no arguments | 16 |

Unresolved *names*: 53 distinct / 292 occurrences —
**21 real Apple-API names (90 uses)**, 17 the app's own symbols (an artifact of
compiling a 104-file subset), 15 other.

**★ THE TYPE CENSUS UNDERSTATES THE WORK, AND THE COMPILER SAYS BY HOW MUCH.**
Only 292 of 1,066 errors are missing *types*. **232 are missing MEMBERS on types
OpenUIKit already has**, 110 are missing enum cases, 86 are optionality
mismatches in signatures, 108 are `@MainActor` isolation, 24 are wrong argument
labels. **No type-level census can see any of those** — every previous coverage
number in this project, including my own 92.3 % above, is a *types* figure and
is therefore an optimistic bound.

**And execution found types the sweep could not.** The compiler names
`CAGradientLayer` (16), `CATransaction` (14), `CABasicAnimation` (4) and
`NSStringDrawingOptions` (2) — my sweep's alphabet was `UI*`, and **Core
Animation is where part of the answer lived.** Reconciliation: 45 static vs 21
compiler, 17 in both; 4 the sweep missed by prefix; 28 the compiler did not
reach because they live in the 75 files outside the subset.

---

## 6. The wall list, ranked by what blocks LAUNCH-TO-FIRST-SCREEN

| # | wall | size | blocks launch? | recommendation |
|---|---|---|---|---|
| 1 | **Glean** (prebuilt Rust xcframework) | 15 files, `AppDelegate` + `BrowserViewController` | **YES** | **STUB.** Telemetry: no pixels, no state a screen depends on. A no-op `GleanMetrics` surface is the single highest-value stub in the app. |
| 2 | **FocusAppServices / Nimbus** (prebuilt Rust xcframework) | 4 files, `initialize()` in `AppDelegate` | **YES** | **STUB.** Feature-flag/experiment lookup — a stub returning defaults leaves screens correct. |
| 3 | **SnapKit** | 7 files incl. `BrowserViewController`, `URLBar` | **YES** | **IMPLEMENT (small).** Pure Swift over `NSLayoutConstraint`; ~1 file of DSL. Or vendor it — it is source-available, unlike 1 and 2. |
| 4 | **UIKit member/signature gap** | 232 member + 110 enum + 86 optionality + 24 label errors | **YES** | **IMPLEMENT**, and it is bigger than the type list suggests. Needs its own scoping pass; goes through the gated `~/uikit` oracle. |
| 5 | **`@MainActor` isolation** | 108 errors | **YES** | **IMPLEMENT.** Likely a small number of missing annotations on OpenUIKit types, not 108 separate problems. |
| 6 | **WebKit** | 28 types, 78 uses, 6 files | **PARTLY** — an object is constructed, no engine is used | **STUB** ~8 types inert for launch; deny-list the other 20. |
| 7 | Core Animation (`CAGradientLayer`, `CATransaction`, `CABasicAnimation`) | 34 uses | **YES** (chrome) | **IMPLEMENT.** Small, and invisible to every prior census. |
| 8 | Xcode-generated SiriKit `EraseIntent*` | 3 types | no | **GENERATE or STUB** — a build-system step, not a framework. |
| 9 | Sentry, Fuzi | 2 + 1 files | no | **STUB** Sentry; Fuzi only parses OpenSearch XML at settings time. |
| 10 | SwiftUI (historical subset count 14) + Combine (7) | onboarding/settings/widgets | no | deferred from this historical first-screen slice; now explicit #94 framework-port work. |

**Recommended first target if this app is pursued: launch-to-first-screen needs
1, 2, 3, 5, 6-partial and the launch-path subset of 4 + 7.** Items 8, 9, 10 and
most of 4 are not on the path to a first render.

---

## 7. What I did NOT do

No stubs were implemented and no OpenUIKit change was made — reporting first, as
instructed. `~/uikit` was cloned, never written. The 1,066-error census is over
**104 of 179** shipping files (those importing only UIKit/Foundation); the other
75 need the module walls above cleared before the compiler can reach them, so
**every count here is a LOWER BOUND**, and the member/enum/optionality classes in
§5c are the ones most likely to grow.
