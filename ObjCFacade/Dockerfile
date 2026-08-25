# Toolchain image for the Objective-C facade prototype (docs/OBJC_FACADE.md).
#
# Base is swift:6.2-noble — the SAME image scripts/linux_verify.sh uses, which
# is Ubuntu 24.04 (noble) plus the Swift 6.2 toolchain. Using the identical
# base is deliberate: the Swift half of the bridge must be compiled by exactly
# the compiler that produces the byte-identical Linux renders, otherwise a
# pixel difference could not be attributed.
#
# On top of it we add the *modern* Objective-C world, which Ubuntu does not
# package:
#   * Ubuntu 24.04 ships gnustep-base 1.29.0 built against GCC's libobjc
#     (libobjc4 14.2.0). That runtime has no ARC, no non-fragile ivars and no
#     `objc_msgSend` fast path — it is the 1990s runtime. So we build the real
#     thing from source:
#   * libobjc2 (GNUstep ObjC runtime v2, ABI "gnustep-2.2")
#   * gnustep-make + gnustep-base, configured `ng-gnu-gnu` (new runtime,
#     gcc-style blocks off, GNU libraries) so NSString/NSArray/NSObject come
#     from gnustep-base and run on libobjc2.
FROM swift:6.2-noble

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        clang cmake ninja-build git ca-certificates make pkg-config \
        libffi-dev libxml2-dev libxslt1-dev libgnutls28-dev libicu-dev \
        libcurl4-openssl-dev libssl-dev zlib1g-dev libbsd-dev \
        libblocksruntime-dev autoconf libtool \
    && rm -rf /var/lib/apt/lists/*

ENV CC=clang CXX=clang++

# ---- libobjc2 ---------------------------------------------------------------
ARG LIBOBJC2_TAG=v2.2.1
RUN git clone --depth 1 --branch ${LIBOBJC2_TAG} \
        https://github.com/gnustep/libobjc2.git /src/libobjc2 \
 && cd /src/libobjc2 \
 && git submodule update --init --depth 1 \
 && cmake -S . -B build -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DGNUSTEP_INSTALL_TYPE=NONE \
        -DTESTS=OFF \
 && cmake --build build \
 && cmake --install build \
 && ldconfig

# ---- gnustep-make -----------------------------------------------------------
ARG GS_MAKE_TAG=make-2_9_3
RUN git clone --depth 1 --branch ${GS_MAKE_TAG} \
        https://github.com/gnustep/tools-make.git /src/tools-make \
 && cd /src/tools-make \
 && ./configure --prefix=/usr/local --with-layout=fhs \
        --with-library-combo=ng-gnu-gnu \
 && make -j"$(nproc)" && make install

ENV GNUSTEP_MAKEFILES=/usr/local/share/GNUstep/Makefiles \
    LD_LIBRARY_PATH=/usr/local/lib

# ---- gnustep-base -----------------------------------------------------------
ARG GS_BASE_TAG=base-1_31_1
RUN git clone --depth 1 --branch ${GS_BASE_TAG} \
        https://github.com/gnustep/libs-base.git /src/libs-base \
 && cd /src/libs-base \
 && . /usr/local/share/GNUstep/Makefiles/GNUstep.sh \
 && ./configure --prefix=/usr/local --disable-tls --disable-mixedabi \
 && make -j"$(nproc)" && make install && ldconfig

RUN printf '%s\n' \
    'libobjc2:      '"${LIBOBJC2_TAG}" \
    'gnustep-make:  '"${GS_MAKE_TAG}" \
    'gnustep-base:  '"${GS_BASE_TAG}" > /VERSIONS.txt
