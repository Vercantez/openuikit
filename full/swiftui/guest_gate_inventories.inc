# guest_gate_inventories.inc -- ARCH-keyed widget/onboarding gate inventories.
# Sourced after full/scripts/guest_arch.inc. Python is the source of truth.
_GUEST_GATE_INVENTORIES_PY="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/guest_gate_inventories.py"

guest_gate_inventory() {
    local gate=$1 kind=$2 name=${3:-}
    local -a args=(
        --arch "${ARCH:?}"
        --gate "$gate"
        --kind "$kind"
        --bind "PACKAGE=${PACKAGE:-}"
        --bind "SYS=${SYS:-}"
        --bind "MRROOT=${MRROOT:-}"
        --bind "FULL=${FULL:-}"
        --bind "OUT=${OUT:-}"
        --bind "FE_OUT=${FE_OUT:-}"
        --bind "FE_COLLECTIONS=${FE_COLLECTIONS:-}"
        --bind "FE_OS=${FE_OS:-}"
        --bind "FE_CSHIMS=${FE_CSHIMS:-}"
        --bind "OPENCOMBINE_ARTIFACTS=${OPENCOMBINE_ARTIFACTS:-}"
        --bind "RELATIVE_TIME_RUNTIME=${RELATIVE_TIME_RUNTIME:-}"
    )
    [ -n "$name" ] && args+=(--name "$name")
    python3 "$_GUEST_GATE_INVENTORIES_PY" "${args[@]}"
}
