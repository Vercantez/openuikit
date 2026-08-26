# swift-macho-linux spike bed.
#
# swift:6.2-noble is already a cross-compiler that understands
# arm64-apple-macos; all it lacks is a Darwin stdlib, which scratch/sysroot
# supplies. lld-18 is the distro one on purpose: Swift's *bundled* lld is
# patched to refuse macOS linking, Ubuntu's ld64.lld-18 is not. Same choice
# machorun's harness/Dockerfile makes, and for the same reason.
FROM swift:6.2-noble
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        lld-18 llvm-18 clang-18 file xxd binutils \
    && rm -rf /var/lib/apt/lists/*
RUN ln -sf /usr/bin/ld64.lld-18 /usr/bin/ld64.lld
WORKDIR /w
