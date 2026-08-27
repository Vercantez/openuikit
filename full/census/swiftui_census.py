#!/usr/bin/env python3
"""SwiftUI / Combine scope census -- and a refusal.

WHAT THIS INSTRUMENT CANNOT MATCH, STATED BEFORE IT IS RUN.

The model-layer census worked because Foundation's alphabet is mostly
NS*-prefixed and therefore unambiguous. SwiftUI's is not, and the failure would
be worse than a wrong number -- it would be a confident one.

1. TYPE NAMES COLLIDE, BADLY. SwiftUI's public vocabulary is `Text`, `Image`,
   `List`, `Group`, `Section`, `Path`, `Alignment`, `State`, `Binding`,
   `Environment`, `Button`, `Label`, `Menu`, `Picker`, `Toggle`, `Spacer`,
   `Color`, `Font`, `Shape`, `Animation`, `Transaction`. Every one of those is
   a plausible app-defined type. The model census already proved this shape:
   scraping `.swiftinterface` swept in `Message`, `Category`, `Field`,
   `Language`, `Currency`, `Style` and inflated a gap number by ~2,900 uses
   with app types. SwiftUI is that hazard concentrated.

2. MOST OF THE API IS NOT TYPE NAMES AT ALL. It is MODIFIERS -- `.padding()`,
   `.frame()`, `.background()` -- method calls on opaque types. And apps define
   their own modifiers freely, so `\\.[a-z]\\w*\\(` cannot separate SwiftUI's
   from the app's. MEASURED, not assumed: the first non-test SwiftUI view found
   in this corpus (pocket-casts `MainTabView.swift`) contains exactly one
   modifier call, `.trackScrollOffset()`, and it is APP-DEFINED. A modifier
   census would have counted it as SwiftUI surface.

3. THE REST IS SYNTAX AND GENERIC STRUCTURE. `some View`, result builders,
   the implicit `@ViewBuilder` on `body`, opaque return types, conditional
   content. None of it is an identifier that can be counted.

SO NO SWIFTUI "TYPE USE COUNT" IS PRODUCED HERE, deliberately. Measuring the
model layer with the wrong alphabet under-reported it; measuring SwiftUI with
this one would over-report it, and both are the same error. What IS counted is
only what is unambiguous:

  * `import SwiftUI` / `import Combine`      -- exact, per file
  * property-wrapper ATTRIBUTES (`@State`, `@Binding`, ...) -- the `@` plus the
    exact name makes these SwiftUI's or Combine's and nobody else's
  * `: View` conformances and `some View`    -- syntax SwiftUI owns
  * a handful of Combine types whose names nobody reuses
    (`AnyCancellable`, `PassthroughSubject`, `CurrentValueSubject`)

That gives the SHAPE and SIZE of the adoption -- how many files, how many view
types, how much state plumbing -- which is what a scoping decision needs. It
does not give an API-surface count, and nothing here should be quoted as one.
"""
import json, os, re, sys
from collections import defaultdict

# Unambiguous: the `@` sigil plus an exact SwiftUI/Combine attribute name.
WRAPPERS = ["State", "Binding", "StateObject", "ObservedObject", "EnvironmentObject",
            "Environment", "Published", "AppStorage", "SceneStorage", "FocusState",
            "GestureState", "Namespace", "ViewBuilder", "Bindable", "Observable",
            "MainActor", "FetchRequest", "ScaledMetric"]
WRAPPER_RE = {w: re.compile(r'@' + w + r'\b') for w in WRAPPERS}

# Syntax SwiftUI owns outright.
SOME_VIEW = re.compile(r'\bsome\s+View\b')
CONFORM_VIEW = re.compile(r'\b(?:struct|enum|class)\s+\w+\s*:[^{\n]*\bView\b')
BODY_DECL = re.compile(r'\bvar\s+body\s*:')
VIEW_MODIFIER = re.compile(r'\b(?:struct|enum|class)\s+\w+\s*:[^{\n]*\bViewModifier\b')
PREVIEW = re.compile(r'#Preview\b|\bPreviewProvider\b')

# Combine names nobody reuses.
COMBINE_TYPES = ["AnyCancellable", "PassthroughSubject", "CurrentValueSubject",
                 "AnyPublisher", "ObservableObject"]
COMBINE_RE = {c: re.compile(r'\b' + c + r'\b') for c in COMBINE_TYPES}

IMPORT_SWIFTUI = re.compile(r'^\s*import\s+SwiftUI\s*$', re.M)
IMPORT_COMBINE = re.compile(r'^\s*import\s+Combine\s*$', re.M)

TESTISH = re.compile(r'(?:^|/)(?:Tests?|Specs?)[^/]*/|Tests?\.swift$|Spec\.swift$', re.I)


def main():
    corpus = sys.argv[1]
    out = {}
    for app in sorted(os.listdir(corpus)):
        adir = os.path.join(corpus, app)
        if not os.path.isdir(adir):
            continue
        s = defaultdict(int)
        for root, dirs, files in os.walk(adir):
            dirs[:] = [d for d in dirs if d not in (".git", "Carthage", "Pods", ".build")]
            for f in files:
                if not f.endswith(".swift"):
                    continue
                path = os.path.join(root, f)
                rel = os.path.relpath(path, adir)
                try:
                    src = open(path, encoding="utf-8", errors="ignore").read()
                except OSError:
                    continue
                s["files"] += 1
                is_test = bool(TESTISH.search(rel))
                if is_test:
                    s["test_files"] += 1
                imp_sui = bool(IMPORT_SWIFTUI.search(src))
                imp_cmb = bool(IMPORT_COMBINE.search(src))
                if imp_sui:
                    s["import_swiftui"] += 1
                    if is_test:
                        s["import_swiftui_test"] += 1
                if imp_cmb:
                    s["import_combine"] += 1

                views = len(CONFORM_VIEW.findall(src))
                someview = len(SOME_VIEW.findall(src))
                # A file that DECLARES a View is real adoption; one that merely
                # imports SwiftUI may be a test or an incidental import. Both
                # are counted, separately, because the difference is the point.
                if views or someview:
                    s["view_bearing_files"] += 1
                    if is_test:
                        s["view_bearing_test_files"] += 1
                s["view_types"] += views
                s["some_view"] += someview
                s["body_decls"] += len(BODY_DECL.findall(src))
                s["view_modifiers"] += len(VIEW_MODIFIER.findall(src))
                s["previews"] += len(PREVIEW.findall(src))
                for w, rx in WRAPPER_RE.items():
                    n = len(rx.findall(src))
                    if n:
                        s["wrapper:" + w] += n
                for c, rx in COMBINE_RE.items():
                    n = len(rx.findall(src))
                    if n:
                        s["combine:" + c] += n
        out[app] = dict(s)
    json.dump(out, open(sys.argv[2], "w"), indent=1)

    tot = defaultdict(int)
    for app, s in out.items():
        for k, v in s.items():
            tot[k] += v

    print("SWIFTUI / COMBINE ADOPTION -- shape and size, NOT an API-surface count\n")
    print(f"{'app':<20}{'files':>7}{'imp SUI':>9}{'(test)':>8}{'view files':>12}{'View types':>12}{'imp Combine':>13}")
    for app, s in out.items():
        print(f"{app:<20}{s.get('files',0):>7}{s.get('import_swiftui',0):>9}"
              f"{s.get('import_swiftui_test',0):>8}{s.get('view_bearing_files',0):>12}"
              f"{s.get('view_types',0):>12}{s.get('import_combine',0):>13}")
    print(f"{'TOTAL':<20}{tot['files']:>7}{tot['import_swiftui']:>9}"
          f"{tot['import_swiftui_test']:>8}{tot['view_bearing_files']:>12}"
          f"{tot['view_types']:>12}{tot['import_combine']:>13}")

    print(f"\nSTRUCTURE  some View={tot['some_view']}  body decls={tot['body_decls']}"
          f"  ViewModifier types={tot['view_modifiers']}  previews={tot['previews']}")

    print("\nPROPERTY WRAPPERS (unambiguous -- '@' plus an exact name):")
    for k in sorted([k for k in tot if k.startswith("wrapper:")], key=lambda k: -tot[k]):
        print(f"  @{k.split(':')[1]:<20}{tot[k]:>6}")
    print("\nCOMBINE TYPES (names nobody reuses):")
    for k in sorted([k for k in tot if k.startswith("combine:")], key=lambda k: -tot[k]):
        print(f"  {k.split(':')[1]:<21}{tot[k]:>6}")


main()
