#!/usr/bin/env python3
"""Compare OpenUIKit-Swift.h selectors of chosen classes with the iOS SDK's.

usage: selcheck.py OpenUIKit-Swift.h Class [Class...]
Prints, per class, generated selectors the SDK does not declare on that class
(or its UIKit/Foundation superclasses): candidates for an explicit @objc(name).
"""
import glob, os, re, subprocess, sys

SDK = subprocess.check_output(['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path'], text=True).strip()
HDRS = glob.glob(SDK + '/System/Library/Frameworks/UIKit.framework/Headers/*.h') + \
       glob.glob(SDK + '/System/Library/Frameworks/Foundation.framework/Headers/*.h') + \
       glob.glob(SDK + '/System/Library/Frameworks/QuartzCore.framework/Headers/*.h') + \
       glob.glob(SDK + '/usr/include/objc/NSObject.h')

def strip_macros(text):
    out, i = [], 0
    pat = re.compile(r'\b(API_\w+|NS_\w+|UIKIT_\w+|__\w+|CF_\w+|MP_\w+)\s*\(')
    while True:
        m = pat.search(text, i)
        if not m:
            out.append(text[i:]); break
        out.append(text[i:m.start()])
        j, d = m.end(), 1
        while j < len(text) and d:
            if text[j] == '(': d += 1
            elif text[j] == ')': d -= 1
            j += 1
        i = j
    return ''.join(out)

def selectors_of_block(block):
    block = strip_macros(block)
    sels = set()
    # methods
    for m in re.finditer(r'^\s*([-+])\s*\([^;{]*?\)\s*([^;{]+?)\s*(?:NS_|API_|UIKIT_|__|;|\{|$)', block, re.M):
        sig = m.group(2)
        parts = re.findall(r'(\w+)\s*:', sig)
        if parts:
            sels.add(m.group(1) + ''.join(p + ':' for p in parts))
        else:
            name = re.match(r'\s*(\w+)', sig)
            if name: sels.add(m.group(1) + name.group(1))
    # properties
    for m in re.finditer(r'^\s*@property\s*(\(([^)]*)\))?\s*([^;]*?);', block, re.M):
        attrs = m.group(2) or ''
        decl = m.group(3)
        decl = re.sub(r'\b(API_\w+|NS_\w+|UIKIT_\w+|__\w+)\s*(\([^)]*\))?', '', decl)
        name = re.findall(r'(\w+)\s*$', decl.strip())
        if not name: continue
        name = name[0]
        getter = re.search(r'getter\s*=\s*(\w+)', attrs)
        setter = re.search(r'setter\s*=\s*(\w+:)', attrs)
        cls_prop = 'class' in re.split(r'\s*,\s*', attrs)
        k = '+' if cls_prop else '-'
        sels.add(k + (getter.group(1) if getter else name))
        if 'readonly' not in attrs:
            sels.add(k + (setter.group(1) if setter else 'set' + name[0].upper() + name[1:] + ':'))
    return sels

def sdk_classes():
    classes = {}  # name -> (super, set)
    for h in HDRS:
        src = open(h, errors='ignore').read()
        for m in re.finditer(r'@interface\s+(\w+)\s*(?::\s*(\w+))?\s*(\([^)]*\))?[^\n]*\n(.*?)@end', src, re.S):
            name, sup, cat, body = m.group(1), m.group(2), m.group(3), m.group(4)
            e = classes.setdefault(name, [None, set()])
            if sup and not cat: e[0] = sup
            e[1] |= selectors_of_block(body)
        for m in re.finditer(r'@protocol\s+(\w+)\s*(<[^>]*>)?[^\n;]*\n(.*?)@end', src, re.S):
            e = classes.setdefault('<' + m.group(1) + '>', [None, set()])
            e[1] |= selectors_of_block(m.group(3))
            if m.group(2):
                e.append([p.strip() for p in m.group(2)[1:-1].split(',')])
    return classes

def main():
    hdr, names = sys.argv[1], sys.argv[2:]
    ours = open(hdr).read()
    sdk = sdk_classes()
    # protocol adoption for SDK classes
    adopt = {}
    for h in HDRS:
        src = open(h, errors='ignore').read()
        for m in re.finditer(r'@interface\s+(\w+)\s*(?::\s*\w+)?\s*(?:\([^)]*\))?\s*<([^>]*)>', src):
            adopt.setdefault(m.group(1), set()).update(p.strip() for p in m.group(2).split(','))
    def all_sels(c, seen=None):
        seen = seen or set()
        out = set()
        while c and c not in seen:
            seen.add(c)
            e = sdk.get(c)
            if not e: break
            out |= e[1]
            for p in adopt.get(c, ()):
                out |= proto_sels(p)
            c = e[0]
        out |= proto_sels('NSObject')
        return out
    def proto_sels(p, seen=None):
        seen = seen or set()
        if p in seen: return set()
        seen.add(p)
        e = sdk.get('<' + p + '>')
        if not e: return set()
        out = set(e[1])
        if len(e) > 2:
            for q in e[2]: out |= proto_sels(q, seen)
        return out
    for n in names:
        m = re.search(r'@interface ' + n + r' : \w+.*?\n(.*?)^@end', ours, re.S | re.M)
        if not m:
            print(f'## {n}: not in header'); continue
        mine = selectors_of_block(m.group(1))
        theirs = all_sels(n)
        missing = sorted(s for s in mine if s not in theirs)
        print(f'## {n}: {len(mine)} selectors, {len(missing)} not in SDK')
        for s in missing: print('   ', s)

main()
