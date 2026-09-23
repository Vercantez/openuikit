#!/bin/zsh
# guestsqliteoptions -- the iOS 26.1 simulator's libsqlite3: version,
# sqlite3_threadsafe() and every sqlite3_compileoption_get() row. The guest's
# libsqlite3.dylib (full/sqlite/build_sqlite_guest.sh) takes its compile options
# from this transcript; full/sqlite/apple_compile_options.tsv says which rows
# are reproduced and why the others are not.
set -eu
D=${0:A:h}
source $D/../sim_lock.zsh
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
OUT=${OUT:-/tmp/guestsqliteoptions}
mkdir -p $OUT
xcrun --sdk iphonesimulator clang -target arm64-apple-ios26.1-simulator -isysroot $SDK $D/main.c -lsqlite3 -o $OUT/sqlopts
sim_lock_acquire
DEV=$(xcrun simctl create "iPhone 16-sqlopts" "iPhone 16" com.apple.CoreSimulator.SimRuntime.iOS-26-1)
trap 'xcrun simctl shutdown "$DEV" >/dev/null 2>&1; xcrun simctl delete "$DEV" >/dev/null 2>&1; sim_lock_release' EXIT
timeout 180 xcrun simctl boot "$DEV"
timeout 180 xcrun simctl bootstatus "$DEV" -b >/dev/null 2>&1
timeout 60 xcrun simctl spawn "$DEV" $OUT/sqlopts > $D/transcript-ios26.1.txt
cat $D/transcript-ios26.1.txt
