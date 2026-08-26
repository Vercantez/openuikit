# Linux test bed for machorun. arm64 native on an Apple-silicon host --
# there is no CPU emulation anywhere in this project.
#
# Built (and named) by harness/run_linux.sh as machorun-testbed:24.04.
FROM ubuntu:24.04

# clang/lld-18 are here because the same container also builds our Mach-O
# dylibs: Ubuntu's ld64.lld-18 links macOS dylibs, while Swift's *bundled*
# lld is patched to refuse. Keep using the distro one.
#
# libc++-18-dev is here because sdk/ has no usr/include/c++/v1 and never will.
# 67% of the SDK surface objc4 reached was Apple's libc++, and docs/SDK_SURVEY.md
# §2.5 measured the substitution rather than assuming it: stock LLVM 18 libc++
# compiles all 28 C++ TUs, produces a byte-identical 09_objc and scores the same
# 41/44 with the same 3 failures. scripts/build_objc4.sh carries the three
# defines that make it behave (__STDC_WANT_LIB_EXT1__, the hardening mode and
# _LIBCPP_VERBOSE_ABORT); that script's header says why each is needed.
# Version-pinned on purpose: this is a build input, not a convenience.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        clang-18 \
        lld-18 \
        llvm-18 \
        libc++-18-dev \
        libc++abi-18-dev \
        curl \
        cmake \
        ninja-build \
        pkg-config \
        python3 \
        file \
        binutils \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 \
 && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 \
 && ln -sf /usr/bin/ld64.lld-18 /usr/bin/ld64.lld

WORKDIR /work
