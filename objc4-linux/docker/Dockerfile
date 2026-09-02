# Build environment for objc4-linux. Ubuntu 24.04 + clang.
# Everything is installed INSIDE the container; the macOS host is never touched.
FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        clang-18 lld-18 llvm-18 \
        libc++-18-dev libc++abi-18-dev \
        libblocksruntime-dev \
        cmake ninja-build make python3 \
        binutils file patch rsync ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/clang-18   /usr/bin/clang \
    && ln -sf /usr/bin/clang++-18 /usr/bin/clang++ \
    && ln -sf /usr/bin/ld.lld-18  /usr/bin/ld.lld

WORKDIR /src
