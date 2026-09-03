# fe_sysroot_measurement.inc -- shared FE sysroot measurement-header helpers.
# Sourced by full/foundation/stage_fe_sysroot.sh (Darwin) and the x86 sibling
# (via scripts/x86/common.inc). The header set lives in
# fe_sysroot_measurement_headers.txt; do not duplicate that list in a stager.

if [ -n "${FE_SYSROOT_MEASUREMENT_INC:-}" ]; then
    return 0 2>/dev/null || true
fi
FE_SYSROOT_MEASUREMENT_INC=1

_fe_meas_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
FE_SYSROOT_MEASUREMENT_HEADERS_FILE=${FE_SYSROOT_MEASUREMENT_HEADERS_FILE:-$_fe_meas_dir/fe_sysroot_measurement_headers.txt}
unset _fe_meas_dir

# Print one relative usr/include path per line (comments and blanks skipped).
fe_sysroot_measurement_headers() {
    local f=${1:-$FE_SYSROOT_MEASUREMENT_HEADERS_FILE}
    [ -f "$f" ] || {
        echo "fe_sysroot_measurement_headers: missing $f" >&2
        return 1
    }
    grep -vE '^[[:space:]]*(#|$)' "$f"
}

# Append the measurement-only vm_copy declaration. Do not replace mach/vm_map.h.
fe_sysroot_append_vm_copy() {
    local vm_h=$1
    [ -f "$vm_h" ] || return 0
    if grep -q 'vm_copy' "$vm_h"; then
        return 0
    fi
    cat >> "$vm_h" <<'EOF'
/* APPENDED by fe_sysroot_append_vm_copy -- MEASUREMENT ONLY.
   Not in machorun's sdk/; see full/foundation/stage_fe_sysroot.sh. */
extern kern_return_t vm_copy(vm_map_t target_task, vm_address_t source_address,
                             vm_size_t size, vm_address_t dest_address);
EOF
    echo "  ~ mach/vm_map.h  [appended vm_copy decl -- MEASUREMENT ONLY]"
}
