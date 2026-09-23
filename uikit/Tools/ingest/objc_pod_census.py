#!/usr/bin/env python3
"""objc_pod_census.py — syntax-check an app's Objective-C CocoaPods against
route (b)'s <UIKit/UIKit.h> and classify every error.

    python3 Tools/ingest/objc_pod_census.py PODS_DIR SPEC.json OUT.json
    python3 Tools/ingest/objc_pod_census.py --ios-sdk CURATED_SDK PODS_DIR SPEC.json OUT.json

PODS_DIR holds one checkout per pod (at the Podfile.lock version). SPEC.json
maps pod name -> source subdirectory holding its .h/.m, e.g.
{"SVProgressHUD": "SVProgressHUD", "ORStackView": "Classes/ios"}.

<UIKit/UIKit.h> is the ingest tool's route-(b) umbrella (OpenUIKit-Swift.h +
UIKitObjCSupport.h + OpenUIKitObjCBridge-Swift.h), with the simplenote
subclassing defines; every translation unit is compiled with
`-include UIKit/UIKit.h`, which is what CocoaPods' generated Pod-prefix.pch
does. Requires `swift build --target OpenUIKitObjCBridge` first (the
generated headers live under .build).

Each error is classified:
  macos-leakage            the macOS SDK answers where iOS would (AppKit /
                           QuartzCore duplicate definitions, NSImage/NSFont
                           branches, TARGET_OS_IPHONE-guarded code) — route
                           (b) compiles for a macOS triple;
  openuikit-objc-surface   a UIKit / Core Animation / layout name the
                           OpenUIKit Objective-C surface does not provide;
  pod-internal-or-cascade  everything else (mostly follow-on errors).
"""
import collections
import json
import os
import re
import subprocess
import sys

UIKIT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BUILD = os.path.join(UIKIT, '.build', 'arm64-apple-macosx', 'debug')
SKIP_DIRS = {'Pods', 'Example', 'Examples', 'Tests', 'Demo'}
MAC = re.compile(r"different definitions in different modules|NSImage|NSFont|NSColor\b|NSView\b|"
                 r"MKAnnotationView|Deployment Target|AppKit|TARGET_OS")
SURFACE = re.compile(r"\b(UI[A-Z]\w+|CA[A-Z]\w+|NSLayout\w+|NSTextAlignment\w*|NSLineBreak\w*|"
                     r"NSParagraphStyle|NSUnderline\w+|NSForegroundColor\w+|NSFontAttribute\w*)\b")

UMBRELLA = """#ifndef OPENUIKIT_ROUTE_B_UIKIT_H
#define OPENUIKIT_ROUTE_B_UIKIT_H
#import <Foundation/Foundation.h>
#import "OpenUIKit-Swift.h"
#import "UIKitObjCSupport.h"
#if !__swift__
#import "OpenUIKitObjCBridge-Swift.h"
#endif
#endif
"""


def classify(msg):
    if MAC.search(msg):
        return 'macos-leakage', None
    m = SURFACE.search(msg) or re.search(r"'((UI|CA)\w+)", msg)
    if m or 'forward declaration' in msg:
        return 'openuikit-objc-surface', (m.group(1) if m else '?')
    return 'pod-internal-or-cascade', None


def main(pods_dir, spec_path, out_path, ios_sdk=None):
    """`ios_sdk`: a curated iPhoneSimulator SDK (Tools/ingest/ios_target_sdk.py).
    The TUs are then compiled for arm64-apple-ios26.1-simulator against it and
    against the iOS-triple build of OpenUIKit (`swift build --triple
    arm64-apple-ios26.1-simulator --sdk <curated> --target OpenUIKitObjCBridge`),
    which is how route (b) builds an app's Objective-C half now
    (ios-target-route.md)."""
    pods_dir = os.path.abspath(pods_dir)
    build = BUILD
    triple = []
    if ios_sdk:
        build = os.path.join(UIKIT, '.build', 'arm64-apple-ios-simulator', 'debug')
        triple = ['-target', 'arm64-apple-ios26.1-simulator', '-isysroot', ios_sdk]
    spec = json.load(open(spec_path))
    # The fixture form carries {"spec": {...}, "header_names": {pod: [...]}}.
    header_names = spec.get('header_names', {}) if 'spec' in spec else {}
    spec = spec.get('spec', spec)
    shim = os.path.join(os.path.dirname(os.path.abspath(out_path)), 'objc_pod_census_shim')
    os.makedirs(os.path.join(shim, 'UIKit'), exist_ok=True)
    open(os.path.join(shim, 'UIKit', 'UIKit.h'), 'w').write(UMBRELLA)
    # CocoaPods' Pods/Headers/Public/<Pod>/: every public header of a pod,
    # flattened, under the pod's name and its module-name spellings
    # (`<FLKAutoLayout/UIView+FLKAutoLayout.h>`, `<Artsy+UIColors/...>`).
    public = os.path.join(shim, 'PodHeaders')
    for pod, sub in spec.items():
        headers = []
        for dp, dn, fn in os.walk(os.path.join(pods_dir, pod, sub)):
            dn[:] = [d for d in dn if d not in SKIP_DIRS]
            headers += [os.path.join(dp, f) for f in fn if f.endswith('.h')]
        for name in [pod] + header_names.get(pod, []):
            d = os.path.join(public, name)
            os.makedirs(d, exist_ok=True)
            for h in headers:
                link = os.path.join(d, os.path.basename(h))
                if not os.path.lexists(link):
                    os.symlink(h, link)
    header_dirs = [public]
    for pod, sub in spec.items():
        for dp, dn, fn in os.walk(os.path.join(pods_dir, pod, sub)):
            dn[:] = [d for d in dn if d not in SKIP_DIRS]
            if any(f.endswith('.h') for f in fn):
                header_dirs.append(dp)
    base = ['xcrun', 'clang', '-fsyntax-only', '-ferror-limit=0', '-fobjc-arc', '-fmodules'] + triple + [
            '-DSWIFT_CLASS(SWIFT_NAME)=SWIFT_RUNTIME_NAME(SWIFT_NAME) '
            '__attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA',
            '-DSWIFT_CLASS_NAMED(SWIFT_NAME)=SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA',
            '-fmodule-map-file=' + os.path.join(build, 'OpenUIKitObjCSupport.build', 'module.modulemap'),
            # UIKitObjCSupport.h includes cportableio.h (attrstring-unify's
            # NSTextStorage edit mask); without these every TU stops at
            # "'cportableio.h' file not found" (MEASURED objc-surface.md).
            '-fmodule-map-file=' + os.path.join(build, 'CPortableIO.build', 'module.modulemap'),
            '-I', os.path.join(UIKIT, 'Sources', 'CPortableIO', 'include'),
            '-include', 'UIKit/UIKit.h', '-I', shim,
            '-I', os.path.join(build, 'OpenUIKit.build', 'include'),
            '-I', os.path.join(UIKIT, 'Sources', 'OpenUIKitObjCSupport', 'include'),
            '-I', os.path.join(build, 'OpenUIKitObjCBridge.build', 'include')]
    base += sum((['-I', d] for d in sorted(set(header_dirs))), [])
    pods = {}
    classes = collections.Counter()
    surface = collections.Counter()
    for pod, sub in sorted(spec.items()):
        tus = {}
        counts = collections.Counter()
        for dp, dn, fn in os.walk(os.path.join(pods_dir, pod, sub)):
            dn[:] = [d for d in dn if d not in SKIP_DIRS]
            for f in sorted(fn):
                if not f.endswith('.m'):
                    continue
                path = os.path.join(dp, f)
                r = subprocess.run(base + [path], capture_output=True, text=True)
                errors = [l.split(' error: ', 1)[1] for l in r.stderr.splitlines() if ' error: ' in l]
                tus[os.path.relpath(path, pods_dir)] = errors
                for e in errors:
                    kind, symbol = classify(e)
                    counts[kind] += 1
                    classes[kind] += 1
                    if symbol:
                        surface[symbol] += 1
        pods[pod] = {'translation_units': len(tus), 'clean': sum(1 for v in tus.values() if not v),
                     'errors': sum(len(v) for v in tus.values()), 'classes': dict(counts), 'by_tu': tus}
        print(f"{pod}: {pods[pod]['translation_units']} TUs, {pods[pod]['clean']} clean, "
              f"{pods[pod]['errors']} errors {dict(counts)}")
    total = sum(p['errors'] for p in pods.values())
    print('TOTAL', total, dict(classes))
    json.dump({'total_errors': total, 'classes': dict(classes),
               'surface_by_symbol': surface.most_common(), 'pods': pods},
              open(out_path, 'w'), indent=1, sort_keys=True)


if __name__ == '__main__':
    args = sys.argv[1:]
    sdk = None
    if len(args) == 5 and args[0] == '--ios-sdk':
        sdk, args = args[1], args[2:]
    if len(args) != 3:
        sys.exit(__doc__)
    main(*args, ios_sdk=sdk)
