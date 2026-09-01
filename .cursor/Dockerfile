# syntax=docker/dockerfile:1.7

# Keep this aligned with harness/Dockerfile. The digest pins the accepted
# multi-architecture Swift 6.2 / Ubuntu 24.04 image used by the Linux platform
# build, while Cursor Builds turn the prepared filesystem into a reusable VM.
FROM swift:6.2-noble@sha256:29b983751c605c2d3102d2ab93438c6e0cadf110d9d2aa6e929b6dec9dcb7cbc

ARG DEBIAN_FRONTEND=noninteractive

# Install toolchains and host libraries only. Do not compile OpenUIKit or
# retain project build products here: framework agents must cold-build their
# acceptance programs from clean scratch directories so stale artifacts can
# never make a gate pass.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        binutils \
        build-essential \
        ca-certificates \
        clang-18 \
        cmake \
        curl \
        file \
        fonts-dejavu-core \
        git \
        git-lfs \
        imagemagick \
        jq \
        libc++-18-dev \
        libcurl4-openssl-dev \
        libedit-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        libicu-dev \
        libncurses-dev \
        libpng-dev \
        libsdl2-dev \
        libsqlite3-dev \
        libxml2-dev \
        libz3-dev \
        lld-18 \
        llvm-18 \
        ninja-build \
        patchelf \
        pkg-config \
        python3 \
        python3-pip \
        python3-venv \
        ripgrep \
        rsync \
        shellcheck \
        sqlite3 \
        sudo \
        unzip \
        xxd \
        xvfb \
        zip \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sfn /usr/bin/ld64.lld-18 /usr/bin/ld64.lld \
    && printf 'ubuntu ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/ubuntu \
    && chmod 0440 /etc/sudoers.d/ubuntu \
    && git lfs install --system \
    && swiftc --version \
    && ld64.lld --version \
    && python3 --version

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    OPENUIKIT_MACIOS_ROOT=/opt/openuikit-evidence/dotnet-macios
