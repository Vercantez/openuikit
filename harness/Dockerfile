# swift-macho-linux spike bed.
#
# swift:6.2-noble is already a cross-compiler that understands
# arm64-apple-macos; all it lacks is a Darwin stdlib, which scratch/sysroot
# supplies. lld-18 is the distro one on purpose: Swift's *bundled* lld is
# patched to refuse macOS linking, Ubuntu's ld64.lld-18 is not. Same choice
# machorun's harness/Dockerfile makes, and for the same reason. The manifest
# digest resolves to the accepted Linux/ARM64 base image
# sha256:b7a5862e90bdf042ed5586b26cd47135ec93c4f97d3dd4d3181fdabcccc3c6d7.
FROM swift:6.2-noble@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        lld-18=1:18.1.3-1ubuntu1 \
        llvm-18=1:18.1.3-1ubuntu1 \
        clang-18=1:18.1.3-1ubuntu1 \
        libc++-18-dev=1:18.1.3-1ubuntu1 \
        file=1:5.45-3build1 \
        xxd=2:9.1.0016-1ubuntu7.20 \
        binutils=2.42-4ubuntu2.10 \
        python3=3.12.3-0ubuntu2.1 \
    && rm -rf /var/lib/apt/lists/*
RUN ln -sf /usr/bin/ld64.lld-18 /usr/bin/ld64.lld
WORKDIR /w
