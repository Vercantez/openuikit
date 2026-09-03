#!/bin/bash
# stage_fe_sysroot.sh -- MACOS ONLY.  Build scratch/sysroot_fe4, the sysroot the
# FoundationEssentials port compiles against, with canImport(Darwin) TRUE.
#
# Linux x86_64 sibling (does not read Xcode; writes scratch/sysroot_fe4-x86_64
# beside this tree, never overwrites it): scripts/x86/stage_fe_sysroot.sh.
#
# RESTAGE, NEVER REUSE.  scratch/sysroot was staged 2026-08-27 12:22:24 and
# machorun's sdk/ was last touched at 12:26:30 -- four minutes of skew that
# every git-level check reports as "current", because the staleness lives in a
# derived artifact with no version in it.  Restaging costs seconds.
#
# ORDER MATTERS AND IT IS NOT OBVIOUS.  stage_objc_module.sh WRITES
# usr/include/module.modulemap from scratch, and gen_darwin_modulemap.py
# APPENDS to it.  Run them the other way round and the Darwin family
# disappears silently -- the file still exists and still declares ObjectiveC.
# (The shared scratch/sysroot currently has the inverse problem: it was
# restaged from machorun/sdk after stage_objc_module.sh ran, so it has NO
# module.modulemap and no objc/NSObject.h at all.)
#
# THE `cp -r sdk-gaps/usr/include/.` IN THE OLD RECIPE IS A SUBTRACTION.
# machorun has shipped the real 680-line <sys/attr.h> since 8380ae9; the
# sdk-gaps stand-in is 17 lines.  A shadowing copy cannot fail, so this script
# copies file by file and REFUSES when the target already exists.
set -euo pipefail
[ "$(uname -s)" = "Darwin" ] || { echo "macOS only (reads Xcode + machorun)" >&2; exit 1; }
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
# shellcheck source=fe_sysroot_measurement.inc
. "$ROOT/full/foundation/fe_sysroot_measurement.inc"
MACHORUN=${MACHORUN:-$HOME/machorun}
SDK=$(xcrun --show-sdk-path --sdk macosx)
SYS=${SYS:-$ROOT/scratch/sysroot_fe4}
OBJC4=${OBJC4:-$MACHORUN/vendor/objc4/runtime}

stage_absent() {   # stage_absent <relpath> <source-root> <label>
    local rel=$1 src=$2 label=$3
    if [ -e "$SYS/usr/include/$rel" ]; then
        echo "  REFUSED (already present, would shadow): $rel" >&2
        return 0
    fi
    mkdir -p "$(dirname "$SYS/usr/include/$rel")"
    cp "$src/$rel" "$SYS/usr/include/$rel"
    echo "  + $rel   [$label]"
}

rm -rf "$SYS"; mkdir -p "$SYS/usr"
cp -R "$MACHORUN/sdk/usr/include" "$SYS/usr/include"
cp -R "$MACHORUN/sdk/usr/lib"     "$SYS/usr/lib"
cp -R "$SDK/usr/lib/swift"        "$SYS/usr/lib/swift"

# canImport(os) must be FALSE for Apple's overlay: it @_exported-imports
# os.log/os.signpost/os.workgroup, needs a Clang module machorun does not
# declare, and is backed by a libswiftos.dylib that does not exist for this
# target.  full/foundation/os-module/ provides the three declarations the port
# actually uses instead; see its header.
rm -rf "$SYS/usr/lib/swift/os.swiftmodule"

# ---- gaps staged for MEASUREMENT ONLY ---------------------------------------
# Each of these is a REAL machorun sdk/ gap.  Staging them here (into a
# gitignored, Xcode-derived sysroot, alongside the .swiftinterface files) is
# what lets the port be measured at all; it is not a fix, and each one belongs
# on full/sdk-gaps/README.md's list.
echo "== gaps staged for measurement (each is a real machorun sdk/ gap):"
# THE FILEMANAGER SET (plus complex.h / sysdir.h). Shared list:
# full/foundation/fe_sysroot_measurement_headers.txt. 108 of the errors in the
# first correctly-configured whole-module run were ONE class -- eight absent
# headers -- confined to nine files (FileOperations, Platform, FileManager+*,
# ProcessInfo, Data+Reading/Writing). Unlike sysdir.h these are NOT
# declaration-only gaps: libSystem exports none of copyfile/fcopyfile,
# removefile*, fts_*, {get,set,list,fget,fset}xattr, getgrnam_r/getgrgid_r,
# uname or quotactl. (It DOES export getpwnam_r and getpwuid_r, so pwd.h alone
# is declaration-only.) Staging them lets the rest of the module be measured;
# it does not make FileManager work, and a build using them will fail at the
# LINK with those symbols undefined.
while IFS= read -r h; do
    [ -n "$h" ] || continue
    case "$h" in
        complex.h)
            stage_absent "$h" "$ROOT/full/sdk-gaps/usr/include" \
                "clean-room stub; clang's own tgmath.h includes it unconditionally"
            ;;
        sysdir.h)
            stage_absent "$h" "$SDK/usr/include" \
                "79 lines; libSystem ALREADY exports _sysdir_start/_get_next_search_path_enumeration -- the implementation is there and only the declaration is missing"
            ;;
        *)
            stage_absent "$h" "$SDK/usr/include" \
                "FileManager set -- header AND libSystem implementation both absent (pwd.h: header only)"
            ;;
    esac
done < <(fe_sysroot_measurement_headers)

# vm_copy: machorun's mach/vm_map.h declares vm_allocate/deallocate/protect/
# remap and NOT vm_copy. Appended rather than shadowed -- replacing the whole
# header with Apple's would silently swap a clean-room file for an Xcode one.
# Platform.swift:63 has a `memmove` fallback for exactly this call.
fe_sysroot_append_vm_copy "$SYS/usr/include/mach/vm_map.h"

# ---- the ObjectiveC Clang module (must precede the generator) ---------------
for h in NSObject.h NSObjCRuntime.h Protocol.h; do cp "$OBJC4/$h" "$SYS/usr/include/objc/$h"; done
cat > "$SYS/usr/include/module.modulemap" <<'EOF'
module ObjectiveC [system] {
  header "objc/objc.h"
  header "objc/objc-api.h"
  header "objc/runtime.h"
  header "objc/message.h"
  export *
  module NSObject  { header "objc/NSObject.h"      export * }
  module Protocol  { header "objc/Protocol.h"      export * }
  module Runtime   { header "objc/NSObjCRuntime.h" export * }
}
EOF
cp "$SDK/usr/include/ObjectiveC.apinotes" "$SYS/usr/include/ObjectiveC.apinotes"

# Foundation's Swift facade and the Objective-C runtime are separate package
# identities. Objective-C framework sources still require the canonical
# public include spelling. Use the same hash-pinned, no-overwrite staging
# contract as the central guest-package builder; it also owns the bounded
# arpa/inet.h SDK forwarding gap used by SystemConfiguration.
bash "$ROOT/full/foundation/stage_objc_platform_headers.sh" \
    "$SYS/usr/include"

# ---- API NOTES ARE NOT OPTIONAL, AND THE SYSROOT WAS STAGING ONE OF FIVE ----
# `Date.swift:239` failed with "cannot find 'CLOCK_REALTIME' in scope", and the
# obvious readings are all wrong: the macro IS in <_time.h>, byte-identical to
# Apple's; `_time.h` IS in module `_DarwinFoundation2._time`; a C program using
# CLOCK_REALTIME compiles against this sysroot both modular and not; and the
# ENUMERATOR `_CLOCK_REALTIME` imports into Swift fine.  Isolated by running
# Apple's own swiftc against OUR sysroot -- it fails there too, so it is the
# sysroot and not the Linux compiler.
#
# `CLOCK_REALTIME` IN SWIFT IS NOT THE C MACRO.  It is an API-notes RENAME of
# the enumerator `_CLOCK_REALTIME`, declared in `_DarwinFoundation2.apinotes`
# (37 lines, all eight CLOCK_* names).  ClangImporter does not import a
# `#define` that aliases an enumerator; the sidecar is the mechanism.
#
# stage_objc_module.sh already knew this class -- its own comment says every
# bit of ObjectiveC nullability comes from the sidecar -- but staged only that
# ONE file.  Apple ships five: ObjectiveC, _DarwinFoundation2, Dispatch, os,
# XPC.  We declare Clang modules for two of those, so two are staged.  A
# missing sidecar presents as "cannot find X in scope" for a symbol that is
# demonstrably present in C, which is why it survived every header-level check.
cp "$SDK/usr/include/_DarwinFoundation2.apinotes" "$SYS/usr/include/_DarwinFoundation2.apinotes"

# ---- the Darwin family, pruned to what this sysroot stages -----------------
python3 "$MACHORUN/scripts/gen_darwin_modulemap.py" "$SYS"

echo "== $SYS"
echo "  usr/include : $(find "$SYS/usr/include" -type f | wc -l | tr -d ' ') headers"
echo "  modulemaps  : $(ls "$SYS"/usr/include/*.modulemap | wc -l | tr -d ' ')"
