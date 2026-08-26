# Swift test bed for machorun's rung (q). arm64 native on an Apple-silicon
# host -- there is no CPU emulation anywhere in this project.
#
# Built (and named) by scripts/swift_gate.sh as machorun-swift:6.2.4.
#
# WHY A SECOND IMAGE, rather than adding Swift to harness/Dockerfile. That
# image is built on every difftest run and is 900 MB; a Swift toolchain is four
# times that and is needed by exactly one gate. Keeping them apart means the
# 19-fixture corpus does not pay for the Swift rung.
#
# The version is pinned to 6.2.4 and that is not a preference. The
# libswiftCore.dylib this gate runs against was cross-built from swift.org
# 6.2.4 source (~/swiftcore-macho); compiling a guest against a DIFFERENT
# compiler's Swift.swiftmodule is a mangled-name and ABI-record mismatch that
# shows up as undefined symbols at link time or garbage at run time. The image
# tag carries the version so a skew is visible rather than mysterious.
FROM swift:6.2-noble

# ld64.lld from Ubuntu's LLVM 18, NOT the one bundled with the Swift toolchain.
# harness/Dockerfile says why in more detail: Swift's bundled lld is patched to
# refuse Mach-O output, the distro one is not. scripts/swift_gate.sh passes
# -B /usr/lib/llvm-18/bin so clang picks this one and not the toolchain's.
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        lld-18 \
        llvm-18 \
        clang-18 \
        file \
        binutils \
        python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
