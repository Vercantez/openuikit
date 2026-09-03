#!/usr/bin/env python3
"""Apply the swiftcore-macho source edits to a pristine swift checkout.

Idempotent. Each edit is anchored on a unique string and asserts it matched, so
a version bump that moves the code fails loudly instead of silently no-opping.
Run from anywhere; pass the checkout as argv[1] (default ~/work/swift).

The authoritative record of *what* changed is `git diff` in the checkout, which
scripts/snapshot_patches.sh captures into patches/. The rationale for each edit
is the docstring above it.
"""
import sys, pathlib

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else
                    pathlib.Path.home() / "work" / "swift")

def edit(relpath, old, new, tag):
    p = ROOT / relpath
    s = p.read_text()
    if new in s:
        print(f"  [skip] {tag} (already applied)")
        return
    assert s.count(old) == 1, f"{tag}: anchor matched {s.count(old)}x in {relpath}"
    p.write_text(s.replace(old, new))
    print(f"  [ok]   {tag}")

# ---------------------------------------------------------------------------
# 1. Let a Linux host configure the OSX *target* SDK.
#
# `include(DarwinSDKs)` is reachable only from the branch that tests whether the
# HOST is Darwin, so on Linux the OSX SDK is never configured and -DSWIFT_SDKS=OSX
# silently yields a build with no targets. This is the one structural assumption
# that blocks the cross-build outright.
# ---------------------------------------------------------------------------
edit("CMakeLists.txt",
"""  # Default is Linux SDK for host
  set(SWIFT_PRIMARY_VARIANT_SDK_default  "${SWIFT_HOST_VARIANT_SDK}")
  set(SWIFT_PRIMARY_VARIANT_ARCH_default "${SWIFT_HOST_VARIANT_ARCH}")
""",
"""  # Default is Linux SDK for host
  set(SWIFT_PRIMARY_VARIANT_SDK_default  "${SWIFT_HOST_VARIANT_SDK}")
  set(SWIFT_PRIMARY_VARIANT_ARCH_default "${SWIFT_HOST_VARIANT_ARCH}")

  # swiftcore-macho: cross-build the Darwin stdlib from a Linux host.
  is_sdk_requested(OSX swift_build_osx_from_linux)
  if(swift_build_osx_from_linux)
    include(DarwinSDKs)
    set(SWIFT_PRIMARY_VARIANT_SDK_default  "OSX")
    list(GET SWIFT_SDK_OSX_ARCHITECTURES 0 SWIFT_PRIMARY_VARIANT_ARCH_default)
  endif()
""", "linux-host may configure OSX SDK")

# ---------------------------------------------------------------------------
# 2. Read SDK version/build metadata without `defaults`/`xcodebuild`.
#
# configure_sdk_darwin shells out to `defaults read .../SDKSettings.plist Version`
# and `xcodebuild -sdk ... -version ProductBuildVersion`. Neither exists on Linux;
# both merely populate version strings. We keep the Darwin path exactly as-is and
# fall back to reading our own SDKSettings.json when the tools are absent, so the
# values are still real rather than empty.
# ---------------------------------------------------------------------------
edit("cmake/modules/SwiftConfigureSDK.cmake",
"""  # Determine the SDK version we found.
  execute_process(
    COMMAND "defaults" "read" "${SWIFT_SDK_${prefix}_PATH}/SDKSettings.plist" "Version"
      OUTPUT_VARIABLE SWIFT_SDK_${prefix}_VERSION
      OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND "xcodebuild" "-sdk" "${SWIFT_SDK_${prefix}_PATH}" "-version" "ProductBuildVersion"
      OUTPUT_VARIABLE SWIFT_SDK_${prefix}_BUILD_NUMBER
      OUTPUT_STRIP_TRAILING_WHITESPACE)
""",
"""  # Determine the SDK version we found.
  execute_process(
    COMMAND "defaults" "read" "${SWIFT_SDK_${prefix}_PATH}/SDKSettings.plist" "Version"
      OUTPUT_VARIABLE SWIFT_SDK_${prefix}_VERSION
      OUTPUT_STRIP_TRAILING_WHITESPACE)

  execute_process(
    COMMAND "xcodebuild" "-sdk" "${SWIFT_SDK_${prefix}_PATH}" "-version" "ProductBuildVersion"
      OUTPUT_VARIABLE SWIFT_SDK_${prefix}_BUILD_NUMBER
      OUTPUT_STRIP_TRAILING_WHITESPACE)

  # swiftcore-macho: `defaults`/`xcodebuild` do not exist off Darwin. Fall back
  # to the SDK's own SDKSettings.json rather than proceeding with empty versions.
  if(NOT SWIFT_SDK_${prefix}_VERSION)
    file(READ "${SWIFT_SDK_${prefix}_PATH}/SDKSettings.json" _sdksettings)
    string(JSON SWIFT_SDK_${prefix}_VERSION GET "${_sdksettings}" "Version")
  endif()
  if(NOT SWIFT_SDK_${prefix}_BUILD_NUMBER)
    set(SWIFT_SDK_${prefix}_BUILD_NUMBER "${SWIFT_SDK_${prefix}_VERSION}")
  endif()
""", "SDK version without defaults/xcodebuild")

# ---------------------------------------------------------------------------
# 3. ImageInspectionMachO.cpp: give the _dyld_lookup_section_info fallback
#    declaration C linkage, and define LLVM_ATTRIBUTE_WEAK if nothing else did.
#
# The block is gated on OBJC_ADDLOADIMAGEFUNC2_DEFINED, which machorun's objc4
# (newer than the SDK Swift 6.2.4 targets) defines, so we enter a branch Apple's
# own build skips. Two things then break:
#   * LLVM_ATTRIBUTE_WEAK is not defined in this TU at all.
#   * the redeclaration sits at C++ namespace scope while our dyld_priv.h
#     declares the same function inside __BEGIN_DECLS, so the two are *overloads*
#     rather than redeclarations and every call is ambiguous.
# C linkage is what the symbol actually has; without extern "C" the fallback
# would emit a call to a mangled name that cannot exist. This is a latent
# upstream portability bug that only a non-Apple SDK exposes.
# ---------------------------------------------------------------------------
edit("stdlib/public/runtime/ImageInspectionMachO.cpp",
"""LLVM_ATTRIBUTE_WEAK
struct _dyld_section_info_result
_dyld_lookup_section_info(const struct mach_header *mh,
                          _dyld_section_location_info_t locationHandle,
                          enum _dyld_section_location_kind kind);
""",
"""#ifndef LLVM_ATTRIBUTE_WEAK
#define LLVM_ATTRIBUTE_WEAK __attribute__((weak))
#endif
extern "C" {
LLVM_ATTRIBUTE_WEAK
struct _dyld_section_info_result
_dyld_lookup_section_info(const struct mach_header *mh,
                          _dyld_section_location_info_t locationHandle,
                          enum _dyld_section_location_kind kind);
}
""", "dyld_lookup_section_info fallback decl gets C linkage")

# ---------------------------------------------------------------------------
# 4. Use the prebuilt swiftc when SWIFT_ENABLE_SWIFT_IN_SWIFT is OFF.
#
# SwiftSource.cmake's first branch hardcodes ${Swift_BINARY_DIR}/bin/swiftc and
# ignores SWIFT_NATIVE_SWIFT_TOOLS_PATH entirely. Its own comment says the path
# exists "only for bootstrapping purposes" — i.e. it assumes the only reason
# swift-in-swift is off is that you are mid-bootstrap and a stage-0 swiftc has
# just been built into the build tree. We are in the other case the flag allows:
# swift-in-swift off because we are not building a compiler at all
# (SWIFT_INCLUDE_TOOLS=OFF) and already have a complete 6.2.4 toolchain. Prefer
# the prebuilt compiler when one was supplied; fall back to the old behaviour
# otherwise, so the bootstrap path is untouched.
# ---------------------------------------------------------------------------
edit("stdlib/cmake/modules/SwiftSource.cmake",
"""  if(NOT SWIFT_ENABLE_SWIFT_IN_SWIFT)
    # This is only for bootstrapping purposes. The just-built Swift is very
    # limited and only built for the builder to build the next stages with
    # hosttools.
    set(swift_compiler_tool "${Swift_BINARY_DIR}/bin/swiftc")
""",
"""  if(NOT SWIFT_ENABLE_SWIFT_IN_SWIFT)
    # This is only for bootstrapping purposes. The just-built Swift is very
    # limited and only built for the builder to build the next stages with
    # hosttools.
    if(SWIFT_PREBUILT_SWIFT)
      # swiftcore-macho: not bootstrapping — a complete toolchain was supplied
      # and no compiler is being built into this tree.
      set(swift_compiler_tool "${SWIFT_NATIVE_SWIFT_TOOLS_PATH}/swiftc${HOST_EXECUTABLE_SUFFIX}")
    else()
      set(swift_compiler_tool "${Swift_BINARY_DIR}/bin/swiftc")
    endif()
""", "prebuilt swiftc when swift-in-swift is off")

# ---------------------------------------------------------------------------
# 5. Register images through objc_addLoadImageFunc + getsectiondata rather than
#    objc_addLoadImageFunc2 + _dyld_lookup_section_info.
#
# Optional (SWIFTCORE_MACHO_LEGACY_IMAGE_REG=1 in the environment). machorun's
# objc4 defines OBJC_ADDLOADIMAGEFUNC2_DEFINED, so Swift takes the newer path
# and asks _dyld_lookup_section_info for each section's location. machorun's
# libSystem exports that symbol but its answer is not the one Swift's MachO
# image inspector expects, and the runtime faults inside
# addImageDynamicReplacementBlockCallback while walking the returned buffer.
# The older path derives the same sections from the Mach-O header itself with
# getsectiondata, which needs nothing from the loader beyond a mapped image.
# ---------------------------------------------------------------------------
import os
if os.environ.get("SWIFTCORE_MACHO_LEGACY_IMAGE_REG") == "1":
    edit("stdlib/public/runtime/ImageInspectionMachO.cpp",
"""#if __has_include(<objc/objc-internal.h>) && __has_include(<mach-o/dyld_priv.h>)
#include <mach-o/dyld_priv.h>
#include <objc/objc-internal.h>""",
"""#if __has_include(<objc/objc-internal.h>) && __has_include(<mach-o/dyld_priv.h>)
#include <mach-o/dyld_priv.h>
#include <objc/objc-internal.h>
// swiftcore-macho: force the getsectiondata path (see patches rationale #5).
#undef OBJC_ADDLOADIMAGEFUNC2_DEFINED
#define OBJC_ADDLOADIMAGEFUNC2_DEFINED 0""", "legacy image registration path")

# ---------------------------------------------------------------------------
# 6. Widen the Objective-C isa mask to match machorun's objc4.
#
# machorun's patches-macho/0001-wide-va-isa-layout.patch widens objc4's ISA_MASK
# to 0x007ffffffffffff8 because the host is Linux, whose user addresses are 48
# bits wide; Apple's arm64 macOS mask (0x00007ffffffffff8, bits 3..46) would
# truncate every class pointer. Swift hardcodes Apple's value and bakes it into
# 48 AND/ANDS-immediate instructions in libswiftCore.
#
# machorun maps guest images above 2^47, so libswiftCore's narrower mask strips
# bit 47 from the class pointer (0x0000fe3de57774b8 -> 0x00007e3de57774b8) and
# the next instruction dereferences a non-class. That is the fault at
# swift_unknownObjectRelease+0x10. Only the unknownObject retain/release family
# reads the isa, which is why plain classes work and non-class-bound
# existentials / AnyObject do not.
#
# scripts/widen_isa_mask.py applies the identical change to an already-built
# dylib, for when no rebuild machine is available.
# ---------------------------------------------------------------------------
# NOT POLICY, and off by default. The team decided the loader fix (map images
# AND heap below 2^47) is the architecture: it repairs Apple's shipped runtime
# too, which widening never can. Keep this only as a fallback for a runtime we
# build and cannot re-target. Set SWIFTCORE_MACHO_WIDEN_ISA=1 to apply.
#
# Its anchor is ALSO unverified against 6.2.4 -- the constant is not in Swift's
# shipped shims and I could not confirm where it lives. It asserts on mismatch,
# so enabling it will fail loudly rather than silently no-op.
if os.environ.get("SWIFTCORE_MACHO_WIDEN_ISA") == "1":
    edit("include/swift/ABI/System.h",
         "0x00007ffffffffff8ULL",
         "0x007ffffffffffff8ULL /* swiftcore-macho: machorun wide-VA isa, patch 6 */",
         "wide-VA objc isa mask")

# ---------------------------------------------------------------------------
# 7. A Darwin target must not force the Darwin (dispatch) executor.
#
# stdlib/public/Concurrency/CMakeLists.txt compiles ALL PlatformExecutor*.swift
# unconditionally and lets each guard itself. PlatformExecutorDarwin.swift's
# guard is `os(macOS) || os(iOS) || ...` -- it never consults
# SWIFT_CONCURRENCY_GLOBAL_EXECUTOR. PlatformExecutorCooperative.swift has no
# guard at all. So choosing `singlethreaded` for a Darwin target compiles BOTH,
# and they both define PlatformExecutorFactory:
#
#   error: invalid redeclaration of 'PlatformExecutorFactory'
#   error: cannot find 'CFMainExecutor' in scope        (Darwin's deps are
#   error: cannot find 'DispatchMainExecutor' in scope   only built for dispatch)
#
# `singlethreaded` on a Darwin target is simply not a configuration upstream
# tests: Darwin is assumed to imply dispatch. Move the Darwin executor into the
# dispatch branch, where its dependencies actually exist.
# ---------------------------------------------------------------------------
edit("stdlib/public/Concurrency/CMakeLists.txt",
"""  CooperativeExecutor.swift
  PlatformExecutorDarwin.swift
  PlatformExecutorLinux.swift""",
"""  CooperativeExecutor.swift
  # swiftcore-macho: PlatformExecutorDarwin guards on os(macOS) alone, so on a
  # Darwin target it collides with whichever executor the build actually chose.
  # It belongs with the dispatch sources it depends on. See patch 7.
  PlatformExecutorLinux.swift""",
     "Darwin target does not imply the dispatch executor")

edit("stdlib/public/Concurrency/CMakeLists.txt",
"""  set(SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_SWIFT_SOURCES
    DispatchExecutor.swift
    CFExecutor.swift
    ExecutorImpl.swift
  )""",
"""  set(SWIFT_RUNTIME_CONCURRENCY_NONEMBEDDED_SWIFT_SOURCES
    DispatchExecutor.swift
    CFExecutor.swift
    PlatformExecutorDarwin.swift
    ExecutorImpl.swift
  )""",
     "Darwin executor moves into the dispatch branch")

# ---------------------------------------------------------------------------
# 8. Darwin *target* must not CMake-link a `dispatch` target that Linux-host
#    libdispatch never creates.
#
# SWIFT_ENABLE_DISPATCH defaults TRUE (CMakeLists.txt:767-769). That sets
# SWIFT_CONCURRENCY_USES_DISPATCH and SWIFT_CONCURRENCY_GLOBAL_EXECUTOR=dispatch
# (stdlib/cmake/modules/StdlibOptions.cmake:217-241). The concurrency sources
# that need that executor (DispatchGlobalExecutor.cpp, DispatchExecutor.swift,
# CFExecutor.swift, PlatformExecutorDarwin.swift) must stay compiled.
#
# cmake/modules/Libdispatch.cmake:49-56 does **not** ExternalProject-build
# dispatch for SWIFT_DARWIN_PLATFORMS ("Darwin targets have libdispatch
# available, do not build it"). The IMPORTED `dispatch-<subdir>-<arch>`
# target and the `dispatch` ALIAS (Libdispatch.cmake:157-168, 258-261) exist
# only for non-Darwin SDKs, and only when sdk == SWIFT_HOST_VARIANT_SDK.
#
# Concurrency/CMakeLists.txt:26-36 keys off CMAKE_SYSTEM_NAME STREQUAL
# Darwin (the *host*). On a Linux host it appends LINK_LIBRARIES `dispatch`
# (line 256). add_swift_target_library then passes that name through
# handle_swift_sources DEPENDS (AddSwiftStdlib.cmake:1058-1072). CMake treats
# a non-target DEPENDS name as a path relative to the current source dir, so
# ninja wants stdlib/public/Concurrency/dispatch with no rule — the operator
# wall on x86_64. A Darwin *host* skips the block: SDK headers + libSystem
# re-exports. A Darwin *target* on Linux must do the same; do not stub a
# dispatch dylib and do not force OSX into DISPATCH_SDKS.
# ---------------------------------------------------------------------------
edit("stdlib/public/Concurrency/CMakeLists.txt",
"""if("${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "dispatch")
  if(NOT CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    include_directories(AFTER
                          ${SWIFT_PATH_TO_LIBDISPATCH_SOURCE})

    # FIXME: we can't rely on libdispatch having been built for the
    # target at this point in the process.  Currently, we're relying
    # on soft-linking.
    list(APPEND swift_concurrency_link_libraries
      dispatch)
  endif()
""",
"""if("${SWIFT_CONCURRENCY_GLOBAL_EXECUTOR}" STREQUAL "dispatch")
  # Darwin host: SDK <dispatch.h> + libSystem re-exports. Linux host + Darwin
  # *target* (SWIFT_PRIMARY_VARIANT_SDK in SWIFT_DARWIN_PLATFORMS): same —
  # Libdispatch.cmake will not create a `dispatch` CMake target for OSX.
  # Keep SWIFT_ENABLE_DISPATCH ON so the dispatch executor sources compile.
  if(NOT CMAKE_SYSTEM_NAME STREQUAL "Darwin" AND
     NOT "${SWIFT_PRIMARY_VARIANT_SDK}" IN_LIST SWIFT_DARWIN_PLATFORMS)
    include_directories(AFTER
                          ${SWIFT_PATH_TO_LIBDISPATCH_SOURCE})

    # FIXME: we can't rely on libdispatch having been built for the
    # target at this point in the process.  Currently, we're relying
    # on soft-linking.
    list(APPEND swift_concurrency_link_libraries
      dispatch)
  endif()
""",
     "Darwin target does not CMake-link a missing dispatch target")

print("patches applied")
