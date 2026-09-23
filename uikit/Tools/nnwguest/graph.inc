# MEASUREMENT ONLY (uikit/Tools/nnwguest/README.md). Sourced by a diagnostic
# copy of full/scripts/build_full.sh right after the guest Apple-name modules
# (CoreGraphics, Security), where compile_app_module, compile_app_objc,
# compile_app_c and OBJC_SWIFT_FLAGS exist. Builds NetNewsWire's chain for
# real from $NNWG_DIR/plan.sh (plan.py) and prints the frontier:
#   NNWG <target> OK | FAILED errors=<n> ...
# A module that fails is compiled again with allow-errors so the modules after
# it are still measured; nothing here is linked or run yet. Ends the build.
set +e
G=$NNWG_DIR/graph-$(echo "$TARGET" | cut -d- -f3)
rm -rf "$G"; mkdir -p "$G/logs" "$G/obj" "$G/bundles"
NNWG_OBJECTS=()
nnwg_clang() {
    local name=$1 count=$2; shift 2
    local flags=() sources=() seen=0 rc=0 f o a
    for a in "$@"; do
        if [ "$a" = -- ]; then seen=1; continue; fi
        if [ "$seen" = 0 ]; then flags+=("$a"); else sources+=("$a"); fi
    done
    : > "$G/logs/$name.log"
    for f in "${sources[@]}"; do
        o="$G/obj/$name-$(basename "${f%.*}").o"
        case $f in
            *.m) compile_app_objc "$o" "$f" "${flags[@]}" >> "$G/logs/$name.log" 2>&1 || rc=1 ;;
            *.c) compile_app_c "$o" "$f" "${flags[@]}" ${ZLIB_INCLUDE:+-I "$ZLIB_INCLUDE"} \
                     >> "$G/logs/$name.log" 2>&1 || rc=1 ;;
        esac
        [ -f "$o" ] && NNWG_OBJECTS+=("$o")
    done
    echo "NNWG $name $([ $rc = 0 ] && echo OK || echo FAILED) kind=clang sources=$count errors=$(grep -c 'error:' "$G/logs/$name.log")"
}
nnwg_bundle() {
    local stem=$1 accessor=$2 resources=$3
    python3 "$W/full/xcodeplan/swiftpm_resource_accessor.py" "$stem" "$accessor"
    rm -rf "$G/bundles/$stem.bundle"; mkdir -p "$G/bundles/$stem.bundle"
    cp -R "$resources/." "$G/bundles/$stem.bundle/"
}
nnwg_swift() {
    local name=$1; shift
    if compile_app_module "$name" "$G/obj/$name.o" "${OBJC_SWIFT_FLAGS[@]}" "$@" > "$G/logs/$name.log" 2>&1; then
        echo "NNWG $name OK"
        NNWG_OBJECTS+=("$G/obj/$name.o")
    else
        local n
        n=$(grep -c ': error:' "$G/logs/$name.log")
        grep -q 'Stack dump:' "$G/logs/$name.log" && n="$n+frontend-crash"
        compile_app_module "$name" "$G/obj/$name.o" "${OBJC_SWIFT_FLAGS[@]}" \
            -Xfrontend -experimental-allow-module-with-compiler-errors "$@" > "$G/logs/$name.allow.log" 2>&1
        echo "NNWG $name FAILED errors=$n first=$(grep -m1 ': error:' "$G/logs/$name.log" | sed -E 's|^.*/Sources/||' | cut -c1-160)"
    fi
}
. "$NNWG_DIR/plan.sh"
echo "NNWG_DONE objects=${#NNWG_OBJECTS[@]}"
exit 0
