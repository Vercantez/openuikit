#!/usr/bin/env bash
# Unmodified libxml2 for Fuzi's real startup OpenSearch parsing.
set -euo pipefail
: "${W:?}" "${SYS:?}" "${OUT:?}" "${TARGET:?}"
XML="$OUT/focus-libxml"
mkdir -p "$XML"
archive="$XML/libxml2-2.9.13.tar.xz"
if [ ! -f "$archive" ]; then
    curl -fL --retry 3 https://download.gnome.org/sources/libxml2/2.9/libxml2-2.9.13.tar.xz -o "$archive"
fi
echo "276130602d12fe484ecc03447ee5e759d0465558fbc9d6bd144e3745306ebf0e  $archive" | sha256sum -c -
if [ ! -d "$XML/libxml2-2.9.13" ]; then tar -xf "$archive" -C "$XML"; fi
cmake -S "$XML/libxml2-2.9.13" -B "$XML/build" -G Ninja \
    -DCMAKE_SYSTEM_NAME=Darwin -DCMAKE_C_COMPILER=clang-18 \
    -DCMAKE_C_COMPILER_TARGET="$TARGET" -DCMAKE_OSX_SYSROOT="$SYS" \
    -DCMAKE_AR=/usr/bin/llvm-ar-18 -DCMAKE_RANLIB=/usr/bin/llvm-ranlib-18 \
    -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY -DCMAKE_BUILD_TYPE=Release \
    '-DCMAKE_C_FLAGS=-D_FORTIFY_SOURCE=0 -Drand_r=openui_xml_rand_r' \
    -DBUILD_SHARED_LIBS=OFF -DHAVE_RAND_R=1 \
    -DLIBXML2_WITH_THREADS=ON -DLIBXML2_WITH_HTTP=OFF -DLIBXML2_WITH_FTP=OFF \
    -DLIBXML2_WITH_ICONV=OFF -DLIBXML2_WITH_ZLIB=OFF -DLIBXML2_WITH_LZMA=OFF \
    -DLIBXML2_WITH_PYTHON=OFF -DLIBXML2_WITH_PROGRAMS=OFF -DLIBXML2_WITH_TESTS=OFF
cmake --build "$XML/build" --parallel 8
clang-18 -target "$TARGET" -isysroot "$SYS" -O2 -c \
    "$W/full/focus-ios/libxml_random.c" -o "$XML/random.o"
mkdir -p "$XML/include/libxml"
cp "$XML/libxml2-2.9.13/include/libxml/"*.h "$XML/include/libxml/"
cp "$XML/build/libxml/"*.h "$XML/include/libxml/"
