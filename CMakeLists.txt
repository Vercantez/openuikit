#
# objc4-linux -- build Apple's Objective-C runtime for Linux/ELF.
#
# Driven by scripts/build_linux.sh, which runs it inside the Ubuntu 24.04 +
# clang container from docker/Dockerfile. Configuring this directly on a host
# is possible but the toolchain must match; the container is the contract.
#
# The compile flags here MIRROR scripts/flags.sh (used by the per-file
# inventory). Keep the two in sync -- flags.sh is the one that fails loudly.
#
cmake_minimum_required(VERSION 3.22)
project(objc4-linux C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

set(OBJC4_SRC   "${CMAKE_SOURCE_DIR}/build/objc4-src")
set(OBJC4_GEN   "${CMAKE_SOURCE_DIR}/build/gen")
set(OBJC4_RT    "${OBJC4_SRC}/runtime")

if(NOT EXISTS "${OBJC4_RT}/objc-runtime-new.mm")
    message(FATAL_ERROR
        "${OBJC4_RT} not found. Run scripts/apply-patches.sh first "
        "(scripts/build_linux.sh does this for you).")
endif()

# ---------------------------------------------------------------------------
# Architecture
# ---------------------------------------------------------------------------
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
    set(OBJC4_ARCH aarch64)
    # __arm64__ / __arm64 are APPLE-ONLY predefines. objc4 has 43 `#if
    # __arm64__` sites; without this every one takes the x86-64/generic branch,
    # silently, including the cache_t layout that C and the assembly messenger
    # must agree on. See docs/PORT_MAP.md 2.7.
    set(OBJC4_ARCH_DEFS __arm64__=1 __arm64=1)
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    set(OBJC4_ARCH x86_64)
    set(OBJC4_ARCH_DEFS "")
    message(WARNING "objc4-linux: x86-64 is not ported yet (PORT_PLAN phase 4)")
else()
    message(FATAL_ERROR "objc4-linux: unsupported arch ${CMAKE_SYSTEM_PROCESSOR}")
endif()

# ---------------------------------------------------------------------------
# Generated sources
#   1. include/objc/*.h  -- objc4 says <objc/runtime.h>; the headers live flat
#      in runtime/. Darwin uses a VFS overlay; we use a symlink tree.
#   2. asm/*-elf.s       -- Mach-O assembly translated to ELF/GAS dialect.
# ---------------------------------------------------------------------------
add_custom_target(objc4_gen_includes ALL
    COMMAND ${CMAKE_COMMAND} -E env WORK=${CMAKE_SOURCE_DIR}
            bash ${CMAKE_SOURCE_DIR}/scripts/gen-include-tree.sh
    COMMENT "generating <objc/*.h> include tree")

set(OBJC4_ASM_INPUTS
    "${OBJC4_RT}/arm64-asm.h"
    "${OBJC4_RT}/Messengers.subproj/objc-msg-arm64.s"
    "${OBJC4_RT}/retain-release-helpers-arm64.s")

set(OBJC4_ASM_GEN
    "${OBJC4_GEN}/asm/arm64-asm-elf.h"
    "${OBJC4_GEN}/asm/objc-msg-arm64-elf.s"
    "${OBJC4_GEN}/asm/retain-release-helpers-arm64-elf.s")

add_custom_command(
    OUTPUT ${OBJC4_ASM_GEN}
    COMMAND ${CMAKE_COMMAND} -E make_directory "${OBJC4_GEN}/asm"
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/gen-elf-asm.py
            "${OBJC4_RT}/arm64-asm.h" "${OBJC4_GEN}/asm/arm64-asm-elf.h"
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/gen-elf-asm.py
            "${OBJC4_RT}/Messengers.subproj/objc-msg-arm64.s"
            "${OBJC4_GEN}/asm/objc-msg-arm64-elf.s"
    COMMAND python3 ${CMAKE_SOURCE_DIR}/scripts/gen-elf-asm.py
            "${OBJC4_RT}/retain-release-helpers-arm64.s"
            "${OBJC4_GEN}/asm/retain-release-helpers-arm64-elf.s"
    DEPENDS ${OBJC4_ASM_INPUTS} ${CMAKE_SOURCE_DIR}/scripts/gen-elf-asm.py
    COMMENT "translating Mach-O assembly to ELF dialect")
add_custom_target(objc4_gen_asm ALL DEPENDS ${OBJC4_ASM_GEN})

# ---------------------------------------------------------------------------
# Sources
# ---------------------------------------------------------------------------
file(GLOB OBJC4_MM  "${OBJC4_RT}/*.mm")
file(GLOB OBJC4_M   "${OBJC4_RT}/*.m")

# dummy-library-mac-i386.c is a 10.x i386 dylib compatibility stub. Nothing on
# aarch64 Linux can reach it.
list(FILTER OBJC4_MM EXCLUDE REGEX "dummy-library-mac-i386")

set(OBJC4_COMPAT_SRC
    "${CMAKE_SOURCE_DIR}/compat/src/objc4linux-compat.cpp"
    "${CMAKE_SOURCE_DIR}/compat/src/objc4linux-elf.cpp")

if(OBJC4_ARCH STREQUAL aarch64)
    set(OBJC4_ASM
        "${OBJC4_GEN}/asm/objc-msg-arm64-elf.s"
        "${OBJC4_GEN}/asm/retain-release-helpers-arm64-elf.s")
else()
    set(OBJC4_ASM "")
endif()

# ---------------------------------------------------------------------------
# Flags
# ---------------------------------------------------------------------------
set(OBJC4_DEFS
    _GNU_SOURCE
    OBJC4LINUX=1
    __OBJC2__=1
    OBJC_DECLARE_SYMBOLS=1
    ${OBJC4_ARCH_DEFS})

set(OBJC4_INCLUDES
    "${OBJC4_GEN}/include"
    "${OBJC4_RT}"
    "${CMAKE_SOURCE_DIR}/compat"
    "${OBJC4_GEN}/asm")

# NOTE the COMPILE_LANGUAGE guard on -include: force-including a C header
# into an assembly translation unit feeds <stdlib.h> to the assembler, which
# reports ~900 "unrecognized instruction mnemonic" errors.
set(OBJC4_COMMON_FLAGS
    -fPIC -fno-strict-aliasing -fblocks -fno-exceptions -fno-rtti
    -fvisibility=hidden -funwind-tables
    $<$<COMPILE_LANGUAGE:C,CXX>:-include$<SEMICOLON>objc4linux/darwin-cdefs.h>
    -Wno-unused-parameter -Wno-unknown-pragmas -Wno-deprecated-declarations
    -Wno-gcc-compat -Wno-unused-function -Wno-unknown-warning-option)

add_library(objc SHARED
    ${OBJC4_MM} ${OBJC4_M} ${OBJC4_COMPAT_SRC} ${OBJC4_ASM})
add_dependencies(objc objc4_gen_includes objc4_gen_asm)

set_target_properties(objc PROPERTIES OUTPUT_NAME objc)
target_compile_definitions(objc PRIVATE ${OBJC4_DEFS})
target_include_directories(objc PRIVATE ${OBJC4_INCLUDES})
target_compile_options(objc PRIVATE ${OBJC4_COMMON_FLAGS})

# .mm is ObjC++ and must be compiled with the APPLE runtime ABI -- that is the
# whole point of the project. .m (objc-magicsel.m) is deliberately plain ObjC:
# it contains @selector(<emoji>), which C++ rejects as an identifier.
foreach(f ${OBJC4_MM})
    set_source_files_properties(${f} PROPERTIES
        LANGUAGE CXX
        COMPILE_OPTIONS "-x;objective-c++;-fobjc-runtime=macosx-10.15")
endforeach()
foreach(f ${OBJC4_M})
    set_source_files_properties(${f} PROPERTIES
        LANGUAGE C
        COMPILE_OPTIONS "-x;objective-c;-fobjc-runtime=macosx-10.15")
endforeach()
foreach(f ${OBJC4_ASM})
    set_source_files_properties(${f} PROPERTIES
        LANGUAGE ASM
        COMPILE_OPTIONS "-x;assembler-with-cpp")
endforeach()

target_link_libraries(objc PRIVATE pthread dl BlocksRuntime)

# The client-facing header set: build/<arch>/include/objc/*.h, self-contained.
# harness/run_linux.sh looks for exactly this next to libobjc.so.
add_custom_command(TARGET objc POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E env WORK=${CMAKE_SOURCE_DIR}
            bash ${CMAKE_SOURCE_DIR}/scripts/gen-sdk.sh
            ${CMAKE_BINARY_DIR}/include
    COMMENT "assembling client header set in ${CMAKE_BINARY_DIR}/include")

# Building the .so is expected to FAIL at link time in the current phase:
# image discovery (runtime/objc-elf.mm) does not exist yet, so several symbols
# the runtime references have no definition. Use `objc_objects` to build every
# translation unit without linking -- that is the phase's actual deliverable.
add_library(objc_objects OBJECT
    ${OBJC4_MM} ${OBJC4_M} ${OBJC4_COMPAT_SRC} ${OBJC4_ASM})
add_dependencies(objc_objects objc4_gen_includes objc4_gen_asm)
target_compile_definitions(objc_objects PRIVATE ${OBJC4_DEFS})
target_include_directories(objc_objects PRIVATE ${OBJC4_INCLUDES})
target_compile_options(objc_objects PRIVATE ${OBJC4_COMMON_FLAGS})
