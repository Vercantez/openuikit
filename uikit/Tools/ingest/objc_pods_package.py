#!/usr/bin/env python3
"""objc_pods_package.py — turn an app's locked Objective-C CocoaPods into a
SwiftPM package of Clang targets that build against OpenUIKit (route b).

    objc_pods_package.py PODS_DIR SPEC.json OUT_DIR --uikit PATH [--vendor]

PODS_DIR holds one checkout per pod at its Podfile.lock commit; SPEC.json is
the fixture with a "podspecs" section (fixtures/realapp/eidolon/objc_pods.json:
source_files / exclude_files / requires_arc / dependencies / module, as
`pod ipc spec` resolves each locked spec).

The package mirrors what `pod install` + `use_frameworks!` gives an app:

  Pods/<pod>/...            the files the spec selects (plus license and spec,
                            and the spec's `resources`, listed per pod in
                            pods-manifest.json for the app bundle),
                            byte-identical; copied with --vendor, else symlinks
                            to PODS_DIR
  Targets/<Module>/         one Clang target per pod:
    Sources/<file>          relative symlinks to Pods/<pod>/<file> (.m/.c)
    include/<Name>/<h>      relative symlinks to every header the spec selects,
                            under the module name and every spelling in
                            header_names (CocoaPods' Headers/Public/<pod>, the
                            framework's <Module/Header.h>)
    include/module.modulemap
  Support/UIKit/UIKit.h     route (b)'s UIKit umbrella
  Support/Pod-prefix.pch    CocoaPods' prefix header, `-include`d by every
                            translation unit: UIKit/UIKit.h under __OBJC__

Compiler flags follow the pod target's xcconfig: -fobjc-arc unless the spec
says requires_arc = false, the pod's own header directory and every
dependency's on the quote-include path, and the OPENUIKIT_OBJC_SUBCLASSING
header defines (Swift classes subclassable from Objective-C).
"""
import argparse
import fnmatch
import glob
import json
import os
import re
import shutil
import sys

SOURCE_EXT = ('.m', '.mm', '.c', '.cc', '.cpp')
HEADER_EXT = ('.h', '.hh', '.hpp')
LICENSE_RE = re.compile(r'^(licen[cs]e|copying)(\..*)?$', re.I)

UMBRELLA = """/* Route-(b) UIKit umbrella for CocoaPods Objective-C sources
 * (Tools/ingest/objc_pods_package.py). OpenUIKit-Swift.h is emitted by
 * SwiftPM for the OpenUIKit target; the support header carries the
 * enums/structs/protocols it cannot. */
#ifndef OPENUIKIT_ROUTE_B_UIKIT_H
#define OPENUIKIT_ROUTE_B_UIKIT_H
#import <Foundation/Foundation.h>
/* Apple's <UIKit/UIKit.h> imports QuartzCore, and on Apple toolchains
 * OpenUIKit's Core Animation classes ARE QuartzCore's (cg-unify phase 3). */
#if __has_include(<QuartzCore/QuartzCore.h>)
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
#endif
#import "OpenUIKit-Swift.h"
#import "UIKitObjCSupport.h"
#if !__swift__
#import "OpenUIKitObjCBridge-Swift.h"
/* UIKit classes implemented in Objective-C over OpenUIKit (UIAlertView). */
#if __has_include("OpenUIKitObjCClasses.h")
#import "OpenUIKitObjCClasses.h"
#endif
#endif
#endif
"""

# CocoaPods' generated Target Support Files/<pod>-prefix.pch: UIKit for
# Objective-C translation units only (a pod's .c file compiles as C, e.g.
# XNGMarkdownParser's fmemopen.c).
PREFIX = """#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif
"""

# The Clang target that publishes <UIKit/UIKit.h> to the pods' consumers.
SUPPORT_TARGET = 'PodsUIKitUmbrella'

SUBCLASSING_DEFINES = [
    '-DSWIFT_CLASS(SWIFT_NAME)=SWIFT_RUNTIME_NAME(SWIFT_NAME) '
    '__attribute__((objc_subclassing_restricted)) SWIFT_CLASS_EXTRA',
    '-DSWIFT_CLASS_NAMED(SWIFT_NAME)=SWIFT_COMPILE_NAME(SWIFT_NAME) SWIFT_CLASS_EXTRA',
]


def expand_braces(pattern):
    m = re.search(r'\{([^{}]*)\}', pattern)
    if not m:
        return [pattern]
    out = []
    for alt in m.group(1).split(','):
        out += expand_braces(pattern[:m.start()] + alt + pattern[m.end():])
    return out


def spec_glob(root, patterns):
    """CocoaPods file patterns: brace alternatives, `**`, and a bare
    directory meaning every source/header file under it."""
    found = set()
    for pattern in patterns:
        for p in expand_braces(pattern):
            full = os.path.join(root, p)
            if os.path.isdir(full):
                for dp, _, fn in os.walk(full):
                    found |= {os.path.join(dp, f) for f in fn if f.endswith(SOURCE_EXT + HEADER_EXT)}
                continue
            found |= {f for f in glob.glob(full, recursive=True) if os.path.isfile(f)}
    return {os.path.relpath(f, root) for f in found}


def pod_files(root, spec):
    files = spec_glob(root, spec['source_files'])
    excluded = spec_glob(root, spec.get('exclude_files', []))
    return sorted(f for f in files - excluded if f.endswith(SOURCE_EXT + HEADER_EXT))


def pod_resources(root, spec):
    """The spec's `resources`, as {"path": pod-relative file, "bundle_path":
    where CocoaPods puts it}: each matched item lands at the root of the app
    bundle (or of the pod framework with use_frameworks!), a directory whole
    (SVProgressHUD.bundle/...). Sorted by path."""
    found = {}
    for pattern in spec.get('resources', []):
        for p in expand_braces(pattern):
            for item in glob.glob(os.path.join(root, p), recursive=True):
                base = os.path.dirname(item)
                if os.path.isdir(item):
                    for dp, _, fn in os.walk(item):
                        for x in fn:
                            f = os.path.join(dp, x)
                            found[os.path.relpath(f, root)] = os.path.relpath(f, base)
                else:
                    found[os.path.relpath(item, root)] = os.path.basename(item)
    return [{'path': k, 'bundle_path': v} for k, v in sorted(found.items())]


def relink(target, link):
    os.makedirs(os.path.dirname(link), exist_ok=True)
    if os.path.lexists(link):
        os.remove(link)
    os.symlink(os.path.relpath(target, os.path.dirname(link)), link)


def swift_list(items, indent):
    pad = ' ' * indent
    return ''.join(f'{pad}{json.dumps(i)},\n' for i in items)


def generate(pods_dir, spec_path, out, uikit, vendor):
    fixture = json.load(open(spec_path))
    specs = fixture['podspecs']
    header_names = fixture.get('header_names', {})
    by_name = {s['name']: pod for pod, s in specs.items()}
    if os.path.isdir(out):
        for sub in ('Targets', 'Support') + (('Pods',) if vendor else ()):
            shutil.rmtree(os.path.join(out, sub), ignore_errors=True)
    os.makedirs(os.path.join(out, 'Support', 'UIKit'), exist_ok=True)
    open(os.path.join(out, 'Support', 'UIKit', 'UIKit.h'), 'w').write(UMBRELLA)
    open(os.path.join(out, 'Support', 'Pod-prefix.pch'), 'w').write(PREFIX)
    # <UIKit/UIKit.h> for every CONSUMER of a pod's module, not only for the
    # pods' own translation units: each pod's umbrella header starts with
    # `#import <UIKit/UIKit.h>` (as CocoaPods writes it), and an app target
    # or a Swift module importing the pod builds that module with its own
    # header search paths (MEASURED: "'UIKit/UIKit.h' file not found" building
    # ARTiledImageView from a Swift target). This target publishes the route
    # (b) umbrella at include/UIKit/UIKit.h; its module map declares an empty
    # module, so nothing is imported by naming it.
    sup = os.path.join(out, 'Targets', SUPPORT_TARGET)
    os.makedirs(os.path.join(sup, 'include', 'UIKit'), exist_ok=True)
    os.makedirs(os.path.join(sup, 'Sources'), exist_ok=True)
    relink(os.path.join(out, 'Support', 'UIKit', 'UIKit.h'), os.path.join(sup, 'include', 'UIKit', 'UIKit.h'))
    open(os.path.join(sup, 'include', 'module.modulemap'), 'w').write(f'module {SUPPORT_TARGET} {{\n}}\n')
    open(os.path.join(sup, 'Sources', 'anchor.c'), 'w').write(
        '// SwiftPM builds a C target from at least one source file.\nint eidolon_pods_support_anchor;\n')
    targets = []
    manifest = {}
    for pod in sorted(specs):
        spec = specs[pod]
        module = spec['module']
        src_root = os.path.join(pods_dir, pod)
        files = pod_files(src_root, spec)
        extras = sorted(f for f in os.listdir(src_root) if LICENSE_RE.match(f) or f.endswith('.podspec'))
        if not any(LICENSE_RE.match(f) for f in extras):
            # No licence file (Artsy+UIFonts 3.1.3): its README states the terms.
            extras += sorted(f for f in os.listdir(src_root) if f.lower() == 'readme.md')
        resources = pod_resources(src_root, spec)
        pod_root = os.path.join(out, 'Pods', pod)
        for rel in files + extras + [r['path'] for r in resources]:
            dst = os.path.join(pod_root, rel)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            if vendor:
                shutil.copyfile(os.path.join(src_root, rel), dst)
            elif not os.path.lexists(dst):
                os.symlink(os.path.join(os.path.abspath(src_root), rel), dst)
        tdir = os.path.join(out, 'Targets', module)
        names = [module] + [n for n in [spec['name']] + header_names.get(pod, []) if n != module]
        names = list(dict.fromkeys(names))
        for rel in files:
            if rel.endswith(SOURCE_EXT):
                relink(os.path.join(pod_root, rel), os.path.join(tdir, 'Sources', rel.replace('/', '__')))
            else:
                for n in names:
                    relink(os.path.join(pod_root, rel), os.path.join(tdir, 'include', n, os.path.basename(rel)))
        # CocoaPods' framework umbrella (Target Support Files/<pod>-umbrella.h):
        # UIKit first, then every public header; the module map names it.
        headers = sorted({os.path.basename(r) for r in files if r.endswith(HEADER_EXT)})
        os.makedirs(os.path.join(tdir, 'include'), exist_ok=True)
        open(os.path.join(tdir, 'include', f'{module}-umbrella.h'), 'w').write(
            '#ifdef __OBJC__\n#import <UIKit/UIKit.h>\n#endif\n\n'
            + ''.join(f'#import "{module}/{h}"\n' for h in headers))
        open(os.path.join(tdir, 'include', 'module.modulemap'), 'w').write(
            f'module {module} {{\n    umbrella header "{module}-umbrella.h"\n    export *\n    module * {{ export * }}\n}}\n')
        deps = [specs[by_name[d]]['module'] for d in spec['dependencies'] if d in by_name]
        missing = [d for d in spec['dependencies'] if d not in by_name]
        manifest[pod] = {'module': module, 'files': files, 'extras': extras, 'dependencies': deps,
                         'missing_dependencies': missing, 'resources': resources}
        targets.append((module, spec, deps))

    def dep_headers(module, seen=None):
        seen = seen if seen is not None else set()
        for m, s, deps in targets:
            if m == module:
                for d in deps:
                    if d not in seen:
                        seen.add(d)
                        dep_headers(d, seen)
        return seen

    lines = ['// swift-tools-version:5.9',
             '// Generated by Tools/ingest/objc_pods_package.py — do not edit by hand.',
             '// Objective-C CocoaPods at their Podfile.lock versions, as Clang targets',
             '// built against OpenUIKit (route b). Pods/ is the pods\' own source.',
             'import PackageDescription',
             'import Foundation',
             '',
             'let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().path',
             'let openUIKit: [Target.Dependency] = [',
             '    .product(name: "OpenUIKit", package: "OpenUIKit"),',
             '    .product(name: "OpenUIKitObjCSupport", package: "OpenUIKit"),',
             '    .product(name: "OpenUIKitObjCBridge", package: "OpenUIKit"),',
             '    .product(name: "OpenUIKitObjCClasses", package: "OpenUIKit"),',
             ']',
             'func podFlags(arc: Bool, headers: [String]) -> [CSetting] {',
             '    [.unsafeFlags([arc ? "-fobjc-arc" : "-fno-objc-arc",',
             '                   "-include", root + "/Support/Pod-prefix.pch", "-I", root + "/Support",',
             ] + [f'                   {json.dumps(d)},' for d in SUBCLASSING_DEFINES] + [
             '                  ] + headers.flatMap { ["-I", root + "/Targets/" + $0] })]',
             '}',
             '',
             'let package = Package(',
             '    name: "EidolonPods",',
             '    platforms: [.macOS(.v11), .iOS("26.0")],',
             '    products: [']
    for module, _, _ in targets:
        lines.append(f'        .library(name: "{module}", targets: ["{module}"]),')
    lines += ['    ],',
              '    dependencies: [',
              f'        .package(name: "OpenUIKit", path: {json.dumps(uikit)}),',
              '    ],',
              '    targets: [']
    lines += ['        .target(',
              f'            name: "{SUPPORT_TARGET}",',
              f'            path: "Targets/{SUPPORT_TARGET}",',
              '            publicHeadersPath: "include"',
              '        ),']
    for module, spec, deps in targets:
        header_dirs = [f'{module}/include/{module}'] + [f'{d}/include/{d}' for d in sorted(dep_headers(module))]
        frameworks = [f for f in spec.get('frameworks', []) if f not in ('UIKit', 'Foundation')]
        lines.append('        .target(')
        lines.append(f'            name: "{module}",')
        lines.append('            dependencies: openUIKit + [' + ', '.join(json.dumps(d) for d in [SUPPORT_TARGET] + deps) + '],')
        lines.append(f'            path: "Targets/{module}",')
        lines.append('            publicHeadersPath: "include",')
        lines.append(f'            cSettings: podFlags(arc: {"true" if spec.get("requires_arc", True) else "false"}, headers: [')
        lines.append(swift_list(header_dirs, 16).rstrip('\n'))
        lines.append('            ])' + (',' if frameworks else ''))
        if frameworks:
            lines.append('            linkerSettings: [' + ', '.join(f'.linkedFramework({json.dumps(f)})' for f in frameworks) + ']')
        lines.append('        ),')
    lines += ['    ]', ')', '']
    open(os.path.join(out, 'Package.swift'), 'w').write('\n'.join(lines))
    json.dump(manifest, open(os.path.join(out, 'pods-manifest.json'), 'w'), indent=1, sort_keys=True)
    print(f'{out}: {len(targets)} targets, {sum(len(m["files"]) for m in manifest.values())} files')
    return manifest


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('pods_dir')
    ap.add_argument('spec')
    ap.add_argument('out')
    ap.add_argument('--uikit', required=True, help='path of the OpenUIKit package, relative to OUT')
    ap.add_argument('--vendor', action='store_true', help='copy pod files instead of symlinking')
    a = ap.parse_args()
    generate(a.pods_dir, a.spec, a.out, a.uikit, a.vendor)


if __name__ == '__main__':
    main()
