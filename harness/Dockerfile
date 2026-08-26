# Linux test bed for machorun. arm64 native on an Apple-silicon host --
# there is no CPU emulation anywhere in this project.
#
# Built (and named) by harness/run_linux.sh as machorun-testbed:24.04.
FROM ubuntu:24.04

# clang/lld-18 are here because the same container also builds our Mach-O
# dylibs: Ubuntu's ld64.lld-18 links macOS dylibs, while Swift's *bundled*
# lld is patched to refuse. Keep using the distro one.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential \
        clang-18 \
        lld-18 \
        llvm-18 \
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
