#!/usr/bin/env python3
"""Make CFPreferences write BINARY property lists, as Darwin does.

    scripts/patch_cf_prefs_binary.py [CF_SOURCE_DIR]        default /work/cf

swift-corelibs-foundation defaults to XML (CFPreferences.c:202):

    static Boolean __CFPreferencesWritesXML = true;

which CFXMLPreferencesDomain.c:307 turns into the format choice:

    CFPropertyListFormat desiredFormat = __CFPreferencesShouldWriteXML()
        ? kCFPropertyListXMLFormat_v1_0 : kCFPropertyListBinaryFormat_v1_0;

MEASURED, real macOS 26.5.2, and the reason for this patch
(~/swift-macho-linux/full/oracle-userdefaults/darwin-behaviour-2026-08-27.txt,
section 9): a UserDefaults write produces

    magic:  62 70 6c 69 73 74 30 30      ("bplist00")
    FORMAT: BINARY plist

So Darwin writes binary and corelibs writes XML. The stated goal for this
class is to match what Darwin DOES, so the flag flips.

WHAT THIS PATCH ACTUALLY BUYS, stated because "the bytes now match" is the
weaker half: flipping it puts CFBinaryPList's WRITER on the preferences path
for the first time. Until now only the XML writer had ever run, so a
round-trip through the binary encoder was untested by anything. Expect the
first run after this patch to exercise code that has never executed, and treat
a failure there as a finding about CFBinaryPList rather than about this flag.

NOT a behaviour change an app can observe through UserDefaults -- the reader
accepts both formats. It is observable to anything reading the FILE: defaults(1),
a diff against a Darwin-produced plist, or a human.
"""
import sys, pathlib

OLD = "static Boolean __CFPreferencesWritesXML = true;"
NEW = ("static Boolean __CFPreferencesWritesXML = false;  /* Darwin writes "
       "bplist00; measured, see scripts/patch_cf_prefs_binary.py */")


def main():
    cf = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/work/cf")
    f = cf / "CFPreferences.c"
    if not f.is_file():
        print(f"FATAL: {f} not found", file=sys.stderr)
        return 2
    src = f.read_text()

    # Idempotent, and "already done" is distinguished from "cannot find it".
    # A patch that silently does nothing looks exactly like one that worked.
    if "__CFPreferencesWritesXML = false" in src:
        print("already patched (binary is the default) -- nothing to do")
        return 0
    n = src.count(OLD)
    if n != 1:
        print(f"FATAL: expected exactly one declaration of "
              f"__CFPreferencesWritesXML = true, found {n}. Upstream may have "
              f"changed it; re-read CFPreferences.c.", file=sys.stderr)
        return 3

    f.write_text(src.replace(OLD, NEW))
    if "__CFPreferencesWritesXML = false" not in f.read_text():
        print("FATAL: the file on disk does not contain the patch after "
              "writing it.", file=sys.stderr)
        return 5
    print("patched CFPreferences.c: __CFPreferencesWritesXML true -> false "
          "(binary plist, matching Darwin)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
