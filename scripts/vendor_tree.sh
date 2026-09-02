# Attest uikit/ and machorun/ as in-repo subtree trees (git rev-parse HEAD:dir)
# or as an external Git checkout override. Source this file; do not execute it.
#
# Required of the caller: a `die` function that prints and exits non-zero.

_vendor_pins_lib=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/vendor_pins.sh
# shellcheck source=vendor_pins.sh
. "$_vendor_pins_lib"
unset _vendor_pins_lib

vendor_canonical() {
    (CDPATH= cd -P -- "$1" && pwd)
}

vendor_is_inrepo() {
    local repo_root=$1 vendor_name=$2 vendor_path=$3 inrepo
    [ -d "$repo_root/$vendor_name" ] || return 1
    inrepo=$(vendor_canonical "$repo_root/$vendor_name") || return 1
    [ "$(vendor_canonical "$vendor_path")" = "$inrepo" ]
}

vendor_tree_of() {
    local repo_root=$1 vendor_name=$2 vendor_path=$3
    if vendor_is_inrepo "$repo_root" "$vendor_name" "$vendor_path"; then
        git -C "$repo_root" rev-parse --verify "HEAD:$vendor_name"
    else
        git -C "$vendor_path" rev-parse --verify 'HEAD^{tree}'
    fi
}

vendor_status_of() {
    local repo_root=$1 vendor_name=$2 vendor_path=$3
    if vendor_is_inrepo "$repo_root" "$vendor_name" "$vendor_path"; then
        git -C "$repo_root" status --porcelain=v1 --untracked-files=all -- "$vendor_name"
    else
        git -C "$vendor_path" status --porcelain=v1 --untracked-files=all
    fi
}

# Usage: assert_vendor_tree REPO_ROOT NAME PATH EXPECTED_TREE LABEL
# NAME is the subtree directory (uikit or machorun). LABEL is a human prefix.
assert_vendor_tree() {
    local repo_root=$1 vendor_name=$2 vendor_path=$3 expected_tree=$4 label=$5
    local actual status
    [ -n "$repo_root" ] && [ -n "$vendor_name" ] && [ -n "$vendor_path" ] \
        && [ -n "$expected_tree" ] && [ -n "$label" ] \
        || die "$label: assert_vendor_tree is missing an argument"
    [ "${#expected_tree}" -eq 40 ] || die "$label expected tree must be lowercase 40-hex"
    case "$expected_tree" in *[!0-9a-f]*)
        die "$label expected tree must be lowercase 40-hex" ;;
    esac
    [ -d "$vendor_path" ] && [ ! -L "$vendor_path" ] \
        || die "$label is not a real directory: $vendor_path"
    if vendor_is_inrepo "$repo_root" "$vendor_name" "$vendor_path"; then
        actual=$(git -C "$repo_root" rev-parse --verify "HEAD:$vendor_name") \
            || die "$label: cannot read in-repo tree HEAD:$vendor_name"
        [ "$actual" = "$expected_tree" ] \
            || die "$label in-repo tree $actual, expected $expected_tree (git rev-parse HEAD:$vendor_name)"
        status=$(git -C "$repo_root" status --porcelain=v1 --untracked-files=all -- "$vendor_name") \
            || die "$label: cannot inspect in-repo $vendor_name/ status"
        [ -z "$status" ] || die "$label subtree is dirty: $status"
        return 0
    fi
    [ -d "$vendor_path/.git" ] || [ -f "$vendor_path/.git" ] \
        || die "$label is not a Git checkout and is not the in-repo $vendor_name/ subtree: $vendor_path"
    actual=$(git -C "$vendor_path" rev-parse --verify 'HEAD^{tree}') \
        || die "$label: cannot read checkout tree"
    [ "$actual" = "$expected_tree" ] \
        || die "$label checkout tree $actual, expected $expected_tree"
    status=$(git -C "$vendor_path" status --porcelain=v1 --untracked-files=all) \
        || die "$label: cannot inspect checkout status"
    [ -z "$status" ] || die "$label checkout is not clean: $status"
}

# Print NUL-terminated Git paths relative to the vendor directory.
vendor_ls_files() {
    local repo_root=$1 vendor_name=$2 vendor_path=$3 pathspec=$4
    if vendor_is_inrepo "$repo_root" "$vendor_name" "$vendor_path"; then
        git -C "$repo_root" ls-files -z -- "$vendor_name/$pathspec" \
            | while IFS= read -r -d '' path; do
                printf '%s\0' "${path#"$vendor_name"/}"
            done
    else
        git -C "$vendor_path" ls-files -z -- "$pathspec"
    fi
}

resolve_inrepo_or_override() {
    local repo_root=$1 vendor_name=$2 override=$3
    if [ -n "$override" ]; then
        printf '%s\n' "$override"
    else
        printf '%s\n' "$repo_root/$vendor_name"
    fi
}
