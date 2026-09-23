#!/usr/bin/env python3
"""Generate Sources/OpenUIKit/Swift4Names.swift from the real SDK's UIKit.apinotes.

UIKit.apinotes carries a `SwiftVersions: Version 4` section: the Swift names
real UIKit imports for clients compiled with `-swift-version 4`
(UIControlEvents, UIViewAnimationOptions, NSNotification.Name.UIKeyboardWillShow,
...). OpenUIKit is Swift source, so it spells those as
`@available(swift, obsoleted: 4.2, renamed:)` typealiases / static lets.

Only names whose *current* spelling OpenUIKit declares are kept: the tool
writes the file, builds the OpenUIKit target, and drops every line the
compiler rejects, repeating until the build is clean (`--no-prune` skips it).

Usage:
  uikit_swift4_names.py [--sdk PATH] [--out PATH] [--no-prune]
"""
import argparse
import os
import re
import subprocess
import sys

KINDS = ['Tags', 'Typedefs', 'Classes', 'Protocols', 'Globals', 'Enumerators', 'Functions']
HERE = os.path.dirname(os.path.abspath(__file__))
PACKAGE = os.path.normpath(os.path.join(HERE, '..', '..'))
DEFAULT_SDK = ('/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/'
               'Developer/SDKs/iPhoneSimulator26.1.sdk')


def swift4_renames(apinotes_text):
    """{kind: [(swift4_name, current_name)]} for names that differ in Swift 4."""
    import yaml
    d = yaml.safe_load(apinotes_text)
    cur = {}
    for kind in KINDS:
        for e in d.get(kind) or []:
            if 'SwiftName' in e:
                cur[(kind, e['Name'])] = e['SwiftName']
    out = {}
    for v in d.get('SwiftVersions') or []:
        if v.get('Version') != 4:
            continue
        for kind in KINDS:
            for e in v.get(kind) or []:
                new = cur.get((kind, e['Name']))
                old = e.get('SwiftName')
                if old and new and new != old:
                    out.setdefault(kind, []).append((old, new))
    return out


def render(renames, sdk_name, skip=()):
    lines = []
    for kind in ['Tags', 'Typedefs']:
        for old, new in renames.get(kind, []):
            if old in skip or '.' not in new:
                continue
            lines.append(f'@available(swift, obsoleted: 4.2, renamed: "{new}")\n'
                         f'public typealias {old} = {new}')
    notes = []
    for old, new in renames.get('Globals', []):
        if new.endswith('Notification') and '.' in new and old not in skip:
            notes.append(f'    @available(swift, obsoleted: 4.2, renamed: "{new}")\n'
                         f'    public static let {old} = {new}')
    out = ['// Swift 4 spellings of UIKit names, for app source built in Swift 4 mode',
           '// (Eidolon: `swiftLanguageVersions: [.version("4")]`).',
           '//',
           f'// GENERATED from the {sdk_name} SDK: UIKit.apinotes, section',
           '// `SwiftVersions: Version 4`, whose SwiftName for a tag / typedef differs',
           '// from the current one (UIControlEvents -> UIControl.Event, ...). Real UIKit',
           '// imports these under the old names in Swift 4 mode; `obsoleted: 4.2` makes',
           '// them invisible to Swift 4.2+ clients, as in UIKit. Only names whose',
           '// current spelling OpenUIKit declares are kept.',
           '// Regenerate: Tools/ingest/uikit_swift4_names.py.',
           '']
    out += lines
    if notes:
        out += ['', '#if canImport(Foundation)', 'import Foundation', '',
                'extension NSNotification.Name {'] + notes + ['}', '#endif']
    return '\n'.join(out) + '\n'


def rejected_names(build_output, text):
    lines = text.split('\n')
    bad = set()
    for m in re.finditer(r'Swift4Names\.swift:(\d+):\d+: error', build_output):
        ln = int(m.group(1)) - 1
        for t in lines[ln:ln + 2]:
            mm = re.search(r'(?:typealias|static let) (\w+)', t)
            if mm:
                bad.add(mm.group(1))
                break
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--sdk', default=DEFAULT_SDK)
    ap.add_argument('--out', default=os.path.join(PACKAGE, 'Sources/OpenUIKit/Swift4Names.swift'))
    ap.add_argument('--no-prune', action='store_true')
    a = ap.parse_args()
    notes = os.path.join(a.sdk, 'System/Library/Frameworks/UIKit.framework/Headers/UIKit.apinotes')
    renames = swift4_renames(open(notes).read())
    sdk_name = os.path.basename(a.sdk.rstrip('/')).removesuffix('.sdk')
    skip = set()
    for _ in range(20):
        text = render(renames, sdk_name, skip)
        open(a.out, 'w').write(text)
        if a.no_prune:
            break
        r = subprocess.run(['swift', 'build', '--target', 'OpenUIKit'], cwd=PACKAGE,
                           capture_output=True, text=True)
        bad = rejected_names(r.stdout + r.stderr, text)
        if not bad:
            if r.returncode != 0:
                sys.exit('OpenUIKit build failed outside Swift4Names.swift')
            break
        skip |= bad
    print(f'{a.out}: {text.count("typealias ")} typealiases, '
          f'{text.count("static let ")} notification names, {len(skip)} pruned')


if __name__ == '__main__':
    main()
