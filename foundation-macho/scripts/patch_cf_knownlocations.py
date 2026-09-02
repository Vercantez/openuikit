#!/usr/bin/env python3
"""Fix CFKnownLocations' per-user preferences path: it is ABSOLUTE and must be
RELATIVE, so every "current user" domain collapses onto the "any user" one.

    scripts/patch_cf_knownlocations.py [CF_SOURCE_DIR]      default /work/cf

THE BUG, upstream, in swift-corelibs-foundation (CFKnownLocations.c:45):

    case _kCFKnownLocationUserCurrent:
        username = NULL;
        // passthrough to:
    case _kCFKnownLocationUserByName: {
        CFURLRef home = CFCopyHomeDirectoryURLForUser(username);
        location = CFURLCreateWithFileSystemPathRelativeToBase(
            alloc, CFSTR("/Library/Preferences"), kCFURLPOSIXPathStyle, true, home);

The path has a LEADING SLASH, and an absolute path discards its base. So the
UserCurrent branch returns /Library/Preferences -- byte for byte what
UserAny returns -- and the user's home is computed, passed in, and thrown away.

MEASURED ON REAL APPLE CoreFoundation, which is the oracle for this primitive
(~/swift-macho-linux/full/oracle-userdefaults/, the urlbase probe):

    "/Library/Preferences" + base $HOME  ->  abs = /Library/Preferences
    "Library/Preferences"  + base $HOME  ->  abs = /Users/<me>/Library/Preferences

So Apple's CF resolves it the same way; the leading slash is simply wrong here.
And Apple's own CFPreferences writes to $HOME/Library/Preferences -- independently
confirmed in darwin-behaviour-2026-08-27.txt section 9. Apple's CFPreferences
therefore does not go through this code at all.

WHY NOBODY UPSTREAM HAS HIT IT: this branch is dead everywhere. On Darwin,
corelibs' CF is not used (the system's is). On Linux, CFKnownLocations takes
the XDG branch, not this one. TARGET_OS_MAC + corelibs is OUR configuration and
nobody else's -- the same reason docs/cf-census/target-os-mac-sweep.md exists.
This is the second measured instance of "a corelibs code path that has never
run anywhere", after UserDefaults' coercion table.

The UserAny case is NOT touched: it calls CFURLCreateWithFileSystemPath with no
base at all, where an absolute path is exactly right.
"""
import sys, pathlib

# Anchored on the three-argument tail so it can only match the based call.
OLD = ('CFURLCreateWithFileSystemPathRelativeToBase(kCFAllocatorSystemDefault, '
       'CFSTR("/Library/Preferences"), kCFURLPOSIXPathStyle, true, home)')
NEW = ('CFURLCreateWithFileSystemPathRelativeToBase(kCFAllocatorSystemDefault, '
       'CFSTR("Library/Preferences"), kCFURLPOSIXPathStyle, true, home)')


def main():
    cf = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/work/cf")
    f = cf / "CFKnownLocations.c"
    if not f.is_file():
        print(f"FATAL: {f} not found", file=sys.stderr)
        return 2
    src = f.read_text()

    # Idempotent, and it distinguishes "already done" from "cannot find it".
    # A patch script that silently does nothing is indistinguishable from one
    # that worked, which is how a build keeps shipping the unpatched file.
    if NEW in src and OLD not in src:
        print("already patched (relative path in place) -- nothing to do")
        return 0
    n = src.count(OLD)
    if n == 0:
        print("FATAL: the expected call was not found. Upstream may have "
              "changed it; re-read CFKnownLocations.c before assuming this "
              "patch is still needed.", file=sys.stderr)
        return 3
    if n != 1:
        print(f"FATAL: expected exactly one site, found {n}. Refusing to "
              "guess which.", file=sys.stderr)
        return 4

    f.write_text(src.replace(OLD, NEW))

    # Verify by re-reading, not by trusting the write.
    check = f.read_text()
    if NEW not in check or OLD in check:
        print("FATAL: the file on disk does not contain the patch after "
              "writing it.", file=sys.stderr)
        return 5
    print(f"patched {f}: CFSTR(\"/Library/Preferences\") -> "
          f"CFSTR(\"Library/Preferences\") at the based call (1 site)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
